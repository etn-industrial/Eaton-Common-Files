classdef RQMSync < handle
    %RQMSYNC Synchonizer for Simulink Test and Rational Quality Manager.

    % Copyright 2021 The MathWorks, Inc.

    properties
        oslcClient oslc.Client;
        verbose logical = true;
        testUrl2RQMTER; % Map of test case URL to RQM test case execution record.
        resultShortId2RQMTR; % Map of test case result short ID to RQM test case result.
        testCaseCustomAttributes; % Custom attributes of RQM test case.
        testExecutionCustomAttributes; % Custom attributes of RQM test execution record.
        rootFolder = fileparts(which('build.m'));
        shortIdArray = [];
        exitcode_PASSED=0;
        exitcode_FAILED=1;
        exitcode_ERROR=40;
        exitcode_INCOMPLETE=41;
        exitcode_INCONCLUSIVE=42;
        exitcode_BLOCKED=43;
        exitcode_PARTIALLY_BLOCKED=44;
        exitcode_PERMANENTLY_FAILED=45;
        exitcode_DEFERRED=46;
    end

    methods
        function this = RQMSync(varargin)
            try
                this.oslcClient = oslc.Client;
                this.testUrl2RQMTER = containers.Map('KeyType', 'char', 'ValueType', 'Any');
                this.resultShortId2RQMTR = containers.Map('KeyType', 'char', 'ValueType', 'Any');
                cfg = setJazzCredentials();
                this.testCaseCustomAttributes = cfg.TestCaseCustomAttributes;
                this.testExecutionCustomAttributes = cfg.TestExecutionCustomAttributes;
                this.setServer(cfg.Server);
                this.setServiceRoot(cfg.ServiceRoot);
                this.setCatalogPath(cfg.CatalogPath);
                if nargin > 1
                    this.setCredentials(varargin(1),varargin(2));
                else
                    this.setUser(cfg.User);
                end
                this.login();
                this.setServiceProvider(cfg.ServiceProvider);
                this.setConfigurationContext(cfg.ConfigurationContext);
            catch ME
                disp(ME.getReport);
                exit(this.exitcode_ERROR);
            end
        end
        
        function setCredentials(this,userName,Password)
            try
                creds = matlab.net.http.Credentials('Username',userName,'Password', ...
                    Password,'scheme',matlab.net.http.AuthenticationScheme.Basic);
                opts = matlab.net.http.HTTPOptions('Credentials',creds);
                setHttpOptions(this.oslcClient,opts);
            catch ME
                disp(ME.getReport);
                exit(this.exitcode_ERROR);
            end
        end

        function setServer(this, server)
            try
                this.oslcClient.setServer(server);
            catch ME
                disp(ME.getReport);
                exit(this.exitcode_ERROR);
            end
        end

        function setServiceRoot(this, root)
            try
                this.oslcClient.setServiceRoot(root);
            catch ME
                disp(ME.getReport);
                exit(this.exitcode_ERROR);
            end
        end

        function setCatalogPath(this, path)
            try
                this.oslcClient.setCatalogPath(path);
            catch ME
                disp(ME.getReport);
                exit(this.exitcode_ERROR);
            end
        end

        function setUser(this, user)
            try
                this.oslcClient.setUser(user);
            catch ME
                disp(ME.getReport);
                exit(this.exitcode_ERROR);
            end
        end

        function login(this)
            try
                this.oslcClient.login();
            catch ME
                disp(ME.getReport);
                exit(this.exitcode_ERROR);
            end
        end

        function setServiceProvider(this, provider)
            try
                this.oslcClient.setServiceProvider(provider);
            catch ME
                disp(ME.getReport);
                exit(this.exitcode_ERROR);
            end
        end

        function setConfigurationContext(this, context)
            try
                this.oslcClient.setConfigurationContext(context);
            catch ME
                disp(ME.getReport);
                exit(this.exitcode_ERROR);
            end
        end

        function createdTCs = genRQMTestCases(this, modelName, testDir)
            try
                this.shortIdArray = [];
                sltest.testmanager.clear();
                sltest.testmanager.clearResults();
                createdTCs = oslc.qm.TestCase.empty();
    
                % Map of test case short ID to RQM test case.
                testShortId2RQMTC = containers.Map('KeyType', 'char', 'ValueType', 'Any');
    
                % Map of test case short ID to Simulink test case.
                testShortId2SLTC = containers.Map('KeyType', 'char', 'ValueType', 'Any');
    
                % Get all applicable test cases in Simulink.
                mldatxFiles = dir(fullfile(testDir, '**', '*.mldatx'));
                testCases = [];
                disp(['scaning folder:',testDir]);
                for i = 1:length(mldatxFiles)
                    if strcmp(mldatxFiles(i).name,[modelName,'_TestFile.mldatx']);
                        mldatxFile = fullfile(mldatxFiles(i).folder, mldatxFiles(i).name);
                        if this.isSLTestFile(mldatxFile)
                            testFile = sltest.testmanager.load(mldatxFile);
                            testCases = [testCases, testFile.getAllTestCases()]; %#ok<AGROW>
                        end
                    else
                        disp(['## Invalid Test File Name:',mldatxFiles(i).name]);
                        disp('## File name must be: ModelName_TestFile.mldatx');
                    end
                end
    
                % Get existing test cases in RQM.
                queryService = this.oslcClient.getQueryService('TestCase');
    
                % Create or update RQM test cases.
                creationFactory = this.oslcClient.getCreationFactory('TestCase');
                creationFactoryTER = this.oslcClient.getCreationFactory('TestExecutionRecord');
                for i = 1:length(testCases)
                    if this.namingComventionCompliance(modelName,testCases(i).Name)
                        slTestCase = testCases(i);
                        shortId = this.getShortIdFromTestCase(slTestCase);
                        if ~isempty(shortId)
                            queryService.setQueryParameter(['oslc.where=oslc:shortId=',char(shortId)])
                            rqmTestCase = queryService.queryTestCases();
                        else
                        rqmTestCase={};
                    end
                    if isempty(rqmTestCase)
                        % RQM test case does not exist.
                        rqmTestCase = this.addRQMTestCase(slTestCase, creationFactory);
                        shortId = rqmTestCase.getProperty('oslc:shortId');
                        this.updateRQMTestCase(slTestCase, rqmTestCase, modelName);
                        createdTCs(end+1) = rqmTestCase; %#ok<AGROW>
                        rqmTER = this.addRQMTestExecutionRecord(rqmTestCase.Title, creationFactoryTER, rqmTestCase.ResourceUrl);
                    else
                            % RQM test case already exists.
                            this.updateRQMTestCase(slTestCase, rqmTestCase, modelName);
                        end
                        testShortId2SLTC(shortId) = slTestCase;
                        %Store proccesed test cases ID
                        this.shortIdArray(i)=str2num(shortId);
                    else
                        %Invalid Test Case naming convention, do not export
                        %it.
                    end
                end
                % Save Simulink test files to keep added tags and decriptions
                % of synchoronized test cases.
                loadedTestFiles = sltest.testmanager.getTestFiles();
                for i = 1:length(loadedTestFiles)
                    if loadedTestFiles(i).Dirty
                        loadedTestFiles(i).saveToFile();
                    end
                end
    
                return
                % Delete obsolete RQM test cases.
                queryService = this.oslcClient.getQueryService('TestCase'); 
                rqmTestCases = queryService.queryTestCases();
                for i = 1:length(rqmTestCases)
                    if rqmTestCases(i).Dirty
                        rqmTestCases(i).fetch();
                    end
                    description = rqmTestCases(i).getProperty('dcterms:description');
                    textCell = strtrim(regexp(description, 'Model: (.+)\n', 'tokens', 'once'));
                    % Make an attempt to delete ONLY if the test case is
                    % automatically created.
                    if ~isempty(textCell)
                        try
                            rqmModelName = textCell{1};
                            rqmShortId = rqmTestCases(i).getProperty('oslc:shortId');
                            if strcmp(rqmModelName, modelName) && ~testShortId2SLTC.isKey(rqmShortId)
                                % Remove RQM test case that is created for the model if
                                % it is obsolete.
                                rqmLinks = rqmTestCases(i).getRequirementLinks();
                                for j = 1:length(rqmLinks)
                                    this.removeLinkFromRequirementToTestCase(rqmLinks(j).ResourceUrl, rqmTestCases(i));
                                end
                                rqmTestCases(i).remove();
                            end
                        catch ME
                            warning(ME.message);
                        end
                    end
                end
            catch ME
                disp(ME.getReport);
                exit(this.exitcode_ERROR);
            end
        end

        function testPlanCfg = genSLTestPlan(this, testPlanName, testDir)
            try
                % Map of Simulink model to Simulink test cases in test plan.
                model2SLTCs = containers.Map('KeyType', 'char', 'ValueType', 'Any');
    
                % Get the test plan in RQM.
                rqmTestPlan = this.getRQMTestPlan(testPlanName);
                if isempty(rqmTestPlan)
                    warning(['Test plan ', testPlanName, ' not found.']);
                    testPlanCfg = model2SLTCs;
                    return;
                end
    
                % Get test cases in the test plan.
                rqmTestCases = getRQMTestCases(this, rqmTestPlan);
    
                % Breakdown test cases in the test plan by model.
                for i = 1:length(rqmTestCases)
                    description = rqmTestCases(i).getProperty('dcterms:description');
                    if~isempty(description)
                        textCell = strtrim(regexp(description, 'Model: (.+)\n', 'tokens', 'once'));
                        modelName = textCell{1};
                        modelName = strtrim(strrep(modelName, 'URL:', '')); % This is just a safeguard.
                        if model2SLTCs.isKey(modelName)
                            model2SLTCs(modelName) = [model2SLTCs(modelName), rqmTestCases(i).Title];
                        else
                            model2SLTCs(modelName) = {rqmTestCases(i).Title};
                        end
                    else
                        %Do Nothing
                    end
                end
    
                % Create the complementary Simulink test plan.
                testPlanDir = testDir;
                if ~exist(testPlanDir, 'dir')
                    mkdir(testPlanDir);
                end
                testPlanCfg = model2SLTCs;
                save(fullfile(testPlanDir, [testPlanName, '.mat']), 'testPlanCfg');
            catch ME
                disp(ME.getReport);
                exit(this.exitcode_ERROR);
            end
        end

        function [createdTERs, createdTRs] = genRQMTestResults(this, modelName,RQMTestCaseName, testDir)
            try
                createdTERs = oslc.qm.TestExecutionRecord.empty();
                createdTRs = oslc.qm.TestResult.empty();
                this.testUrl2RQMTER = containers.Map('KeyType', 'char', 'ValueType', 'Any');
                this.resultShortId2RQMTR = containers.Map('KeyType', 'char', 'ValueType', 'Any');
                % return
                % Map of test case short ID to RQM test case.
                testShortId2RQMTC = containers.Map('KeyType', 'char', 'ValueType', 'Any');

                testResultTimeStamp = containers.Map('KeyType', 'char', 'ValueType', 'Any');

                % Get test case results in Simulink that are applicable to the
                % test plan.
                [testCaseResults, testCaseResultFiles] = this.getSLTestCaseResults(modelName, RQMTestCaseName,testDir);
                if isempty(testCaseResults)
                    % No test results available.
                    return;
                end

                queryService = this.oslcClient.getQueryService('TestCase');
                % Create or update RQM test case execution records and test
                % case results.
                creationFactoryTER = this.oslcClient.getCreationFactory('TestExecutionRecord');
                creationFactoryTR = this.oslcClient.getCreationFactory('TestResult');
                for i = 1:length(testCaseResults)
                    slTR = testCaseResults(i);
                    resultFile = testCaseResultFiles{i};
                    if slTR.Outcome ~= 0 % Not disabled.
                        tcShortId = this.getShortIdFromTestCaseResult(slTR);
                        disp(['Shor ID from simulink TC is:',tcShortId]);
                        % Get test cases in the test plan.
                        %rqmTestCases = getRQMTestCases(this, rqmTestPlan);
                        switch char(slTR.Outcome)
                            case 'Failed'
                                exit(this.exitcode_FAILED);
                            case 'Passed'
                                exit(this.exitcode_PASSED);
                            otherwise
                                exit(this.exitcode_ERROR);
                        end
                        queryService.setQueryParameter(['oslc.where=oslc:shortId=',char(tcShortId)]);
                        rqmTestCases = queryService.queryTestCases();
                        if~isempty(rqmTestCases)
                            testShortId2RQMTC(tcShortId) = rqmTestCases;

                            % Get existing test case execution records in RQM associated with Test Case with tcShortId .
                            queryServiceTER = this.oslcClient.getQueryService('TestExecutionRecord');
                            TERParam=this.createTER(rqmTestCases.ResourceUrl);
                            queryServiceTER.setQueryParameter(['oslc.where=oslc_qm:runsTestCase',TERParam])
                            rqmTestExecutionRecords = queryServiceTER.queryTestExecutionRecords();
                            if length(rqmTestExecutionRecords) > 1
                                currentRQMTestExecutionReport=rqmTestExecutionRecords(1);
                            else
                                currentRQMTestExecutionReport=rqmTestExecutionRecords;
                            end

                            if ~isempty(currentRQMTestExecutionReport)

                                currentRQMTestExecutionReport.fetch(this.oslcClient);
                                disp(['reusing found TER:',currentRQMTestExecutionReport.Title]);
                                disp(['TER Identifier:',currentRQMTestExecutionReport.Identifier]);
                                this.testUrl2RQMTER(rqmTestCases.ResourceUrl) = currentRQMTestExecutionReport;
                            end

                            %Get existing test case results in RQM.
                            queryServiceTR = this.oslcClient.getQueryService('TestResult');
                            TRTitle=this.createTitle(RQMTestCaseName);
                            queryServiceTR.setQueryParameter(['oslc.where=dcterms:title',TRTitle]);
                            rqmTestResults = queryServiceTR.queryTestResults();
                            timeStampArray=[];
                            for i = 1:length(rqmTestResults)
                                rqmTestResults(i).fetch(this.oslcClient);
                                rawTimeStamp=rqmTestResults(i).getProperty('dcterms:modified');
                                timestamp=replace(rawTimeStamp,{'T','Z'},' ');
                                timeStampArray=[timeStampArray datetime(timestamp)];
                                testResultTimeStamp(char(datetime(timestamp)))=rqmTestResults(i);
                                this.resultShortId2RQMTR(rqmTestResults(i).getProperty('oslc:shortId')) = rqmTestResults(i);
                                %latestTestResult=rqmTestResults(i);
                            end
                            if ~isempty(timeStampArray)
                                latestTimeStamp=max(timeStampArray);
                                latestTestResult=testResultTimeStamp(char(latestTimeStamp));
                            end
                            if isempty(currentRQMTestExecutionReport)
                                disp('creating new Test Execution report');
                                rqmTC = testShortId2RQMTC(tcShortId);
                                rqmTER = this.addRQMTestExecutionRecord(slTR.Name, creationFactoryTER, rqmTC.ResourceUrl);
                                latestTestResult=this.addRQMTestResult(factoryTR, slTR, rqmTER);
                                this.updateRQMTestExecutionRecord(resultFile, slTR, rqmTER,latestTestResult, creationFactoryTR);
                                createdTERs(end+1) = rqmTER; %#ok<AGROW>
                            else
                                disp(['updating found TER:',currentRQMTestExecutionReport.Title]);
                                this.updateRQMTestExecutionRecord(resultFile, slTR, currentRQMTestExecutionReport,latestTestResult, creationFactoryTR);
                            end
                        else
                            error(['Test Case:',slTR.Name,' with ID:', ' ''',tcShortId,' ''',' doesn''t exist in RQM. Export Simulink test cases to RQM and then execute them from RQM.']);
                        end
                    end
                end
            catch ME
                disp(ME.getReport);
                exit(this.exitcode_ERROR);
            end
        end
    end
    methods (Access = private)
        function isTestFile = isSLTestFile(~, file)
            % Check if the MLDATX file is a test file.
            [~, ~, ext] = fileparts(file);
            if strcmpi(ext, '.mldatx')
                description = matlabshared.mldatx.internal.getDescription(file);
                isTestFile = strcmp(description, message('stm:general:TestFileDescription').getString());
            else
                isTestFile = false;
            end
        end

        function isResultFile = isSLTestResultFile(~, file)
            % Check if the MLDATX file is a test result file.
            [~, ~, ext] = fileparts(file);
            if strcmpi(ext, '.mldatx')
                description = matlabshared.mldatx.internal.getDescription(file);
                isResultFile = strcmp(description, message('stm:general:ResultFileDescription').getString());
            else
                isResultFile = false;
            end
        end

        function id = getShortIdFromTestCase(~, testCase)
            id = '';
            tag = testCase.Tags;
            res = regexp(tag, 'RQM_ShortId:(?<id>\d+)', 'tokens');
            if ~isempty(res)
                id = res{1};
            end
        end

        function id = getShortIdFromTestCaseResult(~, testCaseResult)
            id = '';
            tag = testCaseResult.Tags;
            res = regexp(tag, 'RQM_ShortId:(?<id>\d+)', 'tokens');
            if ~isempty(res)
                id = res{1};
            end
        end

        function rqmTC = addRQMTestCase(this, slTC, factory)
            % Add a new RQM test case.
            rqmTC = factory.createTestCase(slTC.Name);
            rqmTC.fetch(this.oslcClient);
            if this.verbose
                fprintf('[Test Case] %s is created.\n', slTC.Name());
            end
        end

        function updateRQMTestCase(this, slTC, rqmTC, modelName)
            try
                % Update the RQM test case.
                rqmTC.fetch(this.oslcClient);
                if isempty(rqmTC.Title)
                    rqmTC.Title = slTC.Name;
                end
                if ~strcmp(slTC.Name, rqmTC.Title)
                    rqmTC.Title = slTC.Name;
                end
                % Update properties of the Simulink test case.
                slTC.Description = sprintf('<a href="matlab:web(''%s'')">Open in RQM</a>', rqmTC.ResourceUrl);
                slTC.Tags = sprintf('RQM_ShortId:%s', rqmTC.getProperty('oslc:shortId'));
                %newTag=sprintf('RQM_ShortId:%s <a href="matlab:web(''%s'')">Open in RQM</a>', rqmTC.getProperty('oslc:shortId'),rqmTC.ResourceUrl);
                %slTC.Tags = sprintf('<a href="matlab:web(''%s'')">Open in RQM</a>', rqmTC.ResourceUrl);;
                % Update description of the RQM test case to include model name
                % and URL of the Simulink test case.
                modelName = ['Model: ', char(modelName)];
                navURL = ['URL: ', char(slreq.getExternalURL(slTC))];
                rqmTC.setProperty('dcterms:description', [char(modelName), newline, char(navURL)]);
                % Set custom attribute.
                this.setCustomTestCaseAttributes(slTC, rqmTC);
                % Update requirement links.
                rqmLinks = rqmTC.getRequirementLinks();
                rqmLinkResourceUrls = {};
                if ~isempty(rqmLinks)
                    rqmLinkResourceUrls = {rqmLinks(:).ResourceUrl};
                end
                slreqLinks = slreq.outLinks(slTC);
                for i = 1:length(slreqLinks)
                    proxy = slreq.structToObj(slreqLinks(i).destination);
                    urlCell = strsplit(proxy.id, ' ');
                    reqUrl = urlCell{1};
                    if ~isempty(proxy) && ~any(strcmp(rqmLinkResourceUrls, reqUrl))
                        % Add the requirement link to the test case.
                        rqmTC.addRequirementLink(reqUrl);
                        % Create a link from the linked requirement to the test
                        % case.
                        this.addLinkFromRequirementToTestCase(reqUrl, rqmTC);
                    end
                end
                if rqmTC.Dirty
                    rqmTC.commit(this.oslcClient);
                    if this.verbose
                        fprintf('[Test Case] %s (ShortId:%s) is updated.\n', rqmTC.Title, rqmTC.getProperty('oslc:shortId'))
                    end
                end
            catch ME
                disp(ME.getReport);
                exit(this.exitcode_ERROR);
            end
        end

        function setCustomTestCaseAttributes(this, slTC, rqmTC)
            try
                % Sample RDF entry of the custom test case attribute:
                % <project__WBNdAcl2Eeucys1luQhwhg_testCase:customAttribute__IVCkkGEEEe2D-9l0jyFnkQ rdf:datatype="http://www.w3.org/1999/02/22-rdf-syntax-ns#XMLLiteral">&lt;a href="TEST_CASE_URL" title="TEST_CASE_NAME" target="_blank"&gt;Test Case&lt;/a&gt;</project__WBNdAcl2Eeucys1luQhwhg_testCase:customAttribute__IVCkkGEEEe2D-9l0jyFnkQ>
                customAttribute = this.testCaseCustomAttributes('Simulink URL');
                propName = customAttribute{1};
    %             propAttributeName = 'rdf:datatype';
    %             propAttributeValue = 'http://www.w3.org/1999/02/22-rdf-syntax-ns#XMLLiteral';
                % Construct the property value.
                navURL = slreq.getExternalURL(slTC);
                rqmTC.addTextProperty(propName, navURL);
    %             % Set additional property attribute using DOM API directly.
    %             % Get the element that captures the property.
    %             nodeList = rqmTC.rdfMgr.dom.getElementsByTagName(propName);
    %             node = nodeList.node(1);
    %             % Set the required property attribute.
    %             node.setAttribute(propAttributeName, propAttributeValue);
                % Set namespace information to the top element of the RDF.
                rqmTC.rdfMgr.dom.node(1).setAttributeNS('http://www.w3.org/2000/xmlns/', customAttribute{2}, customAttribute{3});
                % Update the RDF.
                rqmTC.rdfMgr.origRDF = rqmTC.rdfMgr.toString();
                rqmTC.rdfMgr.parse();
            catch ME
                disp(ME.getReport);
                exit(this.exitcode_ERROR);
            end
        end

        function req = addLinkFromRequirementToTestCase(this, reqUrl, rqmTC)
            try
                req = oslc.rm.Requirement();
                %reqUrl = createTitle(this,reqUrl)
                req.setResourceUrl(reqUrl);
                req.fetch(this.oslcClient);
                linkUrls = req.getLinks();
                if ~any(strcmp(rqmTC.ResourceUrl, linkUrls))
                    req.addLink(rqmTC.ResourceUrl);
                    req.commit(this.oslcClient);
                    if this.verbose
                        fprintf('Link added from Requirement [%s] to Test case [%s].\n', req.Title, rqmTC.Title);
                    end
                end
            catch ME
                disp(ME.getReport);
                exit(this.exitcode_ERROR);
            end
        end

        function req = removeLinkFromRequirementToTestCase(this, reqUrl, rqmTC)
            try
                req = oslc.rm.Requirement();
                req.setResourceUrl(reqUrl);
                req.fetch(this.oslcClient);
                linkUrls = req.getLinks();
                if any(strcmp(rqmTC.ResourceUrl, linkUrls))
                    req.removeLink(rqmTC.ResourceUrl);
                    req.commit(this.oslcClient);
                    if this.verbose
                        fprintf('Link removed from Requirement [%s] to Test case [%s].\n', req.Title, rqmTC.Title);
                    end
                end
            catch ME
                disp(ME.getReport);
                exit(this.exitcode_ERROR);
            end
        end

        function rqmTP = getRQMTestPlan(this, testPlanName)
            try
                % Find the test plan in RQM.
                queryService = this.oslcClient.getQueryService('TestPlan');
                titleParam=this.createTitle(testPlanName);
                queryService.setQueryParameter(['oslc.where=dcterms:title',titleParam])
                rqmTestPlan = queryService.queryTestPlans();
                rqmTP = oslc.qm.TestPlan.empty();
                if ~isempty(rqmTestPlan)
                     rqmTP = rqmTestPlan;
                end
            catch ME
                disp(ME.getReport);
                exit(this.exitcode_ERROR);
            end
        end

        function rqmTCs = getRQMTestCases(this, rqmTP)
            try
                % Get the URLs of test cases in the test plan.
                if rqmTP.IsFetched == false
                    rqmTP.fetch;
                end
                if ~isempty(this.shortIdArray)
                    planTestCases = rqmTP.getResourceProperty('oslc_qm:usesTestCase');
                    minTestCaseID=min(this.shortIdArray);
                    % Find test cases with matching URLs in RQM.
                    queryService = this.oslcClient.getQueryService('TestCase');
                    %queryService.setQueryParameter('oslc.where=oslc:shortId%3E86000')
                    queryService.setQueryParameter(['oslc.where=oslc:shortId%3E%3D',num2str(this.shortIdArray(1))]);
                    rqmTestCases = queryService.queryTestCases();
                    k = 0;
                    rqmTCs = oslc.qm.TestCase.empty();
                    for i = 1:length(planTestCases)
                        for j = 1:length(rqmTestCases)
                            if rqmTestCases(j).IsFetched == false
                                rqmTestCases(j).fetch;
                            end
                            if strcmp(rqmTestCases(j).ResourceUrl, planTestCases{i})
                                k = k + 1;
                                rqmTCs(k) = rqmTestCases(j);
                                if this.verbose
                                    disp(['Test case "', rqmTestCases(j).Title, '" found under test plan "', rqmTP.Title, '".']);
                                end
                            end
                        end
                    end
                else
                    rqmTCs = oslc.qm.TestCase.empty();
                end
            catch ME
                disp(ME.getReport);
                exit(this.exitcode_ERROR);
            end
        end

        function rqmTER = addRQMTestExecutionRecord(this, TERname, factoryTER, testCaseResourceUrl, factoryTR)
            try
                % Add a new RQM test case execution record.
                %newName=['TER_',slTR.Name];
                rqmTER = factoryTER.createTestExecutionRecord(TERname, testCaseResourceUrl);
                rqmTER.fetch(this.oslcClient);
                %addResourceProperty(rqmTER, 'oslc_qm:reportsOnTestPlan', testPlanURL);
                addResourceProperty(rqmTER, 'oslc_qm:reportsOnTestCase', testCaseResourceUrl);
                rqmTER.commit();
                this.testUrl2RQMTER(testCaseResourceUrl) = rqmTER;
                if this.verbose
                    fprintf('[Test Execution Record] %s is created.\n', TERname);
                end
                %this.addRQMTestResult(factoryTR, slTR, rqmTER);
            catch ME
                disp(ME.getReport);
                exit(this.exitcode_ERROR);
            end
        end

        function updateRQMTestExecutionRecord(this, resultFile, slTR, rqmTER,rqmTR, factoryTR)
            try
                % Update the RQM test case execution record.
                % rqmTER.fetch();
                % if ~strcmp(slTR.TestCasePath, rqmTER.Title())
                %     rqmTER.Title = slTR.TestCasePath;
                % end
                shortId = slTR.UserData;
                % Set custom attribute.
                this.setCustomTestExecutionAttributes(resultFile, slTR, rqmTER);
                %if ~this.resultShortId2RQMTR.isKey(shortId)
                    %this.addRQMTestResult(factoryTR, slTR, rqmTER);
                % else
                    %rqmTR = this.resultShortId2RQMTR(shortId);
                    this.updateRQMTestResult(slTR, rqmTR);
                %end
                if rqmTER.Dirty
                    rqmTER.commit(this.oslcClient);
                    if this.verbose
                        fprintf('[Test Execution Record] %s (ShortId:%s) is updated.\n', rqmTER.Title, rqmTER.getProperty('oslc:shortId'))
                    end
                end
            catch ME
                disp(ME.getReport);
                exit(this.exitcode_ERROR);
            end
        end

        function setCustomTestExecutionAttributes(this, resultFile, slTR, rqmTER)
            try
                % Sample RDF entry of the custom test execution attribute:
                % <project__WBNdAcl2Eeucys1luQhwhg_testCase:customAttribute__IVCkkGEEEe2D-9l0jyFnkQ rdf:datatype="http://www.w3.org/1999/02/22-rdf-syntax-ns#XMLLiteral">&lt;a href="TEST_CASE_URL" title="TEST_CASE_NAME" target="_blank"&gt;Test Case&lt;/a&gt;</project__WBNdAcl2Eeucys1luQhwhg_testCase:customAttribute__IVCkkGEEEe2D-9l0jyFnkQ>
                customAttribute = this.testExecutionCustomAttributes('Simulink URL');
                propName = customAttribute{1};
    %             propAttributeName = 'rdf:datatype';
    %             propAttributeValue = 'http://www.w3.org/1999/02/22-rdf-syntax-ns#XMLLiteral';
                % Construct the property value.
    %             [navURL, navLabel] = slreq.getExternalURL(slTR);
                resultStruct = struct(slTR);
                resultUUID = resultStruct.ResultUUID;
                navCmd = ['rmi.navigate(''linktype_rmi_testmgr'',''' resultFile ''',''' resultUUID ''','''');'];
                navURL = rmiut.cmdToUrl(navCmd);
    %             navLabel = resultStruct.Name;
    %             propValue = ['<a href="', navURL, '">', navLabel, '</a>'];
                rqmTER.addTextProperty(propName, navURL);
    %             % Set additional property attribute using DOM API directly.
    %             % Get the element that captures the property.
    %             nodeList = rqmTER.rdfMgr.dom.getElementsByTagName(propName);
    %             node = nodeList.node(1);
    %             % Set the required property attribute.
    %             node.setAttribute(propAttributeName, propAttributeValue);
                % Set namespace information to the top element of the RDF.
                rqmTER.rdfMgr.dom.node(1).setAttributeNS('http://www.w3.org/2000/xmlns/', customAttribute{2}, customAttribute{3});
                % Update the RDF.
                rqmTER.rdfMgr.origRDF = rqmTER.rdfMgr.toString();
                rqmTER.rdfMgr.parse();
            catch ME
                disp(ME.getReport);
                exit(this.exitcode_ERROR);
            end
        end

        function addRQMTestResult(this, factoryTR, slTR, rqmTER)
            try
                % Add a new RQM test case result.
                testCaseResourceUrl = rqmTER.getResourceProperty('oslc_qm:runsTestCase'); % Note that this is URL of the test case. URL of the test execution record is given by rqmTER.ResourceUrl.
                rqmTR = factoryTR.createTestResult(slTR.Name, testCaseResourceUrl{1}, rqmTER.ResourceUrl, char(slTR.Outcome));
                rqmTR.fetch(this.oslcClient);
                disp(['Fetch Test Result',rqmTR.Title]);
                disp([' Test Result Idntifier',rqmTR.Identifier]);
                shortId = rqmTR.getProperty('oslc:shortId');
                this.resultShortId2RQMTR(shortId) = rqmTR;
                slTR.UserData = shortId;
                if this.verbose
                    fprintf('[Test Result] %s is created.\n', slTR.Name());
                end
            catch ME
                disp(ME.getReport);
                exit(this.exitcode_ERROR);
            end
        end

        function updateRQMTestResult(this, slTR, rqmTR)
            try
                rqmTR.fetch(this.oslcClient);
                rqmTR.setProperty('oslc_qm:status',char(slTR.Outcome));
                disp(['Fetch Test Result',rqmTR.Title]);
                disp([' Test Result Idntifier',rqmTR.Identifier]);
                % Update the RQM test case result.
                if ~strcmp(slTR.Name, rqmTR.Title)
                    rqmTR.Title = slTR.Name;
                end
                if this.verbose && rqmTR.Dirty
                    fprintf('[Test Result] %s (ShortId:%s) is updated.\n', rqmTR.Title, rqmTR.getProperty('oslc:shortId'))
    %                 rqmTR.update();
                    rqmTR.commit();
                end
            catch ME
                disp(ME.getReport);
                exit(this.exitcode_ERROR);
            end
        end
        
        function titleParameter = createTitle(this,strTitle)
            try
                formatedTitle=this.formatQueryForUrl(strTitle);
                titleParameter=['%3D%22',formatedTitle,'%22'];
            catch ME
                disp(ME.getReport);
                exit(this.exitcode_ERROR);
            end
        end

        function titleParameter = createTER(this,strTitle)
            try
                formatedTitle=this.formatQueryForUrl(strTitle);
                titleParameter=['%3D%22',formatedTitle,'%22'];
            catch ME
                disp(ME.getReport);
                exit(this.exitcode_ERROR);
            end
        end

        function updatedParameter = formatQueryForUrl(this,strParameter)
            try
                updatedParameter = regexprep(strParameter,'_','%5F');
                updatedParameter = regexprep(updatedParameter,':','%3A');
                updatedParameter = regexprep(updatedParameter,'/','%2F');
                %updatedParameter = regexprep(updatedParameter,'.','%2E');
                updatedParameter = regexprep(updatedParameter,'-','%2D');
            catch ME
                disp(ME.getReport);
                exit(this.exitcode_ERROR);
            end
        end

        function validName = namingComventionCompliance(this,modelName,testCaseName)
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
                exit(this.exitcode_ERROR);
            end
        end

        function [tcResults, tcResultFiles] = getSLTestCaseResults(this, modelName, RQMTestCaseName, testDir)
            tcResults = sltest.testmanager.TestCaseResult.empty;
            tcResultFiles = {};
            % Get all applicable test results in Simulink.
            %resultDir = prjDirStruct.getDirPath('sim results', modelName);
            resultDir = testDir;
            mldatxFiles = dir(fullfile(resultDir, '**', '*.mldatx'));
            tfResults = [];
            for i = 1:length(mldatxFiles)
                mldatxFile = fullfile(mldatxFiles(i).folder, mldatxFiles(i).name);
                if this.isSLTestResultFile(mldatxFile)
                    resultSet = sltest.testmanager.importResults(mldatxFile);
                    testFileResults = resultSet.getTestFileResults();
                    for j = 1:length(testFileResults)
                        description = testFileResults(j).Description;
                        textCell = strtrim(regexp(description, 'Test Case: (.+)\n*', 'tokens', 'once'));
                        MATLABTestCase = textCell{1};
                        if strcmp(MATLABTestCase, RQMTestCaseName)
                            tfResults = [tfResults testFileResults(j)]; %#ok<AGROW> 
                        end
                    end
                    [tcResults, tcResultFiles] = getTestCaseResultsFromTestFileResults(mldatxFiles(i).name, tfResults, tcResults, tcResultFiles);
                end
            end
            % sltest.testmanager.clear;
            % sltest.testmanager.close;
            
            function [results, files] = getTestCaseResultsFromTestFileResults(testFile, testFileResults, results, files)
                for ntf = 1:length(testFileResults)
                    testSuiteResults = testFileResults(ntf).getTestSuiteResults;
                    [results, files] = getTestCaseResultsFromTestSuiteResults(testFile, testSuiteResults, results, files);
                end
            end

            function [results, files] = getTestCaseResultsFromTestSuiteResults(testFile, testSuiteResults, results, files)
                for nts = 1:length(testSuiteResults)
                    testCaseResults = testSuiteResults(nts).getTestCaseResults;
                    [results, files] = getTestCaseResultsFromTestCaseResults(testFile, testCaseResults, results, files);
                end
            end

            function [results, files] = getTestCaseResultsFromTestCaseResults(testFile, testCaseResults, results, files)
                for ntc = 1:length(testCaseResults)
                    results(end+1) = testCaseResults(ntc); %#ok<AGROW> 
                    files{end+1} = testFile; %#ok<AGROW> 
                end
            end

        end
    end

end
