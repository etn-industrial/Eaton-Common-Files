classdef CompuMethodRational < xcp.CompuMethod
% CompuMethodRational A2L Convert methods for Rational formula (RAT_FUNC).
%
% Currently not supported: second order coefficients for reverse conversion (a and d must be 0)
% y = (v*v*a +  v*b + c) / (v*v*d +  v*e +  f);

% Copyright 2017 The MathWorks, Inc.
    
properties (SetAccess = 'private')
    a  % Second degree coefficient of numerator.
    b  % First degree coefficient of numerator.
    c  % Constant term of numerator.
    d  % Second degree coefficient of denominator.
    e  % First degree coefficient of denominator.
    f  % Constant term of denominator.
end

methods
    
    function obj = CompuMethodRational(record)
        % Capture the record info from the parsed A2L file.
        obj = obj@xcp.CompuMethod(record);
        obj.a = record.COEFFS.a;
        obj.b = record.COEFFS.b;
        obj.c = record.COEFFS.c;
        obj.d = record.COEFFS.d;
        obj.e = record.COEFFS.e;
        obj.f = record.COEFFS.f;
    end
    
    function rawvalue = convertToRaw(obj, v)
        rawvalue = (v.*v.*obj.a +  v*obj.b + obj.c) ./ (v.*v.*obj.d + v*obj.e + obj.f);
    end
    
    function value = convertToPhy(obj, v)
        rawv = double(v);
        
        if obj.a ~= 0 || obj.d ~= 0
            warning(message('xcp:A2L:UnsupportedRatFunc2ndOrder', obj.Name));
        end
        
        value = (-rawv*obj.f + obj.c) ./ (rawv*obj.e - obj.b);
    end
    
end

end
