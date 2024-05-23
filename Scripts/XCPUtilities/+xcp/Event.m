classdef Event < handle
% Event Event information class.

% Copyright 2017-2018 The MathWorks, Inc.
    
properties (SetAccess = 'private')
    Name
    Direction
    MaxDAQList
    ChannelNumber
    ChannelTimeCycle
    ChannelTimeUnit
    ChannelPriority
    ChannelTimeCycleInSeconds
end

properties (SetAccess = 'private', GetAccess = 'private')
    % TimeResolutionConversion - Conversion factors for timing information.
    TimeResolutionConversion = containers.Map( ...
        { 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12 }, ...
        { 0.000000001, ... % 1 NS.
        0.00000001, ... % 10 NS.
        0.0000001, ... % 100 NS.
        0.000001, ... % 1 US.
        0.00001, ... % 10 US.
        0.0001, ... % 100 US.
        0.001, ... % 1 MS.
        0.01, ... % 10 MS.
        0.1, ... % 100 MS.
        1, ... % 1 S.
        0.000000000001, ...% 1 PS.
        0.00000000001, ... % 10 PS.
        0.0000000001 } ); % 100 PS.
    
    % TimeResolutionConversionString - Conversion factors for timing information as a string.
    TimeResolutionConversionString = containers.Map( ...
        { 'UNIT_1NS', 'UNIT_10NS', 'UNIT_100NS', 'UNIT_1US', 'UNIT_10US', 'UNIT_100US', ...
        'UNIT_1MS', 'UNIT_10MS', 'UNIT_100MS', 'UNIT_1S'}, ...
        { 0, 1, 2, 3, 4, 5, 6, 7, 8, 9 } );
end

methods

    function obj = Event(record)
        obj.Name = record.Field_1;
        obj.Direction = record.Field_4;
        obj.MaxDAQList = record.Field_5;
        obj.ChannelNumber = record.Field_3;
        obj.ChannelTimeCycle = record.Field_6;
        obj.ChannelPriority = record.Field_8;
        
        % Process the time unit both as a numeric value or as a string enumeration value.
        if ischar(record.Field_7)
            obj.ChannelTimeUnit = obj.TimeResolutionConversionString(record.Field_7);
        else
            obj.ChannelTimeUnit = record.Field_7;
        end
        
        if obj.ChannelTimeCycle == 0
            % Set the cycle in seconds to zero if not a time-based event.
            obj.ChannelTimeCycleInSeconds = 0;
        else
            % Otherwise, convert the given cycle time to seconds
            % using the time unit value provided by the A2L file.
            obj.ChannelTimeCycleInSeconds = double(obj.ChannelTimeCycle) * obj.TimeResolutionConversion(obj.ChannelTimeUnit);
        end
    end
    
end

end
