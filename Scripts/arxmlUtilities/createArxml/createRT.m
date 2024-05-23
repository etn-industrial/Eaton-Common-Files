function RT = createRT(docNode,DEName)
    RT = docNode.createElement('IMPLEMENTATION-DATA-TYPE');
    RT.setAttribute('UUID',string(java.util.UUID.randomUUID));
    RTName = docNode.createElement('SHORT-NAME');
    RTName.appendChild(docNode.createTextNode(['RT_',DEName]));
    RTCategory = docNode.createElement('CATEGORY');
    RTCategory.appendChild(docNode.createTextNode('STRUCTURE'));
    
    RTSwDataDefProps = docNode.createElement('SW-DATA-DEF-PROPS');
    RTSwDataDefPropsVariants = docNode.createElement('SW-DATA-DEF-PROPS-VARIANTS');
    RTSwDataDefPropsCond = docNode.createElement('SW-DATA-DEF-PROPS-CONDITIONAL');

    RT.appendChild(RTName);
    RT.appendChild(RTCategory);
    RT.appendChild(RTSwDataDefProps);
    RTSwDataDefProps.appendChild(RTSwDataDefPropsVariants);
    RTSwDataDefPropsVariants.appendChild(RTSwDataDefPropsCond);
end