classdef Checkerboard < PTB_OBJECT.VIDEO.Base
    % Checkerboard Class to prepare and draw a checkerboard in PTB

    properties(GetAccess = public, SetAccess = public)
        % User accessible paramters :
        n_square_width (1,1) double {mustBePositive,mustBeInteger} = 8
        color_flic     (1,4) uint8 = [255 255 255 255]                     % [R G B a] from 0 to 255
        color_flac     (1,4) uint8 = [255 255 255 255]                     % [R G B a] from 0 to 255
    end % props

    properties(GetAccess = public, SetAccess = protected)
        % Internal parameters :
        rect_flic      (4,:) double
        rect_flac      (4,:) double
    end % props

    methods(Access = public)

        %--- constructor --------------------------------------------------
        function self = Checkerboard()
            % pass
        end % fcn

        %------------------------------------------------------------------
        function GenerateRects(self)

            % Number of pixel of the squares wide
            squaresize  = self.window.size_x / self.n_square_width;

            X = 0 : squaresize : self.window.size_x;
            Y = 0 : squaresize : self.window.size_y;

            if mod(length(X),2)
                X(end+1) = X(end) + squaresize;
            end
            if mod(length(Y),2)
                Y(end+1) = Y(end) + squaresize;
            end

            % Creation of a grid : position of each square on the screen
            [ X_Grid , Y_Grid ] = meshgrid( X , Y );

            % Checkerboard matrix composed only whith 0 and 1. We will use this
            % 'logical' checkboard as : 1 => white squares , 0 => black squares
            CB = logical(repmat(eye(2),length(Y)/2,length(X)/2));
            CB_reshaped = reshape(CB',1,[]);

            % Transformation of the matrix into a vector (to fitt with the graphic functions syntax)
            Squares_Xpos_reshaped = reshape(X_Grid',1,[]);
            Squares_Ypos_reshaped = reshape(Y_Grid',1,[]);

            % 1 => white squares
            Squares_Xpos1 = Squares_Xpos_reshaped(CB_reshaped);
            Squares_Ypos1 = Squares_Ypos_reshaped(CB_reshaped);

            % 0 => black squares
            Squares_Xpos2 = Squares_Xpos_reshaped(~CB_reshaped);
            Squares_Ypos2 = Squares_Ypos_reshaped(~CB_reshaped);

            % Sqares position such as : [ X1 Y1 X2 Y2 ;
            %                             X1 Y1 X2 Y2 ;
            %                             ...         ]
            Checkerboard_1 = [Squares_Xpos1; Squares_Ypos1; Squares_Xpos1 + squaresize; Squares_Ypos1 + squaresize];
            Checkerboard_2 = [Squares_Xpos2; Squares_Ypos2; Squares_Xpos2 + squaresize; Squares_Ypos2 + squaresize];

            % Saving data
            self.rect_flic = Checkerboard_1;
            self.rect_flac = Checkerboard_2;

        end % fcn

        %------------------------------------------------------------------
        function DrawFlic(self)
            Screen('FillRect', self.window.ptr, self.color_flic, self.rect_flic)
        end % fcn

        %------------------------------------------------------------------
        function DrawFlac(self)
            Screen('FillRect', self.window.ptr, self.color_flac, self.rect_flac)
        end % fcn

    end % meths

end % class
