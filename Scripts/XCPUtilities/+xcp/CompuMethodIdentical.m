classdef CompuMethodIdentical < xcp.CompuMethod
% CompuMethodIdentical Method used when no conversion is required.

% Copyright 2017 The MathWorks, Inc.
    
methods
    
    function obj = CompuMethodIdentical(record)
        record.Format = '%f';
        record.Unit = '';
        obj = obj@xcp.CompuMethod(record);
    end
    
    function b = convertToRaw(~, a)
        b = a;
    end
    
    function b = convertToPhy(~, a)
        b = a;
    end
    
end

end
