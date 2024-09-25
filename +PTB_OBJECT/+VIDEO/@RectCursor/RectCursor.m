classdef RectCursor < PTB_OBJECT.VIDEO.Base

    properties(GetAccess = public, SetAccess = public)
        % User accessible paramters :
        dim      (1,1) double % ratio from window_size_x, from 0 to 1
        width    (1,1) double % ratio from self.dim, from 0 to 1
        color    (1,4) uint8  % [R G B a] from 0 to 255
        input    (1,:) char   % 'HandGrip' or 'Mouse'
    end % props


    properties(GetAccess = public, SetAccess = protected)
        % Internal parameters :
        dim_px            (1,1) double
        width_px          (1,1) double
        center_x_px       (1,1) double
        center_y_px       (1,1) double
        rect              (1,4) double % coordinates of the cross for PTB, in pixels

        center_x          (1,1) double % ratio from window_size_x, from 0 to 1
        % center_y          (1,1) double % ratio from window_size_y, from 0 to 1

        center_y_lower_px (1,1) double % lower bound of center Y
        center_y_upper_px (1,1) double % upper bound of center Y
    end % props

    methods(Access = public)

        %--- constructor --------------------------------------------------
        function self = RectCursor()
            % pass
        end % fcn

        %------------------------------------------------------------------
        function SetCenterX(self, cx)
            % for initialization
            self.center_x    = cx;
            self.center_x_px = self.center_x * self.window.size_x;

            self.dim_px      = self.dim * self.window.size_y;
            self.width_px    = self.dim_px * self.width;
        end % fcn

        %------------------------------------------------------------------
        function SetRangeY(self, cy_lower, cy_upper)
            % for initialization
            self.center_y_lower_px = cy_lower * self.window.size_y;
            self.center_y_upper_px = cy_upper * self.window.size_y;
        end % fcn

        %------------------------------------------------------------------
        function Init(self)
            switch self.input
                case 'HandGrip'
                case 'Mouse'
                    SetMouse(self.center_x_px,self.center_y_lower_px,self.window.ptr);
                otherwise
                    error('input method ?')
            end
            self.UpdateY(0);
        end % fcn

        %------------------------------------------------------------------
        function Update(self)
            switch self.input
                case 'HandGrip'
                case 'Mouse'
                    [~,y] = GetMouse(self.window.ptr);
                    pos = (y - self.center_y_lower_px) / (self.center_y_upper_px - self.center_y_lower_px);
            end
            self.UpdateY(pos);
        end % fcn

        %------------------------------------------------------------------
        function UpdateY(self,y)
            % y from 0 to 1
            % y: [0-1] -> f(y): [center_y_lower_px center_y_upper_px]
            self.center_y_px = (self.center_y_upper_px - self.center_y_lower_px)*y + self.center_y_lower_px;
            self.rect = CenterRectOnPoint([0 0 self.dim_px self.width_px], self.center_x_px, self.center_y_px);
        end % fcn

        %------------------------------------------------------------------
        function Draw( self )
            % runtime
            c = self.color;
            c(1:3) = c(1:3)/2;
            Screen('FillRect', self.window.ptr,          c, InsetRect(self.rect,-2,-2));
            Screen('FillRect', self.window.ptr, self.color,           self.rect       );
        end % fcn

    end % meths

end % class
