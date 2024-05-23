classdef Group < handle
% Group Group information class.
%
% The Group in A2L file as use to represent the subsystem hierarchy and
% associates the FUNCTIONS, CHARACTERISTICS and MEASUREMENTS to the place
% where they are defined.

% Copyright 2017 The MathWorks, Inc.
    
properties (SetAccess = 'private')
    Name               % Group name.
    LongIdentifier     % Description.
    Root               % Indicate whether that group is an independent root group (no parent).
    SubGroup           % List of subgroups.
    FunctionList       % List of included functions.
    RefCharacteristics % List of included characteristics.
    RefMeasurements    % List of included measurements.
end

methods
    
    function obj = Group(record, a2lInfo)
        % Capture the properties from the parsed record.
        obj.Name = record.GroupName;
        obj.LongIdentifier = record.GroupLongIdentifier;
        obj.Root = record.ROOT;
        if isfield(record, 'FUNCTION_LIST')
            obj.FunctionList = record.FUNCTION_LIST;
        end
        
        obj.RefCharacteristics = {};
        if isfield(record, 'REF_CHARACTERISTIC')
            for i=1:length(record.REF_CHARACTERISTIC)
                if a2lInfo.CharacteristicInfo.isKey(record.REF_CHARACTERISTIC{i})
                    obj.RefCharacteristics{end+1} = a2lInfo.CharacteristicInfo(record.REF_CHARACTERISTIC{i});
                elseif a2lInfo.AxisInfo.isKey(record.REF_CHARACTERISTIC{i})
                    obj.RefCharacteristics{end+1} = a2lInfo.AxisInfo(record.REF_CHARACTERISTIC{i});
                end
            end
        end
        
        obj.RefMeasurements = {};
        if isfield(record, 'REF_MEASUREMENT')
            for i=1:length(record.REF_MEASUREMENT)
                try
                    obj.RefMeasurements{end+1} = a2lInfo.MeasurementInfo(record.REF_MEASUREMENT{i});
                catch
                end
            end
        end
    end
    
end

end
