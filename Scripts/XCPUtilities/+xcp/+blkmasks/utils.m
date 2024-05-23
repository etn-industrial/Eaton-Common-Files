classdef utils
    %XCP.BLKMASKS.UTILS -  Utility functions for XCP block masks.  These
    %functions are either called by the mask classes, or by the block mask
    %initialization/display commands

%   Copyright 2018 The MathWorks, Inc.

    methods (Static = true)
        
        function help(docTag)
            %Callback for Help button on the mask dialog.

            % Initialize map file location.
            mapfileLocation = ''; %#ok<NASGU>
            vntMap = fullfile(docroot, 'vnt', 'vnt.map');
            xpcMap = fullfile(docroot, 'xpc', 'xpc.map');
            
            if exist (vntMap, 'file') % VNT map exists.
                mapfileLocation = vntMap;
            elseif exist (xpcMap, 'file') % xPC map exists.
                mapfileLocation = xpcMap;
            else
                warndlg(DAStudio.message('xcp:xcpblks:noProductDocumentation'),'Warning','modal');
                return;    
            end

            helpview(mapfileLocation, docTag);
        end

        function validateModel
            % Validate an XCP Model
            blkh = gcbh; 
            TLTypeStr = xcp.blkmasks.utils.getTLTypeStr(blkh);
            blkType = get_param(blkh, 'FunctionName');
            
            switch blkType
                case {'sxcpipconfig', 'sxcpcanconfig'}
                    % No seed/key support for Simulink Real-Time
                    if ((~isempty(regexpi(get_param(bdroot, 'SystemTargetFile'),'^xpc')) || ~isempty(regexpi(get_param(bdroot, 'SystemTargetFile'),'^slrt'))) && strcmp(get_param(gcb,'EnableSecurity'),'on'))
                        error(message('xcp:xcpblks:noSeedKeySupportSLRT',TLTypeStr, gcb));
                    end
                    
                    if strcmp(blkType, 'sxcpcanconfig')
                        
                        canTLRx = find_system(bdroot, 'FollowLinks', 'on', ...
                                    'LookUnderMasks', 'on', ...
                                    'FunctionName', 'sxcpcantlrx');
                        canTLTx = find_system(bdroot, 'FollowLinks', 'on', ...
                                    'LookUnderMasks', 'on', ...
                                    'FunctionName', 'sxcpcantltx');

                        % No blocks found.
                        if ( (isempty(canTLTx) || isempty(canTLRx)))
                            error(message('xcp:xcpblks:noCANTLBlocks'));
                        end

                        % More than one found.
                        if ( (length(canTLTx)>1) || (length(canTLRx)>1))
                            error(message('xcp:xcpblks:multipleCANTLBlocks'));
                        end

                    end
                    
                    if strcmp(blkType, 'sxcpipconfig')
                        allUDPConfig = find_system(bdroot, 'FollowLinks', 'on', ...
                                    'LookUnderMasks', 'on', ...
                                    'FunctionName', 'sxcpipconfig');
                        numConfig = length(allUDPConfig);
                        if (numConfig > 1 )
                            addressInfo = cell(numConfig,1);
                            for i = 1:numConfig
                                a2lFile = get_param(allUDPConfig(i),'A2LFile');
                                a2lObj = xcpA2L(a2lFile{1});
                                addressInfo{i} = ['IP:', a2lObj.TransportLayerUDPInfo.AddressString,'Port:', num2str(a2lObj.TransportLayerUDPInfo.Port)];
                            end
                            if (length(addressInfo)~= length(unique(addressInfo)) )
                                error(message('xcp:xcpblks:uniqueIPInfo'));
                            end
                        end
                    end

                case {'sxcpipdaq', 'sxcpipstim', 'sxcpcandaq', 'sxcpcanstim'}
                    slaveName = get_param(blkh, 'SlaveName');
                    if strcmpi(slaveName, '<Please select a config name>')
                        error(message('xcp:xcpblks:noConfigSelected', gcb ));
                    end
                    out = find_system(bdroot, 'LookUnderMasks', 'all', 'MaskType', ['XCP ',TLTypeStr,' Configuration'], 'SlaveName', slaveName);

                    if isempty(out) % The XCP Configuration block has been deleted.
                        error(message('xcp:xcpblks:noConfigFound',TLTypeStr, slaveName));
                    elseif (length(out)>1) 
                        % Multiple XCP Configuration blocks have been found.
                        error(message('xcp:xcpblks:MoreThanOneConfigFound', TLTypeStr, slaveName));
                    end        
                otherwise
                    assert(false,'Internal Error: Invalid Use Case');
            end
        end

        function [dispString, port, NMeasurements] = getDisplayString(enableTimestamp)
            %Return a display string for XCP blocks.
            %
            % We are called every time the mask is initialized,
            % so the current block is always ours.
            blk = gcb;
            blkh = gcbh;
            
            
            if (~exist('enableTimestamp','var'))
                enableTimestamp = 0;
            end

            % Set port to empty.
            port = [];
            % Set dispString to empty.
            dispString = [];

            % Set the default.
            NMeasurements = 1;

            % Check if we're in the library. If so, don't display any dynamic info.
            parentBlk = get_param(blk, 'Parent');
            % Determine the block type.
            blkType = get_param(blk, 'FunctionName');
            if ( strcmpi(parentBlk, 'xcpprotocollib/UDP') || ...
                 strcmpi(parentBlk, 'xcpprotocollib/CAN') || ...
                 strcmpi(parentBlk, 'xcpcantllib')        || ...   %TODO: Check
                 strcmpi(parentBlk, 'vntxcplib/CAN')      || ...
                 strcmpi(parentBlk, 'vntxcplib/UDP')      || ...
                 strcmpi(parentBlk, 'xcpcantllib')        || ...
                 strcmpi(parentBlk, 'xcprtlib/CAN')        || ...
                 strcmpi(parentBlk, 'xcprtlib/UDP') )
             
                blkDiagType = get_param(bdroot, 'BlockDiagramType');
                if strcmpi(blkDiagType, 'library')
                    % Display String inside the library
                    switch blkType
                        case 'sxcpipconfig'
                            dispString = sprintf('XCP UDP\nConfiguration');
                        case 'sxcpipdaq'  
                            dispString = sprintf('XCP UDP\nData Acquisition');
                            port(1).id = 1;
                            port(1).label = '';
                        case 'sxcpipstim'
                            dispString = sprintf('XCP UDP\nData Stimulation');
                            port(1).id = 1;
                            port(1).label = '';
                        case 'sxcpcanconfig'
                            dispString = sprintf('XCP CAN\nConfiguration');
                        case 'sxcpcandaq'  
                            dispString = sprintf('XCP CAN\nData Acquisition');
                            port(1).id = 1;
                            port(1).label = '';
                        case 'sxcpcanstim'
                            dispString = sprintf('XCP CAN\nData Stimulation');
                            port(1).id = 1;
                            port(1).label = '';
                        case 'sxcpcantlrx'
                            dispString = sprintf('XCP CAN\n TL Receive');
                        case 'sxcpcantltx'
                            dispString = sprintf('XCP CAN\n TL Transmit');
                        otherwise 
                            assert(false,'Internal Error: Invalid Use Case');
                    end
                    return;
                end
            end
            switch blkType
                case {'sxcpipconfig', 'sxcpcanconfig'}
                    slaveName = get_param(blkh, 'SlaveName');
                    fullFile = get_param(blkh, 'A2LFile');
                    [~, a2lFile, ext] = fileparts(fullFile);
                    a2lFile = strcat(a2lFile, ext);
                    if isempty(a2lFile)
                        a2lFile = sprintf('No A2L file\nselected');
                    end
                    dispString = sprintf('Config name: %s\n%s', slaveName, a2lFile);
                    nInputPorts = 0;
                    nOutputPorts = 0;
                    if strcmpi(get_param(blkh, 'EnableStatus'), 'on')
                        nOutputPorts = 1;
                        port(1).id = 1;
                        port(1).label = 'Status';
                    end
                case {'sxcpipdaq', 'sxcpcandaq'}
                    dispString = localGetDisplayString(blkh);
                    nInputPorts = 0;
                    measurements = get_param(blkh, 'SelectedMeasurements');
                    [nOutputPorts, port] = localGetPortInfo(measurements);
                    NMeasurements = nOutputPorts;
                    %Add the timestamp port:
                    if (enableTimestamp)
                        timePort = port(end).id+1;
                        port(timePort).id = timePort; %#ok<*AGROW>
                        port(timePort).label = 'Timestamp';
                        nOutputPorts = nOutputPorts+1;
                    end
                case {'sxcpipstim', 'sxcpcanstim'}
                    dispString = localGetDisplayString(blkh);
                    measurements = get_param(blkh, 'SelectedMeasurements');
                    [nInputPorts, port] = localGetPortInfo(measurements);
                    nOutputPorts = 0;
                    NMeasurements = nInputPorts;
                    %Add the timestamp port:
                    if (enableTimestamp)
                        timePort = port(end).id+1;
                        port(timePort).id = timePort; %#ok<*AGROW>
                        port(timePort).label = 'Timestamp';
                        nInputPorts = nInputPorts+1;
                    end
                case 'sxcpcantlrx'
                    % Form display string.
                    dispString = sprintf('XCP CAN\n TL Receive');
                    nInputPorts = 2;
                    nOutputPorts = 0;
                    port(1).id = 1;
                    port(1).label = sprintf('CAN\nMsg');
                    port(2).id = 2;
                    port(2).label = sprintf('N');
                case 'sxcpcantltx'
                    % Form display string.
                    dispString = sprintf('XCP CAN\n TL Transmit');
                    nInputPorts = 0;
                    nOutputPorts = 2;
                    port(1).id = 1;
                    port(1).label = sprintf('CAN\nMsg');
                    port(2).id = 2;
                    port(2).label = sprintf('N');     
                otherwise
                    assert(false,'Internal Error: Invalid Use Case');
            end
            maskDisplayString = localBuildMaskDisplayString(nInputPorts, nOutputPorts);
            set_param(blkh, 'MaskDisplay', maskDisplayString);
        end
            
        function isValid = validateSampleTime(value)
            % Convert sample time to number. 
            sampleTime = str2num(value); %#ok<ST2NM>

            % Initialize
            isValid = true;

            % Allow variable names but do not allow NaN, i and j (complex) as
            % variables. If they are left undefined, it yields incorrect results.
            if isvarname(value) && ~ismember(lower(value), {'nan', 'i', 'j', 'inf'})  
                return;
            end

            % Check for non-numeric
            if  isempty(sampleTime) || ~isscalar(sampleTime) || ~isnumeric(sampleTime) || ...
                    isnan(sampleTime) || isinf(sampleTime)
                isValid = false;
                return;
            end
     
            if (sampleTime<=0 && sampleTime~=-1)
                isValid = false;
                return;
            end

        end

        function TLTypeStr = getTLTypeStr(block)
            maskType = get_param(block,'MaskType');
            if contains(maskType,'UDP')
                TLTypeStr = 'UDP';
            elseif contains(maskType,'CAN')
                TLTypeStr = 'CAN';
            else
                assert(false,'Internal Error: Invalid Use Case');
            end
        end
        
    
        function onOff =  logical2OnOff(logicalVal)
            if logicalVal
                onOff = 'on';
            else
                onOff = 'off';
            end
        end

        function logicalVal = onOff2Logical(onOffString)
            if strcmp(onOffString, 'on')
                logicalVal = true;
            elseif strcmp(onOffString, 'off')
                logicalVal = false;
            else
                error('Invalid Input')
            end
        end
    end
end
   

%% %%%%%%%%%%%%%%%% Local Functions %%%%%%%%%%%%%%%%%%%%

function maskDisplayString = localBuildMaskDisplayString(nInputPorts, nOutputPorts)
    %LOCALUPDATEMASKDISPLAYSTRING Updates Mask Display String value
    %
    %    MASKDISPLAYSTRING = LOCALUPDATEMASKDISPLAYSTRING(NINPUTPORTS, NOUTPUTPORTS)
    %    updates MASKDISPLAYSTRING

    % Build the MaskDisplayString in the block library based on NUMBERPORTS
    maskDisplayString = 'disp(str);';

    portType = '''input''';
    % Loop through number of ports and update mask display string.
    startIdx = 1;
    nestedUpdateStrings(nInputPorts);
    startIdx = nInputPorts + 1;
    portType = '''output''';
    nestedUpdateStrings(nOutputPorts);
        % Nested function to update strings.
        function nestedUpdateStrings(ports)
            for idx = startIdx:startIdx+ports-1
                portID = sprintf('port(%d).id',idx);
                portLabel = sprintf('port(%d).label', idx);
                addStr = sprintf('\nport_label(%s,%s,%s);',portType, portID, portLabel);
                maskDisplayString = strcat(maskDisplayString, addStr);
            end
        end
end


function [nPorts, port] = localGetPortInfo(measurements)
    % Initialize to default.
    nPorts = 1;
    port(1).id = 1;
    port(1).label = 'Data';

    ind = strfind(measurements, ';');
    if ( isempty(measurements) || isempty(ind) )
        if ~isempty(measurements)
            port(1).label = measurements;
        end
        return;
    end

    nPorts = length(ind)+1;
    measurementsCell = strsplit(measurements,';');
    for idx = 1:nPorts
        port(idx).id = idx; %#ok<*AGROW>
        port(idx).label = measurementsCell{idx};
    end

end

function dispString = localGetDisplayString(blkh)

    slaveName = get_param(blkh, 'SlaveName');
    if strcmpi(slaveName, '<Please select a config name>')
        dispString = sprintf('No config\nselected');
        return
    end
    eventName = get_param(blkh, 'EventName');
    if isempty(eventName)
        eventName = 'No events';
    end
    dispString = sprintf('Config name: %s\nEvent: %s', slaveName, eventName);
end







