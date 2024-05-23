classdef utils
%

%   Copyright 2018 The MathWorks, Inc.

    methods (Static = true)

        function [tlTypeStr] = getTLTypeStr
            canTLRx = find_system(bdroot, 'FollowLinks', 'on', ...
                                'LookUnderMasks', 'on', ...
                                'FunctionName', 'sxcpcantlrx');
            canTLTx = find_system(bdroot, 'FollowLinks', 'on', ...
                        'LookUnderMasks', 'on', ...
                        'FunctionName', 'sxcpcantltx');
                    
            if (~isempty(canTLRx) || ~isempty(canTLTx))
                tlTypeStr = 'CAN';
            else
                tlTypeStr = 'UDP'; %default
                %warning(message('xcp:xcpblks:workflowChanges'));
            end
        end
        
        function str = genDeleteBlockLinkStr(blk)
            blk(isspace(blk)) = ' '; %return characters cause problems here.
            str = ['<a href="matlab:xcp.blkForwarding.utils.deleteBlock(''',blk,''');">here</a>'];
        end
        
        function deleteBlock(blk)
            try 
                delete_block(blk);
            catch
                warning(message('xcp:xcpblks:blockAlreadyDeleted',blk));
            end
        end

        function tlInstanceData = importTLInstanceData()
            %In this function, we will assume the model was working in 18b
            %or before.  This means there was originally only one UDP TL
            %block and one XCP configure block.  If this is not true, then
            %we may end up with the wrong tlInstanceData, but continue
            %silently.  
            tlInstanceData = []; 
            udpTL = find_system(bdroot, 'FollowLinks', 'on', ...
                            'LookUnderMasks', 'on', ...
                            'SourceType', 'UDP Transport Layer ');
            if ~isempty(udpTL)
                %The TL block has not been forwarded yet.  Read it's instance data
                tlInstanceData = get_param(udpTL{1}, 'InstanceData');
            else
                %The TL block has already been forwarded.  Check if an obsolete TL block exists.
                obsoleteUDPTL = find_system(bdroot, 'FollowLinks', 'on', ...
                            'LookUnderMasks', 'on', ...
                            'MaskType', 'Obsolete XCP UDP Transport Layer');
                if ~isempty(obsoleteUDPTL)
                    tlInstanceData =  get_param(obsoleteUDPTL{1}, 'UserData');
                else
                    %Check if we forwarded to the SLRT UDP Confgure block.
                    udpConfigure = find_system(bdroot, 'FollowLinks', 'on', ...
                            'LookUnderMasks', 'on', ...
                            'MaskType', 'slrtudpconfigure');
                    for i = 1:length(udpConfigure)
                       tlInstanceData = get_param(udpConfigure{i}, 'UserData');
                       if ~isempty(tlInstanceData)
                           %Stop once we find a udp configure block with
                           %userData.  Otherwise, we could be looking at a
                           %block that already existed in the model before
                           %forwarding
                           break;
                       end
                    end
                end
            end
        end

        
    end
end


