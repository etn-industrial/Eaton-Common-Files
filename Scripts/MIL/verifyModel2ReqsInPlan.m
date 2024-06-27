function varargout = verifyModel2ReqsInPlan(modelName, RQMTestCaseName,testDir, top, varargin)
%verifyModel2ReqsInPlan Verify model against requirements under test plan
%   Verify if the model complies with the high-level software requirements,
%   and then perform model coverage analysis. All tests exercise the
%   compiled model on the host computer via standard simulations. Test
%   cases not found in test plan will be disabled.
%
%   verifyModel2Reqs(ModelName, TestPlanName)
%   verifyModel2Reqs(ModelName, TestPlanName, 'TreatAsTopMdl')
%   verifyModel2Reqs(ModelName, TestPlanName, 'TreatAsTopMdl', AuthorNames)
%   verifyModel2Reqs(ModelName, TestPlanName, 'TreatAsTopMdl', AuthorNames, 'CI')
%   verifyModel2Reqs(ModelName, TestPlanName, 'TreatAsTopMdl', [], 'CI')
%   verifyModel2Reqs(ModelName, TestPlanName, [], AuthorNames, 'CI')
%	verifyModel2Reqs(ModelName, TestPlanName, [], [], 'CI')

%   Copyright 2021 The MathWorks, Inc.
try
	if ~dig.isProductInstalled('Simulink Test')
		error('A Simulink Test license is not available.');
	end
	if ~dig.isProductInstalled('Simulink Coverage')
		error('A Simulink Coverage license is not available.');
	end

	% Close all models.
	bdclose('all');

	% Clear all coverage data.
	cvexit();

	% Administer options.
	if nargin > 3 && ~isempty(top)
		isTop = true;
	else
		isTop = false;
	end


	% Delete the old results and reports if they exist.
	%resultFile = fullfile(prjDirStruct.getDirPath('HLR sim results', modelName), [prjNameConv.getNameStr('HLR sim results', modelName), '.mldatx']);
	resultFile = fullfile(testDir,[modelName,'_TestResultsFile.mldatx']);
	if exist(resultFile, 'file')
		delete(resultFile);
	end
	rptFile = fullfile(testDir,[modelName,'_TestSimReport.pdf']);
	if exist(rptFile, 'file')
		delete(rptFile);
	end
	docDir = testDir;

	cvtFile = fullfile(testDir,[modelName,'_Coverage.cvt']);
	if exist(cvtFile, 'file')
		delete(cvtFile);
	end
	htmlFile = fullfile(testDir,[modelName,'_CoverageReport.html']);
	if exist(htmlFile, 'file')
		delete(htmlFile);
	end
	gifDir = fullfile(testDir,modelName,'scv_images');
	if exist(gifDir, 'dir')
		rmdir(gifDir, 's');
	end

	% Check for prerequisites.
	RBTTestFile = fullfile(testDir,[modelName,'_TestFile.mldatx']);
	if ~exist(RBTTestFile, 'file')
		error(['Test file ''', RBTTestFile, ''' not found.']);
	end

	% Get model information.
	% If any of the test case in the test file needs to perform a load_system
	% on the test harness, querying the checksum after loading the test file
	% leads to an error. To avoid the potential error, get the checksum
	% information before loading the test file.
	load_system(modelName);
	modelVersion = get_param(modelName, 'ModelVersion');
	modifiedDate = get_param(modelName, 'LastModifiedDate');
	% if isTop
	%     modelChecksum = getModelChecksum(modelName, 'TreatAsTopMdl');
	% else
	%     modelChecksum = getModelChecksum(modelName);
	% end

	% Verify the model against HLR test cases in the test file.
	disp(['Running tests on Simulink model ', modelName, '.']);
	sltest.testmanager.clear();
	sltest.testmanager.clearResults();
	testFile = sltest.testmanager.load(RBTTestFile);

	% Activate test cases based on the test plan configuration.
	testCases = testFile.getAllTestCases();
	%activeTestCases = testPlanCfg(modelName);
	for caseIdx = 1:length(testCases)
		if ~isempty(testCases(caseIdx).getProperty('SimulationMode'))
			% If simulation mode has been overridden, restore it to [Model Settings].
			testCases(caseIdx).setProperty('SimulationMode', '');
		end
		%if any(ismember(activeTestCases, testCases(caseIdx).Name))
		if strcmp(RQMTestCaseName,testCases(caseIdx).Name)
			testCases(caseIdx).Enabled = true;
		else
			testCases(caseIdx).Enabled = false;
		end
	end
	testResult = testFile.run();

	% Attach model checksum information to test results.
	checksumStr = sprintf(['Model Version: ', modelVersion, '\n', ...
		'Model Last Modified On: ', datestr(modifiedDate(5:end), 'dd-mmm-yyyy HH:MM:SS')]);
	% Attach test case name to the test results.
	testCaseStr = sprintf(['Test Case: ', RQMTestCaseName]);
	testResult.getTestFileResults.Description = [checksumStr, newline, testCaseStr];

	% Save test results.
	sltest.testmanager.exportResults(testResult, resultFile);

	% Save coverage results.
	if ~isempty(testResult.CoverageResults)
		cvsave(cvtFile, cv.cvdatagroup(testResult.CoverageResults));
	end

	if nargin > 3 && ~isempty(varargin{1})
		authors = varargin{1};
	else
		authors = '';
	end

	result.Message = ['Requirement-based simulation test report for ', modelName, ' is successfully generated.'];
	if nargin > 4 && ~isempty(varargin{2})
		LaunchReport = false;
		cvhtmlOption = '-sRT=0';
		result.Method = 'verifyModel2Reqs';
		result.Component = modelName;
		result.NumTotal = testResult.getTestFileResults().NumTotal;
		result.NumPass = testResult.getTestFileResults().NumPassed;
		result.NumWarn = testResult.getTestFileResults().NumIncomplete;
		result.NumFail = testResult.getTestFileResults().NumFailed;
		if result.NumFail > 0
			result.Outcome = -1;
		elseif result.NumWarn > 0
			result.Outcome = 0;
		else
			result.Outcome = 1;
		end
		if ~isempty(testResult.CoverageResults)
			cov = cv.cvdatagroup(testResult.CoverageResults);
			result.ExecutionCov = executioninfo(cov, modelName);
			result.DecisionCov = decisioninfo(cov, modelName);
			result.ConditionCov = conditioninfo(cov, modelName);
			result.MCDCCov = mcdcinfo(cov, modelName);
		end
		result.Results = testResult.getTestFileResults();
		varargout{1} = result;
	else
		LaunchReport = false;
		cvhtmlOption = '-sRT=1';
		if nargout > 0
			varargout{1} = result;
		end
	end

	% Generate the test report.
	sltest.testmanager.report(testResult, rptFile, ...
		'Author', authors, ...
		'Title',[modelName, ' REQ-Based Tests'], ...
		'IncludeMLVersion', true, ...
		'IncludeTestRequirement', true, ...
		'IncludeSimulationSignalPlots', true, ...
		'IncludeComparisonSignalPlots', false, ...
		'IncludeErrorMessages', true, ...
		'IncludeTestResults', 0, ...
		'IncludeCoverageResult', true, ...
		'IncludeSimulationMetadata', true, ...
		'LaunchReport', LaunchReport);

	% Generate the coverage report.
	if ~isempty(testResult.CoverageResults)
		cvhtml(htmlFile, cv.cvdatagroup(testResult.CoverageResults), cvhtmlOption,"-sRT=0");
	end

    % fileCVT = dir('*.cvt');
    % % if there multiple CVT files stored in the test folder,
    % % delete all the CVT except Merged CVT file for coverage
    % % data
    % mergedCVTfilename = strcat(obj.testHarness.modelName,'_','MergedCovRpt');
    % if isstruct(fileCVT)
    %     for nameInfo = 1:length(fileCVT)
    %         % Idx_Merged = contains(fileCVT(nameInfo).name,mergedCVTfilename,'IgnoreCase',true) && ...
    %         %     ~contains(fileCVT(nameInfo).name,'Copy','IgnoreCase',true);
    %         % if (Idx_Merged == 1)
    %             [cvtos, cvdos] = cvload(fileCVT(nameInfo).name);
    %             cvhtml(strcat(obj.testHarness.modelName,'_','CoverageReport','.html'),cvdos{1});
    %             com.mathworks.mlservices.MatlabDesktopServices.getDesktop.closeGroup('Web Browser');
    %         % elseif strcmp(fileCVT(nameInfo).name,'coverage_data.cvt')
    %         %     %ignore file
    %         % else
    %         %     delete(fileCVT(nameInfo).name);
    %         % end
    %     end
    % else
    %     [cvtos, cvdos] = cvload(fileCVT.name);
    %     cvhtml(strcat(obj.testHarness.modelName,'_','CoverageReport','.html'),cvdos{1});
    %     com.mathworks.mlservices.MatlabDesktopServices.getDesktop.closeGroup('Web Browser');
    % end

	disp(result.Message);
	%Copy Test Report to Eaton Sharepoint
	testReportFolder=replace(char(datetime),{'-',':',' '},'_');
	tReportDestFolder=['C:\Users\E0391985\OneDrive - Eaton\MIL-Test-Report\',testReportFolder];
	mkdir(tReportDestFolder);
	copyfile(rptFile,tReportDestFolder);

	%Save sharepoint link to temp file
	[tPath,tName,tExt]=fileparts(rptFile);
	sharepointReport=[testReportFolder,'/',tName,tExt];
	%https://eaton.sharepoint.com/:f:/r/sites/48vNewSpaceInnovationTheme/Shared%20Documents/General/Firmware/06%20Validation_Results/00-Test-Progress/01-MiL_testing/MIL-Test-Report?csf=1&web=1&e=tJYOhE
	sharepointLink=replace(['https://eaton.sharepoint.com/:f:/r/sites/48vNewSpaceInnovationTheme/Shared%20Documents/General/Firmware/06%20Validation_Results/00-Test-Progress/01-MiL_testing/MIL-Test-Report/',sharepointReport],'%','%%');
	fid=fopen('C:\Temp\DownloadReportPath.txt','w+');
	fprintf(fid,sharepointLink);
	fclose(fid);
    catch ME
        disp(ME.getReport);
        exit(40);
    end
end
