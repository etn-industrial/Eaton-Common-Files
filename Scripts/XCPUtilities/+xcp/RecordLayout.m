classdef RecordLayout < handle
% RecordLayout RecordLayout information class.
%
% Currently does not support:
%  - COL and ROW sorting
%  - RESCALE AXIS
%  - AXIS may have unsupported representation

% Copyright 2017 The MathWorks, Inc.
    
properties (SetAccess = 'private')
    Name    % Name of the layout.
    Records % References to each item (field) in the record.
end

properties (Access = 'private')
    Sizes                  % Size of the supporting datatype in bytes.
    ALIGNMENT_BYTE         % Alignment for byte values.
    ALIGNMENT_WORD         % Alignment for word values.
    ALIGNMENT_LONG         % Alignment for long values.
    ALIGNMENT_FLOAT32_IEEE % Alignment for single values.
    ALIGNMENT_FLOAT64_IEEE % Alignment for double values.
    a2linfo
end

methods
    
    function obj = RecordLayout(record)
        % Capture the record info from the parsed A2L file.
        obj.Name = record.Name;
        obj.Records = [];
        fieldnames = fields(record);
        
        for ii = 1:length(fieldnames)
            fieldname = fieldnames{ii};
            
            switch fieldname
                case 'ALIGNMENT_BYTE'
                    obj.ALIGNMENT_BYTE = record.ALIGNMENT_BYTE;
                case 'ALIGNMENT_WORD'
                    obj.ALIGNMENT_WORD = record.ALIGNMENT_WORD;
                case 'ALIGNMENT_LONG'
                    obj.ALIGNMENT_LONG = record.ALIGNMENT_LONG;
                case 'ALIGNMENT_FLOAT32_IEEE'
                    obj.ALIGNMENT_FLOAT32_IEEE = record.ALIGNMENT_FLOAT32_IEEE;
                case 'ALIGNMENT_FLOAT64_IEEE'
                    obj.ALIGNMENT_FLOAT64_IEEE = record.ALIGNMENT_FLOAT64_IEEE;
                otherwise
                    r = record.(fieldname);
                    if isfield(r, 'Position')
                        pos = r.Position;
                        
                        % Struct field for DataType has varying capitalisation
                        if isfield(r, 'DataType') 
                            dt = r.DataType;
                        elseif isfield(r, 'Datatype')
                            dt = r.Datatype;
                        end
                        dr = xcp.RecordLayoutItem(fieldname, pos, dt);
                        
                        if isfield(r, 'Indexorder')
                            dr.setIndexOrder(r.Indexorder);
                        end
                        
                        if isfield(r, 'IndexMode')
                            dr.setIndexMode(r.IndexMode);
                        end
                        
                        % Struct field for DataType has varying spelling
                        if isfield(r, 'Addresstype') 
                            dr.setAddressType(r.Addresstype);
                        end
                        
                        if isfield(r, 'AddrType')
                            dr.setAddressType(r.AddrType);
                        end
                        
                        [~, obj.Sizes(pos)] = xcp.A2L.getMATLABType(dr.DataType);
                        obj.Records{pos} = dr;
                    end
            end
        end
    end
    
    function setParent(obj, aParent)
        obj.a2linfo = aParent;
    end

    function dt = DataType(obj, itemname)
        % Return the datatype of the field.
        if nargin == 2
            item = getLayoutItem(obj, itemname);
        else
            % If Item is not specified, we use the FNC_VALUES.
            item = getLayoutItem(obj, 'FNC_VALUES');
        end
        dt = item.DataType;
    end
    
    function [offset, size, dims] = getOffsetAndSize(obj, dim, vtype)
        % Return the offset and the size of a field in the record.
        rDeposit = obj.getLayoutItem(vtype);
        pos = rDeposit.Position;
        
        offset = uint32(0);
        for i = 1:pos-1
            % Adjust according to alignment.
            a = uint32(obj.getAlign(obj.Records{i}.DataType));
            if mod(offset, a) ~= 0
                offset = offset - mod(offset, a) + a;
            end
            % Add the size of the next item.
            offset = offset + uint32(xcp.RecordLayout.getDim(obj.Records{i}.Name, dim) * obj.Sizes(i));
        end
        
        [x,dims] = xcp.RecordLayout.getDim(obj.Records{pos}.Name, dim);
        size = uint32(obj.Sizes(pos) * x);
    end
    
    function Describe(obj)
        % Nicely print the record content.
        disp('Record info');
        
        for i=1:length(obj.Records)
            r = obj.Records{i};
            fprintf('  %u:%-20s DataType:%-12s IndexMode:%-10s IndexOrder:%-10s AddressType:%s\n', ...
                r.Position, r.Name, r.DataType,r.IndexMode, r.IndexOrder, r.AddressType);
        end
        
        disp('Alignment info:');
        disp(['  Byte:' num2str(obj.ALIGNMENT_BYTE) ' Word:' num2str(obj.ALIGNMENT_WORD) ' Long:' num2str(obj.ALIGNMENT_LONG)]);
        disp(['  F32:' num2str(obj.ALIGNMENT_FLOAT32_IEEE) ' F64:' num2str(obj.ALIGNMENT_FLOAT64_IEEE)]);
    end
    
end

methods (Access = 'private')
    
    function n = getAlign(obj, type)
        % Return the alignment info for a type.
        switch type
            case { 'UBYTE', 'SBYTE' }
                atype = 'ALIGNMENT_BYTE';
            case { 'UWORD', 'SWORD' }
                atype = 'ALIGNMENT_WORD';
            case { 'ULONG', 'SLONG' }
                atype = 'ALIGNMENT_LONG';
            case { 'FLOAT32_IEEE', 'FLOAT64_IEEE' }
                atype = ['ALIGNMENT_' type];
            otherwise
                atype = 'ALIGNMENT_BYTE';
        end
        
        if ~isempty(obj.(atype))
            % Firstly try to find the definition in the record
            n = obj.(atype);
        elseif ~isempty(obj.a2linfo)
            % Secondly look in the module wide declaration
            n = obj.a2linfo.getAlignForType(atype);
        else
            % Last return 1 as the default value.
            n = 1;
        end
    end
    
    function item = getLayoutItem(obj, name)
        % Search and return an item by name.
        item = [];
        for i= 1:length(obj.Records)
            if strcmp(obj.Records{i}.Name, name)
                item = obj.Records{i};
                return;
            end
        end
    end
    
end

methods (Static)
    
    function [n, nd] = getDim(name, dim)
        % Return the dimension of the given item.
        switch(name)
            case 'AXIS_PTS_X'
                n = dim(1);
                nd = n;
            case 'AXIS_PTS_Y'
                n = dim(2);
                nd = n;
            case 'AXIS_PTS_Z'
                n = dim(3);
                nd = n;
            case 'FNC_VALUES'
                n = prod(dim);
                nd = dim;
            otherwise
                n = 1;
                nd = 1;
        end
    end
    
end

end
