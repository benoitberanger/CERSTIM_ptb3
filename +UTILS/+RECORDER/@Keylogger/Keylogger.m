classdef Keylogger < UTILS.RECORDER.Stim
    % Handles the Keybinds Queue from Psychtoolbox
    %  (ex : record MRI triggers while other code is executing)

    properties(GetAccess = public, SetAccess = public)
        keymap           struct = struct
        kbList_num (1,:) double
        kbList_str (1,:) cell
        kbList_lbl (1,:) cell
        kbEvents   (:,3) cell
        keyboard         struct = struct

        display_symbol = '*'
    end % props

    properties(GetAccess = public, SetAccess = protected)
        icol_kname     (1,1) double = 1 % key name
        icol_konset    (1,1) double = 2 % key onset
        icol_kud       (1,1) double = 3 % 0 up, 1 down
    end % props

    methods(Access = public)

        %------------------------------------------------------------------
        %                           Constructor
        %------------------------------------------------------------------
        function self = Keylogger( keymap  )
            assert(isstruct(keymap) && isscalar(keymap), 'keymap must be a struct such as keymap.<keylabel>=KbName(<keyname>) ')

            self = self@UTILS.RECORDER.Stim(0,{'KbName'})
            self.description = class(self);

            self.keymap     = keymap;
            self.kbList_num = cell2mat(struct2cell(keymap));
            self.kbList_str = KbName(self.kbList_num);
            self.kbList_lbl = fieldnames(keymap);

            [self.keyboard.keyboardIndices, self.keyboard.productNames, self.keyboard.allInfos] = GetKeyboardIndices;
        end % fcn

        %------------------------------------------------------------------
        function Start( self )
            % Initialise the KeyBind Queue and start collecting the inputs

            kbVect = zeros(1,256);
            kbVect(self.kbList_num) = 1;

            for index = 1 : length(self.keyboard.keyboardIndices)
                KbQueueCreate(self.keyboard.keyboardIndices(index),kbVect)
                KbQueueStart (self.keyboard.keyboardIndices(index))
            end

        end % fcn

        %------------------------------------------------------------------
        function Stop( self )
            % Stop collecting KeyBinds and Release the device

            for index = 1 : length(self.keyboard.keyboardIndices)
                KbQueueStop   (self.keyboard.keyboardIndices(index))
                KbQueueRelease(self.keyboard.keyboardIndices(index))
            end

        end % fcn

        %------------------------------------------------------------------
        function GetQueue( self )
            % Fetch the queue

            for index = 1 : length(self.keyboard.keyboardIndices)

                while KbEventAvail(self.keyboard.keyboardIndices(index))
                    [evt, ~] = KbEventGet(self.keyboard.keyboardIndices(index)); % Get all queued keys
                    if any( evt.Keycode == self.kbList_num )
                        key_idx = evt.Keycode == self.kbList_num;
                        self.kbEvents(end+1,:) = { self.kbList_lbl{key_idx} evt.Time evt.Pressed };
                    end
                end

            end

            if size(self.kbEvents,1) == 0
                warning('empty kbEvents')
            end

        end % fcn

        %------------------------------------------------------------------
        function kb2data(self)
            self.data = cell( self.n_lin , self.n_col);
            self.count = 0;

            [ kb_name , ~ , idx_kb2evt ] = unique(self.kbEvents(:,self.icol_kname), 'stable');

            sorted_kbEvents = struct;

            for i = 1 : length(kb_name)

                % get all press for each key
                sorted_kbEvents(i).name   = kb_name{i};
                sorted_kbEvents(i).KbName = self.kbList_str(strcmp(kb_name{i}, self.kbList_lbl));
                sorted_kbEvents(i).onset  = cell2mat(self.kbEvents(idx_kb2evt == i, self.icol_konset));
                sorted_kbEvents(i).press  = cell2mat(self.kbEvents(idx_kb2evt == i, self.icol_kud   ));
                sorted_kbEvents(i).n      = length(sorted_kbEvents(i).press);

                % deal with special cases
                is_n_even = mod(sorted_kbEvents(i).n,2)==0;
                is_first_press_down = sorted_kbEvents(i).press(1) == 1;
                if is_first_press_down && is_n_even
                    % easy, should happen most of the time
                    % pass
                elseif is_first_press_down && ~is_n_even
                    % last relasease not recorded, but thats ok...
                    sorted_kbEvents(i).onset(end+1) = Inf;
                    sorted_kbEvents(i).press(end+1) = 0;
                    sorted_kbEvents(i).n = sorted_kbEvents(i).n + 1;
                elseif ~is_first_press_down && is_n_even
                    % delete first & manage last
                    sorted_kbEvents(i).onset(1) = [];
                    sorted_kbEvents(i).press(1) = [];
                    sorted_kbEvents(i).onset(end+1) = Inf;
                    sorted_kbEvents(i).press(end+1) = 0;
                elseif ~is_first_press_down && ~is_n_even
                    % delete first and we are all good
                    sorted_kbEvents(i).onset(1) = [];
                    sorted_kbEvents(i).press(1) = [];
                    sorted_kbEvents(i).n = sorted_kbEvents(i).n - 1;
                end

                % everything is clean, ready to add in the data
                for j = 1 : sorted_kbEvents(i).n / 2
                    self.AddStim( ...
                        sorted_kbEvents(i).name, ...
                        sorted_kbEvents(i).onset(j*2-1), ...
                        sorted_kbEvents(i).onset(j*2)-sorted_kbEvents(i).onset(j*2-1), ...
                        sorted_kbEvents(i).KbName ...
                        );
                end % for:j

            end % for:i

        end % fcn

        %------------------------------------------------------------------
        function GenerateMRITrigger( self , tr, n_volume, starttime )
            % Generate MRI trigger according to he given number of Volumes
            % and the TR.

            assert( isnumeric(tr) && tr > 0 , 'TR must be positive')
            assert( isnumeric(n_volume) && n_volume > 0 && n_volume == round(n_volume) , 'Volumes must be a positive integer')
            assert( isnumeric(starttime) && starttime >= 0 , 'StartTime must be positive or null')

            MRI_trigger_tag = 'MRItrigger';
            pulse_duration = 0.020; % seconds

            % Check if TR is compatible with the pulse duration
            assert(tr > pulse_duration, 'pulse_duration is set to %.3f, but TR must be such as TR > pulse_duration',pulse_duration)

            % Fill Data whith MRI trigger events
            for v = 1 : n_volume
                self.AddStim(MRI_trigger_tag, starttime + tr*(v-1), pulse_duration, {MRI_trigger_tag});
            end

        end % fcn

    end % meths

end % class
