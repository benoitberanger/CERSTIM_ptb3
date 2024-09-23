function DownloadFiles(inputdir)
logger = getLogger();

pattern = '_EyelinkFilename.txt';

% fetch specific content of the directory using wildcards
dir_content = dir(fullfile(inputdir, ['*' pattern]));
if isempty(dir_content)
    logger.err('No file with %s in %s', pattern, inputdir)
    return
end

nFile = length(dir_content);

for iFile = 1 : nFile

    fname_txt = fullfile(dir_content(iFile).folder, dir_content(iFile).name);
    logger.log('%d/%d : %s', iFile, nFile, fname_txt);

    % check if files has already been downloaded
    fname_edf = strrep(fname_txt, pattern, '.edf');
    if exist(fname_edf, 'file') > 0
        logger.ok('already downloaded : %s', fname_edf);
        continue
    end

    % get eyelink fname from txt file
    fid = fopen(fname_txt, 'r', 'native', 'UTF-8');
    logger.assert(fid>0, 'File could not be openned : %s', fname_txt)
    eyelink_fname = fread(fid,'*char')';
    fclose(fid);
    logger.warn('eyelink_fname : %s', eyelink_fname);

    % download
    logger.log('Starting transfert with `Eyelink(''ReceiveFile'')`, it can take some time...')
    logger.log('destination is %s', fname_edf)
    status = Eyelink('ReceiveFile', eyelink_fname, fname_edf);
    if status > 0
        logger.ok('Eyelink file transfer DONE, size=%d', status)
    elseif status == 0
        logger.err('File transfer cancelled')
    elseif status < 0
        logger.err('ReceiveFile error, status : %d',status);
    end

end

end % fcn
