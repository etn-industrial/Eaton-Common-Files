function [APDT,APDTDC ]= createAPDT(docNode,DEName,Description,MinVal,MaxVal,CMCategory)
    %APDT Element Node Definition
    APDT = docNode.createElement('APPLICATION-PRIMITIVE-DATA-TYPE');
    %APDT.setAttribute('UUID',string(java.util.UUID.randomUUID));
    APDT.setAttribute('UUID',string(java.util.UUID.randomUUID));
    APDTName = docNode.createElement('SHORT-NAME');
    APDTName.appendChild(docNode.createTextNode(['APDT_',DEName]));
    APDTDesc = docNode.createElement('DESC');
    APDTDescText = docNode.createElement('L-2');
    APDTDescText.setAttribute('L',"FOR-ALL");    
    APDTDescText.appendChild(docNode.createTextNode(Description));
    APDTCategory = docNode.createElement('CATEGORY');
    APDTCategory.appendChild(docNode.createTextNode('VALUE'));
    
    APDTSwDataDefProps = docNode.createElement('SW-DATA-DEF-PROPS');
    APDTSwDataDefPropsVariants = docNode.createElement('SW-DATA-DEF-PROPS-VARIANTS');
    APDTSwDataDefPropsCond = docNode.createElement('SW-DATA-DEF-PROPS-CONDITIONAL');
    APDTCMRef = docNode.createElement('COMPU-METHOD-REF');
    APDTCMRef.setAttribute('DEST',"COMPU-METHOD");    
    APDTCMRef.appendChild(docNode.createTextNode(['/Interfaces/CompuMethods/','CM_',DEName]));    
    APDTDCRef = docNode.createElement('DATA-CONSTR-REF');
    APDTDCRef.setAttribute('DEST',"DATA-CONSTR");    
    APDTDCRef.appendChild(docNode.createTextNode(['/Interfaces/DataTypes/ApplicationDataTypes/','APDT_',DEName,'_DC']));    
    
    APDT.appendChild(APDTName);
    APDT.appendChild(APDTDesc);
    APDTDesc.appendChild(APDTDescText);
    APDT.appendChild(APDTCategory);
    APDT.appendChild(APDTSwDataDefProps);
    APDTSwDataDefProps.appendChild(APDTSwDataDefPropsVariants);
    APDTSwDataDefPropsVariants.appendChild(APDTSwDataDefPropsCond);
    APDTSwDataDefPropsCond.appendChild(APDTCMRef);
    APDTSwDataDefPropsCond.appendChild(APDTDCRef);
    
    %APDTDC Element Node Definition    
    APDTDC = docNode.createElement('DATA-CONSTR');
    APDTDC.setAttribute('UUID',string(java.util.UUID.randomUUID));
    APDTDCName = docNode.createElement('SHORT-NAME');
    APDTDCName.appendChild(docNode.createTextNode(['APDT_',DEName,'_DC']));
    APDTDCRules = docNode.createElement('DATA-CONSTR-RULES');
    DCRule = docNode.createElement('DATA-CONSTR-RULE');
    ConstraintLevel = docNode.createElement('CONSTR-LEVEL');
    ConstraintLevel.appendChild(docNode.createTextNode('0'));
    if strcmp(CMCategory,'IDENTICAL')
        DCPhysConstraint = docNode.createElement('PHYS-CONSTRS');
    else
        DCPhysConstraint = docNode.createElement('INTERNAL-CONSTRS');
    end
    DCLowerLimit = docNode.createElement('LOWER-LIMIT');
    DCLowerLimit.appendChild(docNode.createTextNode(MinVal));
    DCUpperLimit = docNode.createElement('UPPER-LIMIT');
    DCUpperLimit.appendChild(docNode.createTextNode(MaxVal));
    
    APDTDC.appendChild(APDTDCName);
    APDTDC.appendChild(APDTDCRules);
    APDTDCRules.appendChild(DCRule);
    DCRule.appendChild(ConstraintLevel);
    DCRule.appendChild(DCPhysConstraint);
    DCPhysConstraint.appendChild(DCLowerLimit);
    DCPhysConstraint.appendChild(DCUpperLimit);
end