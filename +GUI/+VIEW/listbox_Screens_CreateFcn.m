function listbox_Screens_CreateFcn(hObject , ~)

AvailableScreens = Screen('Screens')'; % make it column vector
AvailableScreens = flip(AvailableScreens); % flip it so it appears in descending order

set(hObject, 'String', num2str(AvailableScreens))

end % function
