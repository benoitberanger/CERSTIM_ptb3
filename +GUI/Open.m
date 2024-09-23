function varargout = Open()
% OpenGUI is the function that creates (or bring to focus) gui.
% Then, CORE.Workflow() is always called to start each task. It is the
% "main" program.

logger = getLogger();

logger.log('Starting (or focussing) GUI...');

% debug=1 closes previous figure and reopens it, and send the gui handles
% to base workspace.
debug = 0;

gui_name = [ 'GUI_' CONFIG.ProjectName() ];


%% Open a singleton figure, or focus on it.

% Is the GUI already open ?
figPtr = findall(0,'Tag',gui_name);

if ~isempty(figPtr)

    % brings it to the focus
    figure(figPtr);

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%% DEBUG %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    if debug
        clc %#ok<UNRCH>
        close(figPtr);
        GUI.Open();
    end
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    if nargout > 0
        varargout{1} = guidata(figPtr);
    end

    logger.log('GUI ready');

    return

end

%% Create the figure

% Create a figure
figHandle = figure( ...
    'HandleVisibility', 'off',... % close all does not close the figure
    'MenuBar'         , 'none'                   , ...
    'Toolbar'         , 'none'                   , ...
    'Name'            , gui_name                 , ...
    'NumberTitle'     , 'off'                    , ...
    'Units'           , 'Pixels'                 , ...
    'Position'        , [50, 50, 600, 700]       , ...
    'Tag'             , gui_name                 );

figureBGcolor = [0.9 0.9 0.9]; set(figHandle,'Color',figureBGcolor);
buttonBGcolor = figureBGcolor - 0.1;
editBGcolor   = [1.0 1.0 1.0];

% Create GUI handles : pointers to access the graphic objects
handles               = guihandles(figHandle);
handles.figureBGcolor = figureBGcolor;
handles.buttonBGcolor = buttonBGcolor;
handles.editBGcolor   = editBGcolor  ;


%% UI obj base config

base_cfg_panel       = {'Units', 'Normalized', 'BackgroundColor',figureBGcolor                       };
base_cfg_text        = {'Units', 'Normalized', 'BackgroundColor',figureBGcolor, 'Style','text'       };
base_cfg_edit        = {'Units', 'Normalized', 'BackgroundColor',editBGcolor  , 'Style','edit'       };
base_cfg_pushbutton  = {'Units', 'Normalized', 'BackgroundColor',buttonBGcolor, 'Style','pushbutton' };
base_cfg_radiobutton = {'Units', 'Normalized', 'BackgroundColor',figureBGcolor, 'Style','radiobutton'};
base_cfg_listbox     = {'Units', 'Normalized', 'BackgroundColor',editBGcolor  , 'Style','listbox'    };
base_cfg_checkbox    = {'Units', 'Normalized', 'BackgroundColor',figureBGcolor, 'Style','checkbox'   };


%% Main pannels
% To add a new "main" panel, its here.

handles.uipanel_perma_cfg = uipanel(handles.(gui_name), base_cfg_panel{:}, 'Position',[0.00 0.50 1.00 0.50], 'Title','CFG' );
handles.uipanel_task      = uipanel(handles.(gui_name), base_cfg_panel{:}, 'Position',[0.00 0.00 1.00 0.50], 'Title','TASK');


%% Panel : permanent config

where = handles.uipanel_perma_cfg;

% first line
handles.uipanel_sid     = uipanel      (where, 'Position',[0.00 0.80 1.00 0.20], base_cfg_panel{:}, 'Title','Subject ID'   );
% second line
handles.uipanel_mode    = uibuttongroup(where, 'Position',[0.00 0.50 0.25 0.30], base_cfg_panel{:}, 'Title','ACQ mode'     );
handles.uipanel_save    = uibuttongroup(where, 'Position',[0.25 0.50 0.25 0.30], base_cfg_panel{:}, 'Title','Save'         );
handles.uipanel_kb      = uibuttongroup(where, 'Position',[0.50 0.50 0.25 0.30], base_cfg_panel{:}, 'Title','Keybind'      );
handles.uipanel_parport = uibuttongroup(where, 'Position',[0.75 0.50 0.25 0.30], base_cfg_panel{:}, 'Title','Parallel port');
% third line
handles.uipanel_screen  = uipanel      (where, 'Position',[0.00 0.00 0.40 0.50], base_cfg_panel{:}, 'Title','Screen'       );
handles.uipanel_eyelink = uibuttongroup(where, 'Position',[0.40 0.00 0.60 0.50], base_cfg_panel{:}, 'Title','Eyelink'      );


%% Panel : Subject ID

where = handles.uipanel_sid;
handles.edit_SubjectID = uicontrol(where, base_cfg_edit{:}, 'Position',[0.00 0.00 1.00 1.00], 'String','', 'Callback',@GUI.VIEW.edit_SubjectID_Callback);


%% Panel : Mode

where = handles.uipanel_mode;
handles.radiobutton_mode_acq       = uicontrol(where, base_cfg_radiobutton{:}, 'Position',[0.05 0.66 0.90 0.33], 'String','Acquisition', 'Tooltip','Save data, execute full script.');
handles.radiobutton_mode_debug     = uicontrol(where, base_cfg_radiobutton{:}, 'Position',[0.05 0.33 0.90 0.33], 'String','Debug'      , 'Tooltip','Don''t save data, run the scripts ~normal speed.');
handles.radiobutton_mode_fastdebug = uicontrol(where, base_cfg_radiobutton{:}, 'Position',[0.05 0.00 0.90 0.33], 'String','FastDebug'  , 'Tooltip','Don''t save data, run the scripts very fast.');


%% Panel : Save

where = handles.uipanel_save;
handles.radiobutton_mode_yes = uicontrol(where, base_cfg_radiobutton{:}, 'Position',[0.05 0.50 0.90 0.50], 'String','Yes', 'Tooltip','');
handles.radiobutton_mode_no  = uicontrol(where, base_cfg_radiobutton{:}, 'Position',[0.05 0.00 0.90 0.50], 'String','No' , 'Tooltip','');


%% Panel : Keybind

where = handles.uipanel_kb;
handles.radiobutton_mode_acq   = uicontrol(where, base_cfg_radiobutton{:}, 'Position',[0.05 0.50 0.90 0.50], 'String','fORP (MRI)', 'Tooltip','The grey response button box, with fiber optic devices0');
handles.radiobutton_mode_debug = uicontrol(where, base_cfg_radiobutton{:}, 'Position',[0.05 0.00 0.90 0.50], 'String','Keyboard'  , 'Tooltip','Normal keyboard.');


%% Panel : Parallel port

where = handles.uipanel_parport;
handles.radiobutton_pp_yes = uicontrol(where, base_cfg_radiobutton{:}, 'Position',[0.05 0.50 0.90 0.50], 'String','Yes', 'Tooltip','');
handles.radiobutton_pp_no  = uicontrol(where, base_cfg_radiobutton{:}, 'Position',[0.05 0.00 0.90 0.50], 'String','No' , 'Tooltip','');

result = GUI.VIEW.IsOpenParPortPortDetected();
if ~result
    where.SelectedObject = handles.radiobutton_pp_no;
    handles.radiobutton_pp_yes.Visible = 'off';
    logger.err('Parallel port GUI option disabled')
end


%% Panel : Screen

where = handles.uipanel_screen;
handles.text_screenid        = uicontrol(where, base_cfg_text    {:}, 'Position',[0.05 0.85 0.30 0.10], 'String','Screen ID'    );
handles.listbox_Screens      = uicontrol(where, base_cfg_listbox {:}, 'Position',[0.05 0.05 0.30 0.80], 'String',''             , 'CreateFcn',@GUI.VIEW.listbox_Screens_CreateFcn);
handles.checkbox_windowed    = uicontrol(where, base_cfg_checkbox{:}, 'Position',[0.40 0.66 0.70 0.33], 'String','Windowed mode', 'Tooltip','Not full screen. Useful for single screen debugging (like laptop)');
handles.checkbox_transparent = uicontrol(where, base_cfg_checkbox{:}, 'Position',[0.40 0.33 0.70 0.33], 'String','Transparent'  , 'Tooltip','Transparent window. Useful for single screen debugging (like laptop)');
handles.checkbox_recordmovie = uicontrol(where, base_cfg_checkbox{:}, 'Position',[0.40 0.00 0.70 0.33], 'String','Record movie' , 'Tooltip','Record the screen into a movie, and save it to the disk.');


%% Panel : Eyelink

where = handles.uipanel_eyelink;
where.SelectionChangedFcn = @GUI.VIEW.uipanel_eyelink_SelectionChangedFcn;
handles.radiobutton_eyelink_yes = uicontrol(where, base_cfg_radiobutton{:}, 'Position',[0.05 0.50 0.15 0.50], 'String','Yes','Tooltip','');
handles.radiobutton_eyelink_no  = uicontrol(where, base_cfg_radiobutton{:}, 'Position',[0.05 0.00 0.15 0.50], 'String','No' ,'Tooltip','');
handles.uipanel_eyelink_buttons = uipanel  (where, base_cfg_panel      {:}, 'Position',[0.20 0.00 0.80 1.00], 'Title' ,''   );

where = handles.uipanel_eyelink_buttons;
% first line
handles.pushbutton_eyelink_initialize    = uicontrol(where, base_cfg_pushbutton{:}, 'Position',[0.00 0.50 0.33 0.50], 'String','Initialize'   , 'Callback', @GUI.VIEW.pushbutton_eyelink_initialize_Callback   );
handles.pushbutton_eyelink_isconnected   = uicontrol(where, base_cfg_pushbutton{:}, 'Position',[0.33 0.50 0.33 0.50], 'String','IsConnected'  , 'Callback', @GUI.VIEW.pushbutton_eyelink_isconnected_Callback  );
handles.pushbutton_eyelink_calibration   = uicontrol(where, base_cfg_pushbutton{:}, 'Position',[0.66 0.50 0.33 0.50], 'String','Calibration'  , 'Callback', @GUI.VIEW.pushbutton_eyelink_calibration_Callback  );
% second line
handles.pushbutton_eyelink_downloadfiles = uicontrol(where, base_cfg_pushbutton{:}, 'Position',[0.00 0.00 0.66 0.50], 'String','DownloadFiles', 'Callback', @GUI.VIEW.pushbutton_eyelink_downloadfiles_Callback);
handles.pushbutton_eyelink_forcereset    = uicontrol(where, base_cfg_pushbutton{:}, 'Position',[0.66 0.00 0.33 0.50], 'String','ForceReset   ', 'Callback', @GUI.VIEW.pushbutton_eyelink_forcereset_Callback   );


%% Panel : Task

where = handles.uipanel_task;

tasklist = UTILS.GET.TaskList();

nObjPerRow = 2;
task_dispatcher = GUI.VIEW.ObjectDispatcher(ones(size(tasklist)), nObjPerRow);

for i = 1 : length(tasklist)
    task_dispatcher.next();
    taskname = tasklist{i};
    uiname = sprintf('pushbutton_task_%s', taskname);
    handles.(uiname) = uicontrol(where, base_cfg_pushbutton{:}, 'Position',task_dispatcher.pos(), 'String',taskname, 'Callback', @GUI.Workflow);
end


%% End of opening

% IMPORTANT
guidata(figHandle,handles)
% After creating the figure, dont forget the line
% guidata(figHandle,handles) . It allows smart retrive like
% handles=guidata(hObject)

handles = guidata(figHandle);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%% DEBUG %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if debug
    assignin('base','handles',handles) %#ok<UNRCH>
    disp(handles)
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if nargout > 0
    varargout{1} = handles;
end

logger.log('GUI ready');


end % function
