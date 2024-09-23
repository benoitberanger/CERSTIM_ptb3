function Run()
global S


%% prepare events, timings, randomization

[S.recPlanning, S.cfgEvents] = TASK.(S.guiTask).PrepareEvents(S.guiACQmode);


%% create other recorders

S.recEvent     = UTILS.RECORDER.Event(S.recPlanning);
S.recBehaviour = UTILS.RECORDER.Cell({'trial#' 'condition' 'angle(deg)' 'tetris[4]' 'RT(s)' 'subj_resp' 'resp_ok'}, S.cfgEvents.nTrials);


%% set keybinds

S.cfgKeybinds = TASK.cfgKeyboard(); % cross task keybinds

switch S.guiKeybind
    case 'fORP (MRI)'
        S.cfgKeybinds.Same   = KbName('b');
        S.cfgKeybinds.Mirror = KbName('y');
    case 'Keyboard'
        S.cfgKeybinds.Same   = KbName('RightArrow');
        S.cfgKeybinds.Mirror = KbName('LeftArrow');
    otherwise
        error('unknown S.guiKeybind : %s', S.guiKeybind)
end

S.recKeylogger = UTILS.RECORDER.Keylogger(S.cfgKeybinds);
S.recKeylogger.Start();


%% set parameters for rendering objects

S.cfgFixationCross = TASK.cfgFixationCross();


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

Tetris3D = PTB_OBJECT.VIDEO.Tetris3D();
Tetris3D.window = Window;
Tetris3D.segment_length = S.cfgEvents.cube_segment;
Tetris3D.InitializeOpenGL();
Tetris3D.GenCubeTexture();
Tetris3D.PrepareNormal();

% tetris    = [1 2 3 2];
% angle     = 0;
% is_mirror = true;
%
% Tetris3D.DoubleRenderHack(tetris, angle, is_mirror);
% FixationCross.Draw();
% Window.Flip();
%
% KbWait();
% Tetris3D.DeleteCubeTextures();
% sca
% return

%% run the events

% initialize / pre-allocate some vars
EXIT = false;
secs = GetSecs();
icol_itrial    = S.recPlanning.Get('iTrial');
icol_angle     = S.recPlanning.Get('angle');
icol_condition = S.recPlanning.Get('condition');
icol_tetris    = S.recPlanning.Get('tetris');
prev_onset    = [];
prev_duration = [];
subj_resp = '';
n_resp_ok = 0;

% main loop
for evt = 1 : S.recPlanning.count

    evt_name      = S.recPlanning.data{evt,S.recPlanning.icol_name     };
    % evt_onset     = S.recPlanning.data{evt,S.recPlanning.icol_onset    };
    evt_duration  = S.recPlanning.data{evt,S.recPlanning.icol_duration };
    evt_trial     = S.recPlanning.data{evt,              icol_itrial   };
    evt_angle     = S.recPlanning.data{evt,              icol_angle    };
    evt_condition = S.recPlanning.data{evt,              icol_condition};
    evt_tetris    = S.recPlanning.data{evt,              icol_tetris   };

    switch evt_name

        case 'START'

            FixationCross.Draw();
            Window.Flip();
            S.STARTtime = PTB_ENGINE.START(S.cfgKeybinds.Start, S.cfgKeybinds.Abort);
            S.recEvent.AddStart();
            S.Window.AddFrameToMovie();


        case 'END'

            S.ENDtime = WaitSecs('UntilTime', prev_onset + prev_duration );
            S.recEvent.AddEnd(S.ENDtime - S.STARTtime );
            S.Window.AddFrameToMovie();
            PTB_ENGINE.END();


        case 'Rest'

            FixationCross.Draw();
            real_onset = Window.Flip();
            prev_onset = real_onset;
            prev_duration = evt_duration;
            S.recEvent.AddStim(evt_name, real_onset-S.STARTtime, [], S.recPlanning.data(evt,S.recPlanning.icol_data:end));

            S.Window.AddFrameToMovie(evt_duration);

            next_onset = real_onset + evt_duration - Window.slack;
            while secs < next_onset
                [keyIsDown, secs, keyCode] = KbCheck();
                if keyIsDown
                    EXIT = keyCode(S.cfgKeybinds.Abort);
                    if EXIT, break, end
                end
            end


        case 'Trial'

            switch evt_condition
                case 'same'
                    evt_is_mirror = false;
                case 'mirror'
                    evt_is_mirror = true;
                otherwise
                    error('???')
            end
            Tetris3D.DoubleRenderHack(evt_tetris, evt_angle, evt_is_mirror);
            FixationCross.Draw();
            real_onset = Window.Flip(prev_onset + prev_duration  - Window.slack);
            prev_onset = real_onset;
            prev_duration = evt_duration;
            S.recEvent.AddStim(evt_name, real_onset-S.STARTtime, [], S.recPlanning.data(evt,S.recPlanning.icol_data:end));

            fprintf('#trial=%3d/%3d   angle=%3d   condition=%6s   tetris=%s   ',...
                evt_trial,...
                S.cfgEvents.nTrials,...
                evt_angle,...
                evt_condition,...
                num2str(evt_tetris, repmat('%+2d ', [1 length(evt_tetris)])) ...
                )

            has_responded = false;

            next_onset = real_onset + evt_duration - Window.slack;
            while secs < next_onset
                [keyIsDown, secs, keyCode] = KbCheck();
                if keyIsDown
                    EXIT = keyCode(S.cfgKeybinds.Abort);
                    if EXIT, break, end

                    if keyCode(S.cfgKeybinds.Same)
                        has_responded = true;
                        subj_resp = 'same';
                    end
                    if keyCode(S.cfgKeybinds.Mirror)
                        has_responded = true;
                        subj_resp = 'mirror';
                    end

                    if has_responded
                        RT = secs - real_onset;
                        is_resp_ok = strcmp(subj_resp, evt_condition);
                        n_resp_ok = n_resp_ok + is_resp_ok;
                        S.recBehaviour.AddLine({evt_trial evt_condition evt_angle evt_tetris RT subj_resp is_resp_ok})

                        fprintf('RT=%5.fms   subj_resp=%6s   is_resp_ok=%2d (%3d%%)\n',...
                            round(RT * 1000),...
                            subj_resp,...
                            is_resp_ok,...
                            round(100*n_resp_ok / evt_trial) ...
                            )

                        S.Window.AddFrameToMovie(RT);
                        break
                    end

                end
            end % while

            if ~has_responded
                S.recBehaviour.AddLine({evt_trial evt_condition evt_angle evt_tetris -1 '' -1})
                fprintf('RT=%5.fms   subj_resp=%6s   is_resp_ok=%2d (%3d%%)\n',...
                    -1,...
                    0,...
                    -1,...
                    round(100*n_resp_ok / evt_trial) ...
                    )
                S.Window.AddFrameToMovie(evt_duration);
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
        % UTILS.plotDelay(S.recPlanning, S.recEvent);
        % UTILS.plotStim(S.recPlanning, S.recEvent, S.recKeylogger);
end


end % fcn
