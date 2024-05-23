function createSenderReceiverInterfaces()
    %Single SWC Mode execution
    [file,Path] = uigetfile('*.xlsx','Select Excel file','MultiSelect', 'off');
    if isequal(file,0) || isequal(Path,0)
    %Do nothing , no file selected
    else
        rootFolder = fileparts(which(mfilename));
        cd(rootFolder);
        docNode = com.mathworks.xml.XMLUtils.createDocument('AUTOSAR');
        Root = docNode.getDocumentElement;
        Root.setAttribute('xmlns:xsi',"http://www.w3.org/2001/XMLSchema-instance");
        Root.setAttribute('xmlns',"http://autosar.org/schema/r4.0");
        Root.setAttribute('xsi:schemaLocation', "http://autosar.org/schema/r4.0 AUTOSAR_4-2-2.xsd");

        [NUM,TXT,RAW]=xlsread(fullfile(Path,file));
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Top Nodes %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        [FoundDE DERowIdx DECOlIdx]= findString(RAW,'S-R Inputs DataElementName');
        [FoundUnits UnitRowIdx UnitCOlIdx]= findString(RAW,'Units');
        [FoundIV IVRowIdx IVCOlIdx]= findString(RAW,'Initial Value');
        [FoundCMType CMTypeRowIdx CMTypeCOlIdx]= findString(RAW,'CompuMethod Type');
        [FoundDTType DTTypeRowIdx DTTypeCOlIdx]= findString(RAW,'DataType');
        [FoundDesc DescRowIdx DescCOlIdx]= findString(RAW,'Description');
        [FoundMinVal MinValRowIdx MinValCOlIdx]= findString(RAW,'Min');
        [FoundMaxVal MaxValRowIdx MaxValCOlIdx]= findString(RAW,'Max');
        [FoundAPDT APDTRowIdx APDTCOlIdx]= findString(RAW,'Application DT Name');
        [FoundDT DTRowIdx DTCOlIdx]= findString(RAW,'Implementation DT Name');
        [FoundIVName IVNameRowIdx IVNameCOlIdx]= findString(RAW,'Init Value Name');
        
        if ~FoundDE error('Not found ''S-R Inputs DataElementName'' column');
        elseif ~FoundUnits error('Not found ''Units'' column');
        elseif ~FoundIV error('Not found ''Initial Value'' column');
        elseif ~FoundCMType error('Not found ''CompuMethod Type'' column');
        elseif ~FoundDTType error('Not found ''DataType'' column');
        elseif ~FoundDesc error('Not found ''Description'' column');
        elseif ~FoundMinVal error('Not found ''Min'' column');
        elseif ~FoundMaxVal error('Not found ''Max'' column');
        elseif ~FoundAPDT error('Not found ''Application DT Name'' column');
        elseif ~FoundDT error('Not found ''Implementation DT Name'' column');
        elseif ~FoundIVName error('Not found ''Init Value Name'' column');
        else
        end
        
        [Rows,Cols]=size(RAW);
        InverterProjectNode = docNode.createElement('AR-PACKAGES');
        TopNode = docNode.createElement('AR-PACKAGE');
        IFFolderName = docNode.createElement('SHORT-NAME');
        IFFolderName.appendChild(docNode.createTextNode('Interfaces'));
        TopNode.appendChild(IFFolderName);
        IFFolderNode = docNode.createElement('AR-PACKAGES');

%         %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% COMPU METHODS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%         CompuMethodsFolderNode = docNode.createElement('AR-PACKAGE');
%         CompuMethodsFolderName = docNode.createElement('SHORT-NAME');
%         CompuMethodsFolderName.appendChild(docNode.createTextNode('CompuMethods'));
%         CompuMethodsElements = docNode.createElement('ELEMENTS');
% 
%         for i = 1:Rows-1
%             EnumElement = {};
%             EnumValue = {};
%             if ~isempty(RAW{min(DERowIdx+i,Rows),DECOlIdx})
%                 if strcmp(erase(RAW{min(DERowIdx+i,Rows),CMTypeCOlIdx},' '),'IDENTICAL')
%                     CompuMethodNode = createCM(docNode,eraseUnicodesCharacter(RAW{min(DERowIdx+i,Rows),DECOlIdx}),...
%                                 RAW{min(DERowIdx+i,Rows),CMTypeCOlIdx},RAW{min(DERowIdx+i,Rows),UnitCOlIdx},EnumValue,EnumElement);
%                     CompuMethodsElements.appendChild(CompuMethodNode);
%                 else
%                     
%                     [EnumValue,EnumElement]= getEnumFromCM(RAW{min(DERowIdx+i,Rows),CMTypeCOlIdx});
%                         CompuMethodNode = createCM(docNode,eraseUnicodesCharacter(RAW{min(DERowIdx+i,Rows),DECOlIdx}),...
%                                     'TEXTTABLE',RAW{min(DERowIdx+i,Rows),UnitCOlIdx},EnumValue,EnumElement);
%                     CompuMethodsElements.appendChild(CompuMethodNode);
%                 end
%             end
%         end
% 
% 
%         CompuMethodsFolderNode.appendChild(CompuMethodsFolderName);
%         CompuMethodsFolderNode.appendChild(CompuMethodsElements);
% 
        % %%%%%%%%%%%%%%%%%%%%%%%%%%% APPLICATION DATATYPES %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        DatatypesFolderNode = docNode.createElement('AR-PACKAGE');
        %DTSubNode = docNode.createElement('AR-PACKAGE');
        DatatypesFolderName = docNode.createElement('SHORT-NAME');
        DatatypesFolderName.appendChild(docNode.createTextNode('DataTypes'));
        DatatypesSubFolderNode = docNode.createElement('AR-PACKAGES');
        ARDTFolderNode = docNode.createElement('AR-PACKAGE');
        ARDTFolderName = docNode.createElement('SHORT-NAME');
        ARDTFolderName.appendChild(docNode.createTextNode('ApplicationDataTypes'));
        ARDTElements = docNode.createElement('ELEMENTS');
        
        for i = 1:Rows-1
            DEName = eraseUnicodesCharacter(RAW{min(DERowIdx+i,Rows),DECOlIdx});
            Description = RAW{min(DERowIdx+i,Rows),DescCOlIdx};
            Datatype = eraseUnicodesCharacter(RAW{min(DERowIdx+i,Rows),DTTypeCOlIdx});
            if ~isempty(DEName)&& strcmp(Datatype,'Bus')
                ARDT = createARDT(docNode,DEName,Description);
                ARDTSubElements = docNode.createElement('ELEMENTS');
            elseif ~isempty(DEName)
                APDTName = eraseUnicodesCharacter(RAW{min(DERowIdx+i,Rows),APDTCOlIdx});
                if contains(APDTName,'APDT_DEMEventStatus')
                    APDTName = 'APDT_DEMEventStatus';
                elseif contains(APDTName,'APDT_DEMPreFF')
                    APDTName = 'APDT_DEMPreFF';
                else
                end
               AppRecordElement = createARDTElements(docNode,DEName,APDTName);
               ARDTSubElements.appendChild(AppRecordElement);
               
            else
            end
        end
        ARDT.appendChild(ARDTSubElements);
        ARDTElements.appendChild(ARDT);
        
        DatatypesFolderNode.appendChild(DatatypesFolderName);
        DatatypesFolderNode.appendChild(DatatypesSubFolderNode);
        DatatypesSubFolderNode.appendChild(ARDTFolderNode);
        ARDTFolderNode.appendChild(ARDTFolderName);
        ARDTFolderNode.appendChild(ARDTElements);
        %%%%%%%%%%%%%%%%%%%%%%%%%%%% DATATYPE MAPPING SET %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        DTMSFolderNode = docNode.createElement('AR-PACKAGE');
        DTMSFolderName = docNode.createElement('SHORT-NAME');
        DTMSFolderName.appendChild(docNode.createTextNode('DataTypeMappingSets'));
        DTMSElements = docNode.createElement('ELEMENTS');
        
        for i = 1:Rows-1
            DEName = eraseUnicodesCharacter(RAW{min(DERowIdx+i,Rows),DECOlIdx});
            Datatype = eraseUnicodesCharacter(RAW{min(DERowIdx+i,Rows),DTTypeCOlIdx});
            if ~isempty(DEName)&& strcmp(Datatype,'Bus')            
                DTMS = createDTMS(docNode,eraseUnicodesCharacter(RAW{min(DERowIdx+i,Rows),DECOlIdx}),true);
                DTMSElements.appendChild(DTMS);
            else
            end
        end

        DatatypesSubFolderNode.appendChild(DTMSFolderNode);
        DTMSFolderNode.appendChild(DTMSFolderName);
        DTMSFolderNode.appendChild(DTMSElements);

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% IMPLEMENTATION DATATYPES %%%%%%%%%%%%%%%%%%%%%%%%%
        DTFolderNode = docNode.createElement('AR-PACKAGE');
        DTFolderName = docNode.createElement('SHORT-NAME');
        DTFolderName.appendChild(docNode.createTextNode('ImplementationDataTypes'));
        
        RTElements = docNode.createElement('ELEMENTS');
        for i = 1:Rows-1
            DEName = eraseUnicodesCharacter(RAW{min(DERowIdx+i,Rows),DECOlIdx});
            Description = RAW{min(DERowIdx+i,Rows),DescCOlIdx};
            Datatype = eraseUnicodesCharacter(RAW{min(DERowIdx+i,Rows),DTTypeCOlIdx});
           
            if ~isempty(DEName)&& strcmp(Datatype,'Bus')
                RT = createRT(docNode,DEName);
                RTSubElements = docNode.createElement('SUB-ELEMENTS');
            elseif ~isempty(DEName)
                DTName = eraseUnicodesCharacter(RAW{min(DERowIdx+i,Rows),DTCOlIdx});
                if contains(DTName,'APDT_DEMEventStatus')
                    DTName = 'DT_DEMEventStatus';
                elseif contains(DTName,'APDT_DEMPreFF')
                    DTName = 'DT_DEMPreFF';
                else
                end
                RTSubSubElements = createRTElements(docNode,DEName,DTName);
                RTSubElements.appendChild(RTSubSubElements);
            else
            end
        end
        RT.appendChild(RTSubElements);
        RTElements.appendChild(RT);

        DatatypesSubFolderNode.appendChild(DTFolderNode);
        DTFolderNode.appendChild(DTFolderName);
        DTFolderNode.appendChild(RTElements);
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% INITIAL VALUES %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        IVFolderNode = docNode.createElement('AR-PACKAGE');
        %IVSubNode = docNode.createElement('AR-PACKAGE');
        IVFolderName = docNode.createElement('SHORT-NAME');
        IVFolderName.appendChild(docNode.createTextNode('SenderReceiverInitValues'));
        IVElements = docNode.createElement('ELEMENTS');

        for i = 1:Rows-1
            DEName = eraseUnicodesCharacter(RAW{min(DERowIdx+i,Rows),DECOlIdx});
            DEUnits = eraseUnicodesCharacter(RAW{min(DERowIdx+i,Rows),UnitCOlIdx});
            Datatype = eraseUnicodesCharacter(RAW{min(DERowIdx+i,Rows),DTTypeCOlIdx});
            
            if ~isempty(DEName)&& strcmp(Datatype,'Bus')
                ConstantSpec = createIV(docNode,DEName,'0',DEUnits,true);
                ConstantValueSpec = docNode.createElement('VALUE-SPEC');
                ConstantAPPValueSpec = docNode.createElement('RECORD-VALUE-SPECIFICATION');
                IVFields = docNode.createElement('FIELDS');
            elseif ~isempty(DEName)
                IVName = eraseUnicodesCharacter(RAW{min(DERowIdx+i,Rows),IVNameCOlIdx});
                if contains(IVName,'APDT_DEMEventStatus')
                    IVName = 'IV_DEMEventStatus';
                elseif contains(IVName,'APDT_DEMPreFF')
                    IVName = 'IV_DEMPreFF';
                else
                end
                IVSubFields = createIVSubFields(docNode,DEName,IVName);
                IVFields.appendChild(IVSubFields);
            else
            end
        end
        ConstantSpec.appendChild(ConstantValueSpec);
        ConstantValueSpec.appendChild(ConstantAPPValueSpec);
        ConstantAPPValueSpec.appendChild(IVFields);
        IVElements.appendChild(ConstantSpec);
        IVFolderNode.appendChild(IVFolderName);
        IVFolderNode.appendChild(IVElements);

        %%%%%%%%%%%%%%%%%%%%%%%%% SENDER-RECEIVER INTERFACES %%%%%%%%%%%%%%%%%%%%%%%%%%%%
        SRIFFolderNode = docNode.createElement('AR-PACKAGE');
        SRIFFolderName = docNode.createElement('SHORT-NAME');
        SRIFFolderName.appendChild(docNode.createTextNode('SenderReceiverInterfaces'));
        SRIFElements = docNode.createElement('ELEMENTS');
        for i = 1:Rows-1
            DEName = eraseUnicodesCharacter(RAW{min(DERowIdx+i,Rows),DECOlIdx});
            Datatype = eraseUnicodesCharacter(RAW{min(DERowIdx+i,Rows),DTTypeCOlIdx});
            if ~isempty(DEName)&& strcmp(Datatype,'Bus')
                SRIF = createSRIF(docNode,DEName,true);
                SRIFElements.appendChild(SRIF);
            else
            end
        end

        SRIFFolderNode.appendChild(SRIFFolderName);
        SRIFFolderNode.appendChild(SRIFElements);

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        Root.appendChild(InverterProjectNode);
        InverterProjectNode.appendChild(TopNode);
        TopNode.appendChild(IFFolderNode);
        %IFFolderNode.appendChild(CompuMethodsFolderNode);
        IFFolderNode.appendChild(DatatypesFolderNode);
        IFFolderNode.appendChild(IVFolderNode);
        IFFolderNode.appendChild(SRIFFolderNode);
        xmlwrite('SR_StructureInterface.arxml',docNode);
    end

function [found x y]= findString(data,strtofind)
    %Get the size of the data
    [NumRows NumColumns]=size(data);
    found = false;
    %Look for the string in the data
    for x = 1: NumRows
        for y = 1: NumColumns
            if strcmp(data(x,y),strtofind)
                 found = true;
                 return
                 end
            end
    end

function [EnumValue,EnumElement]= getEnumFromCM(CMTxt)
    EnumTxt = strsplit(CMTxt,'\n');
    elementCount = 0;
    for ii=2:length(EnumTxt)
        if  ~isempty(EnumTxt{ii})||~strcmp(EnumTxt{ii},"")||length(EnumTxt{ii}) > 0
            elementCount = elementCount +1;
            EnumValue{elementCount} = string(erase(extractBefore(EnumTxt{ii},'='),' '));
            EnumElement{elementCount} = string(erase(extractAfter(EnumTxt{ii},'='),' '));
        end
    end
    
    
function newText = eraseUnicodesCharacter(text)
    newText = char(regexprep(string(text),'[^a-zA-Z0-9._%]',''));


function AppRecordElement = createARDTElements(docNode,DEName,APDTName)
    AppRecordElement = docNode.createElement('APPLICATION-RECORD-ELEMENT');
    AppRecordElement.setAttribute('UUID',string(java.util.UUID.randomUUID));
    AppRecordElementName = docNode.createElement('SHORT-NAME');
    AppRecordElementName.appendChild(docNode.createTextNode(DEName));
    AppRecordElemenTypeRef = docNode.createElement('TYPE-TREF');
    AppRecordElemenTypeRef.setAttribute('DEST',"APPLICATION-PRIMITIVE-DATA-TYPE");
    AppRecordElemenTypeRef.appendChild(docNode.createTextNode(['/Interfaces/DataTypes/ApplicationDataTypes/',APDTName]));

    AppRecordElement.appendChild(AppRecordElementName);
    AppRecordElement.appendChild(AppRecordElemenTypeRef);
    
function RTSubElement = createRTElements(docNode,DEName,DTName)
    RTSubElement = docNode.createElement('IMPLEMENTATION-DATA-TYPE-ELEMENT');
    RTSubElement.setAttribute('UUID',string(java.util.UUID.randomUUID));
    RTSubElementName = docNode.createElement('SHORT-NAME');
    RTSubElementName.appendChild(docNode.createTextNode(DEName));
    RTSubElementCategory = docNode.createElement('CATEGORY');
    RTSubElementCategory.appendChild(docNode.createTextNode('TYPE_REFERENCE'));
   
    RTSubElementSwDataDefProps = docNode.createElement('SW-DATA-DEF-PROPS');
    RTSubElementSwDataDefPropsVariants = docNode.createElement('SW-DATA-DEF-PROPS-VARIANTS');
    RTSubElementSwDataDefPropsCond = docNode.createElement('SW-DATA-DEF-PROPS-CONDITIONAL');
    RTSubElementTypeRef = docNode.createElement('IMPLEMENTATION-DATA-TYPE-REF');
    RTSubElementTypeRef.setAttribute('DEST',"IMPLEMENTATION-DATA-TYPE");
    RTSubElementTypeRef.appendChild(docNode.createTextNode(['/Interfaces/DataTypes/ImplementationDataTypes/',DTName]));

    RTSubElement.appendChild(RTSubElementName);
    RTSubElement.appendChild(RTSubElementCategory);
    RTSubElement.appendChild(RTSubElementSwDataDefProps);
    RTSubElementSwDataDefProps.appendChild(RTSubElementSwDataDefPropsVariants);
    RTSubElementSwDataDefPropsVariants.appendChild(RTSubElementSwDataDefPropsCond);
    RTSubElementSwDataDefPropsCond.appendChild(RTSubElementTypeRef);

    
function IVSubFields = createIVSubFields(docNode,DEName,IVName)
    IVSubFields = docNode.createElement('CONSTANT-REFERENCE');
    IV_DEConstantRefSubNode = docNode.createElement('CONSTANT-REF');
    IV_DEConstantRefSubNode.setAttribute('DEST',"CONSTANT-SPECIFICATION");
    IV_DEConstantRefSubNode.appendChild(docNode.createTextNode(['/Interfaces/SenderReceiverInitValues/',IVName]));   
    IVSubFields.appendChild(IV_DEConstantRefSubNode);
