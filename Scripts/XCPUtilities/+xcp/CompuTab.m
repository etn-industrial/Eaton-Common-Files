classdef CompuTab < handle
% CompuTab Contains the data used by the CompuMethodInterp class.

% Copyright 2017 The MathWorks, Inc.
    
properties (SetAccess = 'private')
    Name     % Table name.
    LongID   % Description.
    InTab    % Input axis table.
    OutTab   % Data table.
end

methods
    
    function obj = CompuTab(record)
        % Capture the record info from the parsed A2L file.
        obj.Name   = record.Name;
        obj.LongID = record.LongID;
        obj.InTab  = record.InVal;
        obj.OutTab = record.OutVal;
    end
    
end

end
