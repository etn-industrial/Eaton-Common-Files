classdef TransportLayerCANInfo < handle
% TransportLayerCANInfo Define CAN specific transport layer information.

% Copyright 2017 The MathWorks, Inc.
    
properties (SetAccess = 'private')
    BaudRate              % Bus speed.
    SamplePoint           % Sample information for CAN Bus.
    SampleRate
    BTLCycles
    SJW
    SyncEdge
    MaxDLCRequired        % Max Data Length.
    CANIDMaster           % CAN ID of Master node.
    CANIDMasterIsExtended % True if using 29 bit extended ID.
    CANIDSlave            % CAN ID of Slave node.
    CANIDSlaveIsExtended  % True if using 29 bit extended ID.
end

methods

    function obj = TransportLayerCANInfo(XCP_ON_CAN)
        if isfield(XCP_ON_CAN, 'BAUDRATE')
            obj.BaudRate = XCP_ON_CAN.BAUDRATE;
        end
        if isfield(XCP_ON_CAN, 'SAMPLE_POINT')
            obj.SamplePoint = XCP_ON_CAN.SAMPLE_POINT;
        end
        if isfield(XCP_ON_CAN, 'SAMPLE_RATE')
            obj.SampleRate = XCP_ON_CAN.SAMPLE_RATE;
        end
        if isfield(XCP_ON_CAN, 'BTL_CYCLES')
            obj.BTLCycles = XCP_ON_CAN.BTL_CYCLES;
        end
        if isfield(XCP_ON_CAN, 'SJW')
            obj.SJW = XCP_ON_CAN.SJW;
        end
        if isfield(XCP_ON_CAN, 'SYNC_EDGE')
            obj.SyncEdge = XCP_ON_CAN.SYNC_EDGE;
        end
        if isfield(XCP_ON_CAN, 'MAX_DLC_REQUIRED')
            obj.MaxDLCRequired = XCP_ON_CAN.MAX_DLC_REQUIRED;
        end
        
        % Force the most significant bit to zero to be a standard CAN ID.
        obj.CANIDMaster = bitset(XCP_ON_CAN.CAN_ID_MASTER, 32, 0);
        % Adjust for extended versus standard CAN identifiers.
        if bitget(XCP_ON_CAN.CAN_ID_MASTER, 32)
            obj.CANIDMasterIsExtended = true;
        else
            obj.CANIDMasterIsExtended = false;
        end
        
        % Force the most significant bit to zero to be a standard CAN ID.
        obj.CANIDSlave = bitset(XCP_ON_CAN.CAN_ID_SLAVE, 32, 0);
        % Adjust for extended versus standard CAN identifiers.
        if bitget(XCP_ON_CAN.CAN_ID_SLAVE, 32)
            obj.CANIDSlaveIsExtended = true;
        else
            obj.CANIDSlaveIsExtended = false;
        end
    end
    
end

end
