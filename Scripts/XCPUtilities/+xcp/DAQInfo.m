classdef DAQInfo < handle
% DAQInfo DAQ information class.

% Copyright 2017 The MathWorks, Inc.
    
properties (SetAccess = 'private')
    AddressExtension
    ConfigType
    GranularityODTEntrySize
    IdentificationFieldType
    MaxDAQ
    MaxEventChannels
    MaxODTEntrySize
    MinDAQ
    OptimizationType
    OverloadIndication
    PrescalerSupported
    ResumeSupported
    Timestamp
end

methods

    function obj = DAQInfo(DAQ)
        % Capture the DAQ Info properties from the parsed record.
        obj.AddressExtension = DAQ.Field_6;
        obj.ConfigType = DAQ.Field_1;
        obj.GranularityODTEntrySize = DAQ.Field_8;
        obj.IdentificationFieldType = DAQ.Field_7;
        obj.MaxDAQ = DAQ.Field_2;
        obj.MaxEventChannels = DAQ.Field_3;
        obj.MaxODTEntrySize = DAQ.Field_9;
        obj.MinDAQ = DAQ.Field_4;
        obj.OptimizationType = DAQ.Field_5;
        obj.OverloadIndication = DAQ.Field_10;
        
        if isfield(DAQ, 'PRESCALER_SUPPORTED')
            obj.PrescalerSupported = DAQ.PRESCALER_SUPPORTED;
        else
            obj.PrescalerSupported = 'PRESCALER_NOT_SUPPORTED';
        end
        if isfield(DAQ, 'RESUME_SUPPORTED')
            obj.ResumeSupported = DAQ.RESUME_SUPPORTED;
        else
            obj.ResumeSupported = 'RESUME_NOT_SUPPORTED';
        end
        
        if isfield(DAQ, 'TIMESTAMP_SUPPORTED') && isfield(DAQ.TIMESTAMP_SUPPORTED, 'Field_1')
            obj.Timestamp.Ticks = DAQ.TIMESTAMP_SUPPORTED.Field_1;
        else
            obj.Timestamp.Ticks = 'TIMESTAMP_NOT_SUPPORTED';
        end
        if isfield(DAQ, 'TIMESTAMP_SUPPORTED') && isfield(DAQ.TIMESTAMP_SUPPORTED, 'Field_2')
            obj.Timestamp.Size = DAQ.TIMESTAMP_SUPPORTED.Field_2;
        else
            obj.Timestamp.Size = 'TIMESTAMP_NOT_SUPPORTED';
        end
        if isfield(DAQ, 'TIMESTAMP_SUPPORTED') && isfield(DAQ.TIMESTAMP_SUPPORTED, 'Field_3')
            obj.Timestamp.Unit = DAQ.TIMESTAMP_SUPPORTED.Field_3;
        else
            obj.Timestamp.Unit = 'TIMESTAMP_NOT_SUPPORTED';
        end
    end
    
end

end
