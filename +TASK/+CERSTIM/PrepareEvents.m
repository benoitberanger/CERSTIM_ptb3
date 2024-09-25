function [planning, cfgEvents] = PrepareEvents(ACQmode)

if nargin < 1 % only to plot the paradigm when we execute the function outside of the main script
    ACQmode = 'Acquisition';
    guiTask = 'Full';
end

cfgEvents = struct; % This structure will contain task specific parameters

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% MODIFY SETTINGS FROM HERE....
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% CERSTIM

cfgEvents.Condition          = {'pctFmax', 'Newton'};
cfgEvents.nTrialPerCondition = 15;


%% Timings

% all in seconds
cfgEvents.durRampUp   = [1.0 3.0]; % [min max] for the jitter
cfgEvents.durFlatTop  = 2.0;
cfgEvents.durRest     = 6.0;

cfgEvents.durWindow   = 6.0; % 1 screen content is this duration


%% Debugging

switch ACQmode
    case 'Acquisition'
        % pass
    case 'Debug'
        cfgEvents.nTrialPerCondition = 2;
    case 'FastDebug'
        cfgEvents.nTrialPerCondition = 2;
        cfgEvents.durRampUp   = [1.0 2.0]; % [min max] for the jitter
        cfgEvents.durRest     = 3.0;
    otherwise
        error('mode ?')
end


%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% ... TO HERE
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Generate

% Prepare list of conditions
cfgEvents.nCondition = length(cfgEvents.Condition);
cfgEvents.nTrial     = cfgEvents.nCondition * cfgEvents.nTrialPerCondition;

Trials = NaN(cfgEvents.nTrial, 2); % pre-allocate
vect_rampup = linspace(cfgEvents.durRampUp(1), cfgEvents.durRampUp(2), cfgEvents.nTrialPerCondition);

for i = 1 : cfgEvents.nCondition
    for j = 1 : cfgEvents.nTrialPerCondition
        idx = j + (i-1)*cfgEvents.nTrialPerCondition;
        Trials( idx, 1 ) = i;
        Trials( idx, 2 ) = vect_rampup(j);
    end
end

Trials = Shuffle(Trials,2);
cfgEvents.Trials = Trials;


%% Build planning

% Create and prepare
header = {'#trial', 'stim', 'condition'};
planning = UTILS.RECORDER.Planning(0,header);

% --- Start ---------------------------------------------------------------

planning.AddStart();

% --- Stim ----------------------------------------------------------------

planning.    AddStim('Rest'                , planning.GetNextOnset(), cfgEvents.durRest       , {    [], 'Rest'  ,        ''})
for iTrial = 1 : cfgEvents.nTrial
    condname = cfgEvents.Condition{Trials(iTrial,1)};
    planning.AddStim(['RampUp__'  condname], planning.GetNextOnset(), Trials(iTrial,2)        , {iTrial, 'RampUp' , condname})
    planning.AddStim(['FlatTop__' condname], planning.GetNextOnset(), cfgEvents.durFlatTop    , {iTrial, 'FlatTop', condname})
    planning.AddStim(['Rest__'    condname], planning.GetNextOnset(), cfgEvents.durRest       , {iTrial, 'Rest'   , condname})
end
planning.    AddStim('Rest'                , planning.GetNextOnset(), cfgEvents.durRest       , {    [], 'Rest'  ,        ''})

% --- Stop ----------------------------------------------------------------

planning.AddEnd(planning.GetNextOnset());


%% Display

% To prepare the planning and visualize it, we can execute the function
% without output argument

if nargin < 1

    fprintf( '\n' )
    fprintf(' \n Total stim duration : %g seconds \n' , planning.GetNextOnset() )
    fprintf( '\n' )

    planning.Plot();

end


end % fcn
