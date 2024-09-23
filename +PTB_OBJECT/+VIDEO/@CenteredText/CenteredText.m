classdef CenteredText < PTB_OBJECT.VIDEO.Base
    % TEXT Class to prepare and draw text

    properties(GetAccess = public, SetAccess = public)
        % User accessible paramters :
        size    (1,1) double % font size ratio from window_size_y
        color   (1,4) uint8  % [R G B a] from 0 to 255
        content (1,:) char = '<<<DEFAULT_TEXT>>>'    % this will be the text to display
    end % props

    properties(GetAccess = public, SetAccess = protected)
        % Internal parameters :
    end % props

    methods(Access = public)

        %------------------------------------------------------------------
        function self = CenteredText()
            % pass
        end % fcn

        %------------------------------------------------------------------
        function Draw( self, content )
            self.content = content;
            Screen('TextSize' , self.window.ptr, self.size*self.window.size_y );
            DrawFormattedText(self.window.ptr, self.content, 'center', 'center', self.color);
        end % fcn

    end % meths

end % class
