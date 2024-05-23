classdef canConfig < xcp.blkmasks.configBase
    %XCP.BLKMASKS.CANCONFIG - DDG based class to handle the block mask for the CAN
    %Configuration block.  An object of this class is instantiated through the open callback
    %of the block

%   Copyright 2018 The MathWorks, Inc.
    
    properties
        %No additional properties for CAN Configuration
    end
    
    %% Constructor Block
    methods (Access = private)
        function obj = canConfig(block)
            obj@xcp.blkmasks.configBase(block);
            
            obj.DialogHandle = DAStudio.Dialog(obj);
            installCloseListener(obj); 
        end
    end
    
    %% DDG Dialog Schema
    methods
        function dlgstruct = getDialogSchema(obj)
            dlgstruct = getDialogSchema@xcp.blkmasks.configBase(obj);
            
            %Add CAN XCP Configuration specific fields
            doc.Name           = sprintf('Configures the XCP slave for CAN using the specified ASAP2 Database (A2L) file');
            doc.Type           = 'text';
            doc.RowSpan        = [1 10];
            doc.ColSpan        = [1 1];
            
            HeaderPanel.Type='group';
            HeaderPanel.Name='XCP CAN Configuration';
            HeaderPanel.Items={doc};

            %Need to make sample time field dynamic.  For XCP CAN
            %Configuration, it's only used when the status port is enabled.
            ParametersPanel = dlgstruct.Items{1};
            sampletime = ParametersPanel.Items{end};
            sampletime.Visible = obj.EnableStatus;
            sampletime.DialogRefresh = true;
            ParametersPanel.Items{end} = sampletime;
            
            dlgstruct.Items = {HeaderPanel, ParametersPanel};
            dlgstruct.HelpMethod = 'xcp.blkmasks.utils.help';
            dlgstruct.HelpArgs =  {'xcp_can_config'};
        end
    end
    
    %% Set Methods/Callbacks
    methods
        function PreApplyMethod(obj)
            if (strcmp(get_param(bdroot(obj.BlockName),'BlockDiagramType'),'library'))
                return; %Don't do anything
            end
            PreApplyMethod@xcp.blkmasks.configBase(obj);
            %No other CAN Config Specific properties to save
        end
 
    end
    
    
    %% Static Methods
    methods (Static = true)
        function openDialog(block)
            myBlkHandle = get_param(block, 'handle');
            dlgs = DAStudio.ToolRoot.getOpenDialogs;
            for i = 1 : numel(dlgs)
               dlg = dlgs(i);
               if ~isa(dlg.getSource, 'xcp.blkmasks.canConfig')
                   continue
               end
               if dlg.getSource.BlockHandle == myBlkHandle
                   % If we got here, we have a match.
                   dlg.show();
                   return
               end
            end
            xcp.blkmasks.canConfig(block);
        end
        
        function structToReturn = getWidgetTags()
            structToReturn = getWidgetTags@xcp.blkmasks.configBase();
            %Nothing to add
        end

	end
    
end

