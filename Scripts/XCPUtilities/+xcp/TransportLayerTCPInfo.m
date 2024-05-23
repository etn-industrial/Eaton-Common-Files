classdef TransportLayerTCPInfo < handle
% TransportLayerCANInfo Define TCP specific transport layer information

% Copyright 2017 The MathWorks, Inc.
    
properties (SetAccess = 'private')
    Address
    AddressString
    Port
end

methods

    function obj = TransportLayerTCPInfo(XCP_ON_TCP)
        obj.AddressString = XCP_ON_TCP.Field_3.ADDRESS;
        obj.Address = xcp.ipaddr(XCP_ON_TCP.Field_3.ADDRESS);
        obj.Port = XCP_ON_TCP.Field_2;
    end
    
end

end
