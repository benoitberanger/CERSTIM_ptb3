function [name, run_number] = AppendRunNumber(SubjectDataDir, BasePattern)

if ~exist(SubjectDataDir, 'dir') % no dir
    run_number = 1;
    name = GenBasename(BasePattern,run_number);
    return
end

% fetch specific content of the directory using wildcards
dir_content = dir(fullfile(SubjectDataDir, sprintf('*%s*.mat',BasePattern)));

if isempty(dir_content)
    run_number = 1;
    name = GenBasename(BasePattern,run_number);
    return
end

% filter files
result = regexp({dir_content.name},[BasePattern '__run?(\d+)'],'tokens');
runfiles = ~cellfun('isempty', result);

if ~any(runfiles) % no file found for this run
    run_number = 1;
    name = GenBasename(BasePattern,run_number);
    return
end

% extract all run number
all_numbers = cellfun(@(c) str2double(c{1}), result(runfiles));

% done
max_number = max(all_numbers);
run_number = max_number + 1;
name = GenBasename(BasePattern,run_number);

end % fcn

%--------------------------------------------------------------------------
function name = GenBasename(Base,RunNumber)
name = sprintf('%s__run%02d', Base, RunNumber);
end % fcn
