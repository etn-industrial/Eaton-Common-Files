% This function will convert Simulink Signals to Eaton Signals in the SWC sldd
function [updatedData,bObjectsConverted,logMsg] = ConvertSimulinkClassToEtnClass(modelName,data)
    logMsg = '';
    updatedData = data;
    bObjectsConverted = false;
    disp(['Updating Simulink signals and parameters to Eaton class #' 'of ' ' - ' modelName]);
    f=fieldnames(updatedData);
    for ii=1:size(f,1)
        temp1 = updatedData.(f{ii});
        if strcmp(class(temp1),'Simulink.Signal') || strcmp(class(temp1),'AUTOSAR4.Signal')
            % convert to Eaton.Signal
            updatedData.(f{ii}) = Eaton.Signal;
            description = temp1.Description;
            description(double(description) < 32) = ''; % Clear ASCII characters that are not letters, numbers or symbols
            updatedData.(f{ii}).Description = description;
            updatedData.(f{ii}).DataType = temp1.DataType;
            updatedData.(f{ii}).Min = temp1.Min ;
            updatedData.(f{ii}).Max = temp1.Max;
            updatedData.(f{ii}).InitialValue = temp1.InitialValue;
            updatedData.(f{ii}).Unit = temp1.Unit;
            updatedData.(f{ii}).StorageClass = 'Auto';
            bObjectsConverted = true;
            logMsg = strcat(logMsg,sprintf('%s\n',string(f{ii})));
        end
        
         if strcmp(class(temp1),'Simulink.Parameter') 
            % convert to Eaton.Parameter
            updatedData.(f{ii}) = Eaton.Parameter;
            description = temp1.Description;
            description(double(description) < 32) = ''; % Clear ASCII characters that are not letters, numbers or symbols
            updatedData.(f{ii}).Description = description;
            updatedData.(f{ii}).DataType = temp1.DataType;
            updatedData.(f{ii}).Min = temp1.Min ;
            updatedData.(f{ii}).Max = temp1.Max;
            updatedData.(f{ii}).Unit = temp1.Unit;
            updatedData.(f{ii}).Value = temp1.Value;
            updatedData.(f{ii}).CoderInfo.StorageClass = 'Custom';
            updatedData.(f{ii}).CoderInfo.CustomStorageClass = 'ConstVolatileCal';
            bObjectsConverted = true;
            logMsg = strcat(logMsg,sprintf('%s\n',string(f{ii})));
        end
    end
end

