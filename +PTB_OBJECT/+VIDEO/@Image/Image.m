classdef Image < PTB_OBJECT.VIDEO.Base
    % IAMGE Class to load an image from disk, make it a PTB texture ready to draw.
    % The class has methods to rescale the image and move it's center

    properties(GetAccess = public, SetAccess = public)
        % User accessible paramters :
        filename    (1,:)   char   % path of the image
        rect        (1,4)   double % [0 0 size_x size_y] % ptb coordinates
        rect_scaled (1,4)   double % [0 0 size_x size_y] % ptb coordinates
    end % props

    properties(GetAccess = public, SetAccess = protected)
        % Internal parameters :
        rgba        (:,:,4) uint8  % [R G B a] from 0 to 255
        size_h      (1,1)   double % number of horizontal pixel
        size_w      (1,1)   double % number of vertical   pixel
        ar          (1,1)   double % aspect ratio
        rect_raw    (1,4)   double % [0 0 size_x size_y] % ptb coordinates
        tex         (1,1)   double % ptb texture pointer
    end % props

    methods(Access = public)

        %--- constructor --------------------------------------------------
        function self = Image()
            % pass
        end % fcn

        %------------------------------------------------------------------
        function Load(self)
            [data, map, alpha] = imread(self.filename);
            if ndims(data) == 3 % probably no alpha channel, like jpg
                self.rgba = cat(3,data,255*ones(size(data,1),size(data,2)));
            elseif ndims(data) == 2 % probably alpha channel, like png
                if isa(alpha,'double')
                    alpha = uint8(alpha*255);
                end
                self.rgba = cat(3,ind2rgb8(data,map),alpha);
            end
            self.size_w = size(self.rgba, 2);
            self.size_h = size(self.rgba, 1);
            self.ar = self.size_w / self.size_h;
            self.rect_raw = [0 0 self.size_w self.size_h];
            self.ResetRect();
        end % fcn

        %------------------------------------------------------------------
        function Plot(self)
            % build checkerboard mask with cyan tiles
            freq = 10 / self.size_h;
            [grid_h, grid_w]  = meshgrid(1:self.size_w, 1:self.size_h);
            grid_h = sin(2*pi*freq*grid_h)>0;
            grid_w = sin(2*pi*freq*grid_w)>0;
            checkerboard = xor(grid_h,grid_w);
            bg = zeros(self.size_h, self.size_w, 3); % cyan background
            bg(:,:,1) = 255;
            bg(:,:,2) = 000;
            bg(:,:,3) = 255;
            mask = bg .* checkerboard;
            mask = uint8(mask);

            % draw
            f = figure('Name',self.filename,'NumberTitle','off');
            a = axes(f);
            image(a, self.rgba(:,:,1:3) + (255-self.rgba(:,:,4)).*mask)
            axis(a, 'equal')
            set(a, 'XAxisLocation', 'top')
        end % function

        %------------------------------------------------------------------
        function MakeTexture(self)
            self.tex = Screen('MakeTexture', self.window.ptr, self.rgba);
        end % fcn

        %------------------------------------------------------------------
        function Close(self)
            Screen('Close', self.tex);
        end % fcn

        %------------------------------------------------------------------
        function Draw(self)
            Screen('DrawTexture', self.window.ptr, self.tex, [], self.rect);
        end % fcn

        %------------------------------------------------------------------
        function ResetRect(self)
            self.rect_scaled = self.rect_raw;
            self.rect        = self.rect_raw;
        end % fcn

        %------------------------------------------------------------------
        function Scale(self, factor)
            self.rect_scaled = ScaleRect(self.rect_scaled,factor,factor);
        end % fcn
        %------------------------------------------------------------------
        function ScaleToMax(self)
            ratio_x = self.size_w / self.window.size_x;
            ratio_y = self.size_h / self.window.size_y;
            ratio_max = max(ratio_x,ratio_y);
            self.Scale(1/ratio_max);
        end % fcn

        %------------------------------------------------------------------
        function Move(self, center_x, center_y)
            self.rect = CenterRectOnPoint(self.rect_scaled, center_x, center_y);
        end % fcn
        %------------------------------------------------------------------
        function MoveToCenter(self)
            self.Move(self.window.center_x, self.window.center_y);
        end % fcn

    end % meths

end % class
