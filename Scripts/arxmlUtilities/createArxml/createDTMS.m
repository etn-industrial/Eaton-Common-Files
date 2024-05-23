function DTMS = createDTMS(docNode,DEName,isBus)
    DTMS = docNode.createElement('DATA-TYPE-MAPPING-SET');
    DTMS.setAttribute('UUID',string(java.util.UUID.randomUUID));
    DTMSName = docNode.createElement('SHORT-NAME');
    if isBus
        DTMSName.appendChild(docNode.createTextNode(['DTMS_ARDT_',DEName]));
    else
        DTMSName.appendChild(docNode.createTextNode(['DTMS_APDT_',DEName]));
    end
    DTMapsNode = docNode.createElement('DATA-TYPE-MAPS');
    DTMapSubNode = docNode.createElement('DATA-TYPE-MAP');
    
    APDTRef = docNode.createElement('APPLICATION-DATA-TYPE-REF');
    if isBus
        APDTRef.setAttribute('DEST',"APPLICATION-RECORD-DATA-TYPE");
        APDTRef.appendChild(docNode.createTextNode(['/Interfaces/DataTypes/ApplicationDataTypes/ARDT_',DEName]));
    else
        APDTRef.setAttribute('DEST',"APPLICATION-PRIMITIVE-DATA-TYPE");
        APDTRef.appendChild(docNode.createTextNode(['/Interfaces/DataTypes/ApplicationDataTypes/APDT_',DEName]));
    end
    ImpDTRef = docNode.createElement('IMPLEMENTATION-DATA-TYPE-REF');
    ImpDTRef.setAttribute('DEST',"IMPLEMENTATION-DATA-TYPE");
    if isBus
        ImpDTRef.appendChild(docNode.createTextNode(['/Interfaces/DataTypes/ImplementationDataTypes/RT_',DEName]));
    else
        ImpDTRef.appendChild(docNode.createTextNode(['/Interfaces/DataTypes/ImplementationDataTypes/DT_',DEName]));
    end
    DTMS.appendChild(DTMSName);
    DTMS.appendChild(DTMapsNode);
    DTMapsNode.appendChild(DTMapSubNode);
    DTMapSubNode.appendChild(APDTRef);
    DTMapSubNode.appendChild(ImpDTRef);
end