function [names, onsets, durations, pmod, tmod, orth] = Generate_SPM_NamesOnsetsDurations_parametric()
global S


%% Preparation

names = {
    'Rest'
    'Trial'
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


%% Parametric modulator building

% get behaviour data and modify it to have meaningful SPM modulators

behaviour = S.recBehaviour.data2table();

behaviour.condition_num = double(strcmp(behaviour.condition, 'mirror')) * 2 - 1;
behaviour.subj_resp_num = double(strcmp(behaviour.subj_resp, 'mirror')) * 2 - 1;
behaviour.resp_ok_num   =               behaviour.resp_ok               * 2 -1;

% time modulation : none
tmod = num2cell(zeros(size(names)));

% orthogonalization : none
orth = num2cell(zeros(size(names)));

pmod = struct('name',{''},'param',{},'poly',{});

% condition = same vs mirror
pmod(2).name {1} = 'condition__same-1_mirror+1';
pmod(2).param{1} = behaviour.condition_num;
pmod(2).poly {1} = 1;

% angle
pmod(2).name {2} = 'angle';
pmod(2).param{2} = behaviour.angle_deg_;
pmod(2).poly {2} = 1;

% RT
pmod(2).name {3} = 'RT';
pmod(2).param{3} = behaviour.RT_s_;
pmod(2).poly {3} = 1;

pmod(2).name {4} = 'subjresp__same-1_mirror+1';
pmod(2).param{4} = behaviour.subj_resp_num;
pmod(2).poly {4} = 1;

pmod(2).name {5} = 'respok';
pmod(2).param{5} = behaviour.resp_ok_num;
pmod(2).poly {5} = 1;


%% clean

no_answer_idx = behaviour.RT_s_ < 0;

onsets   {name2idx.Trial}(no_answer_idx) = [];
durations{name2idx.Trial}(no_answer_idx) = [];
for p = 1 : length(pmod(name2idx.Trial).param)
    pmod(name2idx.Trial).param{p}(no_answer_idx) = [];
end


%% Debuging

% UTILS.plotSPMnod(names, onsets, durations)
% UTILS.plotSPMnod(names, onsets, durations, pmod)


end % fcn
