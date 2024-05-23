function outData = transformationFcn(inData)
%TODO:  Consider separating the functions into separate files. 

%   Copyright 2018 The MathWorks, Inc.

%Easier to work with a map here
newDataMap = containers.Map({inData.InstanceData.Name}, {inData.InstanceData.Value});

srcBlock = get_param(gcb,'SourceBlock');
switch srcBlock
    case sprintf('xcprtlib/XCP UDP\nTransport Layer')
        outData.NewBlockPath = 'xpcrtudplib/UDP Configure';
        
        %Parameter Name Change:
        if(isKey(newDataMap,'MasterIpAddress'))
            newDataMap('IpAddress') = newDataMap('MasterIpAddress');
        end
        %Parameters that should be removed:
        remParams = {'MasterIpAddress', 'Port', 'EthDriver','MaxNumMessages', 'TLID','headerErrDet','CTRScheme','SampleTime'}; 
        %^ CTR and SampleTime will be ported over to the XCP UDP Config block
        for i = 1:length(remParams)
            %The key won't exist if the mask param had an empty value
            if (isKey(newDataMap, remParams(i)))
                remove(newDataMap,remParams(i));
            end
        end
        
        %Now CTR and SampleTime are accessible while forwarding XCP
        %configure block:
        set_param(gcb,'UserData',inData.InstanceData);
        
        warning(message('xcp:xcpblks:slrtUDPTLRemoved', get_param(gcb,'Name')));
    case {'xcptllib/XCP UDP Transport Layer','xcplib/XCP UDP Transport Layer', sprintf('xcpcorelib/XCP UDP Transport Layer\nConfiguration')}
        outData.NewBlockPath = 'obsoletexcplib/Obsolete';
        
        newDataMap = containers.Map; %Empty - no parameters on the obsolete block
        
        %Now CTR and SampleTime are accessible when forwarding XCP
        %Configure block:
        set_param(gcb,'UserData',inData.InstanceData);
        
        warning(message('xcp:xcpblks:desktopUDPTLRemoved',gcb,xcp.blkForwarding.utils.genDeleteBlockLinkStr(gcb)));
    case 'xcpprotocollib/XCP Configuration'
        [tlTypeStr] = xcp.blkForwarding.utils.getTLTypeStr;
        outData.NewBlockPath = ['xcpprotocollib/',tlTypeStr,'/XCP ',tlTypeStr,' Configuration'];

        %Parameter Name Change:
        if (isKey(newDataMap,'FileName'))
            newDataMap('A2LFile') = newDataMap('FileName');
        end

        %Parameters that should be removed:
        remParams = {'TLID','FileName', 'TLType'};
        for i = 1:length(remParams)
            %The key won't exist if the mask param had an empty value
            if (isKey(newDataMap, remParams(i)))
                remove(newDataMap,remParams(i));
            end
        end
        
        if strcmp(tlTypeStr, 'UDP')
            tlInstanceData = xcp.blkForwarding.utils.importTLInstanceData;
            try
                tlMap = containers.Map({tlInstanceData.Name}, {tlInstanceData.Value});
                addKeys = {'SampleTime','headerErrDet','CTRScheme','SampleTime'};
                for i = 1:length(addKeys)
                    if(isKey(tlMap,addKeys{i}))
                        newDataMap(addKeys{i}) = tlMap(addKeys{i});
                    end
                end
            catch
                %Just in case something went wront with the import of
                %tlInstanceData.  Examples include:
                %1) There were no TL blocks in the model and TLInstanceData is
                %empty
                %2) There already existed a UDP configure block and the
                %user added persistent user data there.  When we search for the
                %configure blocks, we grab the wrong one and parsing the
                %data results in an error. It seems unnecessary to fully
                %woraround such edge cases. 
                newDataMap('SampleTime') = '-1';
            end
        end

    case 'xcpprotocollib/XCP Data Acquisition'
        tlTypeStr = xcp.blkForwarding.utils.getTLTypeStr;
        outData.NewBlockPath = ['xcpprotocollib/',tlTypeStr,'/XCP ',tlTypeStr,' Data Acquisition'];
        if (isKey(newDataMap, 'FileName'))
            newDataMap('A2LFile') = newDataMap('FileName');
            remove(newDataMap,'FileName');
        end
    case 'xcpprotocollib/XCP Data Stimulation'
        tlTypeStr = xcp.blkForwarding.utils.getTLTypeStr;
        outData.NewBlockPath = ['xcpprotocollib/',tlTypeStr,'/XCP ',tlTypeStr,' Data Stimulation'];
        if (isKey(newDataMap, 'FileName'))
            newDataMap('A2LFile') = newDataMap('FileName');
            remove(newDataMap,'FileName');
        end
    otherwise
        assert(false,'Internal Error - Invalid Use Case - XCP Block Forwarding');
end

%Reassemble as a struct array:        
Names = keys(newDataMap);
Values = values(newDataMap);
if ~isempty(Names)
    outData.NewInstanceData = cell2struct({Names{:};Values{:}},{'Name','Value'},1);
else
    outData.NewInstanceData = [];
end

end
