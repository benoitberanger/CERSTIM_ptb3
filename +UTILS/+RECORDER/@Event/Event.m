classdef Event < UTILS.RECORDER.Stim
    % real stim, onset and duration will be compared to the ones registerd in @UTILS.RECORDER.Planning

    properties(GetAccess = public, SetAccess = public)
        display_symbol = '+'
    end % properties

    methods(Access = public)

        %------------------------------------------------------------------
        %                           Constructor
        %------------------------------------------------------------------
        function self = Event(planning)
            assert(isa(planning, 'UTILS.RECORDER.Planning'))
            self = self@UTILS.RECORDER.Stim(planning.count-2,planning.header_data)
            self.description = class(self);
        end

    end % meths

end % class
