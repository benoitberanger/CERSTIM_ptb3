function [result, status] = Initialize( dummy )
logger = getLogger();

if nargin < 1
    dummy = false;
end

if dummy
    logger.log('Try to connect with the Eyelink in DUMMY mode ...')
    status = Eyelink('InitializeDummy');
else
    logger.log('Try to connect with the Eyelink ...')
    status = Eyelink('Initialize');
end

switch status
    case 0
        logger.ok ('Eyelink initialization status : OK')
        result = true;
    case -1
        logger.ok ('Eyelink initialization status : DUMMY')
        result = true;
    otherwise
        logger.err('Eyelink initialization status : error %d',status)
        result = false;
end

end % fcn
