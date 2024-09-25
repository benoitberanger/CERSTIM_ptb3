classdef Curve < PTB_OBJECT.VIDEO.Base

    properties(GetAccess = public, SetAccess = public)
        size            (1,1) uint64 % curve==buffer size
        color           (1,4) uint8  % [R G B a] from 0 to 255
        window_duration (1,1) double % [s] time to replace all pixels of the window
        width           (1,1) double % line width, from 0 to 1
    end % props

    properties(GetAccess = public, SetAccess = protected)
        buffer            (1,:) double
        offset            (1,1) uint64 = 0
        center_y_lower_px (1,1) double % lower bound of center Y
        center_y_upper_px (1,1) double % upper bound of center Y
        width_px          (1,1) double
        px_per_second     (1,1) double
        px_per_frame      (1,1) double
        Rpx_per_frame     (1,1) double
        n_frame           (1,1) double = 1
        px_expected       (1,1) double = 0
        px_total          (1,1) double = 0
        px_error          (1,1) double = 0
    end % props

    methods(Access = public)

        %--- constructor
        function self = Curve()
            % pass
        end % fcn

        %------------------------------------------------------------------
        function Init(self)
            self.buffer = nan(1,self.size);
            self.width_px = self.width * self.window.size_y;
            self.px_per_second = self.window.size_x / self.window_duration;
            self.px_per_frame  = self.px_per_second / self.window.fps;
            self.Rpx_per_frame = round(self.px_per_frame);
        end % fcn

        %------------------------------------------------------------------
        function SetRangeY(self, cy_lower, cy_upper)
            self.center_y_lower_px = cy_lower * self.window.size_y;
            self.center_y_upper_px = cy_upper * self.window.size_y;
        end % fcn

        %------------------------------------------------------------------
        function Append(self, new_points)
            n    = length(new_points);
            from = self.offset + 1;
            to   = from - 1 + n;
            self.buffer(from:to) = new_points;
            self.offset          = self.offset + n;
        end % fcn

        %------------------------------------------------------------------
        function Draw(self)
            px_to_render = self.center_y_lower_px - (self.center_y_lower_px - self.center_y_upper_px) * self.buffer(1:self.window.size_x);

            y_to_render = repelem(px_to_render        ,2);
            x_to_render = repelem(1:self.window.size_x,2);
            y_to_render = y_to_render(2:end);
            x_to_render = x_to_render(2:end);

            Screen('DrawLines', self.window.ptr, [x_to_render;y_to_render], self.width_px, self.color);
        end % fcn

        %------------------------------------------------------------------
        function Next(self)

            if self.n_frame > 1
                if abs(self.px_error) >= 1
                    shift = self.Rpx_per_frame + sign(self.px_error);
                else
                    shift = self.Rpx_per_frame;
                end
            else
                shift = self.Rpx_per_frame;
            end

            self.buffer   = circshift(self.buffer, -shift);
            self.offset   = self.offset - shift;

            self.px_total    = self.px_total + shift;
            self.px_expected = self.n_frame * self.px_per_frame;
            self.px_error    = self.px_expected - self.px_total;
            self.n_frame     = self.n_frame +1;

        end % end

        %------------------------------------------------------------------
        function Plot(self)
            plot(self.buffer)
        end % fcn

    end % meths

end % class
