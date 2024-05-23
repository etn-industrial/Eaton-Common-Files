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
        [Rows,Cols]=size(RAW);
        
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

        InverterProjectNode = docNode.createElement('AR-PACKAGES');
        TopNode = docNode.createElement('AR-PACKAGE');
        IFFolderName = docNode.createElement('SHORT-NAME');
        IFFolderName.appendChild(docNode.createTextNode('Interfaces'));
        TopNode.appendChild(IFFolderName);
        IFFolderNode = docNode.createElement('AR-PACKAGES');

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% COMPU METHODS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        CompuMethodsFolderNode = docNode.createElement('AR-PACKAGE');
        CompuMethodsFolderName = docNode.createElement('SHORT-NAME');
        CompuMethodsFolderName.appendChild(docNode.createTextNode('CompuMethods'));
        CompuMethodsElements = docNode.createElement('ELEMENTS');

        for i = 1:Rows-1
            EnumElement = {};
            EnumValue = {};
            if ~isempty(RAW{min(DERowIdx+i,Rows),DECOlIdx})
                if strcmp(erase(RAW{min(DERowIdx+i,Rows),CMTypeCOlIdx},' '),'IDENTICAL')
                    CompuMethodNode = createCM(docNode,eraseUnicodesCharacter(RAW{min(DERowIdx+i,Rows),DECOlIdx}),...
                                RAW{min(DERowIdx+i,Rows),CMTypeCOlIdx},RAW{min(DERowIdx+i,Rows),UnitCOlIdx},EnumValue,EnumElement);
                    CompuMethodsElements.appendChild(CompuMethodNode);
                else
                    
                    [EnumValue,EnumElement]= getEnumFromCM(RAW{min(DERowIdx+i,Rows),CMTypeCOlIdx});
                        CompuMethodNode = createCM(docNode,eraseUnicodesCharacter(RAW{min(DERowIdx+i,Rows),DECOlIdx}),...
                                    'TEXTTABLE',RAW{min(DERowIdx+i,Rows),UnitCOlIdx},EnumValue,EnumElement);
                    CompuMethodsElements.appendChild(CompuMethodNode);
                end
            end
        end


        CompuMethodsFolderNode.appendChild(CompuMethodsFolderName);
        CompuMethodsFolderNode.appendChild(CompuMethodsElements);

        % %%%%%%%%%%%%%%%%%%%%%%%%%%% APPLICATION DATATYPES %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        DatatypesFolderNode = docNode.createElement('AR-PACKAGE');
        %DTSubNode = docNode.createElement('AR-PACKAGE');
        DatatypesFolderName = docNode.createElement('SHORT-NAME');
        DatatypesFolderName.appendChild(docNode.createTextNode('DataTypes'));
        DatatypesSubFolderNode = docNode.createElement('AR-PACKAGES');
        APDTFolderNode = docNode.createElement('AR-PACKAGE');
        APDTFolderName = docNode.createElement('SHORT-NAME');
        APDTFolderName.appendChild(docNode.createTextNode('ApplicationDataTypes'));
        APDTElements = docNode.createElement('ELEMENTS');
        for i = 1:Rows-1
            if ~isempty(RAW{min(DERowIdx+i,Rows),DECOlIdx})
                if strcmp(erase(RAW{min(DERowIdx+i,Rows),CMTypeCOlIdx},' '),'IDENTICAL')
                    CMCategory='IDENTICAL';
                else
                    CMCategory='TEXTTABLE';
                end
                [APDT,APDTDC ] = createAPDT(docNode,eraseUnicodesCharacter(RAW{min(DERowIdx+i,Rows),DECOlIdx}),...
                                RAW{min(DERowIdx+i,Rows),DescCOlIdx},string(RAW{min(DERowIdx+i,Rows),MinValCOlIdx}),...
                                string(RAW{min(DERowIdx+i,Rows),MaxValCOlIdx}),CMCategory);
                APDTElements.appendChild(APDT);
                APDTElements.appendChild(APDTDC);
            end
        end

        DatatypesFolderNode.appendChild(DatatypesFolderName);
        DatatypesFolderNode.appendChild(DatatypesSubFolderNode);
        DatatypesSubFolderNode.appendChild(APDTFolderNode);
        APDTFolderNode.appendChild(APDTFolderName);
        APDTFolderNode.appendChild(APDTElements);
        %%%%%%%%%%%%%%%%%%%%%%%%%%%% DATATYPE MAPPING SET %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        DTMSFolderNode = docNode.createElement('AR-PACKAGE');
        DTMSFolderName = docNode.createElement('SHORT-NAME');
        DTMSFolderName.appendChild(docNode.createTextNode('DataTypeMappingSets'));
        DTMSElements = docNode.createElement('ELEMENTS');
        for i = 1:Rows-1
            DTMS = createDTMS(docNode,eraseUnicodesCharacter(RAW{min(DERowIdx+i,Rows),DECOlIdx}),false);
            DTMSElements.appendChild(DTMS);
        end

        DatatypesSubFolderNode.appendChild(DTMSFolderNode);
        DTMSFolderNode.appendChild(DTMSFolderName);
        DTMSFolderNode.appendChild(DTMSElements);

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% IMPLEMENTATION DATATYPES %%%%%%%%%%%%%%%%%%%%%%%%%
        DTFolderNode = docNode.createElement('AR-PACKAGE');
        DTFolderName = docNode.createElement('SHORT-NAME');
        DTFolderName.appendChild(docNode.createTextNode('ImplementationDataTypes'));
        DTElements = docNode.createElement('ELEMENTS');
        for i = 1:Rows-1
            if ~isempty(RAW{min(DERowIdx+i,Rows),DECOlIdx})
                ImplDT = createDT(docNode,eraseUnicodesCharacter(RAW{min(DERowIdx+i,Rows),DECOlIdx}),...
                                RAW{min(DERowIdx+i,Rows),DTTypeCOlIdx});
                DTElements.appendChild(ImplDT);
            end
        end

        DatatypesSubFolderNode.appendChild(DTFolderNode);
        DTFolderNode.appendChild(DTFolderName);
        DTFolderNode.appendChild(DTElements);
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% INITIAL VALUES %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        IVFolderNode = docNode.createElement('AR-PACKAGE');
        %IVSubNode = docNode.createElement('AR-PACKAGE');
        IVFolderName = docNode.createElement('SHORT-NAME');
        IVFolderName.appendChild(docNode.createTextNode('SenderReceiverInitValues'));
        IVElements = docNode.createElement('ELEMENTS');

        for i = 1:Rows-1
            if ~isempty(RAW{min(DERowIdx+i,Rows),DECOlIdx})
                ConstantSpec = createIV(docNode,eraseUnicodesCharacter(RAW{min(DERowIdx+i,Rows),DECOlIdx}),...
                                string(RAW{min(DERowIdx+i,Rows),IVCOlIdx}),RAW{min(DERowIdx+i,Rows),UnitCOlIdx},false);
                IVElements.appendChild(ConstantSpec);
            end
        end

        IVFolderNode.appendChild(IVFolderName);
        IVFolderNode.appendChild(IVElements);

        %%%%%%%%%%%%%%%%%%%%%%%%%% SENDER-RECEIVER INTERFACES %%%%%%%%%%%%%%%%%%%%%%%%%%%%
        SRIFFolderNode = docNode.createElement('AR-PACKAGE');
        SRIFFolderName = docNode.createElement('SHORT-NAME');
        SRIFFolderName.appendChild(docNode.createTextNode('SenderReceiverInterfaces'));
        SRIFElements = docNode.createElement('ELEMENTS');
        for i = 1:Rows-1
            if ~isempty(RAW{min(DERowIdx+i,Rows),DECOlIdx})
                SRIF = createSRIF(docNode,eraseUnicodesCharacter(RAW{min(DERowIdx+i,Rows),DECOlIdx}),false);
                SRIFElements.appendChild(SRIF);
            end
        end

        SRIFFolderNode.appendChild(SRIFFolderName);
        SRIFFolderNode.appendChild(SRIFElements);

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        Root.appendChild(InverterProjectNode);
        InverterProjectNode.appendChild(TopNode);
        TopNode.appendChild(IFFolderNode);
        IFFolderNode.appendChild(CompuMethodsFolderNode);
        IFFolderNode.appendChild(DatatypesFolderNode);
        IFFolderNode.appendChild(IVFolderNode);
        IFFolderNode.appendChild(SRIFFolderNode);
        xmlwrite('SR_Interfaces.arxml',docNode);
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




