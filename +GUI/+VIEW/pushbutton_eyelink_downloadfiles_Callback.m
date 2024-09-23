function pushbutton_eyelink_downloadfiles_Callback(hObject,~)
handles = guidata(hObject);

SubjectID      = GUI.GET.SubjectID(handles);
subjectdatadir = UTILS.GET.SubjectDataDir(SubjectID);

EYELINK.DownloadFiles(subjectdatadir);

end % fcn
