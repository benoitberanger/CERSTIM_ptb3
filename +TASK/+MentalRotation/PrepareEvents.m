function [planning, cfgEvents] = PrepareEvents(ACQmode)

if nargin < 1 % only to plot the paradigm when we execute the function outside of the main script
    ACQmode = 'Acquisition';
end

cfgEvents = struct; % This structure will contain task specific parameters

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% MODIFY SETTINGS FROM HERE....
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 3D Tetris

cfgEvents.cube_segment = [4 3 4 3]; % IMPORTANT : keep an asymatric tetris, so there is no ambiguity

cfgEvents.miniblock  = {
    % angle  name
    000      'same'
    030      'same'
    060      'same'
    120      'same'
    000      'mirror'
    030      'mirror'
    060      'mirror'
    120      'mirror'
    };

cfgEvents.num_tetris = 5;  % == number of repetitions


%% Timings


cfgEvents.durTetris   = 10;    %           seconds
cfgEvents.durFixation = [5 6]; % [min max] seconds

% In this task the 3D rendering is VERY fast, but capturing the image to
% perform the hack is VERY slow. This parameter is used to help having
% better timings for the "Rest" event. On my dev computer, the whole
% render+drawing time is ~80ms.
cfgEvents.durMaxRenderTime = 0.100; % seconds


%% Debugging

switch ACQmode
    case 'Acquisition'
        % pass
    case 'Debug'
        cfgEvents.num_tetris  = 2;
        cfgEvents.durFixation = [0.2 0.2];
    case 'FastDebug'
        cfgEvents.num_tetris  = 4;
        cfgEvents.durFixation = [0.5 0.8];
    otherwise
        error('mode ?')
end


%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% ... TO HERE
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Generate

nTrials = size(cfgEvents.miniblock,1) * cfgEvents.num_tetris;
cfgEvents.nTrials = nTrials;

% Generate tetris ---------------------------------------------------------

nSeg = length(cfgEvents.cube_segment);
all_tetris = zeros(cfgEvents.num_tetris, nSeg); % contain all generated tetris

for t = 1 : cfgEvents.num_tetris

    if t == 1
        tetris = generate_random_tetris(nSeg);
        all_tetris(t,:) = tetris; % since its the first, just store it
    else

        while 1
            tetris = generate_random_tetris(nSeg);
            is_new_tetris = ~any(sum(all_tetris == tetris,2) == nSeg);
            if is_new_tetris
                all_tetris(t,:) = tetris;
                break
            end
        end

    end

end

% shuffle one last time
all_tetris = Shuffle(all_tetris,2);


% Generate Fixation jitter ------------------------------------------------

all_jitters = linspace(cfgEvents.durFixation(1), cfgEvents.durFixation(2), nTrials + 1);
all_jitters = Shuffle(all_jitters);


% Pseudo-randomize events -------------------------------------------------

event_list = {};
for n = 1 : cfgEvents.num_tetris
    event_list = [event_list ; Shuffle(cfgEvents.miniblock,2)]; %#ok<AGROW>
end

tetris_list = repmat(all_tetris, [size(cfgEvents.miniblock,1) 1]);
tetris_list = Shuffle(tetris_list,2);

event_list(:,3) = num2cell(tetris_list,2);


%% Build planning

% Create and prepare
header = { 'iTrial', 'angle(deg)', 'condition', 'tetris'};
planning = UTILS.RECORDER.Planning(0,header);

% --- Start ---------------------------------------------------------------

planning.AddStart();

% --- Stim ----------------------------------------------------------------

for iTrial = 1 : nTrials
    planning.AddStim('Rest' , planning.GetNextOnset(), all_jitters(iTrial)       )
    planning.AddStim('Trial', planning.GetNextOnset(), cfgEvents.durTetris, [{iTrial} event_list(iTrial,:)])
end
planning.AddStim(    'Rest' , planning.GetNextOnset(), all_jitters(iTrial+1)     )

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

function tetris = generate_random_tetris(nSeg)

% generate X Y Z order
order = Shuffle([1 2 3]);
if nSeg > 3
    order = repmat(order, [1 ceil(nSeg/3)]);
    order = order(1:nSeg);
end

% generate positive or negative axis direction
signs = sign(rand(1,nSeg) - 0.5);

% finalize
tetris = order.*signs;

end % fcn
