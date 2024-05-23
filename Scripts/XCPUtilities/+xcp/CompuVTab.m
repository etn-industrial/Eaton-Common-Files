classdef CompuVTab < handle
% CompuVTab ASAP2 representation of Enum types.

% Copyright 2017 The MathWorks, Inc.
    
properties (SetAccess = 'private')
    Name    % Name.
    LongID  % Description.
    InTab   % List of symbols for the enumeration.
    OutTab  % List of values for the enumeration.
end

properties (Access = 'private')
    Map     % Container map defining the association from symbol to values.
end

methods
    
    function obj = CompuVTab(record)
        % Capture the record info from the parsed A2L file.
        obj.Name = record.Name;
        obj.LongID = record.LongID;
        obj.InTab  = int32(record.InVal);
        obj.OutTab = record.OutVal;
        obj.Map = containers.Map(record.OutVal, uint8(record.InVal));
    end
    
    function sym = n2s(obj, n)
        % Convert from enum value to symbol.
        try
            if length(n)>1
                sym = arrayfun(@(e)obj.OutTab(eq(obj.InTab,e)),n);
            else
                sym = obj.OutTab{eq(obj.InTab,n)};
            end
        catch
            error(message('xcp:A2L:IncorrectEnumConversion', obj.Name, n));
        end
    end
    
    function n = s2n(obj, sym)
        % Convert from enum symbol to value.
        try
            if iscell(sym)
                n = cellfun(@(e)obj.Map(e),sym);
            else
                n = obj.Map(sym);
            end
        catch
            if iscell(sym)
                error(message('xcp:A2L:IncorrectEnumConversion', obj.Name, strjoin(sym)));
            else
                error(message('xcp:A2L:IncorrectEnumConversion', obj.Name, sym));
            end
        end
    end
    
end

end
