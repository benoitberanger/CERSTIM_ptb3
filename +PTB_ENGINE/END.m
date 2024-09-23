function END()
global S

if S.guiEyelink
    EYELINK.StopRecording();
    EYELINK.CloseFile();
end

ShowCursor();

end % fcn
