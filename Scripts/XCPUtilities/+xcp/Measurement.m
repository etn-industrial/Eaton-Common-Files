classdef Measurement < xcp.Variable
% Measurement Measurement information class.

% Copyright 2017 The MathWorks, Inc.
    
properties (SetAccess = 'private')
    Resolution
    Accuracy
    LocDataType
end

properties (Hidden)
    FirstByte
    LastByte
    READ_WRITE
    VIRTUAL
end

methods
    
    function obj = Measurement(record, a2lInfo)
        % Capture the parsed record.
        obj = obj@xcp.Variable(record, a2lInfo);
        obj.LocDataType = record.DataType;
        obj.Resolution = record.Resolution;
        obj.Accuracy = record.Accuracy;
        
        try
            % Set the bitmask.
            if isfield(record ,'BIT_MASK')
                obj.setBitMask(record.BIT_MASK);
            end
            
            obj.READ_WRITE = isfield(record ,'READ_WRITE');
            obj.VIRTUAL = isfield(record ,'VIRTUAL');
            
            % Set the dimension.
            obj.setDimension(1);
            if isfield(record ,'ARRAY_SIZE')
                if ~isempty(record.ARRAY_SIZE)
                    obj.setDimension(record.ARRAY_SIZE);
                end
            end
            if isfield(record ,'MATRIX_DIM')
                if ~isempty(record.MATRIX_DIM)
                    obj.setDimension([record.MATRIX_DIM.xDim record.MATRIX_DIM.yDim record.MATRIX_DIM.zDim]);
                end
            end
        catch err %#ok<NASGU>
            % No information in the A2L file, so leave this content empty.
            warning(message('xcp:A2L:ParseMeasurementError', record.Name));
            obj = [];
        end
    end
    
    function t = DataType(obj)
        % Return the object datatype
        t = obj.LocDataType;
    end
end

methods (Hidden)

    function Q = convertPhy2Raw(obj, V)
        % Compute the memory representation from the physical value
        Q = obj.phy2raw(V, obj.DataType, obj.Conversion);
    end
    
    function V = convertRaw2Phy(obj, Q)
        % Compute the physical value from the memory representation
        V = obj.raw2phy(Q, obj.DataType, obj.Conversion);
        % Reshape if required
        if length(obj.Dimension) >=2
            V = reshape(V, obj.Dimension);
        end
    end
    
end

end
