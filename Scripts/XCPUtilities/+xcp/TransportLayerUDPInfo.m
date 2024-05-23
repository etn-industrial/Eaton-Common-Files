classdef TransportLayerUDPInfo < handle
% TransportLayerCANInfo Define UDP specific transport layer information

% Copyright 2017 The MathWorks, Inc.
    
properties (SetAccess = 'private')
    Address
    AddressString
    Port
end

methods

    function obj = TransportLayerUDPInfo(XCP_ON_UDP)
        obj.AddressString = XCP_ON_UDP.Field_3.ADDRESS;
        obj.Address = xcp.ipaddr(XCP_ON_UDP.Field_3.ADDRESS);
        obj.Port = XCP_ON_UDP.Field_2;
    end
    
end

end
