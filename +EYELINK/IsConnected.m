function [result, status]= IsConnected()
logger = getLogger();

status = Eyelink('IsConnected');
switch status
    case 1
        logger.ok('Eyelink connection status : connected')
        result = true;
    case -1
        logger.log('Eyelink connection status : dummy-connected')
        result = true;
    case 2
        logger.log('Eyelink connection status : broadcast-connected')
        result = true;
    case 0
        logger.err('Eyelink connection status : NOT CONNECTED \n')
        result = false;
end

end % function
