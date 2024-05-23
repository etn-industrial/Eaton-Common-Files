classdef AxisPts < xcp.Variable
% AxisPts Define Axis in A2L file.

% Copyright 2017-2018 The MathWorks, Inc.
    
properties (SetAccess = 'private')
    Deposit        % How the Axis is represented in memory (reference to a record layout).
    InputQuantity  % Name of the input signal.
end

methods
    
    function obj = AxisPts(record, a2lInfo)
        % Capture the parsed record.
        obj = obj@xcp.Variable(record, a2lInfo);
        obj.Deposit = a2lInfo.RecordLayouts(record.Deposit);
        obj.ECUAddress = record.Address;
        obj.Dimension = record.MaxAxisPoints;
        if isfield(record, 'InputQuantity')
            obj.InputQuantity = record.InputQuantity;
        end
    end
    
    function t = DataType(obj)
    % DataType Returns the Datatpye for this axis.

        % For a single Axis, the data type is defined in the AXIS_PTS_X of the deposit.
        t = obj.Deposit.DataType('AXIS_PTS_X');
    end
    
end

methods (Hidden)
    
    function Q = convertPhy2Raw(obj, V)
    % convertPhy2Raw Compute the memory representation from the physical value

        Q = obj.phy2raw(V, obj.DataType, obj.Conversion);
    end
    
    function V = convertRaw2Phy(obj, Q)
    % convertRaw2Phy Convert from memory representation to engineering value
    
        V = obj.raw2phy(Q, obj.DataType, obj.Conversion);
        if length(V) ~= obj.Dimension && ~isa(obj.Conversion, 'xcp.CompuMethodEnum')
            error(message('xcp:A2L:IncorrectFrameLength', obj.Name, obj.Dimension));
        end
        
    end
    
end

end
