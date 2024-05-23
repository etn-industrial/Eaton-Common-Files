function CompuMethod = createCM(docNode,DEName,CMCategory,CMUnit,EnumValue,EnumElements)
    CompuMethod = docNode.createElement('COMPU-METHOD');
    CompuMethod.setAttribute('UUID',string(java.util.UUID.randomUUID));
    CompuMethodName = docNode.createElement('SHORT-NAME');
    CompuMethodName.appendChild(docNode.createTextNode(['CM_',DEName]));
    CompuMethodCategory = docNode.createElement('CATEGORY');
    CompuMethodCategory.appendChild(docNode.createTextNode(CMCategory));
    CompuMethodUnitRef = docNode.createElement('UNIT-REF');
    CompuMethodUnitRef.setAttribute('DEST',"UNIT");
    CompuMethodUnitRef.appendChild(docNode.createTextNode(['/Units_Package/',CMUnit]));
    
    CompuMethod.appendChild(CompuMethodName);
    CompuMethod.appendChild(CompuMethodCategory);
    CompuMethod.appendChild(CompuMethodUnitRef);
    if strcmp(CMCategory,'TEXTTABLE')
        CompuInternalToPhys = docNode.createElement('COMPU-INTERNAL-TO-PHYS');
        CompuScales = docNode.createElement('COMPU-SCALES');
        for ii=1:length(EnumElements)
            if ~isempty(str2num(EnumValue{ii}))
                ElementCompuScale = docNode.createElement('COMPU-SCALE');
                LowerLimit = docNode.createElement('LOWER-LIMIT');
                %LowerLimit.setAttribute('INTERVAL-TYPE',"CLOSED");
                LowerLimit.appendChild(docNode.createTextNode(EnumValue{ii}));                  
                UpperLimit = docNode.createElement('UPPER-LIMIT');
                %UpperLimit.setAttribute('INTERVAL-TYPE',"CLOSED");
                UpperLimit.appendChild(docNode.createTextNode(EnumValue{ii}));
                CMElement = docNode.createElement('COMPU-CONST');
                CMElementName = docNode.createElement('VT');
                CMElementName.appendChild(docNode.createTextNode(strcat(DEName,...
                                                                   '_',EnumElements{ii}))); 
                CompuScales.appendChild(ElementCompuScale);
                ElementCompuScale.appendChild(LowerLimit); 
                ElementCompuScale.appendChild(UpperLimit);
                ElementCompuScale.appendChild(CMElement);
                CMElement.appendChild(CMElementName);
            else
                error([char(EnumValue{ii}),' from:',[' CM_',DEName],' is not a valid enumeration value']);
            end
        end
        CompuInternalToPhys.appendChild(CompuScales);
        CompuMethod.appendChild(CompuInternalToPhys);
    end
    

end