function result = IsOpenParPortPortDetected()
logger = getLogger();

fcn_name = 'OpenParPort.m';

logger.log('Looking for %s in the matlab path...', fcn_name)
opp_path = which(fcn_name);

if ~isempty(opp_path)
    logger.ok('Parallel port library detected : %s', opp_path)
    result = true;
else
    logger.err('Parallel port library NOT DETECTED')
    result = false;
end

end % fcn
