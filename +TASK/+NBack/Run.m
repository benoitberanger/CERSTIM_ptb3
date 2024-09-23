function Run()
global S


%% prepare events, timings, randomization

[S.recPlanning, S.cfgEvents] = TASK.(S.guiTask).PrepareEvents(S.guiACQmode);


%% create other recorders

S.recEvent     = UTILS.RECORDER.Event(S.recPlanning);
S.recBehaviour = UTILS.RECORDER.Cell({'trial#' 'block#' 'stim#' 'content' 'iscatch' 'RT(s)' 'resp_ok'}, S.cfgEvents.nTrials);


%% set keybinds

S.cfgKeybinds = TASK.cfgKeyboard(); % cross task keybinds

switch S.guiKeybind
    case 'fORP (MRI)'
        S.cfgKeybinds.Catch = KbName('b');
    case 'Keyboard'
        S.cfgKeybinds.Catch = KbName('DownArrow');
    otherwise
        error('unknown S.guiKeybind : %s', S.guiKeybind)
end

S.recKeylogger = UTILS.RECORDER.Keylogger(S.cfgKeybinds);
S.recKeylogger.Start();


%% set parameters for rendering objects

S.cfgFixationCross = TASK.cfgFixationCross();

S.cfgText.SizeInstruction = 0.10;              % TextSize = round(ScreenY_px * Size)
S.cfgText.SizeStim        = 0.20;              % TextSize = round(ScreenY_px * Size)
S.cfgText.Color           = [127 127 127 255]; % [R G B a], from 0 to 255
S.cfgText.Center          = [0.5 0.5];         % Position_px = [ScreenX_px ScreenY_px] .* Position


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


%% prepare rendering object

FixationCross          = PTB_OBJECT.VIDEO.FixationCross();
FixationCross.window   = Window;
FixationCross.dim      = S.cfgFixationCross.Size;
FixationCross.width    = S.cfgFixationCross.Width;
FixationCross.color    = S.cfgFixationCross.Color;
FixationCross.center_x = S.cfgFixationCross.Position(1);
FixationCross.center_y = S.cfgFixationCross.Position(2);
FixationCross.GenerateCoords();

TextInstruction        = PTB_OBJECT.VIDEO.CenteredText();
TextInstruction.window = Window;
TextInstruction.color  = S.cfgFixationCross.Color;
TextInstruction.size   = 0.10;

TextStim      = TextInstruction.CopyObject();
TextStim.size = 0.20;


%% run the events

% initialize / pre-allocate some vars
EXIT = false;
secs = GetSecs();
icol_trial   = S.recPlanning.Get('trial'  );
icol_block   = S.recPlanning.Get('block'  );
icol_stim    = S.recPlanning.Get('stim'   );
icol_content = S.recPlanning.Get('content');
icol_iscatch = S.recPlanning.Get('iscatch');
n_catch = 0;
n_resp_ok = 0;
has_responded = 0;
has_responded_stim = 0;

% main loop
for evt = 1 : S.recPlanning.count

    evt_name     = S.recPlanning.data{evt,S.recPlanning.icol_name    };
    evt_onset    = S.recPlanning.data{evt,S.recPlanning.icol_onset   };
    evt_duration = S.recPlanning.data{evt,S.recPlanning.icol_duration};
    content      = S.recPlanning.data{evt,           icol_content };

    if evt < S.recPlanning.count
        next_evt_onset = S.recPlanning.data{evt+1,S.recPlanning.icol_onset};
    end

    switch evt_name

        case 'START'

            FixationCross.Draw();
            Window.Flip();
            S.STARTtime = PTB_ENGINE.START(S.cfgKeybinds.Start, S.cfgKeybinds.Abort);
            S.recEvent.AddStart();
            S.Window.AddFrameToMovie();

        case 'END'

            S.ENDtime = WaitSecs('UntilTime', S.STARTtime + evt_onset );
            S.recEvent.AddEnd(S.ENDtime - S.STARTtime );
            S.Window.AddFrameToMovie();
            PTB_ENGINE.END();


        case 'Rest'

            FixationCross.Draw();
            real_onset = Window.Flip(S.STARTtime + evt_onset - Window.slack);
            S.recEvent.AddStim(evt_name, real_onset-S.STARTtime, [], S.recPlanning.data(evt,S.recPlanning.icol_data:end));

            fprintf('Rest : %gs \n', evt_duration)
            S.Window.AddFrameToMovie(evt_duration);

            next_onset = S.STARTtime + next_evt_onset - Window.slack;
            while secs < next_onset
                [keyIsDown, secs, keyCode] = KbCheck();
                if keyIsDown
                    EXIT = keyCode(S.cfgKeybinds.Abort);
                    if EXIT, break, end
                end
            end


        case 'Instruction'

            TextInstruction.Draw(content);
            real_onset = Window.Flip(S.STARTtime + evt_onset - Window.slack);
            S.recEvent.AddStim(evt_name, real_onset-S.STARTtime, [], S.recPlanning.data(evt,S.recPlanning.icol_data:end));

            fprintf('Instruction : %gs --- %s \n', evt_duration, content);
            S.Window.AddFrameToMovie(evt_duration);

            next_onset = S.STARTtime + next_evt_onset - Window.slack;
            while secs < next_onset
                [keyIsDown, secs, keyCode] = KbCheck();
                if keyIsDown
                    EXIT = keyCode(S.cfgKeybinds.Abort);
                    if EXIT, break, end
                end
            end

            skip_delay_check_catch = 1;


        case 'Delay'

            real_onset = Window.Flip(S.STARTtime + evt_onset - Window.slack);
            S.recEvent.AddStim(evt_name, real_onset-S.STARTtime, [], S.recPlanning.data(evt,S.recPlanning.icol_data:end));
            S.Window.AddFrameToMovie(evt_duration);

            if skip_delay_check_catch
                % i dont care if the ABORT section is also skipped for this event,
                % its a very short event...
                continue
            end

            % While loop for most of the duration of the event, so we can press ESCAPE
            next_onset = S.STARTtime + next_evt_onset - Window.slack;
            while secs < next_onset
                [keyIsDown, secs, keyCode] = KbCheck();
                if keyIsDown

                    EXIT = keyCode(S.cfgKeybinds.Abort);
                    if EXIT, break, end

                    if has_responded_stim
                        has_responded = 1;
                        break
                    elseif keyCode(S.cfgKeybinds.Catch)
                        has_responded = 1;
                        RT = secs - stim_real_onset;
                        resp_ok = iscatch;
                        n_resp_ok = n_resp_ok + resp_ok;
                        break
                    end

                end
            end % while

            if has_responded

                if ~iscatch
                    n_resp_ok = n_resp_ok - 1;
                end

                fprintf('RT=%5.fms   resp_ok=%1d (%3d%%)\n',...
                    round(RT * 1000),...
                    resp_ok,...
                    round(100*n_resp_ok / n_catch) ...
                    )

                S.recBehaviour.AddLine({itrial iblock istim stim_content iscatch RT resp_ok})

            else
                fprintf('RT=%5sms   resp_ok=%1s (%3d%%)\n',...
                    '',...
                    iscatch_str,...
                    round(100*n_resp_ok / n_catch) ...
                    )
                S.recBehaviour.AddLine({itrial iblock istim stim_content iscatch -1 ~iscatch})
            end


        case 'Stim'

            TextStim.Draw(content);
            stim_real_onset = Window.Flip(S.STARTtime + evt_onset - Window.slack);
            S.recEvent.AddStim(evt_name, stim_real_onset-S.STARTtime, [], S.recPlanning.data(evt,S.recPlanning.icol_data:end));
            S.Window.AddFrameToMovie(evt_duration);

            itrial  = S.recPlanning.data{evt,icol_trial  };
            iblock  = S.recPlanning.data{evt,icol_block  };
            istim   = S.recPlanning.data{evt,icol_stim   };
            iscatch = S.recPlanning.data{evt,icol_iscatch};
            stim_content = content;

            if iscatch
                iscatch_str = '1';
            else
                iscatch_str = '';
            end
            n_catch = n_catch + iscatch;

            fprintf('#trial=%3d   #block=%2d   #stim=%2d   content=%1s   iscatch=%1s   ',...
                itrial,...
                iblock,...
                istim,...
                content,...
                iscatch_str ...
                )

            has_responded_stim = 0;
            has_responded      = 0;
            skip_delay_check_catch = 0;

            % While loop for most of the duration of the event, so we can press ESCAPE
            next_onset = S.STARTtime + next_evt_onset - Window.slack;
            while secs < next_onset
                [keyIsDown, secs, keyCode] = KbCheck();
                if keyIsDown
                    EXIT = keyCode(S.cfgKeybinds.Abort);
                    if EXIT, break, end

                    if keyCode(S.cfgKeybinds.Catch)
                        has_responded_stim = 1;
                        break
                    end
                end
            end % while

            if has_responded_stim
                RT = secs - stim_real_onset;
                resp_ok = iscatch;
                n_resp_ok = n_resp_ok + resp_ok;
            end

        otherwise
            error('unknown event : %s', evt_name)

    end % switch

    % if Abort is pressed
    if EXIT

        S.ENDtime = GetSecs();
        S.recEvent.AddEnd(S.ENDtime - S.STARTtime);
        S.recEvent.ClearEmptyLines();

        S.recBehaviour.ClearEmptyLines();

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
assignin('base', 'S', S)

switch S.guiACQmode
    case 'Acquisition'
    case {'Debug', 'FastDebug'}
        UTILS.plotDelay(S.recPlanning, S.recEvent);
        % UTILS.plotStim(S.recPlanning, S.recEvent, S.recKeylogger);
end

end % fcn
