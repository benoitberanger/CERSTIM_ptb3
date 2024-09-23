function CheckRequirements()
% perform all installation checks
logger = getLogger();

logger.assert( ~isempty(which('PsychtoolboxRoot')), '"PsychtoolboxRoot" not found : check Psychtooblox installation => http://psychtoolbox.org/' )

datapath = UTILS.GET.DataDir();
if ~exist(datapath, 'dir')
    logger.warning('creating data output dir = %s', datapath)
    mkdir(datapath)
end
logger.log('data output dir = %s', datapath)

end % function
