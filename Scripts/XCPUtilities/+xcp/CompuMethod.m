classdef CompuMethod < handle
% CompuMethod Parent Class for all CompuMethod defined in ASAP2.
%
% Currently supported: LINEAR, INTP, TAB_VERB (=enum), RAT_FUNC, TAB
% Currently not supported: FORMULA

% Copyright 2017 The MathWorks, Inc.
    
properties (SetAccess = 'private')
    Name
    LongID
    Format
    Unit
end

methods
    
    function obj = CompuMethod(record)
        % Capture the information from the parsed A2L file.
        obj.Name = record.Name;
        obj.LongID = record.LongID;
        obj.Format = record.Format;
        obj.Unit = record.Unit;
    end
    
end

methods (Abstract)
    
    % These methods are abstract because implementation is fundamentally
    % different in Measurement, Axis and Characteristics.
    Q = convertToRaw(obj, V)
    V = convertToPhy(obj, Q)
    
end

end
