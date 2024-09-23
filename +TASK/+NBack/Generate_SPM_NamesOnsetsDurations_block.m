function [names, onsets, durations] = Generate_SPM_NamesOnsetsDurations_block()
global S


%% Preparation

names = {
    'Rest'
    'Instruction'
    'Click'
    };

for nback = S.cfgEvents.nBack
    names{end+1} = sprintf('B%d', nback);
end

% 'onsets' & 'durations' for SPM
onsets    = cell(size(names));
durations = cell(size(names));

name2idx = [];
for n = 1 : length(names)
    name2idx.(names{n}) = n;
end


%% special case for this task : need to make blocks

icol_name     = S.recEvent.icol_name;
icol_onset    = S.recEvent.icol_onset;
icol_duration = S.recEvent.icol_duration;
icol_content  = S.recEvent.Get('content');

data_evt = S.recEvent.data; % copy

data = cell(0,size(data_evt,2));
is_new_block = 1;
for evt = 1 : size(data_evt,1)

    is_block = strcmp(data_evt(evt,icol_name), 'Delay') | strcmp(data_evt(evt,icol_name), 'Stim');

    if ~is_block % simple copy
        data(end+1,:) = data_evt(evt,:);
        is_new_block = 1;

    else
        if is_new_block
            is_new_block = 0;
            data(end+1,:) = data_evt(evt,:); % start with simple copy
            % parse instructions to create block name B0, B1, B2, ...
            instruction = data{end-1,icol_content};
            if strfind(instruction, 'X') > 0
                data{end,icol_name} = 'B0';
            else
                data{end,icol_name} = sprintf('B%s', instruction(1));
            end
        else
            data{end,icol_duration} = data{end,icol_duration} + data_evt{evt,icol_duration};
        end

    end
end


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


%% Add Clicks as regressor

keyname = 'Catch';
idx = strcmp(S.recKeylogger.data(:,S.recKeylogger.icol_name), keyname);

onsets   {name2idx.Click} = cell2mat(S.recKeylogger.data(idx,S.recKeylogger.icol_onset   ));
durations{name2idx.Click} = cell2mat(S.recKeylogger.data(idx,S.recKeylogger.icol_duration));


%% Debuging

% UTILS.plotSPMnod(names, onsets, durations)


end % fcn