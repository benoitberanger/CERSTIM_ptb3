function rootdir = RootDir()
% get root directory of the project

rootdir = fileparts(fileparts(fileparts(mfilename('fullpath'))));

end % fcn
