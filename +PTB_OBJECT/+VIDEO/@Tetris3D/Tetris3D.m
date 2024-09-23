classdef Tetris3D < PTB_OBJECT.VIDEO.Base
    %TETRIS3D Class to prepare and draw 3D Tetris, using OpenGL rendering
    % all coordinates are in OpenGL style

    properties(GetAccess = public, SetAccess = public)
        % User accessible paramters :

        % segment_length represents the number of cubes for each segment
        % segment_length = [3 2 4] means 3 cubes, then 2 cubes, then 4 cubes
        segment_length         (1,:) double {mustBeInteger,mustBePositive}

        camera_fov             (1,1) double = 30                           % degree
        camera_init_pos        (1,1) PTB_OBJECT.GEOMETRY.vec3 = [10 10 10] % [X Y Z] OpenGL coordinates
        camera_init_rot_vector (1,1) PTB_OBJECT.GEOMETRY.vec3 = [0 1 1]    % [X Y Z] OpenGL coordinates
        camera_init_rot_angle  (1,1) double = 30                           % degree

        light0_pos             (1,1) PTB_OBJECT.GEOMETRY.vec3 = [0 +10 0]  % [X Y Z] OpenGL coordinates
        lignt0_is_point        (1,1) logical = true                        % false == infinit distance (direction) // true == finit distance (point)
        light0_AMBIENT         (1,4) double = [0.1 0.1 0.1  1.0]           % [R G B a] OpenGL style
        light0_DIFFUSE         (1,4) double = [1.0 1.0 1.0  1.0]           % [R G B a] OpenGL style
        light0_SPECULAR        (1,4) double = [1.0 1.0 1.0  1.0]           % [R G B a] OpenGL style

        light1_pos             (1,1) PTB_OBJECT.GEOMETRY.vec3 = [0 -10 0]  % [X Y Z] OpenGL coordinates
        lignt1_is_point        (1,1) logical = false                       % false == infinit distance (direction) // true == finit distance (point)
        light1_AMBIENT         (1,4) double = [0.0 0.0 0.0  1.0]           % [R G B a] OpenGL style
        light1_DIFFUSE         (1,4) double = [0.2 0.2 0.2  1.0]           % [R G B a] OpenGL style
        light1_SPECULAR        (1,4) double = [0.0 0.0 0.0  1.0]           % [R G B a] OpenGL style

        n_pixel_cubeface       (1,:) double {mustBeInteger,mustBePositive} = 32 % % powers of 2 are faster for redering
        textured_cube_AMBIENT  (1,4) double = [ 0.5 0.5 0.5  1.0 ];        % [R G B a] OpenGL style
        textured_cube_DIFFUSE  (1,4) double = [ 1.0 1.0 1.0  1.0 ];        % [R G B a] OpenGL style
        textured_cube_SHININESS(1,1) double = 30;                          % 0 .. 128
        textured_cube_SPECULAR (1,4) double = [ 1.0 1.0 1.0  1.0 ];        % [R G B a] OpenGL style

        wired_cube_AMBIENT     (1,4) double = [ 0.0 0.0 0.0  1.0 ];        % [R G B a] OpenGL style
        wired_cube_DIFFUSE     (1,4) double = [ 0.0 0.0 0.0  1.0 ];        % [R G B a] OpenGL style
        wired_cube_SHININESS   (1,1) double = 30;                          % 0 .. 128
        wired_cube_SPECULAR    (1,4) double = [ 0.0 0.0 0.0  1.0 ];        % [R G B a] OpenGL style
        wired_cube_LineWidth   (1,1) double = 2.0;
        wired_cube_Size        (1,1) double = 1.01;
    end % props

    properties(GetAccess = public, SetAccess = protected)
        % Internal parameters :
        tex_cubeface           (6,1) uint32  % vector containing pointer to OpenGL texture
        cube_vertex            (3,8) double  % vec3 for 8 vertex
        cube_face              (6,4) double  % 6 faces of 4 vertex
        cube_normal            (3,6) double  % vec3 of 6 faces

        img_L_cropped          (:,:,4) uint8 % R G B a
        img_R_cropped          (:,:,4) uint8 % R G B a

        img_L_rect             (1,4) double % [x0 y0 x1 x1] PTB rect
        img_R_rect             (1,4) double % [x0 y0 x1 x1] PTB rect

        texture_L              (1,1) double % PTB texture pointer
        texture_R              (1,1) double % PTB texture pointer
    end % props


    methods(Access = public)

        %--- constructor --------------------------------------------------
        function self = Tetris3D()
            % pass
        end % fcn

        %------------------------------------------------------------------
        function InitializeOpenGL(self)
            global GL

            % Setup the OpenGL rendering context of the onscreen window for use by
            % OpenGL wrapper. After this command, all following OpenGL commands will
            % draw into the onscreen window 'win':
            Screen('BeginOpenGL', self.window.ptr);

            % Setup default drawing color to yellow (R,G,B)=(1,1,0). This color only
            % gets used when lighting is disabled - if you comment out the call to
            % glEnable(GL.LIGHTING).
            glColor3f(1,0,1); % cyan == error !

            % Turn on OpenGL local lighting model: The lighting model supported by
            % OpenGL is a local Phong model with Gouraud shading. The color values
            % at the vertices (corners) of polygons are computed with the Phong lighting
            % model and linearly interpolated accross the inner area of the polygon from
            % the vertex colors. The Phong lighting model is a coarse approximation of
            % real world lighting with ambient light reflection (undirected isotropic light),
            % diffuse light reflection (position wrt. light source matters, but observer
            % position doesn't) and specular reflection (ideal mirror reflection for highlights).
            %
            % The model does not take any object relationships into account: Any effects
            % of (self-)occlusion, (self-)shadowing or interreflection of light between
            % objects are ignored. If you need shadows, interreflections and global illumination
            % you will either have to learn advanced OpenGL rendering and shading techniques
            % to implement your own realtime shadowing and lighting models, or
            % compute parts of the scene offline in some gfx-package like Maya, Blender,
            % Radiance or 3D Studio Max...
            %
            % If you want to do any shape from shading studies, it is very important to
            % understand the difference between a local lighting model and a global
            % illumination model!!!
            glEnable(GL.LIGHTING);

            % Enable proper occlusion handling via depth tests:
            glEnable(GL.DEPTH_TEST);

            % Use alpha-blending:
            glEnable(GL.BLEND);
            glBlendFunc(GL.SRC_ALPHA, GL.ONE_MINUS_SRC_ALPHA);

            % Enable two-sided lighting - Back sides of polygons are lit as well.
            glLightModelfv(GL.LIGHT_MODEL_TWO_SIDE,GL.TRUE);

            % Make sure that surface normals are always normalized to unit-length,
            % regardless what happens to them during morphing. This is important for
            % correct lighting calculations:
            glEnable(GL.NORMALIZE);

            % Set background clear color (RGBa)
            glClearColor(...
                self.window.bg_color(1)/255, ...
                self.window.bg_color(2)/255, ...
                self.window.bg_color(3)/255, ...
                1                            ...
                );

            % Set projection matrix: This defines a perspective projection,
            % corresponding to the model of a pin-hole camera - which is a good
            % approximation of the human eye and of standard real world cameras --
            % well, the best aproximation one can do with 3 lines of code ;-)
            glMatrixMode(GL.PROJECTION);
            glLoadIdentity();

            % Get the aspect ratio of the screen:
            AspectRatio = self.window.size_x / self.window.size_y;

            % Field of view is 25 degrees from line of sight. Objects closer than
            % 0.01 distance units or farther away than 100 distance units get
            % clipped away, aspect ratio is adapted to the monitors aspect ratio:
            gluPerspective(self.camera_fov, AspectRatio, 0.01, 100);

            % Enable the first local light source GL.LIGHT_0. Each OpenGL
            % implementation is guaranteed to support at least 8 light sources,
            % GL.LIGHT0, ..., GL.LIGHT7

            % LIGHT0
            glEnable (GL.LIGHT0);
            glLightfv(GL.LIGHT0, GL.AMBIENT , self.light0_AMBIENT);
            glLightfv(GL.LIGHT0, GL.DIFFUSE , self.light0_DIFFUSE);
            glLightfv(GL.LIGHT0, GL.SPECULAR, self.light0_SPECULAR);
            glLightfv(GL.LIGHT0,GL.POSITION,[ self.light0_pos.xyz ; self.lignt0_is_point ]);

            % LIGHT1
            glEnable (GL.LIGHT1);
            glLightfv(GL.LIGHT1, GL.AMBIENT , self.light1_AMBIENT);
            glLightfv(GL.LIGHT1, GL.DIFFUSE , self.light1_DIFFUSE);
            glLightfv(GL.LIGHT1, GL.SPECULAR, self.light1_SPECULAR);
            glLightfv(GL.LIGHT1,GL.POSITION,[ self.light1_pos.xyz ; self.lignt1_is_point ]);

            % Finish OpenGL rendering into PTB window. This will switch back to the
            % standard 2D drawing functions of Screen and will check for OpenGL errors.
            Screen('EndOpenGL', self.window.ptr);
        end % fcn

        %------------------------------------------------------------------
        function GenCubeTexture( self )
            global GL
            Screen('BeginOpenGL', self.window.ptr);

            px = self.n_pixel_cubeface;
            self.tex_cubeface = glGenTextures(6);
            for i = 1 : 6
                % Enable i'th texture by binding it:
                glBindTexture(GL.TEXTURE_2D,self.tex_cubeface(i));

                img = max(-5,min(randn(px,px),+5)); % [-5 +5]
                img = 127 * img / 5 + 127;         % [0 255]
                img = repmat (img, [1 1 3]);       % standard [h, w, rgb]
                img = permute(img, [3 2 1]);       % opengl : [rgb, h, w]
                img = uint8(img);                  % convert to unsigned 8bit values

                % Assign image in matrix 'tx' to i'th texture:
                glTexImage2D(GL.TEXTURE_2D, 0, GL.RGB, px, px, 0, GL.RGB, GL.UNSIGNED_BYTE, img);

                % Setup texture wrapping behaviour:
                glTexParameterfv(GL.TEXTURE_2D, GL.TEXTURE_WRAP_S, GL.REPEAT);
                glTexParameterfv(GL.TEXTURE_2D, GL.TEXTURE_WRAP_T, GL.REPEAT);

                % Setup filtering for the textures:
                glTexParameterfv(GL.TEXTURE_2D, GL.TEXTURE_MAG_FILTER, GL.NEAREST);
                glTexParameterfv(GL.TEXTURE_2D, GL.TEXTURE_MIN_FILTER, GL.NEAREST);

                % Choose texture application function: It shall modulate the light
                % reflection properties of the the cubes face:
                glTexEnvfv(GL.TEXTURE_ENV, GL.TEXTURE_ENV_MODE, GL.MODULATE);
            end

            Screen('EndOpenGL', self.window.ptr);
        end % fcn

        %------------------------------------------------------------------
        function PrepareNormal( self )
            % Vector v maps indices to 3D positions of the corners of a face:
            self.cube_vertex = [ 0 0 0 ; 1 0 0 ; 1 1 0 ; 0 1 0 ; 0 0 1 ; 1 0 1 ; 1 1 1 ; 0 1 1 ]'-0.5;

            self.cube_face = [
                4 3 2 1
                5 6 7 8
                1 2 6 5
                3 4 8 7
                2 3 7 6
                4 1 5 8
                ];

            self.cube_normal = zeros(3,6);
            for i = 1 : 6
                self.cube_normal(:,i) = cross(...
                    self.cube_vertex(:,self.cube_face(i,2))-self.cube_vertex(:,self.cube_face(i,1)),...
                    self.cube_vertex(:,self.cube_face(i,3))-self.cube_vertex(:,self.cube_face(i,2))...
                    );
            end
        end % fcn

        %------------------------------------------------------------------
        function Render( self, tetris_axis, angle, is_mirror )
            % tetris_axis = [+1 +3 -2 -1] means +X +Z -Y -X
            global GL
            Screen('BeginOpenGL', self.window.ptr);

            % Reset
            glClear();

            % Setup modelview matrix: This defines the position, orientation and
            % looking direction of the virtual camera:
            glMatrixMode(GL.MODELVIEW);
            glLoadIdentity();

            % mirror is on X axis, which is Left-Right
            tetris_axis = self.ApplyMirror(tetris_axis,is_mirror);

            scene_center = self.GetBarycenter(tetris_axis);
            % scene_center = [0 0 0]; % #debug

            % continue mirrorize
            camera_pos = PTB_OBJECT.GEOMETRY.vec3(self.camera_init_pos.xyz);
            init_rotation_angle = self.camera_init_rot_angle;
            switch is_mirror
                case false
                    % pass
                case true
                    camera_pos.x        = -camera_pos.x;
                    init_rotation_angle = -init_rotation_angle;
                otherwise
                    error('???')
            end

            % place & orient camera
            gluLookAt(...
                scene_center.x+camera_pos.x, scene_center.y+camera_pos.y, scene_center.z+camera_pos.z, ...
                scene_center.x             , scene_center.y             , scene_center.z             , ...
                0,1,0); % axis Y is the "up" axis

            % apply rotation to the scene
            glTranslatef( scene_center.x,  scene_center.y,  scene_center.z);
            glRotatef(init_rotation_angle + angle,...
                self.camera_init_rot_vector.x,...
                self.camera_init_rot_vector.y,...
                self.camera_init_rot_vector.z ...
                );
            glTranslatef(-scene_center.x, -scene_center.y, -scene_center.z);

            % draw textured cube
            glPushMatrix();
            glMaterialfv(GL.FRONT_AND_BACK,GL.AMBIENT  , self.textured_cube_AMBIENT  );
            glMaterialfv(GL.FRONT_AND_BACK,GL.DIFFUSE  , self.textured_cube_DIFFUSE  );
            glMaterialfv(GL.FRONT_AND_BACK,GL.SHININESS, self.textured_cube_SHININESS);
            glMaterialfv(GL.FRONT_AND_BACK,GL.SPECULAR , self.textured_cube_SPECULAR );
            % glutSolidSphere(1.1,100,100)  % #debug
            self.DrawCubeTextured(tetris_axis); % cube size is 1.000
            glPopMatrix();

            % draw wired cube
            glPushMatrix();
            glMaterialfv(GL.FRONT_AND_BACK,GL.AMBIENT  , self.wired_cube_AMBIENT  );
            glMaterialfv(GL.FRONT_AND_BACK,GL.DIFFUSE  , self.wired_cube_DIFFUSE  );
            glMaterialfv(GL.FRONT_AND_BACK,GL.SHININESS, self.wired_cube_SHININESS);
            glMaterialfv(GL.FRONT_AND_BACK,GL.SPECULAR , self.wired_cube_SPECULAR );
            glLineWidth(self.wired_cube_LineWidth);
            self.DrawCubeWired(tetris_axis, self.wired_cube_Size)
            % glutSolidSphere(1.1,100,100) % #debug
            glPopMatrix();

            Screen('EndOpenGL', self.window.ptr);
        end % fcn

        %------------------------------------------------------------------
        function Capture( self, side )
            img = Screen('GetImage', self.window.ptr , [], 'backBuffer' );

            cropped = self.AutoCrop(img);
            rect = [0 0 size(cropped,2) size(cropped,1)];
            texture = Screen('MakeTexture', self.window.ptr, cropped);

            self.(['img_'     side '_cropped']) = cropped;
            self.(['img_'     side '_rect'   ]) = rect;
            self.(['texture_' side           ]) = texture;
        end % fcn

        %------------------------------------------------------------------
        function DeleteCubeTextures( self )
            Screen('BeginOpenGL', self.window.ptr);

            % Delete all allocated OpenGL textures:
            glDeleteTextures(length(self.tex_cubeface),self.tex_cubeface);

            Screen('EndOpenGL', self.window.ptr);
        end % fcn

        %------------------------------------------------------------------
        function DoubleRenderHack(self, tetris, angle, is_mirror)
            % Perspective hack : render L at center of screen, save
            % image, render R at center of screen, save image, re-draw
            % both on Left and Right side of the screen
            self.Render (tetris,     0,         0);
            self.Capture('L');
            self.Render (tetris, angle, is_mirror);
            self.Capture('R');
            glClear();
            Screen('DrawTexture', self.window.ptr, self.texture_L, [], CenterRectOnPoint(self.img_L_rect, self.window.size_x*0.25, self.window.size_y*0.50))
            Screen('DrawTexture', self.window.ptr, self.texture_R, [], CenterRectOnPoint(self.img_R_rect, self.window.size_x*0.75, self.window.size_y*0.50))
            Screen('Close', self.texture_L);
            Screen('Close', self.texture_R);
        end

    end % meths

    methods(Access = protected)

        %------------------------------------------------------------------
        function DrawCubeTextured( self, tetris_axis )
            % tetris_axis = [+1 +3 -2 -1] means +X +Z -Y -X
            assert(length(self.segment_length) == length(tetris_axis))

            nSegment = length(tetris_axis);

            for iSegment = 1 : nSegment

                seg = [0 0 0];
                ax  =  abs(tetris_axis(iSegment));
                dir = sign(tetris_axis(iSegment));
                seg(ax) = dir;
                nDisplacement = self.segment_length(iSegment) - 1;

                if iSegment == 1
                    % glutSolidCube(dim) % #debug
                    self.DrawCube();
                end
                for n = 1 : nDisplacement
                    glTranslatef(seg(1),seg(2),seg(3)) % move
                    % glutSolidCube(dim) % #debug
                    self.DrawCube();
                end

            end % for:iSegment
        end % function

        %------------------------------------------------------------------
        function DrawCube(self)
            global GL

            % Enable 2D texture mapping, so the faces of the cube will show some nice
            % images:
            glEnable(GL.TEXTURE_2D);
            % don't gorget this line before drawing with textures

            for idx = 1 : 6

                % Bind (Select) texture 'tx' for drawing:
                glBindTexture(GL.TEXTURE_2D, self.tex_cubeface(idx));

                % Begin drawing of a new quad:
                glBegin(GL.QUADS);

                % Assign n as normal vector for this polygons surface normal:
                glNormal3f(self.cube_normal(1,idx), self.cube_normal(2,idx), self.cube_normal(3,idx));

                % Define vertex 1 by assigning a texture coordinate and a 3D position:
                glTexCoord2f(0, 0);
                glVertex3f(self.cube_vertex(1,self.cube_face(idx,1)), self.cube_vertex(2,self.cube_face(idx,1)), self.cube_vertex(3,self.cube_face(idx,1)));
                % Define vertex 2 by assigning a texture coordinate and a 3D position:
                glTexCoord2f(1, 0);
                glVertex3f(self.cube_vertex(1,self.cube_face(idx,2)), self.cube_vertex(2,self.cube_face(idx,2)), self.cube_vertex(3,self.cube_face(idx,2)));
                % Define vertex 3 by assigning a texture coordinate and a 3D position:
                glTexCoord2f(1, 1);
                glVertex3f(self.cube_vertex(1,self.cube_face(idx,3)), self.cube_vertex(2,self.cube_face(idx,3)), self.cube_vertex(3,self.cube_face(idx,3)));
                % Define vertex 4 by assigning a texture coordinate and a 3D position:
                glTexCoord2f(0, 1);
                glVertex3f(self.cube_vertex(1,self.cube_face(idx,4)), self.cube_vertex(2,self.cube_face(idx,4)), self.cube_vertex(3,self.cube_face(idx,4)));
                % Done with this polygon:
                glEnd();

            end % for:cubeface
        end % fcn

        %------------------------------------------------------------------
        function DrawCubeWired( self, tetris_axis, dim )
            assert(length(self.segment_length) == length(tetris_axis))

            nSegment = length(tetris_axis);

            for iSegment = 1 : nSegment

                seg = [0 0 0];
                ax  =  abs(tetris_axis(iSegment));
                dir = sign(tetris_axis(iSegment));
                seg(ax) = dir;
                nDisplacement = self.segment_length(iSegment) - 1;

                if iSegment == 1
                    glutWireCube(dim);
                end
                for n = 1 : nDisplacement
                    glTranslatef(seg(1),seg(2),seg(3)) % move
                    glutWireCube(dim);
                end

            end % for:iSegment
        end % fcn

        %------------------------------------------------------------------
        function coords = GetBarycenter( self, tetris_axis )
            % tetris_axis = [+1 +3 -2 -1] means +X +Z -Y -X
            assert(length(self.segment_length) == length(tetris_axis))

            % empty array that will contain the middle point of each segement
            middles = NaN(length(tetris_axis),3);
            dxyz    = NaN(length(tetris_axis),3);

            nSegment = length(tetris_axis);

            for iSegment = 1 : nSegment

                seg = [0 0 0];
                ax  =  abs(tetris_axis(iSegment));
                dir = sign(tetris_axis(iSegment));
                seg(ax) = dir*(self.segment_length(iSegment)-1);

                if iSegment == 1
                    start_point = [0 0 0];
                else
                    % start_point is simply the sum of each previous displacement
                    start_point = sum(dxyz(1:(iSegment-1),:),1);
                end

                middles(iSegment,:) = start_point + seg/2;
                dxyz   (iSegment,:) = seg;

            end % for:iSegment

            weights = self.segment_length; % the weights is the length of each segment
            coords = sum( middles.*weights' ) / sum(weights); % weighted sum

            coords = PTB_OBJECT.GEOMETRY.vec3(coords);
        end % fcn

    end % meths

    methods(Access = protected, Static)

        %------------------------------------------------------------------
        function tetris_axis = ApplyMirror(tetris_axis, is_mirror)
            if is_mirror
                mirror_tetris = tetris_axis; % copy
                x_idx = abs(mirror_tetris) == 1; % in OpenGL, 'left right' axis is X
                mirror_tetris(x_idx) = -mirror_tetris(x_idx);
                tetris_axis = mirror_tetris; % replace
            end
        end % fcn

        %------------------------------------------------------------------
        function o = AutoCrop(i)
            % crop image : i is (height x width x 3[rgb])

            % binarize
            mask = sum(i>0,3) > 0;

            % horizontal crop limit
            vsum = sum(mask,1);
            lr_limits = find(diff(vsum>0));
            left_lim  = lr_limits(1);
            right_lim = lr_limits(end)+1;

            % horizontal crop limit
            hsum      = sum(mask,2);
            ud_limits = find(diff(hsum>0));
            up_lim    = ud_limits(1);
            down_lim  = ud_limits(end)+1;

            % do the crop
            o = cat(3, i(up_lim:down_lim, left_lim:right_lim, :), 255*mask(up_lim:down_lim, left_lim:right_lim, :));
        end % fcn

    end % meths

end % class
