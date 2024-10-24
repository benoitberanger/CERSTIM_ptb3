function Workflow( hObject, ~ )
% Here is the main workflow, where everythging happens
% --- in the GUI, click on task button
% - Retrieve GUI parameters
% - Set most of the variables : data path, current run number, output filename, eyelink filename, ...
% - Start task Run()
% - Save 'raw' data immediately after the end of task
% - Perform post-task operations : generate models for SPM, print run performances, ...
% - Save all files (if necessary)
% --- ready for another run

clc
sca
rng('shuffle') % to make sure each time a task is started the rand* functions will use a new random seed
logger = getLogger(); % my logging object, used everywhere, except at runtime
handles = guidata( hObject ); % Retrieve GUI data


%% Initialize the main structure

% NOTES : Here I made the choice of using a "global" variable, because it
% simplifies a lot all the functions. It allows retrieve of the variable
% everywhere, and make lighter the input/output parameters

global S
S                 = struct; % S is the main structure, containing everything useful, and used everywhere
S.ProjectName     = CONFIG.ProjectName();
S.ProjectRootDir  = UTILS.GET.RootDir();
S.ProjectDataDir  = UTILS.GET.DataDir();
S.TimeStampSimple = datestr(now, 'yyyy-mm-dd HH:MM:SS'); % readable
S.TimeStampFile   = datestr(now, 'yyyymmddTHHMMSS'    ); % to sort automatically files by time of creation


%% Lots of get*

S.guiSubjectID   = GUI.GET.SubjectID  ( handles );
S.guiACQmode     = GUI.GET.ACQmode    ( handles );
S.guiSave        = GUI.GET.Save       ( handles );
S.guiKeybind     = GUI.GET.Keybind    ( handles );
S.guiParport     = GUI.GET.Parport    ( handles );
S.guiScreenID    = GUI.GET.ScreenID   ( handles );
S.guiWindowed    = GUI.GET.Windowed   ( handles );
S.guiTransparent = GUI.GET.Transparent( handles );
S.guiRecordMovie = GUI.GET.RecordMovie( handles );
S.guiEyelink     = GUI.GET.Eyelink    ( handles );
S.guiTask        = GUI.GET.Task       ( hObject );
S.guiInputMethod = GUI.GET.InputMethod( handles );
S.guiValueFmax   = GUI.GET.valueFmax  ( handles );
S.guiPctFmax     = GUI.GET.pctFmax    ( handles );
S.guiNewton      = GUI.GET.Newton     ( handles );


%% Input method

logger.log('Selected input method : %s', S.guiInputMethod)
if strcmp(S.guiInputMethod, 'HandGrip')
    S.LabJackU6 = UTILS.LabJackU6();
    S.LabJackU6.Open();
    S.LabJackU6.Configure();
    S.LabJackU6.GetValue();
else
    % pass
end

%% Hand grip

logger.assert(~isnan(S.guiValueFmax), 'GUI::Empty:: Participant''s Fmax value (N)')
logger.assert(~isnan(S.guiPctFmax  ), 'GUI::Empty:: Task % FmaxY'                  )
logger.assert(~isnan(S.guiNewton   ), 'GUI::Empty:: Task Newton (N)'              )


%% Some warnings, and other stuff

S.WriteFiles = strcmp(S.guiACQmode, 'Acquisition') && S.guiSave;

if S.WriteFiles
    logger.warn('In `Acquisition` mode, data should be saved.')
end


%% SubjectID & where to store the data

if isempty(S.guiSubjectID)
    logger.err('SubjectID is empty')
    return
end

S.SubjectDataDir = UTILS.GET.SubjectDataDir(S.guiSubjectID);


%% Generate base output filepath

basename_norun = sprintf('%s__%s', S.guiSubjectID, S.guiTask );
[S.RunName, S.RunNumber] = UTILS.AppendRunNumber(S.SubjectDataDir, basename_norun);

S.OutFilename    = sprintf('%s__%s', S.TimeStampFile, S.RunName);
S.OutFilepath    = fullfile(S.SubjectDataDir, S.OutFilename);
logger.log('Output file name  = %s', S.OutFilename)

if S.WriteFiles
    if ~exist(S.SubjectDataDir, 'dir')
        mkdir(S.SubjectDataDir);
    end
    % Security : NEVER overwrite a file
    % If erasing a file is needed, you need to do it manually
    % but this should not happen with the timestamp which is unique
    logger.assert( ~exist([S.OutFilepath '.mat'],'file'), 'The file %s.mat already exists', [S.OutFilepath '.mat'] );
end


%% Eyelink

if S.guiEyelink

    eyelink_detected = ~isempty(which('Eyelink.m'));
    if ~eyelink_detected, logger.err('No `Eyelink.m` detected in MATLAB path.')       , return, end
    if ~S.guiSave       , logger.err('Save data MUST be turned on when using Eyelink'), return, end
    if ~EYELINK.IsConnected()                                                         , return, end % log message is inside the function

    % Generate the Eyelink filename
    eyelink_max_finename = 8;                                                       % Eyelink filename must be 8 char maximum (Eyelink limitation)
    available_char        = ['a':'z' 'A':'Z' '0':'9'];                              % This is all characters available (N=62)
    name_num              = randi(length(available_char),[1 eyelink_max_finename]); % Pick 8 numbers, from 1 to N=62 (same char can be picked twice)
    name_str              = available_char(name_num);                               % Convert the 8 numbers into char

    S.EyelinkFile = name_str;
    logger.log('Eyelink file name = %s', S.EyelinkFile)

end


%% Task

result = which('TASK.CERSTIM.Run');
if isempty(result)
    logger.err('TASK.CERSTIM.Run not found')
    return
end

logger.log('Calling TASK.CERSTIM.Run()')

switch S.guiACQmode

    case 'Acquisition'
        % call the Run() in a try/catch
        try
            TASK.CERSTIM.Run();
        catch exception
            % Abort at START ?
            if ~isempty(strfind(exception.message, 'Abort')) && ~isempty(strfind(exception.stack(1).name, 'START'))
                return
            end

            % No ? then try to continue
            disp(exception)
            for i = 1:numel(exception.stack)
                disp(exception.stack(i))
            end
        end

    case {'Debug', 'FastDebug'}
        % no try/catch, because it's easier for debugging
        TASK.CERSTIM.Run();

end


%% Save data 'raw' data immediatly

if S.WriteFiles
    fpath_raw = [S.OutFilepath '__RAW.mat'];
    save(fpath_raw, 'S')
    logger.log('saved RAW file : %s', fpath_raw)
end


%% Save post-processing files

[names, onsets, durations] = TASK.CERSTIM.Generate_SPM_NamesOnsetsDurations_block();

if S.WriteFiles
    fpath_spm_block = [S.OutFilepath '__SPM_block.mat'];
    save(fpath_spm_block, 'names', 'onsets', 'durations'); % light weight file with only the onsets for SPM
    logger.log('saved SPM `block` file : %s', fpath_spm_block)
end


[R_all, names_all] = TASK.CERSTIM.Generate_SPM_NamesOnsetsDurations_regressor();

if S.WriteFiles
    fpath_spm_regressor_base = [S.OutFilepath '__SPM_regressor'];
    for idx = 1:length(names_all)
        fpath_spm_regressor_current = [fpath_spm_regressor_base '__' names_all{idx} '.mat'];
        R     = R_all    (:,idx);
        names = names_all(  idx);
        save(fpath_spm_regressor_current, 'R', 'names');
        logger.log('saved SPM `regressor` file : %s', fpath_spm_regressor_current)
    end
end


%% Ready for another run

WaitSecs(0.100);
pause(0.100);
logger.log('~~~~~~~~~~~~~~~~~~~~~~~~~~~~')
logger.log('    Ready for another run   ')
logger.log('~~~~~~~~~~~~~~~~~~~~~~~~~~~~')


end % fcn
