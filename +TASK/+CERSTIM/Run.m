function Run()
global S


%% prepare events, timings, randomization

[S.recPlanning, S.cfgEvents] = TASK.CERSTIM.PrepareEvents(S.guiACQmode);


%% create other recorders

S.recEvent     = UTILS.RECORDER.Event(S.recPlanning);
S.recBehaviour = UTILS.RECORDER.Cell({'trial#' 'condition#'}, S.cfgEvents.nTrial);


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

S.cfgCursor.Size     = 0.10;              %  Size_px = ScreenY_px * Size
S.cfgCursor.Width    = 0.10;              % Width_px =    Size_px * Width
S.cfgCursor.Color    = [255 050 050 255]; % [R G B a], from 0 to 255
S.cfgCursor.XCenter  = 0.25;              % Position_px = ScreenX_px * XCenter
S.cfgCursor.YRange   = [0.25 0.75];       % Position_px = [ScreenY_px ScreenY_px] .* YRange


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


%% Prepare buffer

condition = S.recPlanning.data(:,S.recPlanning.Get('name'));
is_RampUp = ~cellfun(@isempty, strfind(condition, 'RampUp'));
max_dur_one_trial = max(cell2mat(S.recPlanning.data(is_RampUp,3))) + S.cfgEvents.durFlatTop;
buffer_size_px = round(3 * max_dur_one_trial * S.Window.size_x);
buffer = zeros(1, buffer_size_px);

px_per_second = S.Window.size_x / S.cfgEvents.durWindow;
px_per_frame  = px_per_second / S.Window.fps;


%% Prepare curves
% they will be added in the buffer

flattop_px = S.cfgEvents.durFlatTop * px_per_second;
rest_px    = S.cfgEvents.durRest    * px_per_second;

flatop_steps = flattop_px / px_per_frame;
rest_setps   = rest_px    / px_per_frame;

flatop_points = ones(1,flatop_steps);
rest_points   = ones(1,rest_setps  );

curves = cell(S.cfgEvents.nTrial,1);
for c = 1 : length(S.cfgEvents.nTrial)
    rampup_dur    = S.cfgEvents.Trials(c,2);
    rampup_px     = rampup_dur * px_per_second;
    rampup_steps  = rampup_px / px_per_frame;
    rampup_points = linspace(0, 1, rampup_steps);
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
Cursor.UpdateY(0);


