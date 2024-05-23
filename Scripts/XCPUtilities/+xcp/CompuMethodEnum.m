classdef CompuMethodEnum < xcp.CompuMethod
% CompuMethodEnum Convert between Enum value and cell array to String.
%
% Note: The strings are stored in a CompuTab.

% Copyright 2017 The MathWorks, Inc.
    
properties (SetAccess = 'private')
    CompuTab
end

methods
    
    function obj = CompuMethodEnum(record, a2lInfo)
        % Capture the record info from the parsed A2L file.
        obj = obj@xcp.CompuMethod(record);
        obj.CompuTab = a2lInfo.CompuVTabs(record.COMPU_TAB_REF);
    end
    
    function n = convertToRaw(obj, v)
        % Return the string for a given enum value
        n = obj.CompuTab.s2n(v);
    end
    
    function value = convertToPhy(obj, rawv)
        % Return the value for a given string
        value = obj.CompuTab.n2s(rawv);
    end
    
end

end
