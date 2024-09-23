function StartRecording()
global S

logger = getLogger();

% Check if connected (assume the Eyelink is calibrated)
is_connected = EYELINK.IsConnected();
logger.assert(is_connected, 'Eyelink not connected')

% Open file
status = Eyelink('OpenFile', S.EyelinkFile);
logger.assert(status==0, 'OpenFile error, status : %d ',status)

% Start recording
status = Eyelink('StartRecording');
logger.assert(status==0,'StartRecording error, startrecording_error : %d ',status)

% Write a minifile to remember what is the eyelink 8 char fname
S.EyelinkFileRemember = [S.OutFilepath '__EyelinkFilename.txt'];
fid = fopen(S.EyelinkFileRemember, 'w', 'native', 'UTF-8');
logger.assert(fid>0, 'File could not be openned : %s', S.EyelinkFileRemember)
fprintf(fid, S.EyelinkFile);
fclose(fid);

end % fcn
