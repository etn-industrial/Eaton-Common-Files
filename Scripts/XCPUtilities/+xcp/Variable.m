classdef Variable < handle
% Variable Parent class for Measurement, AxisPts, and Characteristics.
%
% Contains all the properties and methods common to all three.

% Copyright 2017 The MathWorks, Inc.
    
properties (SetAccess = 'protected')
    Name                % Variable name.
    LongIdentifier      % Description.
    ECUAddress          % Address in ECU.
    ECUAddressExtension % Optional address extension (e.g. RAM or Flash).
    Conversion          % CompuMethod.
    Dimension           % Array dimension[s].
    LowerLimit          % Lower value limit.
    UpperLimit          % Upper value limit.
    BitMask             % Bit Mask to select region of interest.
end

properties (Hidden)
    BoolByteOrder       % MSB or LSB.
end

methods

    function obj = Variable(record, a2linfo)
        obj.Name = record.Name;
        obj.LongIdentifier = record.LongID;
        obj.Conversion = a2linfo.CompuMethods(record.Conversion);
        
        % Set default values for optional fields.
        obj.ECUAddressExtension = int16(0);
        obj.ECUAddress= [];
        obj.LowerLimit = -inf;
        obj.UpperLimit = inf;
        obj.BoolByteOrder = true; % True means 'MSB_LAST'.
        
        % Set the address.
        if isfield(record, 'ECU_ADDRESS')
            obj.ECUAddress = record.ECU_ADDRESS;
        end
        
        % Set the address extension.
        if isfield(record ,'ECU_ADDRESS_EXTENSION')
            if ~isempty(record.ECU_ADDRESS_EXTENSION)
                obj.ECUAddressExtension = record.ECU_ADDRESS_EXTENSION;
            end
        end
        
        % Set the byte order.
        if isfield(record ,'BYTE_ORDER')
            if ~isempty(record.BYTE_ORDER)
                obj.setByteOrder(xcp.A2L.convByteOrder(record.BYTE_ORDER));
            else
                obj.setByteOrder(xcp.A2L.convByteOrder(a2linfo.getDefaultByteOrder));
            end
        else
            obj.setByteOrder(xcp.A2L.convByteOrder(a2linfo.getDefaultByteOrder));
        end
        
        % Set lower and upper limits
        if ~strcmpi(record.LowerLimit, 'e') && ...
                ~strcmpi(record.LowerLimit, '-e')
            obj.setLowerLimit(record.LowerLimit);
        end
        if ~strcmpi(record.UpperLimit, 'e') && ...
                ~strcmpi(record.UpperLimit, '-e')
            obj.setUpperLimit(record.UpperLimit);
        end
    end
    
    function setLowerLimit(obj, lim)
        obj.LowerLimit = lim;
    end
    
    function setUpperLimit(obj, lim)
        obj.UpperLimit = lim;
    end
    
    function setByteOrder(obj, order)
        obj.BoolByteOrder = order;
    end
    
    function setDimension(obj, dim)
        obj.Dimension = dim;
    end
    
    function setBitMask(obj, mask)
        obj.BitMask = mask;
    end
    
    function setECUAddress(obj, address)
        obj.ECUAddress = address;
    end
    
    function setECUAddressExtension(obj, addressExtension)
        obj.ECUAddressExtension = addressExtension;
    end
    
    function size = SizeInBytes(obj)
        % Return the Size in bytes of the Variable.
        [~, unitsize] = xcp.A2L.getMATLABType(obj.DataType);
        size = unitsize * prod(obj.Dimension);
    end
    
    function size = SizeInNibbles(obj)
        % Return the Size in nibbles of the Variable.
        size = obj.SizeInBytes * 2;
    end
    
    function size = SizeInBits(obj)
        % Return the Size in bits of the Variable.
        size = obj.SizeInBytes * 8;
    end
    
    function r = MATLABType(obj)
        % Return the equivalent MATLAB type for a given ASAP2 type.
        r = xcp.A2L.getMATLABType(obj.DataType);
    end
    
    function r = ByteOrder(obj)
        % Return the endianness
        if obj.BoolByteOrder
            r = 'MSB_LAST';
        else
            r = 'MSB_FIRST';
        end
    end
    
    function V = raw2phy(obj, Q, dt, cm)
    % raw2phy Convert a frame payload (as transported by XCP) to the engineering value.
        
        % Evaluate the expected frame length.
        [matlabtype, tsize] = xcp.A2L.getMATLABType(dt);
        count = length(Q) / tsize;
        
        % Change the endianness if required (ignore single and double).
        if ~obj.BoolByteOrder  && ~any( strcmp( matlabtype, {'single', 'double'} ))
            x = repmat(tsize:-1:1,1,count)+repelem(0:tsize:tsize*count-tsize, tsize);
            Q = Q(x);
        end
        
        % Reinterpret the frame using the matlab base type.
        t0 = typecast(Q, matlabtype);
        
        % Apply the BitMask as per the ASAM specification.
        if ~isempty(obj.BitMask)
            m = obj.BitMask;
            t0 = bitand(int32(m), int32(t0));
            while mod(m,2) == 0
                m = m/2;
                t0 = t0/2;
            end
        end
        
        % Convert to double prior to applying the compu_method scaling.
        V = cm.convertToPhy(double(t0));
    end
    
    function Q = phy2raw(obj, V, dt, cm)
    % phy2raw Convert the engineering value to a frame payload (as transported by XCP).
    
        % Evaluate the expected array size.
        [matlabtype, tsize] = xcp.A2L.getMATLABType(dt);
        
        % Bound checking
        if ~isa(obj.Conversion, 'xcp.CompuMethodEnum')
            if any(any(V < obj.LowerLimit)) || any(any(V > obj.UpperLimit))
                warning(message('xcp:A2L:OutOfRange', obj.Name, obj.LowerLimit, obj.UpperLimit));
            end
        end
        
        % Convert from engineering to memory representation.
        t0 = cm.convertToRaw(V);
        
        
        % Apply the BitMask as per the ASAM specification.
        if ~isempty(obj.BitMask)
            m = obj.BitMask;
            while mod(m,2) == 0
                m  = m/2;
                t0 = t0*2;
            end
        end
        
        % Reshape.
        count = numel(t0);
        t1 = reshape(t0, [1 count]);
        % Cast to the matlab type.
        t2 = cast(t1, matlabtype);
        % Reinterpret cast to uint8.
        t3 = typecast(t2, 'uint8');
        
        % Change the endianness if required (ignore single and double).
        if ~obj.BoolByteOrder && ~any( strcmp( matlabtype, {'single', 'double'} ))
            x = repmat(tsize:-1:1,1,count)+repelem(0:tsize:tsize*count-tsize, tsize);
            t3 = t3(x);
        end
        
        Q = t3;
    end
    
end

methods (Abstract)
   
    % These method is abstract because implementation is fundamentally
    % different in Measurement, Characteristics, and Axis.
    DataType(obj)
    Q = convertPhy2Raw(obj, V)
    V = convertRaw2Phy(obj, V)

end

end
