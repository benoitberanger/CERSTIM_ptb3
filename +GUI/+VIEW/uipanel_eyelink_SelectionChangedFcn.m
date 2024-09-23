function uipanel_eyelink_SelectionChangedFcn(hObject, eventdata)
handles = guidata(hObject);

switch eventdata.NewValue.String
    case 'Yes'
        handles.uipanel_eyelink_buttons.Visible = 'on';
    case 'No'
        handles.uipanel_eyelink_buttons.Visible = 'off';
end

end % fcn
