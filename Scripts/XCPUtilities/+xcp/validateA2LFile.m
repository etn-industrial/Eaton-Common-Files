function [fileName,fileExt,fileFullPath] = validateA2LFile(file)
% validateA2LFile Perform file identification and name validation.
%
%   This function performs general input file validation and identification
%   on the input to locate and verfiy the specified file. It returns the
%   file name, extension, and full path in the output.

% Copyright 2018 The MathWorks, Inc.

% Perform an argument count check.
narginchk(1, 1);

% Convert string inputs to character vectors.
file = convertStringsToChars(file);

% Validate the file argument.
validateattributes(file, {'char'}, {'nonempty'}, 1);

% Change file seperator on non-Windows.
if isunix
    file = strrep(file, '\', filesep);
end
 
% Parse the file input such that if it is a relative or full path, we can 
% access the file name and extension independent of the path information.
[~, fileName, fileExt] = fileparts(file);

% Error if the specified file is not an A2L file.
if ~strcmpi(fileExt, '.a2l')
    error(message('xcp:A2L:FileNotAnA2LFile'));
end

% Attempt to get a full path to the file requested.
fileFullPath = findFullFilePath(file);
if strcmp(fileFullPath, '')
    % If the file input did not lead to the file,
    % then try to locate it by name alone.
    fileFullPath = findFullFilePath([fileName fileExt]);
end

% If the A2L file was not found, then error.
if strcmp(fileFullPath, '')
    error(message('xcp:A2L:UnableToFindA2LFile'));
end

    function fullFilePath = findFullFilePath(file)
    % findFullFilePath Find the full path to a file.
    %
    %   This method is used internally to attempt to find a given
    %   A2L file. It checks the MATLAB path as well as searching
    %   within relative paths via the file attributes. If the file is
    %   found, a full path to the file is returned, otherwise a blank
    %   string is returned.
        
        % Find the file using which.
        fullFilePath = which(file);
        if ~strcmp(fullFilePath, '')
            % Return the full path if which found the file.
            return;
        end
        
        % Find the file using fileattrib.
        [status, info] = fileattrib(file);
        if status
            % Return the full path if fileattrib found the file.
            fullFilePath = info.Name;
        end
    end
end
