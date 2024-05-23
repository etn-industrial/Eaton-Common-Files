classdef ProtocolLayerInfo < handle
% ProtocolLayerInfo Define the Protocol implementation details.

% Copyright 2017 The MathWorks, Inc.
    
properties (SetAccess = 'private')
    AddressGranularity
    ByteOrder  % Byte order on the transmission frame.
    MaxCTO     % Maximum datasize for transmit to the slave.
    MaxDTO     % Maximum datasize for transmit to the master.
    T1         % T1 to T7: XCP protocol timeout values.
    T2
    T3
    T4
    T5
    T6
    T7
end


methods

    function obj = ProtocolLayerInfo(PROTOCOL_LAYER)
        % Capture the ProtocolLayerInfo properties from the parsed record.
        obj.AddressGranularity = PROTOCOL_LAYER.Field_12;
        obj.ByteOrder = PROTOCOL_LAYER.Field_11;
        obj.MaxCTO = PROTOCOL_LAYER.Field_9;
        obj.MaxDTO = PROTOCOL_LAYER.Field_10;
        obj.T1 = PROTOCOL_LAYER.Field_2;
        obj.T2 = PROTOCOL_LAYER.Field_3;
        obj.T3 = PROTOCOL_LAYER.Field_4;
        obj.T4 = PROTOCOL_LAYER.Field_5;
        obj.T5 = PROTOCOL_LAYER.Field_6;
        obj.T6 = PROTOCOL_LAYER.Field_7;
        obj.T7 = PROTOCOL_LAYER.Field_8;
    end
    
end

end
