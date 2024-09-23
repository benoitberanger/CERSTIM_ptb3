function subjectdatadir = SubjectDataDir(SubjectID)
% get subject data dir, where all files will be written today for this sunbject id

subjectdatadir = fullfile(UTILS.GET.DataDir(), sprintf('%s_%s', datestr(now, 'yyyy-mm-dd'), SubjectID));

end % fcn
