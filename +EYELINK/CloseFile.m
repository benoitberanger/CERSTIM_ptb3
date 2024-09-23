function [result, status] = CloseFile()
logger = getLogger();

status = Eyelink('CloseFile');
switch status
    case 0
        result = true;
    otherwise
        result = false;
        logger.err('Eyelink(''CloseFile'') returned error code %d', status);
end
end % fcn
