classdef (Hidden) A2LManager < handle
% A2LMANAGER File manager for A2L file handling.
%
%   The A2LMANAGER class stores references to all open A2L files. It contains 
%   a handle to each one, allowing for singular opening of any given target file.
%
%   See also VNT.

% Copyright 2017 The MathWorks, Inc.

properties (SetAccess = 'private', GetAccess = 'public')
    % FileObjectMap - Stores copies of all file objects.
    FileObjectMap = containers.Map();
end

    
methods (Access = 'private')
    
    function obj = A2LManager
    end
    
end


methods
    
    function fileObj = find(obj, key)
    % FIND Locate a file object in the manager.
    %
    %   FILEOBJ = FIND(OBJ, KEY) searches for a file object corresponding to 
    %   the given KEY and returning a handle to the file object when found. 
    %   Otherwise, a new file object is constructed, stored, and returned.
        
        % Check if a current file object is in the manager for this target file.
        if isKey(obj.FileObjectMap, key)
            % Get the existing entry from the manager.
            fileObj = obj.FileObjectMap(key);
            
            % Check if the target file has been updated since last opened.
            fileInfo = dir(fileObj.FilePath);
            if fileInfo.datenum ~= fileObj.LastModifiedDate
                % The target file was updated, so refresh the object.
                fileObj.refreshCachedInfo();
            end
            return;
        end

        % Make a new file object for this target file.
        fileObj = xcp.A2L(key);
        
        % Add the file object to the manager.
        obj.add(fileObj, fileObj.FilePath);
    end
    
    function add(obj, fileObj, key)
    % ADD Register a new file object in the manager.
    %
    %   ADD(OBJ, FILEOBJ, KEY) adds a new FILEOBJ to the manager under 
    %   the provided KEY.
        
        % Load the file object in the manager.
        obj.FileObjectMap(key) = fileObj;
    end
    
    function clear(obj)
    % CLEAR Remove all the file objects.
    %
    %   CLEAR(OBJ) removes all file objects from the manager.
    
        % Clear the manager of all entries.
        remove(obj.FileObjectMap, keys(obj.FileObjectMap));
    end
    
end


methods (Static)
    
    function obj = getInstance()
    % GETINSTANCE Gets the single instance of the manager.
        
        % Storage for the singleton object.
        persistent A2LFileManagerInstance;
        
        % Instantiate the object if it does not already exist.
        if isempty(A2LFileManagerInstance)
            A2LFileManagerInstance = xcp.A2LManager();
        end
        
        % Return the singleton object.
        obj = A2LFileManagerInstance;
    end
    
end

end
