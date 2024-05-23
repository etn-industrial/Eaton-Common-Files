function SRIF = createSRIF(docNode,DEName,isBus)
    SRIF = docNode.createElement('SENDER-RECEIVER-INTERFACE');
    SRIF.setAttribute('UUID',string(java.util.UUID.randomUUID));
    SRIFName = docNode.createElement('SHORT-NAME');
    SRIFName.appendChild(docNode.createTextNode(['IF_',DEName]));
    SRIFIsService = docNode.createElement('IS-SERVICE');
    SRIFIsService.appendChild(docNode.createTextNode('false'));
    SRIF_DE = docNode.createElement('DATA-ELEMENTS');
    
    SRIFVarDataPrototype = docNode.createElement('VARIABLE-DATA-PROTOTYPE');
    SRIFVarDataPrototype.setAttribute('UUID',string(java.util.UUID.randomUUID));
    SRIF_DEName = docNode.createElement('SHORT-NAME');
    SRIF_DEName.appendChild(docNode.createTextNode(DEName));
    SRIF_DESwDataDefProps = docNode.createElement('SW-DATA-DEF-PROPS');
    SRIF_DESwDataDefPropsVariants = docNode.createElement('SW-DATA-DEF-PROPS-VARIANTS');
    SRIF_DESwDataDefPropsCond = docNode.createElement('SW-DATA-DEF-PROPS-CONDITIONAL');
    SRIF_DECalAccess = docNode.createElement('SW-CALIBRATION-ACCESS');
    SRIF_DECalAccess.appendChild(docNode.createTextNode('READ-ONLY'));
    SRIF_DESwImplPolicy = docNode.createElement('SW-IMPL-POLICY');
    SRIF_DESwImplPolicy.appendChild(docNode.createTextNode('STANDARD'));
    SRIF_DETypeRef = docNode.createElement('TYPE-TREF');
    if isBus
        SRIF_DETypeRef.setAttribute('DEST',"APPLICATION-RECORD-DATA-TYPE");
        SRIF_DETypeRef.appendChild(docNode.createTextNode(['/Interfaces/DataTypes/ApplicationDataTypes/ARDT_',DEName]));
    else
        SRIF_DETypeRef.setAttribute('DEST',"APPLICATION-PRIMITIVE-DATA-TYPE");
        SRIF_DETypeRef.appendChild(docNode.createTextNode(['/Interfaces/DataTypes/ApplicationDataTypes/APDT_',DEName]));
    end
    SRIF_DEIV = docNode.createElement('INIT-VALUE');
    SRIF_DEConstantRefNode = docNode.createElement('CONSTANT-REFERENCE');
    SRIF_DEConstantRefSubNode = docNode.createElement('CONSTANT-REF');
    SRIF_DEConstantRefSubNode.setAttribute('DEST',"CONSTANT-SPECIFICATION");
    SRIF_DEConstantRefSubNode.appendChild(docNode.createTextNode(['/Interfaces/SenderReceiverInitValues/IV_',DEName]));
    
    SRIF.appendChild(SRIFName);
    SRIF.appendChild(SRIFIsService);
    SRIF.appendChild(SRIF_DE);
    SRIF_DE.appendChild(SRIFVarDataPrototype);
    SRIFVarDataPrototype.appendChild(SRIF_DEName);
    SRIFVarDataPrototype.appendChild(SRIF_DESwDataDefProps);
    SRIF_DESwDataDefProps.appendChild(SRIF_DESwDataDefPropsVariants);
    SRIF_DESwDataDefPropsVariants.appendChild(SRIF_DESwDataDefPropsCond);
    SRIF_DESwDataDefPropsCond.appendChild(SRIF_DECalAccess);
    SRIF_DESwDataDefPropsCond.appendChild(SRIF_DESwImplPolicy);
    SRIFVarDataPrototype.appendChild(SRIF_DETypeRef);
    SRIFVarDataPrototype.appendChild(SRIF_DEIV);
    SRIF_DEIV.appendChild(SRIF_DEConstantRefNode);
    SRIF_DEConstantRefNode.appendChild(SRIF_DEConstantRefSubNode);
    
end