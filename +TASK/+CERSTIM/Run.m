function Run()
global S


%% prepare events, timings, randomization

[S.recPlanning, S.cfgEvents] = TASK.CERSTIM.PrepareEvents(S.guiACQmode);

S.recEvent = UTILS.RECORDER.Event(S.recPlanning);


%% set keybinds

S.cfgKeybinds = TASK.cfgKeyboard(); % cross task keybinds

switch S.guiKeybind
    case 'fORP (MRI)'
        % S.cfgKeybinds.Catch = KbName('b');
    case 'Keyboard'
        % S.cfgKeybinds.Catch = KbName('DownArrow');
    otherwise
        error('unknown S.guiKeybind : %s', S.guiKeybind)
end

S.recKeylogger = UTILS.RECORDER.Keylogger(S.cfgKeybinds);
S.recKeylogger.Start();


%% set parameters for rendering objects

S.cfgCursor.Size     = 0.03;              %  Size_px = ScreenY_px * Size
S.cfgCursor.Width    = 0.30;              % Width_px =    Size_px * Width
S.cfgCursor.Color    = [255 000 000 255]; % [R G B a], from 0 to 255
S.cfgCursor.XCenter  = 0.25;              % Position_px = ScreenX_px * XCenter
S.cfgCursor.YRange   = [0.20 0.80];       % Position_px = [ScreenY_px ScreenY_px] .* YRange

S.cfgCurve.Color     = [128 128 128 255]; % [R G B a], from 0 to 255
S.cfgCurve.Width     = 0.005;              % Width_px =    Size_px * Width


%% start PTB engine

% get object
Window = PTB_ENGINE.VIDEO.Window();
S.Window = Window; % also save it in the global structure for diagnostic

% task specific paramters
S.Window.bg_color       = [0 0 0];
S.Window.movie_filepath = [S.OutFilepath '.mov'];

% set parameters from the GUI
S.Window.screen_id      = S.guiScreenID; % mandatory
S.Window.is_transparent = S.guiTransparent;
S.Window.is_windowed    = S.guiWindowed;
S.Window.is_recorded    = S.guiRecordMovie;

S.Window.Open();


%% Prepare numerical recorder

S.recSensor = UTILS.RECORDER.Double({'time', 'target', 'sensor'}, round(.recPlanning.data{end, S.recPlanning.Get('onset')} * S.Window.fps * 1.2));


%% Prepare buffer size

event_name = S.recPlanning.data(:,S.recPlanning.Get('name'));
is_RampUp = ~cellfun(@isempty, strfind(event_name, 'RampUp')); %#ok<STRCLFH>
duration_RampUp = S.recPlanning.data(is_RampUp,S.recPlanning.Get('duration')); % cell
max_dur_one_trial = max(cell2mat(duration_RampUp)) + S.cfgEvents.durFlatTop;
n_window = 2;
buffer_size_px = round(n_window * (max_dur_one_trial+S.cfgEvents.durRest) * S.Window.size_x);

event_onset = cell2mat(S.recPlanning.data(:,S.recPlanning.Get('onset')));
initial_duration_to_fill = (n_window - 1)*(max_dur_one_trial+S.cfgEvents.durRest);
[~,init_event_maxidx_to_fill] = min(abs(event_onset - initial_duration_to_fill));


%% Prepare curves
% they will be added in the buffer

px_per_second = S.Window.size_x / S.cfgEvents.durWindow;

flattop_px = S.cfgEvents.durFlatTop * px_per_second;
rest_px    = S.cfgEvents.durRest    * px_per_second;
flattop_points = ones(1,flattop_px);
rest_points    = zeros(1,rest_px);

curves = cell(S.cfgEvents.nTrial,1);
for c = 1 : S.cfgEvents.nTrial
    rampup_dur    = S.cfgEvents.Trials(c,2);
    rampup_px     = rampup_dur * px_per_second;
    rampup_points = linspace(0, 1, rampup_px);
    curves{c}     = rampup_points;
end


%% prepare rendering object

Cursor        = PTB_OBJECT.VIDEO.RectCursor();
Cursor.window = Window;
Cursor.dim    = S.cfgCursor.Size;
Cursor.width  = S.cfgCursor.Width;
Cursor.color  = S.cfgCursor.Color;
Cursor.SetCenterX(S.cfgCursor.XCenter);
Cursor.SetRangeY(S.cfgCursor.YRange(2), S.cfgCursor.YRange(1));
Cursor.input  = S.guiInputMethod;
Cursor.Init();

Curve                 = PTB_OBJECT.VIDEO.Curve();
Curve.window          = Window;
Curve.size            = buffer_size_px;
Curve.window_duration = S.cfgEvents.durWindow;
Curve.color           = S.cfgCurve.Color;
Curve.width           = S.cfgCurve.Width;
Curve.Init();
Curve.SetRangeY(S.cfgCursor.YRange(2), S.cfgCursor.YRange(1));


%% run the events

% initialize / pre-allocate some vars
EXIT = false;
time = GetSecs();
icol_trial   = S.recPlanning.Get('trial');
curve_counter = 1;
first_frame_of_event = true;

% main loop
for evt = 1 : S.recPlanning.count

    evt_name     = S.recPlanning.data{evt,S.recPlanning.icol_name    };
    evt_onset    = S.recPlanning.data{evt,S.recPlanning.icol_onset   };
    evt_duration = S.recPlanning.data{evt,S.recPlanning.icol_duration};

    if evt < S.recPlanning.count
        next_evt_onset = S.recPlanning.data{evt+1,S.recPlanning.icol_onset};
    end

    fprintf('[%03d/%03d] %s : %gs \n', evt, S.recPlanning.count, evt_name, evt_duration);

    switch evt_name

        case 'START'

            % fill initial buffer
            init_evt_idx = 1;
            for i = 1 : init_event_maxidx_to_fill
                init_evt_idx = 1 + i; % +1 because START must be skipped
                init_evt_name = S.recPlanning.data{init_evt_idx,S.recPlanning.icol_name};

                if init_evt_idx == 2 && ~strcmp(init_evt_name, 'Rest')
                    error('second event must be Rest')
                end

                if init_evt_idx == 2 && strcmp(init_evt_name, 'Rest')
                    Curve.Append(zeros(1,Cursor.center_x_px))
                    Curve.Append(rest_points);
                elseif strcmp(init_evt_name, 'Rest')
                    Curve.Append(rest_points);
                elseif strfind(init_evt_name, 'FlatTop') %#ok<*STRIFCND>
                    Curve.Append(flattop_points);
                elseif strfind(init_evt_name, 'RampUp')
                    Curve.Append(curves{curve_counter});
                    curve_counter = curve_counter + 1;
                else
                    error('bad event')
                end
            end

            S.STARTtime = PTB_ENGINE.START(S.cfgKeybinds.Start, S.cfgKeybinds.Abort, Cursor, Curve);
            S.recEvent.AddStart();
            S.Window.AddFrameToMovie();

        case 'END'

            S.ENDtime = WaitSecs('UntilTime', S.STARTtime + evt_onset );
            S.recEvent.AddEnd(S.ENDtime - S.STARTtime );
            S.Window.AddFrameToMovie();
            PTB_ENGINE.END();

        otherwise

            first_frame_of_event = true;

            init_evt_idx = init_evt_idx + 1;
            if init_evt_idx < S.recPlanning.count
                buffer_evt_name = S.recPlanning.data{init_evt_idx,S.recPlanning.icol_name};
                if strcmp(buffer_evt_name, 'Rest')
                    Curve.Append(rest_points);
                elseif strfind(buffer_evt_name, 'FlatTop')
                    Curve.Append(flattop_points);
                elseif strfind(buffer_evt_name, 'RampUp')
                    Curve.Append(curves{curve_counter});
                    curve_counter = curve_counter + 1;
                else
                    error('bad event')
                end
            end

            while 1

                [keyIsDown, time, keyCode] = KbCheck();
                if keyIsDown
                    EXIT = keyCode(S.cfgKeybinds.Abort);
                    if EXIT, break, end
                end

                if ~strcmp(S.guiACQmode,'Acquisition')
                    Screen('DrawText', S.Window.ptr, evt_name, 10, 10, Curve.color);
                end

                Curve.Draw();
                Curve.Next();

                Cursor.Update();
                Cursor.Draw();
                flip_onset = Window.Flip();

                S.recSensor.AddLine([flip_onset-S.STARTtime, Curve.buffer(Cursor.center_x_px), Cursor.value]);

                if first_frame_of_event
                    S.recEvent.AddStim(evt_name, flip_onset-S.STARTtime, [], S.recPlanning.data(evt,S.recPlanning.icol_data:end));
                    first_frame_of_event = false;
                end

                if time >= S.STARTtime + next_evt_onset - S.Window.slack
                    break
                end

            end % while

    end % switch

    % if Abort is pressed
    if EXIT

        S.ENDtime = GetSecs();
        S.recEvent.AddEnd(S.ENDtime - S.STARTtime);
        S.recEvent.ClearEmptyLines();

        S.recSensor.ClearEmptyLines();

        if S.WriteFiles
            save([S.OutFilepath '__ABORT_at_runtime.mat'], 'S')
        end

        PTB_ENGINE.END();

        fprintf('!!! @%s : Abort key received !!!\n', mfilename)
        break % stop the forloop:evt

    end

end % forloop:evt


%% End of task routine

S.Window.Close();

S.recEvent.ComputeDurations();
S.recKeylogger.GetQueue();
S.recKeylogger.Stop();
S.recKeylogger.kb2data();
switch S.guiACQmode
    case 'Acquisition'
    case {'Debug', 'FastDebug'}
        TR = CONFIG.TR();
        n_volume = ceil((S.ENDtime-S.STARTtime)/TR);
        S.recKeylogger.GenerateMRITrigger(TR, n_volume, S.STARTtime)
end
S.recKeylogger.ScaleTime(S.STARTtime);
S.recSensor.ClearEmptyLines();

assignin('base', 'S', S)

switch S.guiACQmode
    case 'Acquisition'
    case {'Debug', 'FastDebug'}
        % UTILS.plotDelay(S.recPlanning, S.recEvent);
        % UTILS.plotStim(S.recPlanning, S.recEvent, S.recKeylogger);
end

end % fcn
