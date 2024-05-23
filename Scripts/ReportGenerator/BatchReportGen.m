% Generates reports of all slx models found under MBD folder.
% input = rootFolder
% outputs = pdf design reports stored in MBD/DeisgnReports Folder
%   eg: in the command window write - 
%   BatchReportGen('C:\Users\E0395640\Documents\RTC\M3InverterVFm0aR2Dev\')
%   
%
function BatchReportGen(rootFolder)
slxfiles = FindslxFiles(fullfile(rootFolder, 'MBD'));

ignore_pattern_list = ["Test", "PlantModels"];
	
pattern_found = false;

    for ii= 1:length(slxfiles)
        for a = 1:length(ignore_pattern_list)
            if contains(slxfiles(ii), ignore_pattern_list(a))
				pattern_found = true;
            end
        end
        if ~ pattern_found
				open_system(string(slxfiles(ii)));
				report("Vc4d_M3_ASW_Report_Gen.rpt");
				close_system
        end
        pattern_found = false;
    end
end

%% Search for files with specific extension in given folder and subfolders
    function [FList] = FindslxFiles(DataFolder)
        
        if nargin < 1
            DataFolder = uigetdir;
        end
        
        DirContents=dir(DataFolder);
        FList=[];
        
        if ~isunix
            NameSeperator='\';
        else isunix
            NameSeperator='/';
        end
        
        extList={'slx'};
        
        for i=1:numel(DirContents)
            if(~(strcmpi(DirContents(i).name,'.') || strcmpi(DirContents(i).name,'..')))
                if(~DirContents(i).isdir)
                    if (length(DirContents(i).name) > 3)
                        extension=DirContents(i).name(end-2:end);
                    end
                    
                    if(numel(find(strcmpi(extension,extList)))~=0)
                        FList=cat(1,FList,{[DataFolder,NameSeperator,DirContents(i).name]});
                    end
                else
                    getlist=FindslxFiles([DataFolder,NameSeperator,DirContents(i).name]);
                    FList=cat(1,FList,getlist);
                end
            end
        end
    end




