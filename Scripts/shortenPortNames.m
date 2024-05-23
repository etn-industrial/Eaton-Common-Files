function shortenPortNames
% shortenPortNames Remove duplicated strings from port names when creating
% a Simulink model from an SwC ARXML

H = gcs;
modelPorts = find_system(H, 'LookUnderMasks', 'on','SearchDepth',2,'BlockType', 'Inport');
modelPorts = cat(1,modelPorts,find_system(H, 'LookUnderMasks', 'on','SearchDepth',2,'BlockType', 'Outport'));
modelPortsName = get_param(modelPorts,'Name');

arProps = autosar.api.getAUTOSARProperties(H);
aswcPath = find(arProps,[],'AtomicComponent','PathType','FullyQualified');
SWCPorts=find(arProps,aswcPath{1},'Port','PathType','FullyQualified');

for ii = 1:length(SWCPorts)
    SWCPortsName{ii} = get(arProps,SWCPorts{ii},'Name');
    for jj = 1:length(modelPortsName)
        if startsWith(modelPortsName{jj},[SWCPortsName{ii},'_'])
          set_param(modelPorts{jj},'Name',SWCPortsName{ii});
        end
    end
end