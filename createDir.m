function status = createDir(dirName)
status = '';
switch exist(dirName)
    case 0
        % Directory does not exist
        [success message messageid] = mkdir(dirName);
    case 7
        % Directory already exists
        success = true;
    otherwise
        % Some other object possibly a file exists with the name
        delete(outputDir);
        [success message messageid] = mkdir(dirName);
end
if ~success
    status = sprintf('Unable to successfully create %s directory: %s', dirName, message);
end
end