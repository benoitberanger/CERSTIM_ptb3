function [names, onsets, durations] = Generate_SPM_NamesOnsetsDurations_block()
global S


%% Preparation

names = {
    'Rest'
    'ClickSame'
    'ClickMirr'
    };

for mb = 1 : length(S.cfgEvents.miniblock)
    condition = S.cfgEvents.miniblock{mb,2};
    angle     = S.cfgEvents.miniblock{mb,1};
    names{end+1} = sprintf('Trial__%s__%03d', condition(1:4), angle);
end

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
icol_condition = S.recEvent.Get('condition');
icol_angle     = S.recEvent.Get('angle'    );


%% Onsets building

for evt = 1:size(data,1)
    if strcmp(data{evt,icol_name}, S.recEvent.label_start) || strcmp(data{evt,icol_name}, S.recEvent.label_end)
        %pass
    elseif strcmp(data{evt,icol_name}, 'Trial')
        condition = data{evt,icol_condition};
        angle     = data{evt,icol_angle    };
        regname   = sprintf('Trial__%s__%03d', condition(1:4), angle);
        onsets{name2idx.(regname)} = [onsets{name2idx.(regname)} ; data{evt,icol_onset}];
    else
        onsets{name2idx.(data{evt,icol_name})} = [onsets{name2idx.(data{evt,icol_name})} ; data{evt,icol_onset}];
    end
end


%% Durations building

for evt = 1:size(data,1)
    if strcmp(data{evt,1}, S.recEvent.label_start) || strcmp(data{evt,1}, S.recEvent.label_end)
        %pass
    elseif strcmp(data{evt,icol_name}, 'Trial')
        condition = data{evt,icol_condition};
        angle     = data{evt,icol_angle    };
        regname   = sprintf('Trial__%s__%03d', condition(1:4), angle);
        durations{name2idx.(regname)} = [durations{name2idx.(regname)} ; data{evt,icol_duration}];
    else
        durations{name2idx.(data{evt,icol_name})} = [ durations{name2idx.(data{evt,icol_name})} ; data{evt,icol_duration}];
    end
end


%% Add Clicks as regressor

keyname = 'Same';
idx = strcmp(S.recKeylogger.data(:,S.recKeylogger.icol_name), keyname);
onsets   {name2idx.ClickSame} = cell2mat(S.recKeylogger.data(idx,S.recKeylogger.icol_onset   ));
durations{name2idx.ClickSame} = cell2mat(S.recKeylogger.data(idx,S.recKeylogger.icol_duration));

keyname = 'Mirror';
idx = strcmp(S.recKeylogger.data(:,S.recKeylogger.icol_name), keyname);
onsets   {name2idx.ClickMirr} = cell2mat(S.recKeylogger.data(idx,S.recKeylogger.icol_onset   ));
durations{name2idx.ClickMirr} = cell2mat(S.recKeylogger.data(idx,S.recKeylogger.icol_duration));


%% Debuging

% UTILS.plotSPMnod(names, onsets, durations)


end % fcn
