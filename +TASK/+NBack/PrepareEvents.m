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
%% N-Back

cfgEvents.nBack      = [0 2]; % 0-back & 2-back
cfgEvents.nBlock     = 3;     % repetition of each x-back block
cfgEvents.catchRatio = 0.20;  % percentage of catch
cfgEvents.nCatch     = 5;     % catch items per block

cfgEvents.availLetter{1} = { 'B' 'N' 'D' 'Q' 'G' 'S' 'J' 'V' };
cfgEvents.availLetter{2} = { 'C' 'P' 'F' 'R' 'H' 'T' 'L'  };
% this is seperated into 2 lists, to help psedo-random setup


%% Timings

% all in seconds
cfgEvents.durInstruction = 4.0;
cfgEvents.durStim        = 0.5;
cfgEvents.durDelay       = 1.5;
cfgEvents.durRest        = [7 8]; % [min max] for the jitter


%% Debugging

switch ACQmode
    case 'Acquisition'
        % pass
    case 'Debug'
        cfgEvents.nBlock     = 1;
        cfgEvents.nCatch     = 3;
        cfgEvents.durRest    = [1.0 1.0];
    case 'FastDebug'
        cfgEvents.nBlock     = 1;
        cfgEvents.nCatch     = 3;
        cfgEvents.durInstruction = 1.0;
        cfgEvents.durStim        = 0.2;
        cfgEvents.durDelay       = 0.5;
        cfgEvents.durRest        = [0.5 0.5];
    otherwise
        error('mode ?')
end


%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% ... TO HERE
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Generate

nStim = round(cfgEvents.nCatch * 1/cfgEvents.catchRatio);
block_order = repmat(cfgEvents.nBack, [1 cfgEvents.nBlock]);
cfgEvents.nTrials = length(block_order) * nStim;

blocks(length(block_order)) = struct;

for iBlock = 1 : length(block_order)

    % save difficulty info
    blocks(iBlock).nBack = block_order(iBlock);

    % generate random pseudo-random stim
    starting_subgroup = round(rand)+1;
    ending_subgroup   = -starting_subgroup + 3; % [1 2] -> [2 1]
    blk = [];
    while length(blk) < nStim % generate as much as we need
        blk = [blk Shuffle( cfgEvents.availLetter{starting_subgroup} ) Shuffle( cfgEvents.availLetter{ending_subgroup} )];
    end
    blk = blk(1:nStim); % crop to the right number

    % define position of catch trials
    catch_position = linspace(1,nStim,cfgEvents.nCatch+2); catch_position = catch_position(2:end-1); % evenly spread in the middle
    displacement = round(3*(rand(1,cfgEvents.nCatch)-0.5)); % add some radomness {-1 0 +1} in the position
    catch_position = round(catch_position) + displacement;

    if block_order(iBlock) == 0
        blk(catch_position) = {'X'}; % replace the catch trials
        blocks(iBlock).instruction = 'CLICK ON "X"';
    else
        for pos_idx = 1:length(catch_position)
            blk(catch_position(pos_idx)) = blk(catch_position(pos_idx)-block_order(iBlock)); % replace the catch trials
        end
        blocks(iBlock).instruction = sprintf('%d-BACK', block_order(iBlock));
    end

    % save
    blocks(iBlock).Trials = blk;
    blocks(iBlock).CatchIdx = catch_position;
    vect = zeros(1,nStim);
    vect(catch_position) = 1;
    blocks(iBlock).CatchVect = vect;

end

% save
cfgEvents.blocks = blocks;


%% Generate jitter

all_jitters = linspace(cfgEvents.durRest(1), cfgEvents.durRest(2), length(block_order) + 1);
all_jitters = Shuffle(all_jitters);


%% Build planning

% Create and prepare
header = {'#trial',  '#block', '#stim', 'content', 'iscatch'};
planning = UTILS.RECORDER.Planning(0,header);

% --- Start ---------------------------------------------------------------

planning.AddStart();

% --- Stim ----------------------------------------------------------------

iTrial = 0;
for iBlock = 1 : length(block_order)

    planning.AddStim(      'Rest',        planning.GetNextOnset(), all_jitters(iBlock)       )
    planning.AddStim(      'Instruction', planning.GetNextOnset(), cfgEvents.durInstruction, {[]     []     []    blocks(iBlock).instruction  []                               })
    planning.AddStim(      'Delay',       planning.GetNextOnset(), cfgEvents.durDelay        )
    for iStim = 1 : nStim
        iTrial = iTrial + 1;
        planning.AddStim(  'Stim',        planning.GetNextOnset(), cfgEvents.durStim,        {iTrial iBlock iStim blocks(iBlock).Trials{iStim} blocks(iBlock).CatchVect(iStim) })
        planning.AddStim(  'Delay',       planning.GetNextOnset(), cfgEvents.durDelay        )
    end
end
planning.AddStim(          'Rest',        planning.GetNextOnset(), all_jitters(iBlock+1)     )


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
