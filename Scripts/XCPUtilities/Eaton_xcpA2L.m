function obj = Eaton_xcpA2L(file)
% xcpA2L Parses an A2L file for use with XCP connections.
%
%   OBJ = xcpA2L(A2L_FILE) creates an A2L file object OBJ linked to the
%   specified A2L_FILE. The object parses the A2L file to allow
%   command line access much of the contained information. The A2L file
%   object is also used in the creation and use of live XCP connections
%   in MATLAB. The A2L_FILE can be specified as a string representing the 
%   file name or the full file path.
%
%   Example:
%       a2lObj = xcpA2L('myFile.a2l');
%
%   See also VNT.

% Copyright 2013-2018 The MathWorks, Inc.

% Perform a Windows OS check.
if ~ispc()
    error(message('xcp:A2L:WindowsOnly'));
end

% Perform an argument count check.
narginchk(1, 1);

% Convert string inputs to character vectors.
file = convertStringsToChars(file);

% Validate the file input.
[~, ~, fileFullPath] = xcp.validateA2LFile(file);

% Pass the call through to the A2L file manager.
obj = xcp.A2LManager.getInstance.find(fileFullPath);
end
