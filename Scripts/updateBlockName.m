function updateBlockName
% Make the the Calibration block name same as Calibration name if they are
% different

H = gcs;
list=find_system(H, ...
                'Regexp','on', ...
                'FollowLinks', 'on', ...
                'MaskType','Calibratible Input');
            
for i=1:length(list)
    temp1=get_param(list{i},'Name');
    temp2=get_param(list{i},'CalValue');
    if(~strcmp(temp1, temp2))
        j=0;
        while j==0
            try
                set_param(list{i},'Name',temp2);
                j=1;
            catch
                if endsWith(temp2,'_C')
                    temp2 = insertBefore(temp2,"_C",num2str(i));
                    j=0;
                elseif endsWith(temp2,'_TC')
                    temp2 = insertBefore(temp2,"_TC",num2str(i));
                    j=0;
                elseif endsWith(temp2,'_TO')
                    temp2 = insertBefore(temp2,"_TO",num2str(i));
                    j=0;
                else 
                    j=1;%break
                end
            end
        end
    end
end