classdef UnitTestFactory < handle
    %This class handles Unit Testing
    %Generates a xml file from the test case template
    %Create a test harness , run simulation and collect results
    %Generate test report
    properties
        xmlFile = XMLFileGeneration;
        testHarness = TestHarnessGeneration;
        testReport = TestReportGeneration;
        linkedTestCases = 0;
        
        UTError = UnitTestError;
        globalError = false
        OverallResultsTable
    end
    
    methods
        %Unit Test Factory creates model's test harneses and collect results into a single test report.
        %It can be invoqued either without any argument or with a folder path as an argument.
        %when invoqued without arguments it has 2 modes of operation ,user will pick 1 of these modes. 
        %Single mode: runs 1 or more test case files over a single model.
        %Batch mode: runs all test case files found in the specific path including subpaths over all models.
        %The option to run UnitTestFactory providing the path as argument
        %UnitTestFactory('CustomPath') it is intended to be used by
        %Continuos integration server Jenkins.
        function obj = UnitTestFactory(varargin)
            try
                %Script modes
                %**********************%
                BATCH_MODE = 0;
                SINGLE_MODE = 1;
                if nargin > 0
                    optSelected = BATCH_MODE;
                else
                    optSelected= getUserInput(obj);
                end
                obj.UTError.deleteLogErrorFile();
                load_system simulink;
                tic
            catch ME
                obj.setErrorMessage(ME);
            end


            if(optSelected == BATCH_MODE)
                try
                    if nargin > 0
                        rootFolder = fileparts(which('M3Inverter_startup.m'))
                        destDir = fullfile(rootFolder,varargin{1})
                        if ~exist(destDir, 'dir')
                            error('Directory:',destDir,'doesn''t exist');
                        end
                    else
                        destDir = uigetdir(pwd, 'Select destination folder to run batch mode over (MBD or any other subfolder)');
                    end
                    if destDir == 0, return, end
                    %Add flag to prevent model close callback to run
                    assignin('base','buildInProgress',true);
                    
                    obj.OverallResultsTable = table('Size',[0 13],'VariableTypes',...
                        {'categorical','categorical','categorical','categorical','categorical','categorical',...
                        'categorical','categorical','categorical','categorical','categorical','categorical','categorical'});
                    obj.OverallResultsTable.Properties.VariableNames = {'SWC_Name','System_Under_Test','File','Total_Test_Cases','Untested','Passed','Failed','LinkedTestCases',...
                                                                        'Complexity','Decision','Condition','MCDC','Execution'};
                    %Batch Mode execution
                    obj.testReport.BatchMode = true;
                    
                    MBDFolder = what('MBD');
                    TestReportStorage = strcat(MBDFolder.path,'\Unit Test Reports\');
                    if ~exist(TestReportStorage, 'dir')
                        mkdir(TestReportStorage);
                        addpath(TestReportStorage);
                    end

                    %Get folders containing xlsx files and remove duplicated paths.
                    rawFileStructs = dir([destDir '\**\*.xlsx']);
                    rawFileCells = struct2cell(rawFileStructs);
                    xlxsTestFolders = unique(rawFileCells(2,:));
                    for ii = 1:length(xlxsTestFolders)
                        xlsxFileStructs = dir([xlxsTestFolders{ii} '\*.xlsx']);
                        xlsxFileCells = struct2cell(xlsxFileStructs);
                        testFiles = xlsxFileCells(1,:);
                        testFolder = xlsxFileCells{2};
                        %testFiles = strcat(xlsxFileCells(2,:),filesep,xlsxFileCells(1,:));
                        %Discard files with wrong format.
                        %testFiles = obj.discardFilesWithWrongFormat(xlsxFileCells(1,:));
                        
                        if ~isempty(testFiles)
                            obj.testReport.Path = testFolder;
                            obj.runUnitTest(testFiles);
                            obj.copyTestReportToBatchFolder();
                            obj.updateSummaryReport();
                            obj.deleteUnwantedFiles();
                        end
                    end
                    obj.printMIlResultsSummary();
                    evalin( 'base', 'clear(''buildInProgress'')' );
                catch ME
                    obj.setErrorMessage(ME);
                end
            elseif (optSelected == SINGLE_MODE)
                try
                    %Single SWC Mode execution
                    [testFiles,obj.testReport.Path] = uigetfile('*.xlsx','Select Excel file','MultiSelect', 'on');
                    if isequal(testFiles,0) || isequal(obj.testReport.Path,0)
                        %Do nothing , no file selected
                    else
                        %testFiles = obj.discardFilesWithWrongFormat(file);
                        if ~isempty(testFiles)
                            obj.runUnitTest(testFiles);
                            obj.deleteUnwantedFiles();
                        end
                    end
                catch ME
                    obj.setErrorMessage(ME);
                end
            else
            end
            if obj.globalError
                %error(['1 or more errors found , Please check log error file: ',[obj.UTError.scriptFolder,'\UnitTest_ErrorLog.txt']]);
                disp(fileread([obj.UTError.scriptFolder,'\UnitTest_ErrorLog.txt']));
            end
            toc
        end
    end
    
    methods (Access = private)
        %This method executes the xml file,test harness and test report generation
        function runUnitTest(obj,file)
            obj.testReport.initTestReport();
            %change to directory where the file is read from
            cd(obj.testReport.Path);
            file = obj.discardFilesWithWrongFormat(file);
            %Clear previous results from Test Manager
            obj.testHarness.mergedTestSummaryData = [0 0 0 0];
            obj.testReport.HarnessIndex = 0;
            obj.testHarness.harnessCount = 0;
            obj.linkedTestCases = 0;
            obj.testHarness.coverageInfo = {};
            %check if multiple files selected
            if iscell(file)
                %read data from file
                obj.testHarness.totalHarnesses = length(file);
                for  i =1 :length(file)
                    try
                        obj.xmlFile.xmlError = false;
                        obj.testHarness.testHarnessError = false;
                        obj.testReport.testReportError= false;
                        obj.validateFile(file{i});
                        if ~obj.xmlFile.ignoreFile
                            obj.testReport.HarnessIndex = obj.testReport.HarnessIndex + 1;
                            obj.testHarness.harnessCount = obj.testReport.HarnessIndex;
                            obj.createTestHarness(file{i});
                            obj.linkedTestCases = obj.linkedTestCases + obj.xmlFile.linkedTestCasesCount;
                            % save merged coverage data
                            if ~isempty(obj.testHarness.mergedCoverageData)&&~obj.globalError
                                try
                                    cvsave(strcat(obj.testHarness.modelName,'_','MergedCovRpt'), obj.testHarness.mergedCoverageData);
                                    % generate html report for merged coverage data file
                                    ExtractCoverageInfoAll(obj);
                                catch ME
                                    obj.testHarness.setErrorMessage(ME);
                                end
                            end
                            
                            obj.reestoreAll();
                        end
                        
                    catch ME
                        obj.reestoreAll();
                        obj.setErrorMessage(ME);
                    end
                end
                if ~obj.testHarness.testHarnessError
                    obj.testHarness.closeModel(false);
                end
                if  (obj.testReport.HarnessIndex>1)
                    try
                        obj.testReport.mergedSummaryDataTable = obj.testReport.createMergedOverallSummaryTable();
                        obj.testReport.addChapterSection(obj.testReport.overallResultsChapter,[obj.testHarness.modelName,' - Merged Test Coverage'],obj.testReport.mergedCoverageTable);
                        obj.testReport.addChapterSection(obj.testReport.overallResultsChapter,[obj.testHarness.modelName,' - Merged Results'],obj.testReport.mergedSummaryDataTable);
                    catch ME
                        obj.setErrorMessage(ME);
                    end
                end
            else
                try
                    %single file selected
                    obj.xmlFile.xmlError = false;
                    obj.testHarness.testHarnessError = false;
                    obj.testReport.testReportError= false;
                    obj.validateFile(file);
                    
                    obj.testReport.HarnessIndex = 1;
                    obj.testHarness.harnessCount = 1;
                    obj.createTestHarness(file);
                    obj.linkedTestCases = obj.linkedTestCases + obj.xmlFile.linkedTestCasesCount;
                    % save merged coverage data
                    if ~isempty(obj.testHarness.mergedCoverageData)&&~obj.globalError
                        cvsave(strcat(obj.testHarness.modelName,'_','MergedCovRpt'), obj.testHarness.mergedCoverageData);
                        % generate html report for merged coverage data file
                        ExtractCoverageInfoAll(obj);
                    end
                    obj.reestoreAll();
                    if ~obj.testHarness.testHarnessError
                        obj.testHarness.closeModel(false);
                    end
                                        
                catch ME
                    obj.reestoreAll();
                    obj.setErrorMessage(ME);
                end
            end
            if (obj.testReport.HarnessIndex>0)
                %Generate test report
                obj.testReport.createCustomReport();
                obj.logTestReportError();
                
                if exist([obj.testReport.Path,'Snapshots'],'dir')
                    rmdir([obj.testReport.Path,'Snapshots'],'s');
                end
            end
        end
        
        function validateFile(obj,file)
            try
                %initialize SignalBuilder property from xmlFile obj
                obj.xmlFile.signalBuilderGroupActive = {};
                %create an xml file from an excel file
                obj.xmlFile.Convert_xlsx_to_xml(file);
                if obj.xmlFile.ignoreFile
                    obj.testHarness.Error.appendErrorText('This file doesn''t match with the test case template format.');
                    disp('This file doesn''t match with the test case template format.')
                end
            catch ME
                obj.setErrorMessage(ME);
            end
        end
        
        function testFiles = discardFilesWithWrongFormat(obj,files)
            testFiles = {};
            if iscell(files)
                validFileCounter = 1;
                for ii = 1: length(files)
                    try
                        [~,~,rawData] = xlsread(files{ii});
                    catch ME
                        obj.setErrorMessage(ME);
                    end
                    [found,~,~] = obj.xmlFile.findString(string(rawData),'TestHarnessName');
                    if found
                        testFiles{validFileCounter} = files{ii};
                        validFileCounter = validFileCounter + 1;
                    else
                        %Ignore file
                    end
                end
                if length(testFiles)==1
                    testFiles = testFiles{1};
                end
            else
                [~,~,rawData] = xlsread(files);
                [found,~,~] = obj.xmlFile.findString(string(rawData),'TestHarnessName');
                if found
                    testFiles = files;
                else
                    %Ignore file
                end
            end
        end
        
        %This method creates the test harness
        function createTestHarness(obj,file)
            try
                obj.testHarness.Error.addTextToFile(['******************************************',...
                    '******************************************',...
                    '\nProccessing file: ',file]);
                disp(['** Proccessing file: ',obj.formatPrintMessage(file)]);
                %create test harness,run simulation and collect results
                obj.testHarness.createTestHarness(obj.xmlFile);
                %log errors if exist
                obj.logTestHarnessError();
                %create test report content
                obj.testReport.generateTestReport(obj.testHarness,obj.xmlFile.xlsxData);
                %log errors if exist
                obj.logTestReportError();
            catch ME
                
                obj.setErrorMessage(ME);
            end
        end
        
        %This method gets the script's execution mode
        function optSelected= getUserInput(obj)
            try
                obj.testReport.BatchMode = false;
                %get execution mode from user
                disp('Select script execution mode:');
                disp('Batch SWC mode : 0');
                disp('Single SWC mode : 1');
                userInput =  input('mode:');
                if isempty(userInput)
                    userInput = '1';
                elseif userInput == 0|| userInput == 1
                else
                    disp('InvalidSelection');
                    userInput = '-1';
                end
                optSelected = userInput;
            catch ME
                obj.setErrorMessage(ME);
            end
        end
        
        %This method copies the generated test report into Unit Test Report
        %folder when batch mode selected
        function copyTestReportToBatchFolder(obj,testFile)
            if ~obj.testHarness.testHarnessError && ~obj.testReport.testReportError
                try
                    batchFolder = what('Unit Test Reports');
                    FileName = [obj.testReport.subsystemName ,' Test Report.pdf'];
                    source = fullfile(obj.testReport.Path,FileName);
                    destination = fullfile(batchFolder.path,FileName);
                    copyfile(source,destination);
                    
                        if isfield(obj.testHarness.coverageInfo,'Complexity')
                            Complexity = obj.testHarness.coverageInfo.Complexity;
                        else
                            Complexity = 'X';
                        end
                        if isfield(obj.testHarness.coverageInfo,'Decision')
                            Decision = obj.testHarness.coverageInfo.Decision;
                        else
                            Decision = 'X';
                        end
                        if isfield(obj.testHarness.coverageInfo,'Condition')
                            Condition = obj.testHarness.coverageInfo.Condition;
                        else
                            Condition = 'X';
                        end
                        if isfield(obj.testHarness.coverageInfo,'MCDC')
                            MCDC = obj.testHarness.coverageInfo.MCDC;
                        else
                            MCDC = 'X';
                        end
                        if isfield(obj.testHarness.coverageInfo,'Execution')
                            Execution = obj.testHarness.coverageInfo.Execution;
                        else
                            Execution = 'X';
                        end
                    
                    obj.OverallResultsTable(length(obj.OverallResultsTable.SWC_Name)+1,:) = {obj.testReport.modelName,...
                        obj.testHarness.subsystemName,...
                        obj.testHarness.testHarnessName,...
                        string(obj.testHarness.mergedTestSummaryData(1)),...
                        string(obj.testHarness.mergedTestSummaryData(2)),...
                        string(obj.testHarness.mergedTestSummaryData(3)),...
                        string(obj.testHarness.mergedTestSummaryData(4)),...
                        string(obj.linkedTestCases),...
                        Complexity,Decision,Condition,MCDC,Execution};
                catch ME
                    obj.setErrorMessage(ME);
                end
            end
        end
        %This method in case of an error reestores any configuration changed in DD or model
        %configuration,closes model and test harness.
        function reestoreAll(obj)
            if obj.testHarness.testHarnessError
                try
                    SWCDictonary = Simulink.data.dictionary.open([obj.testHarness.modelName,'.sldd']);
                    modelData = getSection(SWCDictonary,'Design Data');
                    discardChanges(SWCDictonary);
                    
                    obj.testHarness.closeHarness(true);
                    
                    obj.testHarness.closeModel(true);
                    if (obj.xmlFile.totalTestCases>0)
                        obj.linkedTestCases = obj.xmlFile.linkedTestCasesCount;
                        obj.OverallResultsTable(length(obj.OverallResultsTable.SWC_Name)+1,:) = {obj.testHarness.modelName,...
                            obj.testHarness.subsystemName,...
                            obj.testHarness.testHarnessName,...
                            string(0),...
                            string(obj.xmlFile.totalTestCases),...
                            string(0),...
                            string(0),...
                            string(obj.linkedTestCases),...
                            'X','X','X','X','X'};
                    end
                    obj.linkedTestCases = 0;
                catch ME
                    obj.setErrorMessage(ME);
                end
                obj.testHarness.testHarnessError = false; %disable error to allow execution of following methods.
                
                obj.testHarness.testHarnessError = true; %Enable error back.
                delete([obj.testReport.Path,'LoggedWarningsFromCommandWindow']);
                delete([obj.testReport.Path,[obj.testReport.testHarnessName,'_TestReport.docx']]);
            else
                obj.testHarness.closeHarness(false);
                obj.testHarness.saveModel();
            end
            %obj.testHarness.restoreMultiTaskingInReferencedConfiguration();
            
        end
        
        function logTestHarnessError(obj)
            if obj.testHarness.testHarnessError
                if isempty(obj.testHarness.modelName)
                    obj.testHarness.Error.Msg = strcat('ModelName : ',obj.testHarness.Error.ME.message);
                elseif isempty(obj.testHarness.testHarnessName)
                    obj.testHarness.Error.Msg = strcat('Test Harness Name : ',obj.testHarness.Error.ME.message);
                elseif isempty(obj.testHarness.subsystemPath)
                    obj.testHarness.Error.Msg = strcat('SubsystemPath : ',obj.testHarness.Error.ME.message);
                else
                    obj.testHarness.Error.Msg = obj.testHarness.Error.ME.message;%getReport(obj.testHarness.Error.ME);
                end
                %obj.testHarness.Error.logErrors();
                obj.globalError = true;
            end
        end
        
        function logTestReportError(obj)
            if obj.testReport.testReportError
                %obj.testReport.Error.Msg = getReport(obj.testReport.Error.ME);
                obj.testReport.Error.Msg = obj.testReport.Error.ME.message;
                %obj.testReport.Error.logErrors();
                obj.globalError = true;
            end
        end
        
        function setErrorMessage(obj,ME)
            obj.UTError.ME = ME;
            obj.UTError.appendErrorText(ME.message);
            calStack = '##CALL STACK##';
            for ii = 1:length(ME.stack)
                ME_stack_file=obj.formatPrintMessage(regexprep(ME.stack(ii).file,'.*\\',''));
                ME_stack_name=obj.formatPrintMessage(ME.stack(ii).name);
                calStack = sprintf('%s\n%s %s\t->\t',calStack,'file:',ME_stack_file);
                calStack = sprintf('%s %s %s\t->\t',calStack,'function:',ME_stack_name);
                calStack = sprintf('%s %s %s\n',calStack,'line:',num2str(ME.stack(ii).line));
            end
            obj.UTError.appendErrorText(calStack);
        end
        
        function updateSummaryReport(obj)
            batchFolder = what('Unit Test Reports');         
            writetable(obj.OverallResultsTable,[batchFolder.path,'\UnitTestOverallResults.xlsx']);
            copyfile([obj.UTError.scriptFolder,'\UnitTest_ErrorLog.txt'],batchFolder.path);
        end
        
        function printMIlResultsSummary(obj)
            batchFolder = what('Unit Test Reports');
            % Result Summary Log
            totalTC=sum(double(string(obj.OverallResultsTable.Total_Test_Cases))+double(string(obj.OverallResultsTable.Untested)));
            passedTC=sum(double(string(obj.OverallResultsTable.Passed)));
            untestedTC=sum(double(string(obj.OverallResultsTable.Untested)));
            failedTC=sum(double(string(obj.OverallResultsTable.Failed)));
            compCovTab=obj.OverallResultsTable;
            compCovTab(compCovTab.Complexity=='X', :)=[];
            Complexity=mean(double(string(compCovTab.Complexity)));
            decisionCovTab=obj.OverallResultsTable;
            decisionCovTab(decisionCovTab.Decision=='X', :)=[];
            Decision=mean(double(erase(string(decisionCovTab.Decision),'%')));
            conditionCovTab=obj.OverallResultsTable;
            conditionCovTab(conditionCovTab.Condition=='X', :)=[];
            Condition=mean(double(erase(string(conditionCovTab.Condition),'%')));
            mcdcCovTab=obj.OverallResultsTable;
            mcdcCovTab(mcdcCovTab.MCDC=='X', :)=[];
            MCDC=mean(double(erase(string(mcdcCovTab.MCDC),'%')));
            executionCovTab=obj.OverallResultsTable;
            executionCovTab(executionCovTab.Execution=='X', :)=[];
            Execution=mean(double(erase(string(executionCovTab.Execution),'%')));
            fid=fopen([batchFolder.path,'\mil_summary.txt'],'w+');
            fprintf(fid,['Total Test Cases: ',num2str(totalTC),'\n']);
            fprintf(fid,['Passed Test Cases: ',num2str(passedTC),'\n']);
            fprintf(fid,['Untested Test Cases: ',num2str(untestedTC),'\n']);
            fprintf(fid,['Failed Test Cases: ',num2str(failedTC),'\n']);
            if isnan(Complexity)
                fprintf(fid,'Complexity Coverage: \n');
            else
                fprintf(fid,'Complexity Coverage: %.2f\n',Complexity);
            end
            if isnan(Decision)
                fprintf(fid,'Decision Coverage: \n');
            else
                fprintf(fid,'Decision Coverage: %.2f%%\n',Decision);
            end
            if isnan(Condition)
                fprintf(fid,'Condition Coverage: \n');
            else
                fprintf(fid,'Condition Coverage: %.2f%%\n',Condition);
            end
            if isnan(MCDC)
                fprintf(fid,'MCDC Coverage: \n');
            else
                fprintf(fid,'MCDC Coverage: %.2f%%\n',MCDC);
            end
            if isnan(Execution)
                fprintf(fid,['Execution Coverage: \n']);
            else
                fprintf(fid,'Execution Coverage: %.2f%%\n',Execution);
            end
            fclose(fid);
        end
        function ExtractCoverageInfoAll(obj)
            if ~obj.globalError
                try
                    disp('processing merged coverage data file:');
                    % find .CVT files stored in the SWC test folder
                    fileCVT = dir('*.cvt');
                    % if there multiple CVT files stored in the test folder,
                    % delete all the CVT except Merged CVT file for coverage
                    % data
                    mergedCVTfilename = strcat(obj.testHarness.modelName,'_','MergedCovRpt');
                    if isstruct(fileCVT)
                        for nameInfo = 1:length(fileCVT)
                            Idx_Merged = contains(fileCVT(nameInfo).name,mergedCVTfilename,'IgnoreCase',true) && ...
                                ~contains(fileCVT(nameInfo).name,'Copy','IgnoreCase',true);
                            if (Idx_Merged == 1)
                                [cvtos, cvdos] = cvload(fileCVT(nameInfo).name);
                                cvhtml(strcat(obj.testHarness.modelName,'_','CoverageReport','.html'),cvdos{1});
                                com.mathworks.mlservices.MatlabDesktopServices.getDesktop.closeGroup('Web Browser');
                            elseif strcmp(fileCVT(nameInfo).name,'coverage_data.cvt')
                                %ignore file
                            else
                                delete(fileCVT(nameInfo).name);
                            end
                        end
                    else
                        [cvtos, cvdos] = cvload(fileCVT.name);
                        cvhtml(strcat(obj.testHarness.modelName,'_','CoverageReport','.html'),cvdos{1});
                        com.mathworks.mlservices.MatlabDesktopServices.getDesktop.closeGroup('Web Browser');
                    end
                catch ME
                    obj.setErrorMessage(ME);
                end
            end
        end
        
        function deleteUnwantedFiles(obj)
            folderContent = dir(obj.testReport.Path);
            unwantedFolders={'scv_images','slcov_output','Snapshots'};
            unwantedFiles={'scv_images','slcov_output','Snapshots'};
            for k = 3 : length(folderContent)
                contentName = folderContent(k).name;
                fullPath = fullfile(folderContent(k).folder, contentName);
                try
                if isfolder(fullPath)
                    if ismember(contentName,unwantedFolders)
                        rmpath(fullPath);
                        [status,msg] = rmdir(fullPath,'s');
                    else
                        %Ignore folder
                    end
                elseif isfile(fullPath)
                    [folderN,fileN,ext]=fileparts(fullPath);
                    if isempty(ext)|| strcmp(ext,'.cvt')
                        delete(fullPath);
                    end
                else
                    %Do nothing
                end
                catch ME
                    disp(ME.identifier);
                end
            end
        end
        
        function formatedMessage=formatPrintMessage(obj,message)
            formatedMessage  = regexprep(message ,'%','%%');
            formatedMessage  = regexprep(formatedMessage ,'\\','\\\\');
        end
    end
end