function tasklist = TaskList()
% To add a task, add a package dir like this : ./+TASK/+<MyNewTask>

logger = getLogger();

task_folder = './+TASK';

d = dir(fullfile(task_folder,'+*'));

dirname = {d.name}';
tasklist = regexprep(dirname, '\+', ''); % remove the + at the begining

if isempty(tasklist)
    logger.err('Empty task list')
end

end % fcn
