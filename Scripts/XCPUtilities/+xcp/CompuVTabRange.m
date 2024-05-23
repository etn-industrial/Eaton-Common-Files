classdef CompuVTabRange < handle
% CompuVTABRANGE Define ranges in ASAP2.

% Copyright 2017-2018 The MathWorks, Inc.
    
properties (SetAccess = 'private')
    Name             % Table name.
    LongID           % Description.
    NumberValuePairs % Number of intervals defined.
    InValMin         % Array containing the min values of each interval.
    InValMax         % Array containing the max values of each interval.
    OutVal           % Array containing the names of each interval.
    DEFAULT_VALUE    % Name returned if no matching interval is found.
end

methods
    
    function obj = CompuVTabRange(record)
		% Capture the parsed record.
		obj.Name = record.Name;
		obj.LongID = record.LongID;
		obj.NumberValuePairs = record.NumberValuePairs;
		obj.InValMin = record.InValMin;
		obj.InValMax = record.InValMax ;
		obj.OutVal = record.OutVal;
		
		% Default value is an optional element for this A2L entry.
		try
			obj.DEFAULT_VALUE = record.DEFAULT_VALUE;
		catch
		end
	end
    
    function sym = n2s(obj, n)
		% Convert from enum value to symbol.
		try
			if length(n)>1
				sym = arrayfun(@(e)obj.OutVal(eq(obj.InValMin,e)),n);
			else
				sym = obj.OutVal{and(le(obj.InValMin,n), le(n, obj.InValMax))};
			end
		catch
			if ~isempty(obj.DEFAULT_VALUE)
				sym = obj.DEFAULT_VALUE;
			else
				sym ='';
				warning(message('xcp:A2L:IncorrectEnumConversion', obj.Name, n));
			end
		end
	end
	
	function n = s2n(obj, sym)
		% Convert from enum symbol to value range.
		try
			if iscell(sym)
				n = cellfun(@(e)obj.OutVal(e),sym);
			else
				filter=cellfun(@(x) strcmp(x, sym), obj.OutVal);
				idx = find(filter);
				n = [obj.InValMin(idx) obj.InValMax(idx)];
			end
		catch
			if iscell(sym)
				error(message('xcp:A2L:IncorrectEnumConversion', obj.Name, strjoin(sym)));
			else
				error(message('xcp:A2L:IncorrectEnumConversion', obj.Name, sym));
			end
		end
	end
end

end
