function cfg = setJazzCredentials(varargin)
% Eaton
cfg.Server = 'loutcsvrtcp01.napa.ad.etn.com:9443/';
cfg.ServiceRoot = 'qm';
cfg.CatalogPath = 'oslc_qm/catalog';
cfg.ServiceProvider = '48V Power Conversion Technology (Quality Management)';
cfg.ConfigurationContext = '';
cfg.User = getenv('username');
cfg.TestCaseCustomAttributes = containers.Map();
cfg.TestCaseCustomAttributes('Simulink URL') = {'project__xmgioPOHEeu_O8zDLaL0-A_testCase:customAttribute__cMD8sY-cEe6rJrXFAEH69g', ...
    'xmlns:project__xmgioPOHEeu_O8zDLaL0-A_testCase', ...
    'https://loutcsvrtcp01.napa.ad.etn.com:9443/qm/oslc_qm/contexts/_xmgioPOHEeu_O8zDLaL0-A/shape/resource/com.ibm.rqm.planning.VersionedTestCase#'};
cfg.TestExecutionCustomAttributes = containers.Map();
cfg.TestExecutionCustomAttributes('Simulink URL') = {'project__xmgioPOHEeu_O8zDLaL0-A_testExecutionRecord:customAttribute__fFox4Y-cEe6rJrXFAEH69g', ...
    'xmlns:project__xmgioPOHEeu_O8zDLaL0-A_testExecutionRecord', ...
    'https://loutcsvrtcp01.napa.ad.etn.com:9443/qm/oslc_qm/contexts/_xmgioPOHEeu_O8zDLaL0-A/shape/resource/com.ibm.rqm.execution.TestcaseExecutionRecord#'};
