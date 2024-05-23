function ConstantSpec = createIV(docNode,DEName,IVValue,IVUnit,isBus)
    
    ConstantSpec = docNode.createElement('CONSTANT-SPECIFICATION');
    ConstantSpec.setAttribute('UUID',string(java.util.UUID.randomUUID));
    ConstantName = docNode.createElement('SHORT-NAME');
    ConstantName.appendChild(docNode.createTextNode(['IV_',DEName]));
    ConstantCategory = docNode.createElement('CATEGORY');
    ConstantCategory.appendChild(docNode.createTextNode('VALUE'));
    
    if ~isBus
        ConstantValueSpec = docNode.createElement('VALUE-SPEC');
        ConstantAPPValueSpec = docNode.createElement('APPLICATION-VALUE-SPECIFICATION');
        ConstantAPPValueSpecCat = docNode.createElement('CATEGORY');
        ConstantAPPValueSpecCat.appendChild(docNode.createTextNode('VALUE'));
        ConstantSwValueCont = docNode.createElement('SW-VALUE-CONT');
        ConstantUnitRef = docNode.createElement('UNIT-REF');
        ConstantUnitRef.setAttribute('DEST',"UNIT");
        ConstantUnitRef.appendChild(docNode.createTextNode(['/Units_Package/',IVUnit]));
        ConstantSwValuePhys = docNode.createElement('SW-VALUES-PHYS');
        ConstantValue= docNode.createElement('V');
        ConstantValue.appendChild(docNode.createTextNode(IVValue));
    end
    
    ConstantSpec.appendChild(ConstantName);
    ConstantSpec.appendChild(ConstantCategory);

    if ~isBus
        ConstantSpec.appendChild(ConstantValueSpec);
        ConstantValueSpec.appendChild(ConstantAPPValueSpec);
        ConstantAPPValueSpec.appendChild(ConstantAPPValueSpecCat);
        ConstantAPPValueSpec.appendChild(ConstantSwValueCont);
        ConstantSwValueCont.appendChild(ConstantUnitRef);
        ConstantSwValueCont.appendChild(ConstantSwValuePhys);
        ConstantSwValuePhys.appendChild(ConstantValue);
    end
end