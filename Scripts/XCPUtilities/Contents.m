% XCP functionality is provided as part of Vehicle Network Toolbox.
% See "help vnt" for general toolbox information.
%
% A2L file operations.
%   xcpA2L                     - Parses an A2L file for use with XCP connections.
%   xcp.A2L.getEventInfo       - Query for information for a specified event by name.
%   xcp.A2L.getMeasurementInfo - Query for information for a specified measurement by name.
%
% XCP channel operations.
%   xcpChannel              - Creates an XCP channel able to connect to a slave module.
%   xcp.Channel.connect     - Starts an active connection to the slave module.
%   xcp.Channel.disconnect  - Stops an active connection to the slave module.
%   xcp.Channel.isConnected - Returns a boolean value to indicate active connection to the slave.
%
% XCP channel DAQ/STIM list operations.
%   xcp.Channel.createMeasurementList - Configure a DAQ/STIM list on the XCP channel.
%   xcp.Channel.freeMeasurementLists  - Remove all DAQ/STIM lists from the XCP channel.
%   xcp.Channel.viewMeasurementLists  - View the configured DAQ/STIM lists.
%   xcp.Channel.startMeasurement      - Start all configured DAQ/STIM lists.
%   xcp.Channel.stopMeasurement       - Stop all configured DAQ/STIM lists.
%   xcp.Channel.isMeasurementRunning  - Returns a boolean value to indicate active DAQ/STIM list activity.
%   xcp.Channel.readDAQListData       - Read samples of the specified measurement from a DAQ list.
%   xcp.Channel.writeSTIMListData     - Write a new value of the specified measurement to a STIM list.
%
% XCP channel direct data access.
%   xcp.Channel.readSingleValue  - Read a sample of the specified measurement from direct memory.
%   xcp.Channel.writeSingleValue - Write a new value of the specified measurement to direct memory.

% Copyright 2012 The MathWorks, Inc.
% $Revision: 1.1.6.1 $  $Date: 2012/11/08 16:33:51 $

