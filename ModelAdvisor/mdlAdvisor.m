function mdlAdvisor

%Find the SW component
arxmlFolder = fullfile(cd,'Architecture','SystemDesk','SwCExports');
arxmlSearchMask = fullfile(arxmlFolder,'SWC_*.arxml');
arxmlFiles = dir(arxmlSearchMask);
modelNames = regexprep({arxmlFiles.name},'.arxml','');

%Selecti the mat file
[file,path] = uigetfile([cd,'\Utilities\MATLAB\ModelAdvisor\*.mat'],'Select the mdl Advisor Configuration');

%Run the advisor
ModelAdvisor.run(modelNames, 'Configuration',fullfile(file));

end