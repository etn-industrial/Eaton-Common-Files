classdef CompuString < handle
% CompuString Convert between String to an Array of characters.

% Copyright 2017 The MathWorks, Inc.

properties (SetAccess = 'private')
    Name        % Name.
    FrameLength % Maximum string length.
end

methods
    function obj = CompuString(name, frameLength)
        % Capture the parsed record.
        obj.Name = name;
        obj.FrameLength = frameLength;
    end
    
    function n = convertToRaw(obj, v)
        % Convert to memory representation. Clip strings that are too long.
        if length(v) > obj.FrameLength
            warning(message('xcp:A2L:Clipping', obj.FrameLength));
            v = v(1:obj.FrameLength-1);
        end
        n = [uint8(v) uint8(repelem(0, obj.FrameLength-length(v)))];
    end
    
    function str = convertToPhy(~, n)
        % Convert to readable string (remove trailing blanks).
        str = deblank(char(n));
    end
    
end

end
