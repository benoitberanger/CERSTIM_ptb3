function [names, onsets, durations] = Generate_SPM_NamesOnsetsDurations_block()
global S


%% Preparation

names = {
    'Rest'
    'RampUp__pctFmax'
    'FlatTop__pctFmax'
    'Rest__pctFmax'
    'RampUp__Newton'
    'FlatTop__Newton'
    'Rest__Newton'
    };

% 'onsets' & 'durations' for SPM
onsets    = cell(size(names));
durations = cell(size(names));

name2idx = [];
for n = 1 : length(names)
    name2idx.(names{n}) = n;
end

data = S.recEvent.data;
icol_name      = S.recEvent.icol_name;
icol_onset     = S.recEvent.icol_onset;
icol_duration  = S.recEvent.icol_duration;


%% Onsets building

for evt = 1:size(data,1)
    if strcmp(data{evt,icol_name}, S.recEvent.label_start) || strcmp(data{evt,icol_name}, S.recEvent.label_end)
        %pass
    else
        onsets{name2idx.(data{evt,icol_name})} = [onsets{name2idx.(data{evt,icol_name})} ; data{evt,icol_onset}];
    end
end


%% Durations building

for evt = 1:size(data,1)
    if strcmp(data{evt,1}, S.recEvent.label_start) || strcmp(data{evt,1}, S.recEvent.label_end)
        %pass
    else
        durations{name2idx.(data{evt,icol_name})} = [ durations{name2idx.(data{evt,icol_name})} ; data{evt,icol_duration}];
    end
end

%% Debuging

% UTILS.plotSPMnod(names, onsets, durations)


end % fcn