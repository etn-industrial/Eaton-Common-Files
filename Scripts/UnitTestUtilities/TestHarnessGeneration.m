classdef TestHarnessGeneration < handle
    properties
        rootNode
        modelName
        InstParam
        subsystemPath
        subsystemName
        modelInports
        modelOutports
        harnessInports
        harnessOutports
        testHarnessName
        testSeqBlock
		ICSubsystem
		OCSubsystem
        harnessCount
        totalHarnesses
        signalBuilderBlock
        tableSummary
        mergedTestSummaryData
        tableTestCaseDescription
        tableFailedTestCases
        tableTestCase
        coverageInfo
        coverageData
        mergedCoverageData
        coverageTable
        mergedCoverageTable
        testHarnessError
        messages
        initCalValuesStr
        Error = UnitTestError
    end
    
    methods
        function  createTestHarness(obj,xmlClassInstance)
            try
                initializeTables(obj);
                %find model name
                obj.rootNode = xmlClassInstance.xmlObj.getElementsByTagName('Root');
                obj.modelName = obj.getNodeTextContent(obj.rootNode.item(0),'ModelName');
                obj.subsystemPath = obj.getNodeTextContent(obj.rootNode.item(0),'SubsystemPath');
                obj.testHarnessName = obj.getNodeTextContent(obj.rootNode.item(0),'TestHarnessName');
                obj.signalBuilderBlock = xmlClassInstance.signalBuilderGroupActive;
            catch  ME
                obj.setErrorMessage(ME);
            end
            createTest(obj);
            RunTestHarnessSimulation(obj);
        end
    end
    
    methods (Access = {?UnitTestFactory})
        function createTest(obj)
            if ~obj.testHarnessError
                try
                    %create the harness
                    %stopTime = obj.getNodeTextContent(obj.rootNode.item(0),'SimulationTime');
                    createHarness(obj);
                    functionStubs = createFunctionCallsStubs(obj);
                    %create the test
                    createTestSequence(obj,functionStubs);
                    if (length(obj.modelInports)>0)
                        if strcmp(obj.modelName,obj.subsystemName)
                            %replace signal specification blocks inside Input Conversion Subsystem
                            %by DataTypeConversion blocks with Inherith type
                            %obj.replaceSigSpecByDTConversionBlocks(obj.testHarnessName);
                            updateInputConversionSubsystem(obj);
                            %check if runnables are triggered by function calls if so then insert Function-Call Generator blocks to trigger
                            %runnables at their respective rate
                            checkResult = getParentModelSampleRate(obj);
                            if(checkResult)
                                if ~isempty(obj.ICSubsystem)
                                    deleteFromTagsfromSubsystem(obj,[obj.testHarnessName,'/Input Conversion Subsystem/']);
                                    replace_block([obj.testHarnessName,'/Input Conversion Subsystem/'],'Goto','Terminator','noprompt');
                                end
                                %disableMultiTaskingInReferencedConfiguration(obj);
                            end
                            obj.checkForSameSampleRateFunctionCallGen()
                        else
                            %                             TriggerPort = find_system(obj.subsystemPath,'BlockType','TriggerPort');
                            %                             if ~isempty(TriggerPort)
                            %                                 if strcmp(get_param(TriggerPort,'IsSimulinkFunction'),'on')
                            %                                     obj.deleteRateTransitionBlocks([obj.testHarnessName,'/Input Conversion Subsystem']);
                            %                                 else
                            %                                 end
                            %                             end
                            %updateSignalSpecification(obj);
                        end
                    else isempty(obj.modelInports)&&isempty(obj.modelOutports)
                         %obj.replaceSigSpecByDTConversionBlocks(obj.testHarnessName);
                         updateInputConversionSubsystem(obj);
                            %check if runnables are triggered by function calls if so then insert Function-Call Generator blocks to trigger
                            %runnables at their respective rate
                            checkResult = getParentModelSampleRate(obj);
                            if(checkResult)
                                if ~isempty(obj.ICSubsystem)
                                    deleteFromTagsfromSubsystem(obj,[obj.testHarnessName,'/Input Conversion Subsystem/']);
                                    replace_block([obj.testHarnessName,'/Input Conversion Subsystem/'],'Goto','Terminator','noprompt');
                                end
                                %disableMultiTaskingInReferencedConfiguration(obj);
                            end
                            obj.checkForSameSampleRateFunctionCallGen();
                    end
                    
                    obj.deleteRateTransitionBlocks();
                    obj.updateBusCreatorConfig();
                    if ~isempty(obj.OCSubsystem)
                        updateRateTransitionInitCondition(obj,[obj.testHarnessName,'/Output Conversion Subsystem']);
                    end
                    %                      if ~obj.testHarnessError
                    %                         set_param(eval(obj.testHarnessName),'StopTime',stopTime);
                    %                      end
                    %open the model
                    openHarness(obj);
                    %save the model
                    saveHarness(obj);
                catch  ME
                    if isempty(obj.modelName)
                        obj.Error.appendErrorText('ModelName :');
                    elseif isempty(obj.testHarnessName)
                        obj.Error.appendErrorText('Test Harness Name : ');
                    elseif isempty(obj.subsystemPath)
                        obj.Error.appendErrorText('SubsystemPath : ');
                    else
                        obj.Error.Msg = obj.Error.ME.message;%getReport(obj.testHarness.Error.ME);
                    end
                    obj.setErrorMessage(ME);
                end
            end
        end
        
        function createHarness(obj)
            if ~obj.testHarnessError
                try
                    %load the model
                    obj.loadModel();
                    obj.subsystemName = get_param(obj.subsystemPath,'Name');
                    
                    %Set UnitTest model config
                    activeConfigObj = getActiveConfigSet(obj.modelName);
                    set_param(activeConfigObj,'SourceName','UnitTestConfig_Autosar');
                    
                    %look for all the model harnesses
                    harnessList = sltest.harness.find(obj.modelName,'Name',obj.testHarnessName);
                    if length(harnessList)>0
                        %Delete test harness if exist
                        sltest.harness.delete(harnessList.ownerFullPath,obj.testHarnessName);
                    end
                    %Get model ports
                    [obj.modelInports , obj.modelOutports] = obj.getModelPorts(obj.subsystemPath);
                    if ~isempty(obj.signalBuilderBlock)
                        %check if inputs should come from SignalBuilder
                        %create the harness
                        sltest.harness.create(obj.subsystemPath,'Name',obj.testHarnessName,'Source','Signal Builder','SynchronizationMode','SyncOnOpen');
                        sltest.harness.load(obj.subsystemPath,obj.testHarnessName);
						obj.findInAndOutConversionSubsystems();
                        
                        %Set Model Argument Values
                        initializeInstanceParameters(obj);
                        [obj.harnessInports,obj.harnessOutports] = obj.getModelPorts(obj.testHarnessName);
                        connectOutputsToTestSequenceBlock(obj);
                        updateSignalBuilder(obj);
                        %check that model contains at least 1 inport and 1 outport
                        %before create a test harness with test sequence block
                    elseif (length(obj.modelInports)>0) &&(length(obj.modelOutports)>0)
                        %create the harness
                        sltest.harness.create(obj.subsystemPath,'Name',obj.testHarnessName,'Source','Test Sequence','SynchronizationMode','SyncOnOpen');
                        sltest.harness.load(obj.subsystemPath,obj.testHarnessName);
						obj.findInAndOutConversionSubsystems();
                        %Set Model Argument Values
                        initializeInstanceParameters(obj);
                    elseif (length(obj.modelInports)<=0) &&(length(obj.modelOutports)>0)
                            sltest.harness.create(obj.subsystemPath,'Name',obj.testHarnessName,'Source','Test Sequence','SynchronizationMode','SyncOnOpen');
                            sltest.harness.load(obj.subsystemPath,obj.testHarnessName);
							obj.findInAndOutConversionSubsystems();
                            %Set Model Argument Values
                            initializeInstanceParameters(obj);
                            %Get test harness Inports and Outports if exist
                            [obj.harnessInports,obj.harnessOutports] = obj.getModelPorts(obj.testHarnessName);
                            %Replace all Inports and Outports by Goto Tags (This tags will be connecte to test seq block)
                            connectOutputsToTestSequenceBlock(obj);
                    elseif (length(obj.modelInports)>0) &&(length(obj.modelOutports)<= 0)
                        if strcmp(obj.modelName,obj.subsystemName)
                            %if model does not contain any Outports, test
                            %harness will have to be modified to add a test sequence
                            %block
                            sltest.harness.create(obj.subsystemPath,'Name',obj.testHarnessName,'SynchronizationMode','SyncOnOpen');
                            sltest.harness.load(obj.subsystemPath,obj.testHarnessName);
							obj.findInAndOutConversionSubsystems();
                            %Set Model Argument Values
                            initializeInstanceParameters(obj);
                            %Get test harness Inports and Outports if exist
                            [obj.harnessInports,obj.harnessOutports] = obj.getModelPorts(obj.testHarnessName);
                            connectTestSequenceBlockToHarnessInputs(obj);
                        else
                            sltest.harness.create(obj.subsystemPath,'Name',obj.testHarnessName,'Source','Test Sequence','SynchronizationMode','SyncOnOpen');
                            sltest.harness.load(obj.subsystemPath,obj.testHarnessName);
							obj.findInAndOutConversionSubsystems();
                            %Set Model Argument Values
                            initializeInstanceParameters(obj);
                        end
                    else
                        if strcmp(obj.modelName,obj.subsystemName)
                            %if model does not contain any Outports, test
                            %harness will have to be modified to add a test sequence
                            %block
                            sltest.harness.create(obj.subsystemPath,'Name',obj.testHarnessName,'SynchronizationMode','SyncOnOpen');
                            sltest.harness.load(obj.subsystemPath,obj.testHarnessName);
							obj.findInAndOutConversionSubsystems();
                            %Set Model Argument Values
                            initializeInstanceParameters(obj);
                            %Get test harness Inports and Outports if exist
                            [obj.harnessInports,obj.harnessOutports] = obj.getModelPorts(obj.testHarnessName);
                            connectTestSequenceBlockToHarnessInputs(obj);
                        else
                            sltest.harness.create(obj.subsystemPath,'Name',obj.testHarnessName,'Source','Test Sequence','SynchronizationMode','SyncOnOpen');
                            sltest.harness.load(obj.subsystemPath,obj.testHarnessName);
							obj.findInAndOutConversionSubsystems();
                            %Set Model Argument Values
                            initializeInstanceParameters(obj);
                        end
                    end
                    obj.findTestSequenceBlock();
                catch  ME
                    obj.setErrorMessage(ME);
                end
            end
        end
        
        function findTestSequenceBlock(obj)
            % This function finds the test sequence common block names.
            %* Test Sequence Block
            %* Function-call scheduler
            %* Simulink Function scheduler
            obj.testSeqBlock = {};
            if ~obj.testHarnessError
                   testSequenceBlock = {};
                   if ~isempty(find_system(obj.testHarnessName,'SearchDepth',1,'Name','Test Sequence'))
				   		testSequenceBlock =	find_system(obj.testHarnessName,'SearchDepth',1,'Name','Test Sequence');
                       	obj.testSeqBlock = testSequenceBlock{1};
                   elseif ~isempty(find_system(obj.testHarnessName,'SearchDepth',1,'Name','Function-call scheduler'))
                       testSequenceBlock = find_system(obj.testHarnessName,'SearchDepth',1,'Name','Function-call scheduler');
                       obj.testSeqBlock = testSequenceBlock{1};
				   elseif ~isempty(find_system(obj.testHarnessName,'SearchDepth',1,'Name','Simulink Function scheduler'))
                       testSequenceBlock = find_system(obj.testHarnessName,'SearchDepth',1,'Name','Simulink Function scheduler');
                       obj.testSeqBlock = testSequenceBlock{1};
				   else
                   end
            end
        end
		
		function findInAndOutConversionSubsystems(obj)
			if ~obj.testHarnessError
				obj.ICSubsystem = find_system(obj.testHarnessName,'SearchDepth',1,'Name','Input Conversion Subsystem');
        		obj.OCSubsystem = find_system(obj.testHarnessName,'SearchDepth',1,'Name','Output Conversion Subsystem');
			end
		end
        
        function FunctionCallsStubs = createFunctionCallsStubs(obj)
            FunctionCallsStubs = "";
            functionCallCounter = 0;
            if ~obj.testHarnessError
                try
                    %Get position of the Test Sequence block
                    modelPosition = get_param(strcat(obj.testHarnessName,'/',obj.subsystemName),'Position');
                    %Define path of the stub function subsystems.
                    GlobalFunctionsPath = [obj.testHarnessName,'/GlobalFunctions/'];
                    %Look for all the Function Callers in the model
                    csInterfaces = lookForAllClientServerInterfaces(obj);
                    %Create the function call stubs if there are CLient or Server functions in the model
                    if (~isempty(csInterfaces))
                        %delete un-used components created by default
                        obj.deleteDefaultDiagnosticServiceBlock(obj.testHarnessName);
                        %Create a new susbsytem GlobalFunctions to store the new subsystems
                        obj.createGlobalFunctionsSubsystem(obj.testHarnessName);
                        %set GlobalFunctions subsystem position above the Test Sequence block
                        set_param(GlobalFunctionsPath,'position',[modelPosition(1),modelPosition(2)-150,modelPosition(3),modelPosition(2)-50]);
                        %Create 1 subsystem for each Function caller found.
                        for ii = 1:length(csInterfaces)
                            if ~isempty(csInterfaces{ii})
                                FunctionPrototype = get_param(csInterfaces(ii),'FunctionPrototype');
                                inputArgumentSpec = get_param(csInterfaces(ii),'InputArgumentSpecifications');
                                inputArgumentSpec = erase(inputArgumentSpec,' ');
                                outputArgumentSpec = get_param(csInterfaces(ii),'OutputArgumentSpecifications');
                                outputArgumentSpec =  erase(outputArgumentSpec,' ');
                                %extract Output arguments from function prototype
                                outArg_filter = erase(extractBefore(FunctionPrototype,'='),' ');
                                OutArguments = regexp(string(outArg_filter),'\w*','match');
                                %extract Input arguments from function prototype
                                inArg_filter = extractBetween(FunctionPrototype,'(',')');
                                InArguments = regexp(string(inArg_filter),'\w*','match');
                                %Extract function agument's initial value and datatype
                                inArgInitialValue = split(inputArgumentSpec,',');
                                outArgInitialValue = split(outputArgumentSpec,',');
                                if ~isempty(inArgInitialValue{1})
                                    inputArgDatatype = obj.getArgumentDatatype (inArgInitialValue);
                                end
                                if ~isempty(outArgInitialValue{1})
                                    outputArgDatatype = obj.getArgumentDatatype (outArgInitialValue);
                                end
                                
                                %ClientServerName = obj.extractFunctionCallNameFromFuncPrototype(csInterfaces{ii});
                                ClientServerName = get_param(csInterfaces{ii},'Name');
                                %Add simulink function stub for ClientServer
                                add_block('simulink/User-Defined Functions/Simulink Function',strcat(GlobalFunctionsPath,string(ClientServerName)));
                                SimulinkFunctionPath = strcat(GlobalFunctionsPath,string(ClientServerName));
                                deleteAllLinesFromSubsystem(obj,char(SimulinkFunctionPath),false);
                                set_param(strcat(SimulinkFunctionPath,'/f'),'FunctionVisibility','global','FunctionPrototype',string(FunctionPrototype));
                                
                                for jj = 1:length(InArguments)
                                    %Configure function stub
                                    set_param(strcat(SimulinkFunctionPath,'/',InArguments{jj}),'OutDataTypeStr',inputArgDatatype{jj});
                                    %create Data Store Memory to store function input arguments.
                                    functionCallCounter = functionCallCounter + 1;
                                    FunctionCallsStubs(functionCallCounter) = createDataStoreReadBlock(obj,ClientServerName,InArguments{jj},...
                                        inputArgDatatype{jj},inArgInitialValue{jj},functionCallCounter,...
                                        SimulinkFunctionPath);
                                    set_param(strcat(SimulinkFunctionPath,'/',InArguments{jj}),'Name',FunctionCallsStubs(functionCallCounter));
                                end
                                
                                for kk = 1:length(OutArguments)
                                    %Configure function stub
                                    set_param(strcat(SimulinkFunctionPath,'/',OutArguments{kk}),'OutDataTypeStr',outputArgDatatype{kk});
                                    if strcmp(OutArguments{kk},'ERR')
                                        %stub ERR argument to 0
                                        add_block('simulink/Commonly Used Blocks/Constant',strcat(SimulinkFunctionPath,'/Constant1'),'Value','0');
                                        add_block('simulink/Commonly Used Blocks/Data Type Conversion',strcat(SimulinkFunctionPath,'/Data Type Conversion1'),'OutDataTypeStr',outputArgDatatype{kk});
                                        add_line(strcat(SimulinkFunctionPath,'/'),'Constant1/1','Data Type Conversion1/1');
                                        add_line(strcat(SimulinkFunctionPath,'/'),'Data Type Conversion1/1','ERR/1');
                                    else
                                        %create Data Store Memory to store function input arguments.
                                        functionCallCounter = functionCallCounter + 1;
                                        FunctionCallsStubs(functionCallCounter) = createDataStoreWriteBlock(obj,ClientServerName,OutArguments{kk},...
                                            outputArgDatatype{kk},outArgInitialValue{kk},functionCallCounter,...
                                            SimulinkFunctionPath);
                                        set_param(strcat(SimulinkFunctionPath,'/',OutArguments{kk}),'Name',FunctionCallsStubs(functionCallCounter));
                                    end
                                end
                                
                                %Configure Blocks position
                                set_param(strcat(SimulinkFunctionPath,'/'),'position',[100,200+(ii*100),600,250+(ii*100)]);
                                Simulink.BlockDiagram.arrangeSystem(strcat(SimulinkFunctionPath,'/'));
                            end
                        end
                    end
                catch  ME
                    obj.setErrorMessage(ME);
                end
            end
        end
        
        function ArgumentDatatype = getArgumentDatatype(obj,ArgumentInitialValue)
            ArgumentDatatype = {};
            if ~obj.testHarnessError
                try
                    SWCDictonary = Simulink.data.dictionary.open([obj.modelName,'.sldd']);
                    modelData = getSection(SWCDictonary,'Design Data');
                    for ii = 1:length(ArgumentInitialValue)
                        if contains(ArgumentInitialValue{ii},'(')
                            ArgumentDatatype{ii} = extractBefore(ArgumentInitialValue{ii},'(');
                        else
                            ArgumentDatatype{ii} = ArgumentInitialValue{ii};
                        end
                        %Check for simulink native basetypes
                        cmpToBaseType = strcmp(ArgumentDatatype{ii},{'boolean','uint8','int8','uint16','int16',...
                            'uint32','int32','uint64','int64','double',...
                            'single','void'});
                        isBaseType = sum(cmpToBaseType);
                        
                        enumDatatype = Simulink.findIntEnumType(ArgumentDatatype{ii});
                        if ~isempty(enumDatatype)
                            ArgumentDatatype{ii} = ['Enum: ',ArgumentDatatype{ii}];
                        elseif isBaseType
                            %do nothing
                        else
                            %check for type def base type
                            typeDef = getEntry(modelData,ArgumentDatatype{ii});
                            typeDef = getValue(typeDef);
                            ArgumentDatatype{ii} = typeDef.DataType;
                        end
                    end
                    SWCDictonary.close;
                catch  ME
                    obj.setErrorMessage(ME);
                end
            end
        end
        
        function clientServer = lookForAllClientServerInterfaces(obj)
            %this function will look for in the model for all the autosar
            %client-server
            clientServer = {};
            if ~obj.testHarnessError
                try
                    %1.- look for all the function callers
                    functionCalls = find_system(obj.subsystemPath,'BlockType','FunctionCaller');
                    %2.- Get the Autosar properties of the model
                    modelAutosarProps = autosar.api.getAUTOSARProperties(obj.modelName);
                    %3.- look for ClientPorts
                    modelClientPorts = find(modelAutosarProps,[],'ClientPort');
                    CSMatchCounter = 0;
                    %4.- Compare Client and server ports with function callers
                    for clientCounter = 1: length(modelClientPorts)
                        clientName = extractAfter(modelClientPorts(clientCounter),'/');
                        clientName = strcat(clientName,'_');
                        for fcCounter = 1: size(functionCalls)
                            fcnCallName = get_param(functionCalls{fcCounter},'Name');
                            if contains(fcnCallName,clientName)
                                %obj.extractFunctionCallNameFromFuncPrototype(functionCalls{fcCounter});
                                CSMatchCounter = CSMatchCounter + 1;
                                clientServer{CSMatchCounter} = functionCalls{fcCounter};
                                break;
                            end
                        end
                    end
                catch  ME
                    obj.setErrorMessage(ME);
                end
            end
        end
        
        function DTSM_BlockName = createDataStoreReadBlock(obj,FunctionCallerName,blockEventName,blockEventDatatype,eventIV,idx,SimulinkFunctionPath)
            if ~obj.testHarnessError
                try
                    %Get the position of Test Sequence block
                    modelPosition = get_param(strcat(obj.testHarnessName,'/',obj.subsystemName),'Position');
                    modelWidth = modelPosition(3) - modelPosition(1);
                    modelCenterPosition = modelPosition(1) + modelWidth/2;
                    %                     modelPosition(1)
                    %                     %modelCenterPosition -30
                    %                     modelPosition(3)
                    %modelCenterPosition + 30
                    %Define the name of the Data Store Memory block by removing 'R_' and 'Set' from the function call names
                    %i.e. R_DiagBusVolt_stDgouHVDCSenOOR_SetEventStatus -> DiagBusVolt_stDgouHVDCSenOOR_EventStatus
                    DTSM_Name = split(FunctionCallerName,'_');
                    DTSM_BlockName = string(strcat(DTSM_Name(2),'_',DTSM_Name(3),'_',blockEventName));
                    DTSM_BlockPath = string(strcat(obj.testHarnessName,'/',DTSM_BlockName));
                    add_block('simulink/Signal Routing/Data Store Memory',DTSM_BlockPath);
                    %Set parameters of the Data Store Memory
                    set_param(DTSM_BlockPath,'DataStoreName',DTSM_BlockName,...
                        'InitialValue',eventIV,...
                        'OutDataTypeStr',blockEventDatatype,...
                        'ReadBeforeWriteMsg','none',...
                        'WriteAfterWriteMsg','none',...
                        'WriteAfterReadMsg','none',...
                        'SignalType','real',...
                        'ShowName','off',...
                        'position',[(modelCenterPosition -150) ,modelPosition(4)+(30*idx),(modelCenterPosition + 150),modelPosition(4)+(30*idx)+20]);
                    blockName = sprintf('Data Store Write%d',idx);
                    %Add Data Store Write blocks inside the functioncallstubs
                    add_block('simulink/Signal Routing/Data Store Write',strcat(SimulinkFunctionPath,'/',blockName));
                    set_param(strcat(SimulinkFunctionPath,'/',blockName),'DataStoreName',DTSM_BlockName,...
                        'ShowName','off',...
                        'position',[250,80,500,110]);
                    %Connect EventStatus to the Data Store Write
                    add_line(strcat(SimulinkFunctionPath,'/'),[blockEventName,'/1'],[blockName,'/1']);
                catch  ME
                    obj.setErrorMessage(ME);
                end
            else
                DTSM_BlockName = '';
            end
        end
        
        function DTSM_BlockName = createDataStoreWriteBlock(obj,FunctionCallerName,blockEventName,blockEventDatatype,eventIV,idx,SimulinkFunctionPath)
            if ~obj.testHarnessError
                try
                    %deleteAllLinesFromSubsystem(obj,char(SimulinkFunctionPath));
                    %Get the position of Test Sequence block
                    modelPosition = get_param(strcat(obj.testHarnessName,'/',obj.subsystemName),'Position');
                    modelWidth = modelPosition(3) - modelPosition(1);
                    modelCenterPosition = modelPosition(1) + modelWidth/2;
                    %Define the name of the Data Store Memory block by removing 'R_' and 'Set' from the function call names
                    %i.e. R_DiagBusVolt_stDgouHVDCSenOOR_SetEventStatus -> DiagBusVolt_stDgouHVDCSenOOR_EventStatus
                    DTSM_Name = split(FunctionCallerName,'_');
                    DTSM_BlockName = string(strcat(DTSM_Name(2),'_',DTSM_Name(3),'_',blockEventName));
                    DTSM_BlockPath = string(strcat(obj.testHarnessName,'/',DTSM_BlockName));
                    add_block('simulink/Signal Routing/Data Store Memory',DTSM_BlockPath);
                    %Set parameters of the Data Store Memory
                    set_param(DTSM_BlockPath,'DataStoreName',DTSM_BlockName,...
                        'InitialValue',eventIV,...
                        'OutDataTypeStr',blockEventDatatype,...
                        'ReadBeforeWriteMsg','none',...
                        'WriteAfterWriteMsg','none',...
                        'WriteAfterReadMsg','none',...
                        'SignalType','real',...
                        'ShowName','off',...
                        'position',[(modelCenterPosition -150) ,modelPosition(4)+(30*idx),(modelCenterPosition + 150),modelPosition(4)+(30*idx)+20]);
                    blockName = sprintf('Data Store Read%d',idx);
                    %Add Data Store Write blocks inside the functioncallstubs
                    add_block('simulink/Signal Routing/Data Store Read',strcat(SimulinkFunctionPath,'/',blockName));
                    set_param(strcat(SimulinkFunctionPath,'/',blockName),'DataStoreName',DTSM_BlockName,...
                        'ShowName','off',...
                        'position',[50,80,300,110]);
                    set_param(strcat(SimulinkFunctionPath,'/',blockEventName),'position',[350,80,450,110]);
                    %Connect EventStatus to the Data Store Write
                    add_line(strcat(SimulinkFunctionPath,'/'),[blockName,'/1'],[blockEventName,'/1']);
                catch  ME
                    obj.setErrorMessage(ME);
                end
            else
                DTSM_BlockName = '';
            end
        end
        
        
        function initializeInstanceParameters(obj)
            if ~obj.testHarnessError
                try
                    if strcmp(obj.modelName,obj.subsystemName)
                        %Get Instance Parameters of model reference
                        obj.InstParam = get_param([obj.testHarnessName,'/',obj.modelName],'InstanceParameters');
                        %Initialize Instance parameters if exist
                        if ~isempty(obj.InstParam)
                            set_param(obj.modelName,'ParameterArgumentNames','');
                        end
                    end
                catch  ME
                    obj.setErrorMessage(ME);
                end
            end
        end
        
        function reestoreInstanceParameters(obj)
            if ~obj.testHarnessError
                try
                    if strcmp(obj.modelName,obj.subsystemName)
                        %Initialize Instance parameters if exist
                        if ~isempty(obj.InstParam)
                            parameters = obj.InstParam(1).Name;
                            [M N]= size(obj.InstParam);
                            for ii = 2: M
                                parameters = cat(2,parameters,',',obj.InstParam(ii).Name);
                            end
                            set_param(obj.modelName,'ParameterArgumentNames',parameters);
                        end
                    end
                catch  ME
                    obj.setErrorMessage(ME);
                end
            end
        end
        
        function updateSignalBuilder(obj)
            if ~obj.testHarnessError
                try
                    %This function import signal builder groups from file
                    [excelFile Group] = getSignalBuilderInputs(obj);
                    if isequal(excelFile,0)
                        return
                    end
                    [Type,TestCases] = xlsfinfo(excelFile);
                    for sheet_index = 1:length(TestCases)
                        [Num,Text]=xlsread(excelFile,TestCases{sheet_index});
                        
                        if sheet_index==1
                            % Use signals names of the first sheet as reference.
                            SignalName=Text(end,2:end);
                        else
                            % Check consistent of signals names.
                            if ~isequal(SignalName, Text(end,2:end))
                                errordlg('Signals Names mismatch!');
                                return;
                            end
                        end
                        
                        % Create time vector
                        Time{sheet_index}=Num(:,1);
                        
                        % Create data
                        for s=2:size(Text,2)
                            Data{s-1,sheet_index}=Num(:,s);
                        end
                        
                    end
                    signalbuilder(strcat(obj.testHarnessName,'/Harness Inputs'), 'APPEND', Time,Data,SignalName,TestCases);
                    signalbuilder(strcat(obj.testHarnessName,'/Harness Inputs'),'ACTIVEGROUP',Group);
                catch  ME
                    obj.setErrorMessage(ME);
                end
            end
        end
        
        function [excelFile Group] = getSignalBuilderInputs(obj)
            if ~obj.testHarnessError
                try
                    text = split(obj.signalBuilderBlock,'_');
                    excelFile = text{1};
                    Group = str2num(extractAfter(text{3},'Group'))+1;
                catch  ME
                    obj.setErrorMessage(ME);
                end
            else
                excelFile = '';
                Group = 0;
            end
        end
        
        
        
        
        %%%%%%%%%%%%%%%%%%%%%%%%----FUNCTIONS TO CREATE HARNESS WITHOUT INPORTS OR OUTPORTS----%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function connectOutputsToTestSequenceBlock(obj)
            if ~obj.testHarnessError
                try
                    if ~isempty(obj.OCSubsystem)
                        tcBlock=find_system(obj.testHarnessName,'Searchdepth',1,'Name','Test Sequence');
                        if isempty(tcBlock)
                            %get the position of Output Conversion Subsystem
                            OCSubsystem = get_param([obj.testHarnessName,'/Output Conversion Subsystem'],'Position');
                            left = OCSubsystem(1)+150;
                            bottom = OCSubsystem(2);
                            width = OCSubsystem(1)+250;
                            height = OCSubsystem(4);
                            add_block('sltestlib/Test Sequence',[obj.testHarnessName,'/Test Sequence'],'Position',[left bottom width height]);
                            sltest.testsequence.deleteStep([obj.testHarnessName,'/Test Sequence'],'step_1');
                            obj.findTestSequenceBlock();
                            editStepName(obj,'step_2','Run');
                            renamedBlocks = renameTerminatorBlocks(obj);
                            obj.harnessOutports =  cat(1,obj.harnessOutports,renamedBlocks);
                            for i = 1: length(obj.harnessOutports)
                                blockName = get_param(obj.harnessOutports{i},'Name');
                                %delete ouport blocks
                                delete_block(obj.harnessOutports{i});
                                %add outport name as input for test sequence block
                                addTestSeqSymbol(obj,blockName,'Inherit: Same as Simulink','Input');
                            end
                            %delete the unconnected lines left
                            deleteUnconnectedLines(obj,obj.testHarnessName);
                            %read portHandles from Output Conversion Subsystem and Test
                            %Sequence block and connect them.
                            OCSubsystemPortHandles = get_param([obj.testHarnessName,'/Output Conversion Subsystem'],'PortHandles');
                            TestSequencePortHandles = get_param([obj.testHarnessName,'/Test Sequence'],'PortHandles');
                            add_line(obj.testHarnessName,OCSubsystemPortHandles.Outport,TestSequencePortHandles.Inport,'autorouting','on');
                        end
                    end
                catch  ME
                    obj.setErrorMessage(ME);
                end
            end
        end
        
        %Rename terminator blocks same as subsystem's output
        function renamedBlocks = renameTerminatorBlocks(obj)
            renamedBlocks = {};
            terminatorBlocks=find_system(obj.testHarnessName,'SearchDepth',1,'BlockType','Terminator');
            OCSubsystem = find_system(obj.testHarnessName,'SearchDepth',1,'Name','Output Conversion Subsystem');
            OCSubsystem = OCSubsystem{1};
            blockCount = 1;
            for ii=1:length(terminatorBlocks)
                %trace back the terminator to find the output conencted to
                %it
                srcBlock = obj.getSrcBlockPort(terminatorBlocks{ii});
                if strcmp(OCSubsystem,srcBlock.Parent)
                    OCPorts=find_system(OCSubsystem,'SearchDepth',1,'BlockType','Outport');
                    ocOutport=OCPorts{srcBlock.PortNumber};
                    srcBlock = obj.getSrcBlockPort(ocOutport);

                    while true
                        %loop to find all intermediate blocks connected
                        %between the terminator block and output.
                        if strcmp('Inport',get_param(srcBlock.Parent,'BlockType'))
                            srcBlock.Parent;
                            portNumber = get_param(srcBlock.Parent,'Port');

                            break;
                        end
                        srcBlock = obj.getSrcBlockPort(getfullname(srcBlock.Handle));
                    end
                    ocsHandle=get_param(OCSubsystem,'PortHandles');
                    ocsLine = get_param(ocsHandle.Inport(str2num(portNumber)),'Line');
                    oscSrcport = get_param(ocsLine, 'Srcporthandle');
                    unitUnderTestPort = get(oscSrcport);
                    unitUnderTestOutports=find_system(unitUnderTestPort.Parent,'SearchDepth',1,'BlockType','Outport');
                    unitUnderTestPortName = get_param(unitUnderTestOutports{unitUnderTestPort.PortNumber},'Name');
                    %rename terminator as the subsystem output
                    set_param(terminatorBlocks{ii},'Name',unitUnderTestPortName);
                    renamedBlocks{blockCount}= [obj.testHarnessName,'/',unitUnderTestPortName];
                    blockCount = blockCount + 1;
                end
            end
        end
        
        function connectTestSequenceBlockToHarnessInputs(obj)
            if ~obj.testHarnessError
                try
                    
                    if ~isempty(obj.ICSubsystem)
                        %read position of Input Convertion Subsystem
                        ICSubsystemPos = get_param([obj.testHarnessName,'/Input Conversion Subsystem'],'Position');
                        left = ICSubsystemPos(1)-80;
                        bottom = ICSubsystemPos(2);
                        width = left+50;
                        height = ICSubsystemPos(4);
                        %Add Test Sequence Block next to Input Convertion Subsystem
                        add_block('sltestlib/Test Sequence',[obj.testHarnessName,'/Test Sequence'],'Position',[ left bottom width height]);
                        %Rename default test sequence block step
                        sltest.testsequence.deleteStep([obj.testHarnessName,'/Test Sequence'],'step_1');
                        obj.findTestSequenceBlock();
                        editStepName(obj,'step_2','Run');
                        for i = 1: length(obj.harnessInports)
                            blockName = extractAfter(obj.harnessInports{i},'/');
                            %delete one by one inport block
                            delete_block(obj.harnessInports{i});
                            % Add deleted inport name as an output for test sequence block
                            addTestSeqSymbol(obj,blockName,'Inherit: Same as Simulink','Output');
                        end
                        %delete the unconnected lines left
                        deleteUnconnectedLines(obj,obj.testHarnessName);
                        %read portHandles from Input Conversion Subsystem and Test
                        %Sequence block and connect them.
                        ICSubsystemPortHandles = get_param([obj.testHarnessName,'/Input Conversion Subsystem'],'PortHandles');
                        TestSequencePortHandles = get_param([obj.testHarnessName,'/Test Sequence'],'PortHandles');
                        add_line(obj.testHarnessName,TestSequencePortHandles.Outport,ICSubsystemPortHandles.Inport,'autorouting','on');
                    end
                catch  ME
                    obj.setErrorMessage(ME);
                end
            end
        end
        
        function deleteUnconnectedLines(obj,modelPath)
            if ~obj.testHarnessError
                try
                    delete_line(find_system(modelPath, 'FindAll', 'on', 'Type', 'line', 'Connected', 'off'));
                catch  ME
                    obj.setErrorMessage(ME);
                end
            end
        end
        
        function disableMultiTaskingInReferencedConfiguration(obj)
            if ~obj.testHarnessError
                try
                    %Get model active configuration set
                    myConfigObj = getActiveConfigSet(obj.modelName);
                    %Get referenced configuration set
                    refConfigObj = getRefConfigSet(myConfigObj);
                    %Disable MultiTasking
                    set_param(refConfigObj,'EnableMultiTasking', 'off');
                catch  ME
                    obj.setErrorMessage(ME);
                end
            end
        end
        
        function restoreMultiTaskingInReferencedConfiguration(obj)
            if ~obj.testHarnessError
                try
                    %Get model active configuration set
                    myConfigObj = getActiveConfigSet(obj.modelName);
                    %Get referenced configuration set
                    refConfigObj = getRefConfigSet(myConfigObj);
                    %Disable MultiTasking
                    set_param(refConfigObj,'EnableMultiTasking', 'on');
                catch  ME
                    obj.setErrorMessage(ME);
                end
            end
        end
        
        function result = getParentModelSampleRate(obj)
            %Look for Inports with parameter 'OutputFunctionCall' ON
            result = false;
            if ~obj.testHarnessError
                try
                    ports = find_system(obj.modelName,'SearchDepth',1,'LookUnderMasks', 'on', 'BlockType', 'Inport');
                    for ii = 1:length(ports)
                        % TriggerPort = find_system('SWC_IOCAdptCore0ASILC','BlockType','TriggerPort')
                        FuncCallStatus{ii} = get_param(ports{ii}, 'OutputFunctionCall');
                        if strcmp(FuncCallStatus{ii},'on')
                            Phandle =  get_param(ports{ii},"PortConnectivity");
                            DstBlock = get_param(Phandle.DstBlock,'Name');
                            found = obj.lookForParentSampleRate(DstBlock);
                            if found || strcmp(obj.modelName,obj.subsystemName)
                                SampleTime = get_param(ports{ii}, 'SampleTime');
                                PortNumber = get_param(ports{ii}, 'Port');
                                replaceDataTyConversionByFunctionCallGenerator(obj,SampleTime,PortNumber);
                                result = true;
                            end
                        end
                    end
                catch  ME
                    obj.setErrorMessage(ME);
                end
            end
        end
        
        function found = lookForParentSampleRate(obj,DstBlock)
            SubsystemPath = obj.subsystemPath;
            found = false;
            while ~isempty(SubsystemPath)
                if strcmp(get_param(SubsystemPath,'Name'),DstBlock)
                    found = true;
                    break;
                else
                    SubsystemPath = get_param(SubsystemPath,'Parent');
                end
            end
        end
        
        function replaceDataTyConversionByFunctionCallGenerator(obj,FC_SampleTime,FC_PortNumber)
            if ~obj.testHarnessError
                try
                    if ~isempty(obj.ICSubsystem)
                        if ~strcmp(obj.modelName,obj.subsystemName)
                            FC_PortNumber  = string(length(obj.modelInports) + 1);
                        end
                        FuncGeneratorName = strcat('SigSpec_',FC_PortNumber);
                        set_param(obj.ICSubsystem{1},'Permissions','ReadWrite');
                        replace_block(strcat(obj.ICSubsystem{1},'/'),...
                            'Name',FuncGeneratorName,'simulink/Ports & Subsystems/Function-Call Generator','noprompt');
                        set_param(strcat(obj.testHarnessName,'/Input Conversion Subsystem/',FuncGeneratorName),'sample_time',FC_SampleTime);
                    end
                catch  ME
                    obj.setErrorMessage(ME);
                end
            end
        end
        
        %This function look for Function Call generator that trigger
        %runnables with same sample rate and deletes them and insert a
        %function call split block , this is done in order to fix Simulink
        %error.
        function checkForSameSampleRateFunctionCallGen(obj)
            if ~obj.testHarnessError
                try
                        if ~isempty(obj.ICSubsystem)
                            blockPath = [obj.testHarnessName,'/Input Conversion Subsystem/'];
                            FuncCallGenBlock = find_system(blockPath,'BlockType','S-Function');
                            for ii=1:length(FuncCallGenBlock)
                                RateCounter = 1;
                                if ~isempty(FuncCallGenBlock{ii})
                                    Rate1 = get_param(FuncCallGenBlock{ii},'sample_time');
                                    for jj=1:length(FuncCallGenBlock)
                                        if ii == jj
                                        else
                                            if ~isempty(FuncCallGenBlock{jj})
                                                Rate2 = get_param(FuncCallGenBlock{jj},'sample_time');
                                                if strcmp(Rate1,Rate2)
                                                    if(RateCounter==1)
                                                        FuncCalGen1_Position = get_param(FuncCallGenBlock{ii},'Position');
                                                        FuncCalGen1_PortConnectParam = get_param(FuncCallGenBlock{ii},'PortConnectivity');
                                                        OutPort1Handle = get_param(FuncCalGen1_PortConnectParam.DstBlock,'PortHandles');
                                                        delete_line(blockPath,FuncCalGen1_PortConnectParam.Position);
                                                        FuncCallSpliName = strcat(blockPath,'Funtion-Call Split',sprintf('%d',ii));
                                                        add_block('simulink/Ports & Subsystems/Function-Call Split',FuncCallSpliName,'Position',...
                                                            [FuncCalGen1_Position(3)+15,FuncCalGen1_Position(2)-10,FuncCalGen1_Position(3)+30,FuncCalGen1_Position(4)+10]);
                                                        FuncCalGen1_PortHandle = get_param(FuncCallGenBlock{ii},'PortHandles');
                                                        FuncCalSplit_PortHandle = get_param(FuncCallSpliName,'PortHandles');
                                                        add_line(blockPath,FuncCalGen1_PortHandle.Outport,FuncCalSplit_PortHandle.Inport,'autorouting','on');
                                                        add_line(blockPath,FuncCalSplit_PortHandle.Outport(RateCounter),OutPort1Handle.Inport,'autorouting','on');
                                                    else
                                                        set_param(FuncCallSpliName,'NumOutputPorts',sprintf('%d',RateCounter+1));
                                                    end
                                                    FuncCalSplit_PortHandle = get_param(FuncCallSpliName,'PortHandles');
                                                    FuncCalGen2_PortConnectParam = get_param(FuncCallGenBlock{jj},'PortConnectivity');
                                                    OutPort2Handle = get_param(FuncCalGen2_PortConnectParam.DstBlock,'PortHandles');
                                                    delete_line(blockPath,FuncCalGen2_PortConnectParam.Position);
                                                    %Remove function call with same rate
                                                    delete_block(FuncCallGenBlock{jj});
                                                    FuncCallGenBlock{jj} = '';
                                                    RateCounter = RateCounter + 1;
                                                    add_line(blockPath,FuncCalSplit_PortHandle.Outport(RateCounter),OutPort2Handle.Inport);
                                                end
                                            end
                                        end
                                    end
                                end
                            end
                            Simulink.BlockDiagram.arrangeSystem(blockPath);
                        end
                catch  ME
                    obj.setErrorMessage(ME);
                end
            end
        end
        
        function deleteFromTagsfromSubsystem(obj,blockPath)
            if ~obj.testHarnessError
                try
                    FromTags = find_system(blockPath,'BlockType','From');
                    for ii = 1:length(FromTags)
                        %Terminate Function Call Inputs
                        delete_block(FromTags{ii});
                    end
                    deleteAllLinesFromSubsystem(obj,blockPath,true);
                catch  ME
                    obj.setErrorMessage(ME);
                end
            end
        end
        
        function deleteAllLinesFromSubsystem(obj,modelPath,justUnconnectedLines)
            if ~obj.testHarnessError
                try
                    %Get all lines objects in the subsystem
                    linesObj = find_system(modelPath,'FindAll','on','type','line');
                    for i=1:length(linesObj)
                        lineSrc=get_param(linesObj(i),'SrcPortHandle');
                        lineDst=get_param(linesObj(i),'DstPortHandle');
                        if(justUnconnectedLines)
                            if (lineSrc < 0) || (lineDst < 0)
                                delete_line(linesObj(i));
                            end
                        else
                            delete_line(linesObj(i));
                        end
                    end
                catch  ME
                    obj.setErrorMessage(ME);
                end
            end
        end
        
        %this method will find the name associated with a node
        function [text] = getName(obj,nodeItem)
            try
                text = '';
                if ~obj.testHarnessError
                    text = obj.getNodeTextContent(nodeItem,'Name');
                end
            catch  ME
                obj.setErrorMessage(ME);
            end
        end
        
        %this method will find the name associated with a node
        function [text] = getDescription(obj,nodeItem)
            try
                text = '';
                if ~obj.testHarnessError
                    text = obj.getNodeTextContent(nodeItem,'Description');
                end
            catch  ME
                obj.setErrorMessage(ME);
            end
        end
        
        %this method will find the name associated with a node
        function [condText,nextStepText] = getTransition(obj,nodeItem)
            if ~obj.testHarnessError
                try
                    transNode = nodeItem.getElementsByTagName('Transition');
                    if(transNode.getLength>0)
                        condText = obj.getNodeTextContent(transNode.item(0),'Condition');
                        nextStepText = obj.getNodeTextContent(transNode.item(0),'NextStep');
                    else
                        condText = [];
                        nextStepText = [];
                    end
                catch  ME
                    obj.setErrorMessage(ME);
                end
            else
                condText = [];
                nextStepText = [];
            end
        end
        
        function initializeTables(obj)
            if ~obj.testHarnessError
                obj.Error.Category = '***Test Harness Generation Error***';
                obj.tableTestCaseDescription = table('Size',[0 3],'VariableTypes',{'categorical','categorical','categorical'});
                obj.tableTestCaseDescription.Properties.VariableNames= {'TestCaseName','Description','Result'};
                obj.tableFailedTestCases = table('Size',[0 4],'VariableTypes',{'categorical','categorical','categorical','categorical'});
                %Define column names
                obj.tableFailedTestCases.Properties.VariableNames= {'StepName','Failed_Verify_Statement','TimeStamp','Value_at_TimeStamp'};
                obj.tableTestCase = table('Size',[0 6],'VariableTypes',{'categorical','categorical','categorical','categorical','categorical','categorical'});
                %Define column names
                obj.tableTestCase.Properties.VariableNames= {'TestCase','TestStep','Verify_Statement','Result','CurrentValue','TimeStamp'};
            end
        end
        
        function createTestSequence(obj,functionStubs)
            if ~obj.testHarnessError
                try
                    %create initialization step
                    createInitStep(obj,functionStubs);
                    lastTestName = 'Init';
                    
                    %find test sequence node
                    testSequenceNode = obj.rootNode.item(0).getElementsByTagName('TestSequences');
                    testNode = testSequenceNode.item(0).getElementsByTagName('Test');
                    
                    %loop through tests
                    for(ii = 0:testNode.getLength-1)
                        %find the top level test node
                        topLevelNode = testNode.item(ii).getElementsByTagName('TopLevel');
                        
                        %get info for the node
                        testName = getName(obj,topLevelNode.item(0));
                        testActions = getActions(obj,topLevelNode.item(0),testName);
                        testDescription = getDescription(obj,topLevelNode.item(0));
                        [testTransCondition,nextStep] = getTransition(obj,topLevelNode.item(0));
                        
                        addStepAfter(obj,lastTestName,testName,testActions,testDescription);
                        
                        obj.tableTestCaseDescription.TestCaseName(ii+1) = string(testName);
                        obj.tableTestCaseDescription.Description(ii+1) = string(testDescription);
                        obj.tableTestCaseDescription.Result(ii+1) = "";
                        obj.tableTestCase.TestCase(length(obj.tableTestCase.Verify_Statement)+1)= string(testName);
                        %add transition
                        if(~isempty(nextStep))
                            addTransition(obj,testName, nextStep, testTransCondition);
                        end
                        
                        %set last step name for next iteration
                        lastTestName = testName;
                        
                        %get the test steps
                        stepsNode = testNode.item(ii).getElementsByTagName('Step');
                        
                        %llop through steps node and add them to the sequence
                        for(jj = 0:stepsNode.getLength-1)
                            
                            %get info for the node
                            stepName = getName(obj,stepsNode.item(jj));
                            stepActions = getActions(obj,stepsNode.item(jj),stepName);
                            stepDescription = getDescription(obj,stepsNode.item(jj));
                            [stepTransCondition,nextStep] = getTransition(obj,stepsNode.item(jj));
                            
                            stepActions = discardQueuedMessages(obj,stepsNode.item(jj),stepActions);
                            
                            %add step
                            addSubStep(obj,testName,stepName,stepActions,stepDescription);
                            
                            %add transition
                            if(~isempty(nextStep))
                                addTransition(obj,[testName,'.',stepName], [testName,'.',nextStep], stepTransCondition);
                            end
                        end
                    end
                    %add termination
                    createTerminationStep(obj,lastTestName);
                catch  ME
                    obj.setErrorMessage(ME);
                end
            end
        end
        
        function updatedStepActions = discardQueuedMessages(obj,nodeItem,stepActions)
            %This function pulls and discard messages from queued
            %outputs to avoid overflow
            isPeriodicTask = false;
            updatedStepActions = stepActions;
            actionNode = nodeItem.getElementsByTagName('Actions');
            VerifyActions = obj.getNodeTextContent(actionNode.item(0),'Verify');
            if ~isempty(obj.messages)
                messageReceived = '';
                messageDiscarded = '';
                for ii=1:length(obj.messages)
                    if ii == 1
                        messageReceived = [messageReceived,'if receive(',obj.messages{ii},')'];
                    else
                        messageReceived = [messageReceived,'&& receive(',obj.messages{ii},')'];
                    end
                    messageDiscarded = [messageDiscarded,'discard(',obj.messages{ii},')\n'];
                end
                isPeriodicTask = getParentModelSampleRate(obj);
				if isPeriodicTask
					if ~isempty(VerifyActions)
						messageDiscarded = [messageDiscarded,'end\n'];
						%pull messages , verify outputs and discard messages
						updatedStepActions = obj.appendText(messageReceived, updatedStepActions);
						updatedStepActions = obj.appendText(updatedStepActions, messageDiscarded);
					else
						messageDiscarded = [messageDiscarded,'end\n'];
						%pull and discard messages
						updatedStepActions = obj.appendText(updatedStepActions, messageReceived);
						updatedStepActions = obj.appendText(updatedStepActions, messageDiscarded);
                    end
                else
                    %Do nothing , queue overflow is not possible since task is
                    %triggered not periodic.
				end
            end
        end
        
        function createInitStep(obj,functionStubs)
            if ~obj.testHarnessError
                try
                    %Create local Variables
                    createLocalVariables(obj);
                    
                    %find local varnames
                    localVarNode = obj.rootNode.item(0).getElementsByTagName('LocalVariables');
                    varsNode = localVarNode.item(0).getElementsByTagName('Var');
                    
                    %loop through vars and add them to chart
                    for(ii = 0:varsNode.getLength-1)
                        %extract the data
                        varName = obj.getNodeTextContent(varsNode.item(ii),'Name');
                        varDataType = obj.getNodeTextContent(varsNode.item(ii),'DataType');
                        
                        %add local end test variable
                        addLocalTestSeqSymbol(obj,varName,varDataType);
                    end
                    
                    %change fist step to init
                    editStepName(obj,'Run','Init');
                    defaultFCStep = sltest.testsequence.findStep(obj.testSeqBlock,'Name','AsyncFunctionCalls');
                    if ~isempty(defaultFCStep)
                        sltest.testsequence.deleteStep(obj.testSeqBlock,'AsyncFunctionCalls');
                    end
                    
                    %set actions for init
                    defaultActions = {'coder.extrinsic(''assignin'');';...
                        'coder.extrinsic(''getSection'');';...
                        'coder.extrinsic(''set_param'');';...
                        'coder.extrinsic(''get_param'');';...
                        'coder.extrinsic(''Simulink.data.dictionary.open'');';...
                        'coder.extrinsic(''discardChanges'');';...
                        ['SWCDictonary = Simulink.data.dictionary.open(''',obj.modelName,'.sldd'');'];...
                        'modelData = getSection(SWCDictonary,''Design Data'');';...
                        ['modelWorkSpace = get_param(''',obj.modelName,''',''ModelWorkspace'');']};
                    
                    
                    %convert to char
                    text = '';
                    for (jj = 1:length(defaultActions))
                        if(jj == 1)
                            text = defaultActions{jj};
                        else
                            text = [text,'\n',defaultActions{jj}];
                        end
                    end
                    
                    %write the actions
                    editStepAction(obj,'Init',text);
                    
                    %edit the description
                    editStepDescription(obj,'Init','This step creates all the links to the data dictonary and gives access to matlab functions');
                    
                    %find first test sequence step
                    testSequenceNode = obj.rootNode.item(0).getElementsByTagName('TestSequences');
                    testNode = testSequenceNode.item(0).getElementsByTagName('Test');
                    topLevelNode = testNode.item(0).getElementsByTagName('TopLevel');
                    
                    %get info for the node
                    testName = getName(obj,topLevelNode.item(0));
                    
                    %add transition to first test
                    addTransition(obj,'Init', testName, 'true');
                    for i=1:length(functionStubs)
                        if ~strcmp(functionStubs(i),"")
                            sltest.testsequence.addSymbol(obj.testSeqBlock,functionStubs(i),'Data','Data Store Memory');
                        end
                    end
                    if strcmp(obj.modelName,obj.subsystemName)
                        %Update test sequence block outputs'  datatype when
                        %UnitTest runs at model top level
                        testSeqOutputs = sltest.testsequence.findSymbol(obj.testSeqBlock,'Scope','Output','Kind','Data');
                        for ii = 1:length(testSeqOutputs)
                            sltest.testsequence.editSymbol(obj.testSeqBlock,testSeqOutputs{ii},'DataType','Inherit: Same as Simulink');
                        end 
                    end
					obj.messages = sltest.testsequence.findSymbol(obj.testSeqBlock,'Scope','Input','Kind','Message');
                catch  ME
                    obj.setErrorMessage(ME);
                end
            end
        end
        
        function createLocalVariables(obj)
            if ~obj.testHarnessError
                try
                    %create nodes till get the one that contains node SetLocalVar
                    testSequenceNode = obj.rootNode.item(0).getElementsByTagName('TestSequences');
                    testNode = testSequenceNode.item(0).getElementsByTagName('Test');
                    topLevelNode = testNode.item(0).getElementsByTagName('TopLevel');
                    actionNode = topLevelNode.item(0).getElementsByTagName('Actions');
                    LocalVarActions = obj.getNodeTextContent(actionNode.item(0),'SetLocalVar');
                    %parse local var actions
                    if(~isempty(LocalVarActions))
                        if(~ischar(LocalVarActions))
                            for (jj = 1:length(LocalVarActions))
                                AddLocarVarSymbols(obj,LocalVarActions(jj));
                            end
                        else
                            AddLocarVarSymbols(obj,LocalVarActions);
                        end
                    end
                    
                    %add standard symbols
                    addLocalTestSeqSymbol(obj,'SWCDictonary','Inherit: From definition in chart');
                    addLocalTestSeqSymbol(obj,'modelData','Inherit: From definition in chart');
                    addLocalTestSeqSymbol(obj,'modelWorkSpace','Inherit: From definition in chart');
                    
                    LocalVarData = sltest.testsequence.findSymbol(obj.testSeqBlock,'Scope','Local','Kind','Data');
                    for ii =1:length(LocalVarData)
                        sltest.testsequence.editSymbol(obj.testSeqBlock,LocalVarData{ii},'DataType','Inherit: From definition in chart');
                    end
                    sltest.testsequence.editSymbol(obj.testSeqBlock,'endTest','InitialValue','false');
                catch  ME
                    obj.setErrorMessage(ME);
                end
            end
        end
        
        function AddLocarVarSymbols(obj,LocalVarAction)
            if ~obj.testHarnessError
                try
                    LocalVar = string(LocalVarAction);
                    %                     %extract local variable's datatype
                    %                     DataType = strrep(extractBetween(LocalVar,'=','('),' ','');
                    %                     if isempty(DataType)
                    %                         DataType = 'boolean';
                    %                     end
                    %extract local variable's name
                    VarName = strrep(extractBefore(LocalVar,'='),' ','');
                    %Add test symbols to test sequence
                    addLocalTestSeqSymbol(obj,VarName,'Inherit: From definition in chart');
                catch  ME
                    obj.setErrorMessage(ME);
                end
            end
        end
        
        %This method create termination step to discard any change done onthe DD
        function createTerminationStep(obj,lastTestName)
            if ~obj.testHarnessError
                try
                    sltest.testsequence.deleteStep(obj.testSeqBlock,'Init');
                    %set actions for init
                    defaultActions = {'discardChanges(SWCDictonary);';...
                        ['set_param(''',obj.testHarnessName,''',','''SimulationCommand'',','''stop''',');']};
                    
                    %convert to char
                    text = '';
                    for (jj = 1:length(defaultActions))
                        if(jj == 1)
                            text = defaultActions{jj};
                        else
                            text = [text,'\n',defaultActions{jj}];
                        end
                    end
                    %terminate model by closing dictonary
                    addStepAfter(obj,lastTestName,'Terminate',text,'close data dictonary');
                    addTransition(obj,lastTestName,'Terminate','endTest==true');
                catch  ME
                    obj.setErrorMessage(ME);
                end
            end
        end
        
        %this method will find all the actions associated with a node
        function [Actiontext] = getActions(obj,nodeItem,testName)
            Actiontext = '';
            if ~obj.testHarnessError
                try
                    %init update required variable
                    updateRequired = false;
                    
                    %get different action types
                    actionNode = nodeItem.getElementsByTagName('Actions');
                    InputActions = obj.getNodeTextContent(actionNode.item(0),'SetInput');
                    ParamActions = obj.getNodeTextContent(actionNode.item(0),'SetParam');
                    LocalVarActions = obj.getNodeTextContent(actionNode.item(0),'SetLocalVar');
                    
                    VerifyActions = obj.getNodeTextContent(actionNode.item(0),'Verify');
                    %parse input actions
                    if(~isempty(InputActions))
                        if(~ischar(InputActions))
                            for (jj = 1:length(InputActions))
                                Actiontext = strcat(Actiontext, [InputActions{jj},';\n']);
                            end
                        else
                            Actiontext = obj.appendText(Actiontext, [InputActions,';']);
                        end
                    end
                    
                    %parse param actions
                    if(~isempty(ParamActions))
                        updateRequired = true;
                        if(~ischar(ParamActions))
                            for (jj = 1:length(ParamActions))
                                action = ParamActions{jj};
                                idx = strfind(action,'=');
                                varName = strrep(action(1:idx-1),' ','');
                                value = strrep(strrep(action(idx+1:end),' ',''),';','');
                                if obj.calFoundInModelWkspc(varName)
                                    paramString = ['on at(1,tick):assignin(modelWorkSpace,''',varName,''',',value,');'];
                                else
                                    paramString = ['on at(1,tick):assignin(modelData,''',varName,''',',value,');'];
                                end
                                Actiontext = obj.appendText(Actiontext, paramString);
                            end
                        else
                            action = ParamActions;
                            idx = strfind(action,'=');
                            varName = strrep(action(1:idx-1),' ','');
                            value = strrep(strrep(action(idx+1:end),' ',''),';','');
                            if obj.calFoundInModelWkspc(varName)
                                paramString = ['on at(1,tick):assignin(modelWorkSpace,''',varName,''',',value,');'];
                            else
                                paramString = ['on at(1,tick):assignin(modelData,''',varName,''',',value,');'];
                            end
                            Actiontext = obj.appendText(Actiontext, paramString);
                        end
                    end
                    
                    if ~isempty(VerifyActions)
                        if  isundefined(obj.tableTestCase.Verify_Statement(length(obj.tableTestCase.Verify_Statement)))
                            obj.tableTestCase.TestStep(length(obj.tableTestCase.Verify_Statement))= string(testName);
                        else
                            obj.tableTestCase.TestStep(length(obj.tableTestCase.Verify_Statement)+1)= string(testName);
                        end
                        if(~ischar(VerifyActions))
                            for(jj = 1:length(VerifyActions))
                                if  isundefined(obj.tableTestCase.Verify_Statement(length(obj.tableTestCase.Verify_Statement)))
                                    obj.tableTestCase.Verify_Statement(length(obj.tableTestCase.Verify_Statement))= VerifyActions{jj};
                                else
                                    obj.tableTestCase.Verify_Statement(length(obj.tableTestCase.Verify_Statement)+1)= VerifyActions{jj};
                                end
                                
                                VerStatement = addVerifyStatementErrorMessage(obj,VerifyActions{jj},testName,jj);
                                verifyString = ['verify(',VerStatement,');'];
                                Actiontext = obj.appendText(Actiontext, verifyString);
                            end
                        else
                            if isundefined(obj.tableTestCase.Verify_Statement(length(obj.tableTestCase.Verify_Statement)))
                                obj.tableTestCase.Verify_Statement(length(obj.tableTestCase.Verify_Statement))= VerifyActions;
                            else
                                obj.tableTestCase.Verify_Statement(length(obj.tableTestCase.Verify_Statement)+1)= VerifyActions;
                            end
                            
                            VerStatement = addVerifyStatementErrorMessage(obj,VerifyActions,testName,1);
                            verifyString = ['verify(',VerStatement,');'];
                            Actiontext = obj.appendText(Actiontext, verifyString);
                        end
                    end
                    
                    %add update if prameter has changed
                    if(updateRequired == true)
                        Actiontext = obj.appendText(Actiontext, ['on at(1,tick):set_param(''',obj.testHarnessName,''',','''SimulationCommand'',','''update''',');']);
                    end
                    
                    %parse local var actions
                    if(~isempty(LocalVarActions))
                        if(~ischar(LocalVarActions))
                            for (jj = 1:length(LocalVarActions))
                                Actiontext = strcat(Actiontext, [LocalVarActions{jj},';\n']);
                            end
                        else
                            Actiontext = obj.appendText(Actiontext, [LocalVarActions,';']);
                        end
                    end
                catch  ME
                    obj.setErrorMessage(ME);
                end
            end
        end
        
        %This method looks for a calibration in the model workspace
        %,returns true if cal found , false otherwise.
        function found = calFoundInModelWkspc(obj,CalName)
            found = false;
            mdlWks = get_param(obj.modelName,'ModelWorkspace');
            mdlWksData = mdlWks.whos;
            for ii = 1 : length(mdlWksData)
                if strcmp(mdlWksData(ii).name,CalName)
                    found = true;
                    break;
                end
            end
        end
        
        %This method adds to the verify statement the ID and error's messages
        function VerStatement = addVerifyStatementErrorMessage(obj,verifyStatement,testName,VerifyNum)
            if ~obj.testHarnessError
                try
                    %objectsModel = find_system(obj.modelName);
                    TestSequenceSymbols = sltest.testsequence.findSymbol(obj.testSeqBlock);
                    Identifier =strcat("TestCase:",testName,"_Verify",sprintf("%d",VerifyNum));
                    ErrorMessage ="Current Output Value:";
                    paramValues = "";
                    %ErrorMessage = "";
                    SymbolCount=1;
                    if ~isempty(TestSequenceSymbols)
                        for j = 1: length(TestSequenceSymbols)
                            VERIFY_SYMBOL_REGEXP = ['\s*',char(TestSequenceSymbols(j)),'(\.*\w*)*(\(\s*\d*\s*\))*(\{\s*\d*\s*\})*(\[\s*\d*\s*\])*'];
                            verify_expresion = regexp(verifyStatement,VERIFY_SYMBOL_REGEXP,'match');
                            %(verify_expresion);
                            if iscell(verify_expresion) && ~isempty(verify_expresion)
                                verify_expresion = verify_expresion{1};
                            else
                            end
                            if ~isempty(verify_expresion)
                                if SymbolCount <= 1
                                    if obj.isNotIntegerNumber(string(verify_expresion))
                                        ErrorMessage = strcat(ErrorMessage,verify_expresion," = %%f");
                                    else
                                        ErrorMessage = strcat(ErrorMessage,verify_expresion," = %%d");
                                    end
                                    paramValues = strcat( paramValues,",","single(",verify_expresion,")");
                                else
                                    if ~contains(ErrorMessage,verify_expresion)
                                        if obj.isNotIntegerNumber(verify_expresion)
                                            ErrorMessage = strcat(ErrorMessage,", ",verify_expresion," = %%f");
                                        else
                                            ErrorMessage = strcat(ErrorMessage,", ",verify_expresion," = %%d");
                                        end
                                        paramValues = strcat( paramValues,",","single(",verify_expresion,")");
                                    end
                                end
                                SymbolCount = SymbolCount+1;
                                break;
                            end
                        end
                    end
                    if strcmp(ErrorMessage,"") || strcmp(paramValues,"")
                        VerStatement = verifyStatement;
                    else
                        VerStatement = strcat(verifyStatement,",'",Identifier,"',","'",ErrorMessage,"'",paramValues);
                        VerStatement = char(VerStatement);
                    end
                catch  ME
                    obj.setErrorMessage(ME);
                end
            else
                VerStatement = '';
            end
        end
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% METHODS TO EDIT TEST SEQUENCE BLOCK %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        function addTestSeqSymbol(obj,symbName,DataType,Scope)
            if ~obj.testHarnessError
                try
                    %creates a new local symbol
                    sltest.testsequence.addSymbol([obj.testHarnessName,'/Test Sequence'],symbName,'Data',Scope);
                    sltest.testsequence.editSymbol([obj.testHarnessName,'/Test Sequence'],symbName,'DataType',DataType);
                catch  ME
                    obj.setErrorMessage(ME);
                end
            end
        end
        
        function addLocalTestSeqSymbol(obj,symbName,DataType)
            if ~obj.testHarnessError
                try
                    %creates a new local symbol
                    sltest.testsequence.addSymbol(obj.testSeqBlock,symbName,'Data','Local');
                    sltest.testsequence.editSymbol(obj.testSeqBlock,symbName,'DataType',DataType);
                catch  ME
                    obj.setErrorMessage(ME);
                end
            end
        end
        
        function editStepName(obj,currStepName,newStepName)
            if ~obj.testHarnessError
                try
                    %sets step named currStepName with new step name newStepName
                    sltest.testsequence.editStep(obj.testSeqBlock,currStepName,'Name',newStepName);
                catch  ME
                    obj.setErrorMessage(ME);
                end
            end
        end
        
        function editStepAction(obj,stepName,action)
            if ~obj.testHarnessError
                try
                    %sets step named stepName Action to action
                    sltest.testsequence.editStep(obj.testSeqBlock,stepName,'Action',sprintf(action));
                catch  ME
                    obj.setErrorMessage(ME);
                end
            end
        end
        
        function editStepDescription(obj,stepName,text)
            if ~obj.testHarnessError
                try
                    %sets step named stepName description to description
                    sltest.testsequence.editStep(obj.testSeqBlock,stepName,'Description',text);
                catch  ME
                    obj.setErrorMessage(ME);
                end
            end
        end
        
        function addStepAfter(obj,prevStepName,newStepName,actions,description)
            if ~obj.testHarnessError
                try
                    if strcmp(prevStepName,'Init')
                        obj.initCalValuesStr = sprintf(actions);
                        initActions = sltest.testsequence.readStep(obj.testSeqBlock,prevStepName, 'Action');
                        sltest.testsequence.addStepAfter(obj.testSeqBlock,newStepName,prevStepName,'Action',sprintf([initActions,'\n','endTest = false;\n',actions]),'Description',description);
                    else
                        %Add a new step to the test sequence
                        %sltest.testsequence.addStepAfter(blockPath,newStep,stepPath,Name,Value)
                        %adds a step to a Test Sequence block specified by blockPath. The new step is named newStep and is inserted after stepPath. Step properties are specified by Name,Value
                        sltest.testsequence.addStepAfter(obj.testSeqBlock,newStepName,prevStepName,'Action',sprintf(['endTest = false;\n',actions]),'Description',description);
                    end
                catch  ME
                    obj.setErrorMessage(ME);
                end
            end
        end
        
        function addSubStep(obj,parentStepName,childStepName,actions,description)
            if ~obj.testHarnessError
                try
                    %sltest.testsequence.addStep(blockPath,stepPath,Name,Value)
                    %adds a step named stepPath to a Test Sequence block specified by blockPath. Step properties are specified by Name,Value pairs.
                    sltest.testsequence.addStep(obj.testSeqBlock,[parentStepName,'.',childStepName],'Action',sprintf(actions),'Description',description);
                catch  ME
                    obj.setErrorMessage(ME);
                end
            end
        end
        
        function addTransition(obj,firstStep, secondStep, transCondition)
            if ~obj.testHarnessError
                try
                    %sltest.testsequence.addTransition(blockPath,fromStep,condition,toStep)
                    %creates a test step transition in the Test Sequence block blockPath. The transition executes on condition, from the origin fromStep,
                    %to the destination toStep. fromStep and toStep must be at the same hierarchy level.
                    sltest.testsequence.addTransition(obj.testSeqBlock,firstStep,transCondition,secondStep);
                catch  ME
                    obj.setErrorMessage(ME);
                end
            end
        end
        
        %This method run harness simulation and logs the errors on a
        %temporal file
        function RunTestHarnessSimulation(obj)
            if ~obj.testHarnessError
                try
                        diary LoggedWarningsFromCommandWindow;
                        %Run test harness simulation
                        testModel = cvtest(obj.testHarnessName);
                        sldiagviewer.diary('UnitTestError.txt');
                        %sldiagviewer.diary
                        
                        obj.InitializeCalibrations();
                        obj.coverageData = cvsim(testModel);
                        
                        sldiagviewer.diary('off');
                        delete('UnitTestError.txt');
                        obj.reestoreInstanceParameters();
                        
                        if(obj.harnessCount==1)
                            obj.mergedCoverageData = obj.coverageData;
                            obj.mergedCoverageTable = obj.createCoverageTable(true);
                        else
                            [covSettings,obj.mergedCoverageData] = cvload('coverage_data');
                            if ~isempty(obj.mergedCoverageData{1})
                                obj.mergedCoverageData = obj.mergedCoverageData{1}+obj.coverageData;
                            else
                                obj.mergedCoverageData = obj.coverageData;
                            end
                        end
                    
                    %Disable logging text from command window
                    diary off;
                    obj.coverageTable = obj.createCoverageTable(false);
                    obj.mergedCoverageTable = obj.createCoverageTable(true);
                    cvsave('coverage_data',obj.mergedCoverageData);
                    %Create table with failed test cases
                    createTestCasesFailTable(obj);
                    extractTestResults(obj);
                    
                catch  ME
                    if exist('UnitTestError.txt')==2
                        obj.Error.addTextToFile(strcat(fileread('UnitTestError.txt'),'\n',...
                            'Open test harness and run simultion for more details.'));
                        sldiagviewer.diary('off');
                        diary off;
                        delete('UnitTestError.txt');
                    end
                    
                    if exist('LoggedWarningsFromCommandWindow')==2
                        delete('LoggedWarningsFromCommandWindow');
                    end
                    obj.setErrorMessage(ME);
                end
            end
        end
        
        function InitializeCalibrations(obj)
            try
                SWCDictonary = Simulink.data.dictionary.open([obj.modelName,'.sldd']);
                modelData = getSection(SWCDictonary,'Design Data');
                updateCalCommand=extractBetween(obj.initCalValuesStr,'on at(1,tick):',';');
                for ii=1:length(updateCalCommand)
                    eval(updateCalCommand{ii});
                end
            catch ME
                obj.setErrorMessage(ME);
            end
        end
        
        function extractTestResults(obj)
            %Read test Assessment results
            simAssessments = sltest.getAssessments(obj.testHarnessName);
            obj.tableSummary = struct2table(simAssessments.getSummary);
            %Update tab name from Total to Total_Test_Cases
            obj.tableSummary.Properties.VariableNames{'Total'} = 'Total_Test_Cases';
            obj.tableSummary.Result = categorical(string(obj.tableSummary.Result));
            
            summary = simAssessments.getSummary;
            testCaseCounter = 0;
            %Initialize overall results
            obj.tableSummary.Failed = 0;
            obj.tableSummary.Untested = 0;
            obj.tableSummary.Passed = 0;
            failedVerifyStatement = false;
            untestedVerifyStatement = false;
            passedVerifyStatement = false;
            totalTestSteps = length(obj.tableTestCase.TestStep);
            %Obtain test step results.
            for jj = 1:totalTestSteps
                if ~isundefined(obj.tableTestCase.TestStep(jj))
                    %New test step found
                    verifyCounter = 1;
                    stepIndex = jj;
                    testStepID = sprintf('TestCase:%s_Verify%d',string(obj.tableTestCase.TestStep(stepIndex)),verifyCounter);
                else
                    %Test step's verify statement found
                    verifyCounter = verifyCounter + 1;
                    testStepID = sprintf('TestCase:%s_Verify%d',string(obj.tableTestCase.TestStep(stepIndex)),verifyCounter);
                end
                %Get verify statement results
                testStepAssesment = find(simAssessments,'Name',testStepID);
                testStepInfo = getSummary(testStepAssesment);
                obj.tableTestCase.Result(jj) = string(testStepInfo.Result);
                if strcmp(string(testStepInfo.Result),'Fail')
                    failedVerifyStatement = true;
                    for kk = 1:length(obj.tableFailedTestCases.StepName)
%                         if strcmp(erase(string(obj.tableFailedTestCases.StepName(kk)),' '),erase(string(obj.tableTestCase.TestStep(stepIndex)),' '))&&...
%                                 strcmp(erase(string(obj.tableFailedTestCases.Failed_Verify_Statement(kk)),' '),erase(string(obj.tableTestCase.Verify_Statement(jj)),' '))
                        disp(regexprep(string(obj.tableFailedTestCases.StepName(kk)),'[\s\n]',''));
                        disp(regexprep(string(obj.tableTestCase.TestStep(stepIndex)),'[\s\n]',''));
                        disp(regexprep(string(obj.tableFailedTestCases.Failed_Verify_Statement(kk)),'[\s\n]',''));
                        disp(regexprep(string(obj.tableTestCase.Verify_Statement(jj)),'[\s\n]',''));
                        if strcmp(regexprep(string(obj.tableFailedTestCases.StepName(kk)),'[\s\n]',''),regexprep(string(obj.tableTestCase.TestStep(stepIndex)),'[\s\n]',''))&&...
                                strcmp(regexprep(string(obj.tableFailedTestCases.Failed_Verify_Statement(kk)),'[\s\n]',''),regexprep(string(obj.tableTestCase.Verify_Statement(jj)),'[\s\n]',''))
                            obj.tableTestCase.CurrentValue(jj) = obj.tableFailedTestCases.Value_at_TimeStamp(kk);
                            obj.tableTestCase.TimeStamp(jj) = obj.tableFailedTestCases.TimeStamp(kk);
                        end
                    end
                elseif strcmp(string(testStepInfo.Result),'Untested')
                    untestedVerifyStatement = true;
                elseif strcmp(string(testStepInfo.Result),'Pass')
                    passedVerifyStatement = true;
                end
                
                if ~isundefined(obj.tableTestCase.TestCase(min(jj+1,totalTestSteps)))|| jj==totalTestSteps
                    %at the begining of next test case , check previous
                    %test case result.
                    if failedVerifyStatement
                        testCaseCounter = testCaseCounter + 1;
                        obj.tableTestCaseDescription.Result(testCaseCounter) = 'Fail';
                        obj.tableSummary.Failed = obj.tableSummary.Failed + 1;
                        failedVerifyStatement = false;
                    elseif untestedVerifyStatement
                        testCaseCounter = testCaseCounter + 1;
                        obj.tableTestCaseDescription.Result(testCaseCounter) = 'Untested';
                        obj.tableSummary.Untested = obj.tableSummary.Untested + 1;
                        untestedVerifyStatement = false;
                    elseif passedVerifyStatement
                        testCaseCounter = testCaseCounter + 1;
                        obj.tableTestCaseDescription.Result(testCaseCounter) = 'Pass';
                        obj.tableSummary.Passed = obj.tableSummary.Passed + 1;
                    else
                        %do nothing
                    end
                end
            end
            
            obj.tableSummary.Total_Test_Cases = length(obj.tableTestCaseDescription.TestCaseName);
            obj.mergedTestSummaryData(1) = obj.mergedTestSummaryData(1) +  obj.tableSummary.Total_Test_Cases;
            obj.mergedTestSummaryData(2) =  obj.mergedTestSummaryData(2) + obj.tableSummary.Untested;
            obj.mergedTestSummaryData(3) = obj.mergedTestSummaryData(3) + obj.tableSummary.Passed;
            obj.mergedTestSummaryData(4) = obj.mergedTestSummaryData(4) + obj.tableSummary.Failed;
            
            obj.tableSummary
            obj.tableFailedTestCases
            obj.tableTestCase
        end
        
        function table = createCoverageTable(obj,isMergedCoverage)
            import mlreportgen.report.*
            import mlreportgen.dom.*
            if ~obj.testHarnessError
                try
                    if isMergedCoverage
                        covData = obj.mergedCoverageData;
                    else
                        covData = obj.coverageData;
                    end
                    if strcmp(obj.modelName,obj.subsystemName)
                        ModelUnderTest = obj.modelName;
                    else
                        ModelUnderTest = [obj.testHarnessName,'/',obj.subsystemName];
                    end
                    table = FormalTable();
                    table.TableEntriesStyle={Border('none'),FontFamily('Times New Roman'),...
                        FontSize('9pt'),ResizeToFitContents(true),Color('black'),VAlign('middle')};
                    modelIcon =Image(fullfile([obj.Error.scriptFolder,'\Icons\Top_model_16.png']));
                    headerRow = TableRow();
                    headerRow.Style={BackgroundColor('steelblue'),Bold,Color('white'),HAlign('center')};
                    headerEntry = TableEntry('');
                    headerEntry.Style= {Width('0.15in')};
                    append(headerRow,headerEntry);
                    headerEntry = TableEntry('Analyzed Model');
                    headerEntry.Style= {Width('1.7in'),HAlign('left')};
                    append(headerRow,headerEntry);
                    headerEntry = TableEntry('SimMode');
                    headerEntry.Style= {Width('0.8in')};
                    append(headerRow,headerEntry);
                    row = TableRow();
                    row.Style = {Color('black'),HAlign('center')};
                    rowEntry =TableEntry(modelIcon);
                    append(row,rowEntry);
                    rowEntry =TableEntry(obj.subsystemName);
                    rowEntry.Style = {HAlign('left'),InnerMargin('0.05in', '0.05in')};
                    append(row,rowEntry);
                    rowEntry =TableEntry('Normal');
                    append(row,rowEntry);
                    
                    complxCov = complexityinfo(covData,ModelUnderTest);
                    if ~isempty(complxCov)
                        complexity = complxCov(1);
                        headerEntry = TableEntry('Complexity');
                        headerEntry.Style= {Width('0.8in')};
                        append(headerRow,headerEntry);
                        rowEntry =TableEntry(string(complexity));
                        obj.coverageInfo.Complexity = string(complexity);
                        append(row,rowEntry);
                    end
                    decisionCov = decisioninfo(covData,ModelUnderTest);
                    if ~isempty(decisionCov)
                        decPerc = 100*(decisionCov(1)/decisionCov(2));
                        headerEntry = TableEntry('Decision');
                        headerEntry.Style= {Width('0.8in')};
                        append(headerRow,headerEntry);
                        rowEntry =TableEntry([num2str(round(decPerc)),'%']);
                        obj.coverageInfo.Decision = string([num2str(round(decPerc)),'%']);
                        append(row,rowEntry);
                    end
                    conditionCov = conditioninfo(covData,ModelUnderTest);
                    if ~isempty(conditionCov)
                        condPerc = 100*(conditionCov(1)/conditionCov(2));
                        headerEntry = TableEntry('Condition');
                        headerEntry.Style= {Width('0.8in')};
                        append(headerRow,headerEntry);
                        rowEntry =TableEntry([num2str(round(condPerc)),'%']);
                        obj.coverageInfo.Condition = string([num2str(round(condPerc)),'%']);
                        append(row,rowEntry);
                    end
                    mcdcCov = mcdcinfo(covData,ModelUnderTest);
                    if ~isempty(mcdcCov)
                        mcdcPerc = 100*(mcdcCov(1)/mcdcCov(2));
                        headerEntry = TableEntry('MCDC');
                        headerEntry.Style= {Width('0.8in')};
                        append(headerRow,headerEntry);
                        rowEntry =TableEntry([num2str(round(mcdcPerc)),'%']);
                        obj.coverageInfo.MCDC = string([num2str(round(mcdcPerc)),'%']);
                        append(row,rowEntry);
                    end
                    executionCov = executioninfo(covData,ModelUnderTest);
                    if ~isempty(executionCov)
                        execPerc = 100*(executionCov(1)/executionCov(2));
                        headerEntry = TableEntry('Execution');
                        headerEntry.Style= {Width('0.8in')};
                        append(headerRow,headerEntry);
                        rowEntry =TableEntry([num2str(round(execPerc)),'%']);
                        obj.coverageInfo.Execution = string([num2str(round(execPerc)),'%']);
                        append(row,rowEntry);
                    end
                    appendHeaderRow(table,headerRow);
                    append(table,row);
                catch  ME
                    obj.setErrorMessage(ME);
                end
            else
                table = FormalTable();
            end
        end
        
        %This method proccess warnings from command window after test harness simulation finish.  
        function createTestCasesFailTable(obj)
            if ~obj.testHarnessError
                try
                    warningLog = fileread('LoggedWarningsFromCommandWindow');
                    REGEXP_FAILED_TEST = 'Test[\r\n\s]*verification[\r\n\s]*failed[\r\n\s]*at[\r\n\s]*t[\r\n\s]*=';
                    REGEXP_OUTPUT_VALUE = 'Current[\r\n\s]*Output[\r\n\s]*Value[\r\n\s]*:';
                    failedTestMatch = regexp(warningLog,['(?s)(',REGEXP_FAILED_TEST,')(.*?)(?=<\/strong>)'],'match');
                    for ii = 1:length(failedTestMatch)
                        
                        timeStampMatch = regexp(failedTestMatch{ii},['(?s)(?<=',REGEXP_FAILED_TEST,')(.*?)(?=:)'],'match');
                        outputValueMatch = regexp(failedTestMatch{ii},['(?s)(?<=',REGEXP_OUTPUT_VALUE,')(.*?)(?=Step)'],'match');
                        stepNameMatch = regexp(failedTestMatch{ii},'(?s)(?<=>)(.*?)(?=<\/a>)','match');
                        verifyMatch = regexp(failedTestMatch{ii},'(?s)(?<=<strong>verify[\r\n\s]*\()(.*?)(?=,)','match');
                        
                        if ~isempty(timeStampMatch)&&~isempty(outputValueMatch)&&~isempty(stepNameMatch)&&~isempty(verifyMatch)
                            timeStampMatch = regexprep(timeStampMatch{1},'[\n\r]',' ');
                            outputValueMatch = regexprep(outputValueMatch{1},'[\n\r]',' ');
                            stepNameMatch = regexprep(stepNameMatch{1},'[\n\r]',' ');
                            verifyMatch = regexprep(verifyMatch{1},'[\n\r]',' ');
                            obj.tableFailedTestCases.TimeStamp(ii) = strtrim(timeStampMatch);
                            obj.tableFailedTestCases.Value_at_TimeStamp(ii) = strtrim(outputValueMatch);
                            obj.tableFailedTestCases.StepName(ii) = strtrim(stepNameMatch);
                            obj.tableFailedTestCases.Failed_Verify_Statement(ii) = strtrim(verifyMatch);
                        end
                    end
                    
                    delete('LoggedWarningsFromCommandWindow');
                catch  ME
                    obj.setErrorMessage(ME);
                end
            end
        end
        
        %This method opens given harness
        function saveHarness(obj)
            if ~obj.testHarnessError
                try
                    save_system(obj.testHarnessName);
                catch  ME
                    obj.setErrorMessage(ME);
                end
            end
        end
        
        %This method opens given harness
        function openHarness(obj)
            if ~obj.testHarnessError
                try
                    sltest.harness.open(obj.subsystemPath,obj.testHarnessName);
                catch  ME
                    obj.setErrorMessage(ME);
                end
            end
        end
        
        %This method closes given harness
        function closeHarness(obj,bDiscardChanges)
            try
                if bDiscardChanges
                    bdclose(obj.testHarnessName);
                else
                    sltest.harness.close(obj.modelName);
                    %close_system(obj.testHarnessName);
                end
            catch  ME
                obj.setErrorMessage(ME);
            end
        end
        
        %This method saves given model
        function saveModel(obj)
            if ~obj.testHarnessError
                try
                    save_system(obj.modelName);
                catch  ME
                    obj.setErrorMessage(ME);
                end
            end
        end
        
        %This method closes given model
        function closeModel(obj,bDiscardChanges)
            try
                if bDiscardChanges
                    bdclose(obj.modelName);
                else
                    close_system(obj.modelName);
                end
            catch  ME
                obj.setErrorMessage(ME);
            end
        end
        
        %This method loads given model
        function loadModel(obj)
            try
                load_system(obj.modelName);
            catch  ME
                obj.setErrorMessage(ME);
            end
        end
        
        function setErrorMessage(obj,ME)
            obj.Error.ME = ME;
            obj.Error.appendErrorText(ME.message);
            calStack = '##CALL STACK##';
            for ii = 1:length(ME.stack)
                calStack = sprintf('%s\n%s %s\t->\t',calStack,'file:',regexprep(ME.stack(ii).file,'.*\\',''));
                calStack = sprintf('%s %s %s\t->\t',calStack,'function:',ME.stack(ii).name);
                calStack = sprintf('%s %s %s\n',calStack,'line:',num2str(ME.stack(ii).line));
            end
            obj.Error.appendErrorText(calStack);
            obj.testHarnessError = true;
        end
        
        %This method returns the function call's Name
        function fcName = extractFunctionCallNameFromFuncPrototype(obj,functionCall)
            if ~obj.testHarnessError
                fcPrototype = get_param(functionCall,'FunctionPrototype');
                fcName = regexp(fcPrototype,'=?\w*\(','match');
                if isempty(fcName)
                    fcName = '';
                end
                fcName = erase(fcName,{'=',' ','('}); 
            else
                fcName = '';
            end
        end
        
        %This method returns the argument's name of a get event function calls
        function argumentName = getOutputArgumentName(obj,FunctionPrototype)
            argumentName = '';
            if ~obj.testHarnessError
                arg_filter1 = extractBefore(FunctionPrototype,'=');
                arg_filter2 = erase(arg_filter1,' ');
                arg_filter3 = split(arg_filter2,["[","]",","]);
                for ii = 1:length(arg_filter3)
                    if ~isempty(arg_filter3{ii}) && ~strcmp(arg_filter3{ii},'ERR')
                        argumentName = char(arg_filter3{ii});
                        break;
                    end
                end
            end
        end
        
        %This method returns the argument's name of a set event function calls
        function argumentName = getInputArgumentName(obj,FunctionPrototype)
            if ~obj.testHarnessError
                arg_filter1 = extractAfter(FunctionPrototype,'=');
                arg_filter2 = erase(arg_filter1,' ');
                argumentName = char(extractBetween(arg_filter2,"(",")"));
            else
                argumentName = '';
            end
        end
        
        %This method returns the argument's initial value and datatype of a set event function calls
        function [InitialValue Datatype] = getInputArgIVAndDatatype(obj,functionCallBlock)
            if ~obj.testHarnessError
                InitialValue = get_param(functionCallBlock,'InputArgumentSpecifications');
                Datatype = extractBefore(InitialValue,'(');
            else
                InitialValue = '';
                Datatype = '';
            end
        end
        
        %This function returns the argument's initial value and datatype of a get event function calls
        function [InitialValue Datatype] = getOutputArgIVAndDatatype(obj,functionCallBlock)
            if ~obj.testHarnessError
                arguments = get_param(functionCallBlock,'OutputArgumentSpecifications');
                InitialValue = extractBefore(arguments,',');
                if ~contains(InitialValue,'(')
                    InitialValue = strcat(InitialValue,'(0)');
                end
                Datatype = extractBefore(InitialValue,'(');
            else
                InitialValue = '';
                Datatype = '';
            end
        end
        
        %This method creates a subsystem to store function call stubs
        function createGlobalFunctionsSubsystem(obj,testHarnessName)
            if ~obj.testHarnessError
                add_block('simulink/Ports & Subsystems/Subsystem',strcat(testHarnessName,'/GlobalFunctions'));
                %Delete content created by default when create a new subsystem
                Simulink.SubSystem.deleteContents(strcat(testHarnessName,'/GlobalFunctions'));
            end
        end
        
        %This method deletes default DiagnosticService Block
        function deleteDefaultDiagnosticServiceBlock(obj,testHarnessName)
            if ~obj.testHarnessError
                DSC = find_system(testHarnessName,'Type','block','Name','Diagnostic Service Component');
                NVSC = find_system(testHarnessName,'Type','block','Name','NVRAM Service Component');
                GSF = find_system(testHarnessName,'Type','block','Name','Global Stub Functions');
                if ~isempty(GSF)
                    delete_block(GSF);
                end
                if ~isempty(NVSC)
                    delete_block(NVSC);
                end
                if ~isempty(DSC)|| ~isempty(NVSC)
                    delete_block(DSC);
                    %delete Anotation Area around the Diagnostic Service Component
                    AnnotationArea = find_system(testHarnessName,'FindAll','on','type','annotation');
                    for j = 1: length(AnnotationArea)
                        AnnotationObject = get_param(AnnotationArea(j),'Object');
                        if strcmp(AnnotationObject.getDisplayLabel,'AUTOSAR Basic Software Services')
                            AnnotationObject.delete;
                            break;
                        end
                    end
                end
            end
        end
        
        %This method replace signal spec by DatatypeConversion
        %blocks from Input Conversion Subsystem
        function replaceSigSpecByDTConversionBlocks(obj,testHarnessName)
            if ~obj.testHarnessError
                if ~isempty(obj.ICSubsystem)
                    set_param(strcat(testHarnessName,'/Input Conversion Subsystem'),'Permissions','ReadWrite');
                    replace_block(strcat(testHarnessName,'/Input Conversion Subsystem'),'SignalSpecification','DataTypeConversion','noprompt');
                end
            end
        end
        
        function updateInputConversionSubsystem(obj)
            if ~isempty(obj.ICSubsystem)
                set_param(strcat(obj.testHarnessName,'/Input Conversion Subsystem'),'Permissions','ReadWrite');
                sigSpecBlocks = find_system(obj.ICSubsystem{1},'BlockType','SignalSpecification');
                for ii =1:length(sigSpecBlocks)
                    outDatatype = get_param(sigSpecBlocks{ii},'OutDataTypeStr');
                    if startsWith(outDatatype,'Bus:')
                    else
                        replace_block(sigSpecBlocks{ii},'SignalSpecification','DataTypeConversion','noprompt');
                    end
                end
            end
        end
        
        function deleteRateTransitionBlocks(obj)
            if ~obj.testHarnessError
                if ~isempty(obj.ICSubsystem)
                    set_param(obj.ICSubsystem{1},'Permissions','ReadWrite');
                    RateTransBlocks = find_system(obj.ICSubsystem{1},'BlockType','RateTransition');
                    if ~isempty(RateTransBlocks)
                        for ii = 1:length(RateTransBlocks)
                            obj.removeAndReconnectBlock(RateTransBlocks{ii});
                        end
                    end
                end
            end
        end
        
        function updateBusCreatorConfig(obj)
            if ~obj.testHarnessError
                BusCreatorBlocks = find_system(obj.testHarnessName,'BlockType','BusCreator');
                if ~isempty(BusCreatorBlocks)
                    for ii = 1:length(BusCreatorBlocks)
                        set_param(BusCreatorBlocks{ii},'InheritFromInputs','off');
                    end
                end
            end
        end
        
        function updateRateTransitionInitCondition(obj,Path)
            if ~obj.testHarnessError
                if getSimulinkBlockHandle(Path) ~= -1
                    set_param(Path,'Permissions','ReadWrite');
                    SignalSpecBlocks = find_system(Path, 'LookUnderMasks', 'on','BlockType','SignalSpecification');
                    RateTransBlocks = find_system(Path, 'LookUnderMasks', 'on','BlockType','RateTransition');
                    UnitDelayBlock = find_system(Path, 'LookUnderMasks', 'on','BlockType','UnitDelay');
                    if (~isempty(SignalSpecBlocks)&& ~isempty(RateTransBlocks))
                        for ii = 1:length(SignalSpecBlocks)
                            blockDatatype = get_param(SignalSpecBlocks{ii},'OutDataTypeStr');
                            if startsWith(blockDatatype,'Bus:')
                                PortConnectivityParam = get_param(SignalSpecBlocks{ii}, 'PortConnectivity');
                                BlockType = get_param(PortConnectivityParam(2).DstBlock, 'BlockType');
                                if strcmp(BlockType,'RateTransition')
                                    RateTransName = get_param(PortConnectivityParam(2).DstBlock, 'Name');
                                    RateTransBlockPath = [Path,'/',RateTransName];
                                    busDatatype = erase(extractAfter(blockDatatype,'Bus:'),' ');
                                    %rateBlockName = get_param(RateTransBlocks,'Name');
                                    InitCondition = getBlockInitialCondition(obj,busDatatype);
                                    set_param(RateTransBlockPath,'InitialCondition',InitCondition);
                                    
                                    PortConnectivityParam = get_param(RateTransBlockPath, 'PortConnectivity');
                                    BlockType = get_param(PortConnectivityParam(2).DstBlock, 'BlockType');
                                    if strcmp(BlockType,'UnitDelay')
                                        UnitDelayName = get_param(PortConnectivityParam(2).DstBlock, 'Name');
                                        UnitDelayBlockPath = [Path,'/',UnitDelayName];
                                        set_param(UnitDelayBlockPath,'InitialCondition',InitCondition);
                                    end
                                end
                            end
                        end
                    end
                else
                    %path not found.
                end
            end
        end
        
        function InitCondition = getBlockInitialCondition(obj,busDatatype)
            InitCondition = {};
            if ~obj.testHarnessError
                SWCDictonary = Simulink.data.dictionary.open([obj.modelName,'.sldd']);
                modelData = getSection(SWCDictonary,'Design Data');
                %entries = find(section, '-value', '-class', 'Simulink.Bus');
                slddEntry = getEntry(modelData, busDatatype);
                if ~isempty(slddEntry)
                    ARDTBus = getValue(slddEntry);
                    ARDTbusElements = ARDTBus.getLeafBusElements;
                    % produce a cell array of cell arrays of Simulink.busElements objects:
                    InitCondition = getBusInitialValue(obj,ARDTbusElements);
                end
            end
        end
        
        function initialCondition = getBusInitialValue(obj,busElements)
            %%Get bus element's datatype and MinValue to construct initial condition
            %%for bus rate transition blocks.
            initialCondition = '';
            SWCDictonary = Simulink.data.dictionary.open([obj.modelName,'.sldd']);
            modelData = getSection(SWCDictonary,'Design Data');
            if ~obj.testHarnessError
                if (length(busElements)<1)
                    errordlg('There is a bus with zero elements.');
                else
                    initialCondition = 'struct(';
                    for ii = 1:length(busElements)
                        elementName = strcat("'",busElements(ii).Name,"'");
                        if isempty(busElements(ii).Min)
                            MinValue='0';
                        else
                            MinValue=num2str(busElements(ii).Min);
                        end
                        if ~isempty(busElements(ii).Dimensions)
                            if busElements(ii).Dimensions>1
                                MinValue = sprintf("zeros(1,%d)",busElements(ii).Dimensions);
                            end
                        end
                        if contains(busElements(ii).DataType,':')
                            slddAPDT = erase(extractAfter(busElements(ii).Datatype,':'),' ');
                            slddEntry = getEntry(modelData, slddAPDT);
                            entryValue = getValue(slddEntry);
                            MinValue = strcat(slddAPDT,'.',entryValue.DefaultValue);
                        end
                        if ii == length(busElements)
                            initialCondition = strcat(initialCondition,elementName,',',MinValue);
                        else
                            initialCondition = strcat(initialCondition,elementName,',',MinValue,',');
                        end
                    end
                    initialCondition = strcat(initialCondition ,')');
                    initialCondition = erase(initialCondition,' ');
                end
            end
        end
        
        function removeAndReconnectBlock(obj,blockHandle)
            if ~isempty(blockHandle)
                %Get port handles and parent system
                portHandles = get_param(blockHandle,'PortHandles');
                sys = get_param(blockHandle,'Parent');
                %Get source port
                srcSignal = get_param(portHandles.Inport,'Line');
                srcPort = get_param(srcSignal,'SrcPortHandle');
                %Get destination port
                destSignal = get_param(portHandles.Outport,'Line');
                destPort = get_param(destSignal,'DstPortHandle');
                %Remove
                delete_line(destSignal);
                delete_line(srcSignal);
                delete_block(blockHandle);
                %Reconnect
                add_line(sys,srcPort,destPort);
            end
        end
        
        function updateSignalSpecification(obj)
            SigSpec = find_system(obj.ICSubsystem{1},'BlockType','SignalSpecification');
            if ~obj.testHarnessError
                if ~isempty(SigSpec)
                    for ii=1:length(SigSpec)
                        set_param(SigSpec{ii},'OutDataTypeStr','Inherit: auto');
                    end
                end
            end
        end
        
        %This method return the simulink path of the top level ports
        function [Inports Outports] = getModelPorts(obj,modelName)
            Inports = {};
            Outports = {};
            if ~obj.testHarnessError
                numInports=1;
                numOutports=1;
                %Get model blocks
                blks = find_system(modelName,'Type','block');
                %Get block types
                blkType = get_param(blks, 'BlockType');
                %Looking for Inports and Ourports
                for i = 1:length(blks)
                    if ~contains(extractAfter(blks{i},[modelName,'/']),'/')
                        if ( strcmp(blkType{i},'Inport'))
                            Inports{numInports} = blks{i};
                            numInports = numInports+1;
                        elseif ( strcmp(blkType{i},'Outport'))
                            Outports{numOutports} = blks{i};
                            numOutports = numOutports+1;
                        end
                    end
                end
            end
        end
		

    end
    
    methods (Static, Access = private)
        %This method returns the node's text
        function thisText = getNodeTextContent(thisNode,sting)
            thisText = [];
            %find the node for the subproperty
            subNode = thisNode.getElementsByTagName(sting);
            
            %get node length
            lengthNode = subNode.getLength;
            
            %get the text content of the node
            try
                if(lengthNode>1)
                    %loop through the node and extract the text
                    for ii=0:subNode.getLength-1
                        thisText{ii+1,1} = char(subNode.item(ii).getTextContent);
                    end
                else
                    %get single value
                    thisText = char(subNode.item(0).getTextContent);
                end
                
            catch
                %display message if property cannot be found
                %disp(['cannot find property: ',sting]);
            end
        end
        
        function DecimalPart = isNotIntegerNumber(number)
            DecimalPart = false;
            %Convert cell to number and get the integer part
            integer_part = fix(cell2mat(number));
            %Get the number decimal part
            decimal_part = mod(abs(cell2mat(number)),1);
            if decimal_part > 0
                DecimalPart = true;
            end
        end
        
        %This method appends strings
        function text = appendText(string1, string2)
            if(strcmp(string1,''))
                text = string2;
            else
                text = [string1,'\n',string2];
            end
            
        end
        
        function block = getSrcBlockPort(blockObj)
            %Read port handle
            pHandle=get_param(blockObj,'PortHandles');
            %Get line 
            line = get_param(pHandle.Inport,'Line');  
            %read Source Port handle
            oscSrcport = get_param(line, 'Srcporthandle');
            %Get Port
            block = get(oscSrcport);
        end
    end
end