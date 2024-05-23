function ipAd = ipaddr(ipStr, varargin)
% IPADDR Verifies input is a valid IPv4 address and converts the string
% based IP address to a numerical based IP address.
%
% The input should be a string comprised of four period delimited fields of
% decimal numbers in the range 0-255, or a variable that contains such a
% string. For example: ipaddr('10.200.30.4') returns 180887044
%
% Specifying a second argument 'array' returns the IP Address in the
% form of a 1x4 double array.
% For example: ipaddr('10.200.30.4', 'array') returns [10, 200, 30, 4]
%
% Specifying  a second argument 'string' returns the IP Address in the
% form of a string comprised of four period delimited fields of decimal
% numbers in the range 0-255. This is useful for resolving IP Addresses
% provided in workspace variables and for validating IP Addresses.

% Copyright 2017 The MathWorks, Inc.

narginchk(1, 2);

% Ensure input is a non empty char array.
validateattributes(ipStr, {'char'}, {'nonempty'});

if ~isIPv4String(ipStr)
    % Could be a workspace variable - try slResolve.
    try
        ipStr = slResolve(ipStr, gcb);
        % If it resolves to a scalar integer, no more.
    catch E
        error(message('SimulinkRealTime:UDP:invalidIPAdd'));
    end
    
    % Now ipStr should be a valid IPv4 address, else error.
    if ~ischar(ipStr) || ~isIPv4String(ipStr)
        error(message('SimulinkRealTime:UDP:invalidIPAdd'));
    end
end

% Split it into the individual fields.
ipVec = sscanf(ipStr, ['%u' '.' '%u' '.' '%u' '.' '%u']);

% Validate the Address.
if ~all(ipVec <= 255)
     error(message('SimulinkRealTime:UDP:invalidIPAdd'));
end

% Translate IP address to decimal format.
if (nargin == 2)
    switch varargin{1}
        case 'array'
            ipAd = ipVec';
        case 'string'
            ipAd = ipStr;
        otherwise
            error(message('SimulinkRealTime:UDP:invalidOption'));
    end
else
    % Called without an option.
    ipAd = 2.^[ 24 16 8 0] * ipVec;
end

function out = isIPv4String(ipStr)
out = ~isempty(regexp(strtrim(ipStr), '^\d{1,3}(\.\d{1,3}){3}$', 'once'));
