classdef Characteristic < xcp.Variable
% Characteristic Define  A2L Characteristic record.

% Copyright 2017-2018 The MathWorks, Inc.
    
properties (SetAccess = 'private')
    CharacteristicType  % Type of CHARACTERISTIC (e.g. VALUE, CURVE, MAP).
    Deposit             % Reference to the RECORD_LAYOUT.
    AxisConversion      % Compu_method associated to each axis.
    AxisDescr
end

methods

    function obj = Characteristic(record, a2lInfo)
        obj = obj@xcp.Variable(record, a2lInfo);
        
        % Copy data that is present in all record.
        obj.CharacteristicType = record.Type;
        obj.Deposit = a2lInfo.RecordLayouts(record.Deposit);
        obj.ECUAddress = record.Address;
        if isfield(record ,'AXIS_DESCR')
            obj.AxisDescr = record.AXIS_DESCR;
        end
        
        try
            obj.AxisConversion = {};
            
            % Each record type will present different fields.
            switch(record.Type)
                case 'VALUE'
                    dim = 1;
                case 'VAL_BLK'
                    if isfield(record, 'NUMBER')
                        dim = record.NUMBER;
                    end
                case 'ASCII'
                    dim = record.NUMBER;
                    obj.Conversion = xcp.CompuString('', dim);
                case 'CURVE'
                    dim = record.AXIS_DESCR.MaxAxisPoints;
                case { 'MAP', 'CUBOID' }
                    dim = [];
                    for jj=1:length(record.AXIS_DESCR)
                        dim(end+1) = record.AXIS_DESCR(jj).MaxAxisPoints; %#ok<AGROW>
                    end
                otherwise
                    warning(message('xcp:A2L:UnsupportedCharacteristicType', record.Name, record.Type));
                    dim = [];
            end
            
            % Get dimension for 1D arrays.
            if isfield(record ,'ARRAY_SIZE')
                if ~isempty(record.ARRAY_SIZE)
                    dim = record.ARRAY_SIZE;
                end
            end
            
            % Get dimension for 2D or 3D arrays.
            if isfield(record ,'MATRIX_DIM')
                if ~isempty(record.MATRIX_DIM)
                    dim = [record.MATRIX_DIM.xDim record.MATRIX_DIM.yDim record.MATRIX_DIM.zDim];
                end
            end
            obj.Dimension = dim;
            
            % Set the Axis information.
            if isfield(record ,'AXIS_DESCR')
                obj.setAxisDescription(a2lInfo, record.AXIS_DESCR);
            end
        catch err %#ok<NASGU>
            warning(message('xcp:A2L:ParseCharacteristicError', record.Name));
        end
    end
    
    function t = DataType(obj, item)
    % DataType Return the datatype for a given item. 
    
        % If item is omitted, return the information for the FNC_VALUES
        % (always present).
        if nargin >= 2
            t = obj.Deposit.DataType(item);
        else
            t = obj.Deposit.DataType('FNC_VALUES');
        end
    end
    
    function [offset, sizes, dims] = getLayoutOffsetAndSize(obj, item)
    % getLayoutOffsetAndSize Return the offset, size, and dimensions for a given item.
    
        [offset, sizes, dims] = obj.Deposit.getOffsetAndSize(obj.Dimension, item);
    end
    
    function compumethod = getCompuMethod(obj, item)
    % getCompuMethod Return the Conversion method for a given item.
    
        switch item
            case 'AXIS_PTS_X'
                compumethod = obj.AxisConversion{1};
            case 'AXIS_PTS_Y'
                compumethod = obj.AxisConversion{2};
            case 'AXIS_PTS_Z'
                compumethod = obj.AxisConversion{3};
            case 'FNC_VALUES'
                compumethod = obj.Conversion;
            case { 'NO_AXIS_PTS_X', 'NO_AXIS_PTS_Y', 'NO_AXIS_PTS_Z' }
                compumethod = xcp.CompuMethodIdentical('id','','');
            otherwise
                compumethod = xcp.CompuMethodIdentical('id','','');
                warning(message('xcp:A2L:UnsupportedRecordItem', item, obj.Name));
        end
    end
    
end

methods (Access = 'private')
    
    function setAxisDescription(obj, a2lInfo, r)
    % setAxisDescription Add a conversion method nth Axis.
    
        for jj = 1:length(r)
            obj.AxisConversion{end+1} = a2lInfo.CompuMethods(r(jj).Conversion);
        end
    end
    
end

methods (Hidden)
    
    function Q = convertPhy2Raw(obj, V, item)
    % convertPhy2Raw Convert from engineering value to memory representation.
    
        if nargin < 3
            item = 'FNC_VALUES';
        end
        Q = obj.phy2raw(V, obj.DataType(item), obj.getCompuMethod(item));
    end
    
    function V = convertRaw2Phy(obj, Q, item)
    % convertRaw2Phy Convert from memory representation to engineering value.
    
        if nargin < 3
            item = 'FNC_VALUES';
        end
        
        % Convert with CompuMethod.
        V = obj.raw2phy(Q, obj.DataType(item), obj.getCompuMethod(item));
        
        % Reshape if required.
        [~,dims]=obj.Deposit.getDim(item, obj.Dimension);
        if length(dims) >= 2
            V = reshape(V, dims);
        end
    end
    
end

end
