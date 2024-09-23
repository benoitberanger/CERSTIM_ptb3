function edit_SubjectID_Callback(hObject, ~)
handles = guidata(hObject);
logger = getLogger();

MinNrChar = 3;

SubjectID = GUI.GET.SubjectID( handles );

if length(SubjectID) < MinNrChar
    set(hObject,'String','')
    logger.err('SubjectID must be at least %d chars', MinNrChar)
else
    logger.ok('SubjectID     = %s', SubjectID)
    logger.log('SubjectID dir = %s', UTILS.GET.SubjectDataDir(SubjectID))
end

end % function
