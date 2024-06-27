% NAME:
% 	UnitTestExport
% 
% DESCRIPTION:
% 	This script exports existing test cases from Simulink to RQM, it also
% 	executes test cases and collect results to be uploaded  back to RQM
% 	when configured so.
% USAGE:
% 	 UnitTestExport 'ExportTestCasesToRQM' : Export all test cases whitin
% 	 MDB folder to RQM - skips the ones already exist in RQM.
%    UnitTestExport 'TesCaseName': execute the specified test case and
%    upload test result to shared sharepoint location.
%    UnitTestExport 'TesCaseName' 'username' 'password': skip the RQM
%    connection promt and uses provided user name and password to
%    syncronize matlab and RQM.
function UnitTestExport(arg1,varargin)

rootFolder = fileparts(which('build.m'));
if nargin == 1
    obj=RQMSync;
elseif nargin == 3
    obj=RQMSync(varargin(1),varargin(2));
else
    displayHelp();
    return
end

if strcmp(arg1,'ExportTestCasesToRQM')
    testFiles = dir([rootFolder '\MBD\**\*_TestFile.mldatx']);
    for ff=1:length(testFiles)
        testDir=testFiles(ff).folder;
        modelDir=extractBefore(testDir,'\Test');
        disp(modelDir);
        modelName=erase(modelDir,regexp(modelDir,'.*\','match'));
        if exist([modelName,'.slx']) ~= 4
            disp(['Model: ',modelName, 'Not Found.']);
            %Error out
            continue;
        end
        obj.genRQMTestCases(modelName,testDir);
    end
    return
    %exit(0);
else
    %Extract model name from test case name
    % Test Case Naming Convention TC_ReqLevel_Platform_Feature_ModelName_NameofTest
    modelName=extractAfter(arg1,'_');
    modelName=extractAfter(modelName,'_');
    modelName=extractAfter(modelName,'_');
    modelName=extractAfter(modelName,'_');
    modelName=extractBefore(modelName,'_');
    if exist([modelName,'.slx']) ~= 4
        disp(['Model: ',modelName, ' Not Found. Make sure TC name is correct.']);
        %Error out
        exit(40);
    end
    testFiles = dir([rootFolder '\MBD\**\',modelName,'_TestFile.mldatx']);
    testCaseName=arg1;
end

if isempty(testFiles)

    disp(['Test File for ',modelName, ' Not Found.']);
    return

else
    if namingComventionCompliance(modelName,testCaseName)
        testDirectory=testFiles(1).folder;
        verifyModel2ReqsInPlan(modelName, testCaseName,testDirectory);
        obj.genRQMTestResults(modelName,testCaseName,testDirectory);
    else
        exit(40);
    end

end
%exit(0);
end

function validName = namingComventionCompliance(modelName,testCaseName)
    try
        validName = true;
    
        %Test case naming convention
        %TC_400L_MIL_FEATURE_MODELNAME_TESTNAME_XXX
        REGEXP_PATTERN=['TC_400L_MIL_[a-zA-Z0-9]+_',modelName,'_[a-zA-Z0-9]+_\d\d\d'];
        tcName=regexp(testCaseName,REGEXP_PATTERN,'match');
        if isempty(tcName)
            %Invalid name
            validName = false;
        else
            %Test case name is compliant with naming convention.
        end
    
        if ~validName
            disp(['## Invalid test case name:',testCaseName]);
            disp('Update test case name to this format: TC_400L_MIL_FEATURE_MODELNAME_TESTNAME_XXX');
            disp('Where:');
            disp('FEATURE = Diag|InputMgmt|OutputMgmt|Control.');
            disp('TESTNAME = Descriptive Name of what the test case is meant to test.');
            disp('XXX = 3 digit test case number starting with 001.');
        end
    catch ME
        disp(ME.getReport);
        exit(40);
    end
end

function displayHelp()
    strHelp=sprintf('\n\nNAME:\n\tUnitTestExport');
    strHelp=sprintf('%s\n\nDESCRIPTION:\n\tThis script exports existing test cases from Simulink to RQM, it also executes test cases and collect results to be uploaded back to RQM when commanded so.',strHelp);
    strHelp=sprintf(['%s\n\nUSAGE:\n\t UnitTestExport ''ExportTestCasesToRQM'' : Export all test cases found whitin MDB folder to RQM - skips the ones already exist in RQM.',...
                     '\n\t\t <strong>i.e. </strong> UnitTestExport ''ExportTestCasesToRQM''',...
                     '\n\t UnitTestExport ''TesCaseName'': execute the specified test case and upload test result to shared sharepoint location.',...
                     '\n\t\t <strong>i.e. </strong> UnitTestExport ''TC_400L_MIL_Diag_HiLvlDiagHeatrEl_HighLevelDiagHeaterElementFltAgg_001''',...
                     '\n\t UnitTestExport ''TesCaseName'' ''username'' ''password'': skip the RQM login promt and uses provided user name and password to syncronize matlab and RQM.',...
                     '\n\t\t <strong>i.e. </strong> UnitTestExport ''TC_400L_MIL_Diag_HiLvlDiagHeatrEl_HighLevelDiagHeaterElementFltAgg_001'' ''EXXXXX'' ''abc123'''],strHelp);
    disp(strHelp);

end