function ImplDT = createDT(docNode,DEName,BaseType)
    if strcmp(BaseType,'int8')
        basetype = 'sint8';
    elseif strcmp(BaseType,'int16')
        basetype = 'sint16';
    elseif strcmp(BaseType,'int32')
        basetype = 'sint32';
    else
        basetype = BaseType;
    end
    ImplDT = docNode.createElement('IMPLEMENTATION-DATA-TYPE');
    ImplDT.setAttribute('UUID',string(java.util.UUID.randomUUID));
    ImplDTName = docNode.createElement('SHORT-NAME');
    ImplDTName.appendChild(docNode.createTextNode(['DT_',DEName]));
    ImplDTCategory = docNode.createElement('CATEGORY');
    ImplDTCategory.appendChild(docNode.createTextNode('TYPE_REFERENCE'));
    
    ImplDTSwDataDefProps = docNode.createElement('SW-DATA-DEF-PROPS');
    ImplDTSwDataDefPropsVariants = docNode.createElement('SW-DATA-DEF-PROPS-VARIANTS');
    ImplDTSwDataDefPropsCond = docNode.createElement('SW-DATA-DEF-PROPS-CONDITIONAL');
    ImplDTTypeRef = docNode.createElement('IMPLEMENTATION-DATA-TYPE-REF');
    ImplDTTypeRef.setAttribute('DEST',"IMPLEMENTATION-DATA-TYPE");
    ImplDTTypeRef.appendChild(docNode.createTextNode(['/AUTOSAR/Platform/ImplementationDataTypes/',basetype]));

    ImplDT.appendChild(ImplDTName);
    ImplDT.appendChild(ImplDTCategory);
    ImplDT.appendChild(ImplDTSwDataDefProps);
    ImplDTSwDataDefProps.appendChild(ImplDTSwDataDefPropsVariants);
    ImplDTSwDataDefPropsVariants.appendChild(ImplDTSwDataDefPropsCond);
    ImplDTSwDataDefPropsCond.appendChild(ImplDTTypeRef);
end