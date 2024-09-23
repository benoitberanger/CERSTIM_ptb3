function main()
% Just run this function

% clear command window
clc

% set the seed of Random Number Generator to the current time
rng('shuffle')

% get logger instance
logger = getLogger();

% make sure to stay in the current directory
project_dir = UTILS.GET.RootDir();
cd(project_dir);

% print some info
logger.log('Project name = %s', CONFIG.ProjectName() );
logger.log('Project path = %s', project_dir);

% lets go
UTILS.CheckRequirements()
CONFIG.PrintReminder()
GUI.Open() % the GUI is the **ONLY** interface the user will interact with

% The workflow is here : GUI.Workflow()

end % function
