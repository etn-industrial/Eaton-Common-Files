classdef CompuMethodLinear < xcp.CompuMethod
% CompuMethodLinear Convert with a Linear Formula (y = a.x +b).

% Copyright 2017 The MathWorks, Inc.
    
properties (SetAccess = 'private')
    a % Slope.
    b % Bias.
end

methods
    function obj = CompuMethodLinear(record)
        % Capture the record info from the parsed A2L file.
        obj = obj@xcp.CompuMethod(record);
        obj.a = record.COEFFS_LINEAR.a;
        obj.b = record.COEFFS_LINEAR.b;
    end

    function n = convertToRaw(obj, v)
        n = (v - obj.b) ./ obj.a;
    end
    
    function value = convertToPhy(obj, rawv)
        value = rawv .* obj.a + obj.b;
    end

end

end
