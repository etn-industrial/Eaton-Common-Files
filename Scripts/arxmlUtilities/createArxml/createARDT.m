function ARDT = createARDT(docNode,DEName,Description)
   %ARDT Element Node Definition
   ARDT = docNode.createElement('APPLICATION-RECORD-DATA-TYPE');
   ARDT.setAttribute('UUID',string(java.util.UUID.randomUUID));
   ARDTName = docNode.createElement('SHORT-NAME');
   ARDTName.appendChild(docNode.createTextNode(['ARDT_',DEName]));
   ARDTDesc = docNode.createElement('DESC');
   ARDTDescText = docNode.createElement('L-2');
   ARDTDescText.setAttribute('L',"FOR-ALL");    
   ARDTDescText.appendChild(docNode.createTextNode(Description));
   ARDTCategory = docNode.createElement('CATEGORY');
   ARDTCategory.appendChild(docNode.createTextNode('STRUCTURE'));

   ARDT.appendChild(ARDTName);
   ARDT.appendChild(ARDTDesc);
   ARDTDesc.appendChild(ARDTDescText);
   ARDT.appendChild(ARDTCategory);
end
   
