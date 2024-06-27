function [errors,warnings,updates] = runModelAdvisor()
% NAME: runModelAdvisor
% USAGE: 
%       1.- Run 'runModelAdvisor' command
%       2.- Select desired model
%       3.- Model advisor analysis will start
%       4.- Model Advisor report will be generated in a 'ModelAdvisor'
%           folder(folder will be created autonatically if it doesn't exist).
%           i.e. MBD\HighLevelDiagnostics\HiLvlDiagCurr\ModelAdvisor\HiLvlDiagCurr_Model_Advisor_Report.pdf
    rootFolder = fileparts(which('build.m'));
    [modelFile,modelFilePath] = uigetfile('*.slx','Select model');
    if modelFile == 0, return, end
    
    if isfile(fullfile(modelFilePath,modelFile))
        [modelPath,modelName,modelExt] = fileparts(fullfile(modelFilePath,modelFile));
    end
    
    try
        lastwarn(''); % Clear last warning
    
        modelAdvisorFolder= regexprep(modelFilePath,'\Design','\ModelAdvisor')
        modelAdvisorReportFile=fullfile(modelAdvisorFolder,[modelName, '_Model_Advisor_Report.pdf']);
        disp(['#### Running Model Advisor Analysis for:',modelFile]);
        load_system(modelName);
    
        %delete existing report
        if ~exist(modelAdvisorFolder,'dir')
            mkdir(modelAdvisorFolder);
        end
        if isfile(modelAdvisorReportFile)
            delete(modelAdvisorReportFile);
        end
    
        disp(['Analyzing:  ' modelName]);
        results = ModelAdvisor.run(modelName, 'Configuration', 'MdlAdvis_2023.json', 'Force', 'on', 'TreatAsMdlRef', 'on');
        % Create a configuration for Model Advisor report generation.
        rptCfg = ModelAdvisor.ExportPDFDialog.getInstance;
        rptCfg.TaskNode = Simulink.ModelAdvisor.getModelAdvisor(modelName).TaskAdvisorRoot;
        rptCfg.ReportFormat = 'pdf' ; %'html'; %can be pdf
        rptCfg.ReportName = [modelName, '_Model_Advisor_Report'];
        rptCfg.ReportPath = fullfile(modelAdvisorFolder);
        rptCfg.ViewReport = true;
        % Generate the report.
        rptCfg.Generate;
    
        close_system(modelName);
        disp(modelAdvisorReportFile);
        if isfolder([modelAdvisorFolder,'\sldv_output'])
            rmdir([modelAdvisorFolder,'\sldv_output'],'s');
        end
    catch ME
        disp(ME.getReport);
    end
end