classdef A2L < matlab.mixin.SetGet
% A2L Class that implements an interface to an XCP A2L file.
    
% Copyright 2012-2018 The MathWorks, Inc.
    
properties (SetAccess = 'private')
    FileName               % Name of the A2L file used in this object.
    FilePath               % Full file path to the A2L file used in this object.
    SlaveName              % Name of the slave node.
    
    ProtocolLayerInfo      % Structure of general protocol layer information.
    DAQInfo                % Structure of DAQ related information.
    
    TransportLayerCANInfo  % Structure of CAN transport layer information.
    TransportLayerUDPInfo  % Structure of UDP transport layer information.
    TransportLayerTCPInfo  % Structure of TCP transport layer information.
    
    Events                 % Cell array of strings of the names of all of the events in the A2L file.
    Measurements           % Cell array of strings of the names of the measurements in the A2L file.
    Characteristics        % Cell array of strings of the names of the characteristics in the A2L file.
    
    EventInfo              % Container for Event objects
    MeasurementInfo        % Container for Measurement objects
    CharacteristicInfo     % Container for Characteristic objects
    AxisInfo               % Container for Axis objects.
    RecordLayouts          % Container for Characteristic objects.
    CompuMethods           % Container for Computation method objects.
    CompuTabs              % Container for ComputationVAB method objects (used for interp).
    CompuVTabs             % Container for ComputationVTAB method objects (used for enum).
end

properties (Hidden, SetAccess = 'private')
    Groups            % Groups represents the subsystems in which variables are used.
    LastModifiedDate  % The A2L file datenum of the file when the A2L object information was cached.
end

properties (SetAccess = 'private', GetAccess = 'private')
    A2LContent        % The raw parsed A2L structure returned by the file parser.
    A2MLContent       % The raw parsed A2ML structure returned by the file parser.
    MOD_COMMON        % Define module wide setting such as myte order and datatype alignment.
end


methods
    
    function obj = A2L(a2lFile)
    % A2L Creates and returns an XCP A2L file object.
    %
    %   OBJ = A2L(A2L_FILE) creates an A2L file object OBJ linked to the
    %   specified A2L_FILE. The object parses the A2L file to allow
    %   command line access much of the contained information. The A2L file
    %   object is also used in the creation and use of live XCP connections
    %   in MATLAB. The A2L_FILE can be specified as a string representing
    %   the file name or the full file path.
    %
    %   Example:
    %       a2lObj = xcpA2L('myFile.a2l');
    %
    %   See also VNT.
        
        % Perform an argument count check.
        narginchk(1, 1);
        
        % Convert string inputs to character vectors.
        a2lFile = convertStringsToChars(a2lFile);
        
        % Validate the file input.
        [fileName, fileExt, fileFullPath] =  xcp.validateA2LFile(a2lFile);
        
        % Record the file information into the A2L object.
        obj.FileName = [fileName fileExt];
        obj.FilePath = fileFullPath;
        
        % Set all the data into the object.
        obj.refreshCachedInfo();
    end
    
    function info = getEventInfo(obj, eventName)
    % getEventInfo Query for information for a specified event by name.
    %
    %   INFO = getEventInfo(OBJ, EVENT_NAME) finds information about the
    %   specified EVENT_NAME and returns this information as a structure
    %   INFO. The information structure contains various fields that
    %   define the characteristics of the event. If the specified event is
    %   not found, empty is returned. The EVENT_NAME must be specified as a
    %   string.
    %
    %   Example:
    %       a2lObj = xcpA2L('myFile.a2l');
    %       info = getEventInfo(a2lObj, 'MyEvent');
    %
    %   See also VNT.
        
        % Perform an argument count check.
        narginchk(2, 2);
        
        % Convert string inputs to character vectors.
        eventName = convertStringsToChars(eventName);

        % Validate the event argument.
        validatestring(eventName, obj.Events, 'a2l.getEventInfo', 'event name', 2);
        
        % Use logical indexing to find a match for the provided event name
        % in the event property. Note that the match is done case
        % insensitive in order to be more forgiving on the user. It is not
        % expected to see multiple events with the same name differing only
        % by case.
        idx = strcmp(eventName, obj.Events);
        info = obj.EventInfo(idx);
    end
    
    function info = getMeasurementInfo(obj, measurementName)
    % getMeasurementInfo Query for information for a specified measurement by name.
    %
    %   INFO = getMeasurementInfo(OBJ, MEASUREMENT_NAME) finds information
    %   about the specified MEASUREMENT_NAME and returns this information
    %   as a structure INFO. The information structure contains various
    %   fields that define the characteristics of the measurement. If the
    %   specified measurement is not found, empty is returned. The
    %   MEASUREMENT_NAME must be specified as a string.
    %
    %   Example:
    %       a2lObj = xcpA2L('myFile.a2l');
    %       info = getMeasurementInfo(a2lObj, 'MyMeasurement');
    %
    %   See also VNT.
        
        % Perform an argument count check.
        narginchk(2, 2);
        
        % Convert string inputs to character vectors.
        measurementName = convertStringsToChars(measurementName);

        % Validate each entry in the measurements argument.
        validatestring(measurementName, obj.Measurements, 'a2l.getMeasurementInfo', 'measurement name', 2);
        
        % Use logical indexing to find a match for the provided measurement
        % name in the measurement property. Note that the match is done case
        % insensitive in order to be more forgiving on the user. It is not
        % expected to see multiple measurements with the same name differing
        % only by case.
        if obj.MeasurementInfo.isKey(measurementName)
            info = obj.MeasurementInfo(measurementName);
        else
            warning(message('xcp:A2L:MissingMeasurement', measurementName));
            info = [];
        end
    end
    
    function info = getCharacteristicInfo(obj, characteristicName)
    % getCharacteristicInfo Query for information for a specified characteristic by name.
    %
    %   INFO = getCharacteristicInfo(OBJ, CHARACTERISTIC_NAME) finds information
    %   about the specified CHARACTERISTIC_NAME and returns this information
    %   as a structure INFO. The information structure contains various
    %   fields that define the characteristics of the characteristic. If the
    %   specified characteristic is not found, empty is returned. The
    %   NAME must be specified as a string.
    %
    %   Example:
    %       a2lObj = xcpA2L('myFile.a2l');
    %       info = getCharacteristicInfo(a2lObj, 'MyCal');
    %
    %   See also VNT.
        
        % Perform an argument count check.
        narginchk(2, 2);
        
        % Convert string inputs to character vectors.
        characteristicName = convertStringsToChars(characteristicName);

        % Validate each entry in the measurements argument.
        validatestring(characteristicName, obj.CharacteristicInfo.keys, 'a2l.getCharacteristicInfo', 'characteristics name', 2);
        
        % Use logical indexing to find a match for the provided characteristic
        % name in the characteristic property. Note that the match is done case
        % insensitive in order to be more forgiving on the user. It is not
        % expected to see multiple characteristics with the same name differing
        % only by case.
        if obj.CharacteristicInfo.isKey(characteristicName)
            info = obj.CharacteristicInfo(characteristicName);
        else
            warning(message('xcp:A2L:MissingCharacteristic', characteristicName));
            info = [];
        end
    end
        
end
    
    
methods (Hidden)
    
    function refreshCachedInfo(obj)
    % A2L Creates and returns an XCP A2L file object.
    %
    %   OBJ = A2L(A2L_FILE) creates an A2L file object OBJ linked to the
    %   specified A2L_FILE. The object parses the A2L file to allow
    %   command line access much of the contained information. The A2L file
    %   object is also used in the creation and use of live XCP connections
    %   in MATLAB. The A2L_FILE can be specified as a string representing
    %   the file name or the full file path.
    %
    %   Example:
    %       a2lObj = xcpA2L('myFile.a2l');
    %
    %   See also VNT.
        
        % Use the parser to read the A2L file contents.
        a2mlFile = fullfile(toolboxdir(['shared' filesep 'xcp']), '+xcp', 'private', 'a2l_def_1_31.a2ml');
        asamFile = fullfile(toolboxdir(['shared' filesep 'xcp']), '+xcp', 'private', 'asam_specials.a2ml');
        try
            [obj.A2LContent, obj.A2MLContent] = a2lparsermex(obj.FilePath, {a2mlFile, asamFile});
        catch err
            error(message('xcp:A2L:UnableToParseA2LFile'));
        end
        
        % Store the datenum of the file so we know when A2L details were read.
        fileInfo = dir(obj.FilePath);
        obj.LastModifiedDate = fileInfo.datenum;
        
        % Populate the basic slave node information.
        obj.SlaveName = obj.A2LContent.PROJECT.MODULE.Name;
        
        % Populate the MOD_COMMON section, while defaulting values per the
        % ASAM specification if they are not present in the A2L file.
        try
            obj.MOD_COMMON.Comment = obj.A2LContent.PROJECT.MODULE.MOD_COMMON.Comment;
        catch
        end
        
        try
            obj.MOD_COMMON.BYTE_ORDER = obj.A2LContent.PROJECT.MODULE.MOD_COMMON.BYTE_ORDER;
        catch
            obj.MOD_COMMON.BYTE_ORDER = 'MSB_LAST';            
        end
        
        try
            obj.MOD_COMMON.ALIGNMENT_BYTE = obj.A2LContent.PROJECT.MODULE.MOD_COMMON.ALIGNMENT_BYTE;
        catch
            obj.MOD_COMMON.ALIGNMENT_BYTE = 1;            
        end

        try
            obj.MOD_COMMON.ALIGNMENT_WORD = obj.A2LContent.PROJECT.MODULE.MOD_COMMON.ALIGNMENT_WORD;
        catch
            obj.MOD_COMMON.ALIGNMENT_WORD = 2;            
        end
        
        try
            obj.MOD_COMMON.ALIGNMENT_LONG = obj.A2LContent.PROJECT.MODULE.MOD_COMMON.ALIGNMENT_LONG;
        catch
            obj.MOD_COMMON.ALIGNMENT_LONG = 4;            
        end

        try
            obj.MOD_COMMON.ALIGNMENT_FLOAT16_IEEE = obj.A2LContent.PROJECT.MODULE.MOD_COMMON.ALIGNMENT_FLOAT16_IEEE;
        catch
            obj.MOD_COMMON.ALIGNMENT_FLOAT16_IEEE = 2;            
        end

        try
            obj.MOD_COMMON.ALIGNMENT_FLOAT32_IEEE = obj.A2LContent.PROJECT.MODULE.MOD_COMMON.ALIGNMENT_FLOAT32_IEEE;
        catch
            obj.MOD_COMMON.ALIGNMENT_FLOAT32_IEEE = 4;            
        end

        try
            obj.MOD_COMMON.ALIGNMENT_FLOAT64_IEEE = obj.A2LContent.PROJECT.MODULE.MOD_COMMON.ALIGNMENT_FLOAT64_IEEE;
        catch
            obj.MOD_COMMON.ALIGNMENT_FLOAT64_IEEE = 8;            
        end

        try
            obj.MOD_COMMON.ALIGNMENT_INT64 = obj.A2LContent.PROJECT.MODULE.MOD_COMMON.ALIGNMENT_INT64;
        catch
            obj.MOD_COMMON.ALIGNMENT_INT64 = 8;            
        end

        try
            obj.MOD_COMMON.DATA_SIZE = obj.A2LContent.PROJECT.MODULE.MOD_COMMON.ALIGNMENT_FLOADATA_SIZET32_IEEE;
        catch
        end

        try
            obj.MOD_COMMON.DEPOSIT = obj.A2LContent.PROJECT.MODULE.MOD_COMMON.DEPOSIT;
        catch
        end
        
        % Populate the protocol layer information.
        try
            PROTOCOL_LAYER = obj.A2LContent.PROJECT.MODULE.IF_DATA.XCP.PROTOCOL_LAYER;
            obj.ProtocolLayerInfo = xcp.ProtocolLayerInfo(PROTOCOL_LAYER);
        catch err %#ok<NASGU>
            % No information in the A2L file, so leave this content empty.
            obj.ProtocolLayerInfo = [];
        end
        
        % Populate the DAQ information.
        try
            DAQ = obj.A2LContent.PROJECT.MODULE.IF_DATA.XCP.DAQ;
            obj.DAQInfo = xcp.DAQInfo(DAQ);
        catch
            obj.DAQInfo = [];
        end
        
        % Populate the transport layer on CAN information.
        try
            record = obj.A2LContent.PROJECT.MODULE.IF_DATA.XCP.XCP_ON_CAN;
            obj.TransportLayerCANInfo = xcp.TransportLayerCANInfo(record);
        catch err %#ok<NASGU>
            % No information in the A2L file, so leave this content empty.
            obj.TransportLayerCANInfo = [];
        end
        
        % Populate the transport layer on UDP information.
        try
            record = obj.A2LContent.PROJECT.MODULE.IF_DATA.XCP.XCP_ON_UDP_IP;
            obj.TransportLayerUDPInfo = xcp.TransportLayerUDPInfo(record);
        catch err %#ok<NASGU>
            % No information in the A2L file, so leave this content empty.
            obj.TransportLayerUDPInfo = [];
        end
        
        % Populate the transport layer on TCP information.
        try
            record = obj.A2LContent.PROJECT.MODULE.IF_DATA.XCP.XCP_ON_TCP_IP;
            obj.TransportLayerTCPInfo = xcp.TransportLayerTCPInfo(record);
        catch err %#ok<NASGU>
            % No information in the A2L file, so leave this content empty.
            obj.TransportLayerTCPInfo = [];
        end
        
        A2LContent = obj.A2LContent; %#ok<*PROP>
        
        % Populate the event property information.
        obj.EventInfo = [];
        obj.Events = {};
        try
            % Load the event information.
            for ii = 1:numel(A2LContent.PROJECT.MODULE.IF_DATA.XCP.DAQ.EVENT)
                try
                    DaqEvent = A2LContent.PROJECT.MODULE.IF_DATA.XCP.DAQ.EVENT(ii);
                    % Create an xcp.Event object
                    e = xcp.Event(DaqEvent);
                    
                    % Set the event names.
                    obj.EventInfo = [obj.EventInfo e];
                    obj.Events{end+1} = e.Name;
                    
                catch err %#ok<NASGU>
                    % Incorrect or Not supported information in the A2L file
                    warning(message('xcp:A2L:ParseEventError', e.Name));
                end
            end
        catch
            obj.EventInfo = [];
            obj.Events = {};
        end
        
        % Collect all the CompuVTab in a containers.Map dictionary.
        % They contain the enum symbol and values definitions for A2L.
        obj.CompuVTabs = containers.Map;
        if isfield( A2LContent.PROJECT.MODULE, 'COMPU_VTAB' )
            for ii = 1:numel(A2LContent.PROJECT.MODULE.COMPU_VTAB)
                record = A2LContent.PROJECT.MODULE.COMPU_VTAB(ii);
                c = xcp.CompuVTab(record);
                obj.CompuVTabs(record.Name) = c;
            end
        end
        
        % Collect all the CompuTab in the same containers.Map dictionary.
        % They contain the interpolation values COMPU_METHOD INTERP.
        obj.CompuTabs = containers.Map;
        if isfield( A2LContent.PROJECT.MODULE, 'COMPU_TAB' )
            for ii = 1:numel(A2LContent.PROJECT.MODULE.COMPU_TAB)
                record = A2LContent.PROJECT.MODULE.COMPU_TAB(ii);
                c = xcp.CompuTab(record);
                obj.CompuTabs(record.Name) = c;
            end
        end
        
        % Collect all the CompuTabRange in the same containers.Map dictionary.
        % They contain the range values and names definitions for A2L.
        if isfield( A2LContent.PROJECT.MODULE, 'COMPU_VTAB_RANGE' )
            for ii = 1:numel( A2LContent.PROJECT.MODULE.COMPU_VTAB_RANGE)
                record = A2LContent.PROJECT.MODULE.COMPU_VTAB_RANGE(ii);
                c = xcp.CompuVTabRange(record);
                obj.CompuVTabs(record.Name) = c;
            end
        end
        
        % Collect all the CompuMethod in a containers.Map dictionary. They 
        % define how values are converted from stored integer to real world values.
        obj.CompuMethods = containers.Map;
        obj.CompuMethods('NO_COMPU_METHOD') = xcp.CompuMethodIdentical(struct('Name', 'NO_COMPU_METHOD', 'LongID', 'NO_COMPU_METHOD'));
        if isfield( A2LContent.PROJECT.MODULE, 'COMPU_METHOD' )
            for ii = 1:numel(A2LContent.PROJECT.MODULE.COMPU_METHOD)
                record = A2LContent.PROJECT.MODULE.COMPU_METHOD(ii);
                switch record.ConversionType
                    case 'RAT_FUNC'
                        % Rational scaling (ax2+bx+c) / (dx2+ex+f)
                        c = xcp.CompuMethodRational(record);
                        
                    case 'FORM'
                        % Formula based scaling
                        % Can't be implemented because the parser does not
                        % include the formula
                        c = [];
                        
                    case 'TAB_VERB'
                        % Enum scaling
                        c = xcp.CompuMethodEnum(record, obj);
                        
                    case 'TAB_INTP'
                        % Scaling specified by an interpolation table
                        c = xcp.CompuMethodInterp(record, obj);
                        
                    case 'IDENTICAL'
                        % Scaling 1:1
                        c = xcp.CompuMethodIdentical(record);
                        
                    case 'LINEAR'
                        % Scaling ax+b
                        c = xcp.CompuMethodLinear(record);
                        
                    otherwise
                        warning(message('xcp:A2L:UnsupportedConversion', c.Name, record.ConversionType));
                        c = [];
                end
                obj.CompuMethods(record.Name) = c;
            end
        end
        
        % Collect all the RecordLayouts in a containers.Map dictionary.
        obj.RecordLayouts = containers.Map;
        if isfield( A2LContent.PROJECT.MODULE, 'RECORD_LAYOUT' )
            for ii = 1:numel(A2LContent.PROJECT.MODULE.RECORD_LAYOUT)
                record = A2LContent.PROJECT.MODULE.RECORD_LAYOUT(ii);
                % Create the record object.
                c = xcp.RecordLayout(record);
                c.setParent(obj);
                % Add the the record in the container.
                obj.RecordLayouts(record.Name) = c;
            end
        end
        
        % Populate the measurement property information.
        obj.MeasurementInfo = containers.Map;
        obj.Measurements = {};
        if isfield( A2LContent.PROJECT.MODULE, 'MEASUREMENT' )
            for ii = 1:numel(A2LContent.PROJECT.MODULE.MEASUREMENT)
                record = A2LContent.PROJECT.MODULE.MEASUREMENT(ii);
                % Create the measurement object.
                m = xcp.Measurement(record, obj);
                % Add the the measurement in the container.
                obj.MeasurementInfo(record.Name) = m;
                obj.Measurements{end+1} = record.Name;
            end
        end
        
        % Collect all the AXIS_PTS in a containers.Map dictionary.
        obj.AxisInfo = containers.Map;
        if isfield( A2LContent.PROJECT.MODULE, 'AXIS_PTS' )
            for ii = 1:numel(A2LContent.PROJECT.MODULE.AXIS_PTS)
                record = A2LContent.PROJECT.MODULE.AXIS_PTS(ii);
                % Create the axis object.
                axis = xcp.AxisPts(record, obj);
                % Add the the axis in the container.
                obj.AxisInfo(record.Name) = axis;
            end
        end
        
        % Collect all the Characteristic in a containers.Map dictionary.
        obj.Characteristics = {};
        obj.CharacteristicInfo = containers.Map;
        if isfield( A2LContent.PROJECT.MODULE, 'CHARACTERISTIC' )
            for ii = 1:numel(A2LContent.PROJECT.MODULE.CHARACTERISTIC)
                record = A2LContent.PROJECT.MODULE.CHARACTERISTIC(ii);
                % Create the characteristic object.
                c = xcp.Characteristic(record, obj);
                obj.Characteristics{end+1} = record.Name;
                obj.CharacteristicInfo(record.Name) = c;
            end
        end
        
        obj.Groups = {};
        if isfield( A2LContent.PROJECT.MODULE, 'GROUP' )
            for ii = 1:numel(A2LContent.PROJECT.MODULE.GROUP)
                record = A2LContent.PROJECT.MODULE.GROUP(ii);
                g = xcp.Group(record, obj);
                obj.Groups{end+1} = g;
            end
        end
        
        % Add the new object to the manager using the path as the key.
        instance = xcp.A2LManager.getInstance;
        instance(1).add(obj, obj.FilePath);
    end
    
    function n = getDefaultByteOrder(obj)
    % getDefaultByteOrder Return the default byte order.

        n = obj.MOD_COMMON.BYTE_ORDER;
    end
    
    function n = getAlignForType(obj, type)
    % getAlignForType Return the memory alignment for a given type.
    
        n = obj.MOD_COMMON.(type);
    end
    
end


methods (Static)
    
    function [mltype, size] = getMATLABType(a2lType)
    % getMATLABType Return the MATLAB type and data size for an A2L type.
    
        % Convert string inputs to character vectors.
        a2lType = convertStringsToChars(a2lType);

        switch a2lType
            case {'UBYTE'}
                mltype =  'uint8';
                size = 1;
            case {'SBYTE', 'BYTE'}
                mltype =  'int8';
                size = 1;
                
            case {'UWORD'}
                mltype =  'uint16';
                size = 2;
            case {'SWORD','WORD'}
                mltype =  'int16';
                size = 2;
                
            case {'UDWORD', 'ULONG'}
                mltype =  'uint32';
                size = 4;
            case {'SDWORD', 'DWORD', 'SLONG', 'LONG'}
                mltype =  'int32';
                size = 4;
                
            case {'UDLONG'}
                mltype =  'uint64';
                size = 8;
            case {'SDLONG', 'DLONG'}
                mltype =  'int64';
                size = 8;
                
            case 'FLOAT32_IEEE'
                mltype =  'single';
                size = 4;
            case 'FLOAT64_IEEE'
                mltype =  'double';
                size = 8;
            
            otherwise
                mltype = [];
                size = 0;
        end
    end
    
    function b = convByteOrder(name)
    % Convert Byte Order from String (MSB_LAST or MSB_FIRST) to bool (true or false).
    
        % Convert string inputs to character vectors.
        name = convertStringsToChars(name);

        % When endianness is not specified, we use default (using MSB_FIRST).
        if isempty(name)            
            b = false;
        end
        
        switch (name)
            case {'MSB_LAST'}
                b = true;
            case {'MSB_FIRST'}
                b = false;
            otherwise
                warning(message('xcp:A2L:UnsupportedRecordEndianness', name));
        end
    end
    
end

end
