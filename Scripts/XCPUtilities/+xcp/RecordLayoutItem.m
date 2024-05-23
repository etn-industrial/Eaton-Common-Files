classdef RecordLayoutItem < handle
% RecordLayoutItem

% Copyright 2017 The MathWorks, Inc.
    
properties (SetAccess = 'private')
    Name        % Name of the field in the record.
    Position    % Position of the field in memory.
    DataType    % Datatype for the data.
    IndexMode   % Row or col index.
    IndexOrder  % Indicates whether the array is stored in increasing or decreasing index.
    AddressType % Indicate whether the data is represented by a pointer or laid in directly in the record.
end

methods
    function obj = RecordLayoutItem(Name, aPosition, aDataType)
        obj.Name = Name;
        obj.Position = aPosition;
        obj.DataType = aDataType;
    end
    
    function setIndexMode(obj, aValue)
        obj.IndexMode = aValue;
    end
    function setAddressType(obj, aValue)
        obj.AddressType = aValue;
    end
    function setIndexOrder(obj, aValue)
        obj.IndexOrder = aValue;
    end
    
end

end
