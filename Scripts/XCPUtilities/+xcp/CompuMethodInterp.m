classdef CompuMethodInterp < xcp.CompuMethod
% CompuMethodInterp Convert with an interpolation table.

% Copyright 2017 The MathWorks, Inc.
    
properties (SetAccess = 'private')
    CompuTab
end

methods
    
    function obj = CompuMethodInterp(record, a2lInfo)
        % Capture the record info from the parsed A2L file.
        obj = obj@xcp.CompuMethod(record);
        obj.CompuTab = a2lInfo.CompuTabs(record.COMPU_TAB_REF);
    end
    
    function n = convertToRaw(obj, v)
        n = interp1(obj.CompuTab.OutTab, obj.CompuTab.InTab, v);
    end
    
    function value = convertToPhy(obj, rawv)
        % Note: This does not work if OutTab is not monotonous.
        value = interp1(obj.CompuTab.InTab, obj.CompuTab.OutTab, rawv);
    end
    
end

end
