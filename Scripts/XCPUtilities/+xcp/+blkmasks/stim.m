classdef stim < xcp.blkmasks.daqStimBase
    %XCP.BLKMASKS.STIM - DDG based class to handle the block masks for
    %the XCP CAN and UDP Data Stimulation blocks.  An object of this class is
    %instantiated through the open callback of the block

%   Copyright 2018 The MathWorks, Inc.
    
    properties
        %No additional STIM-Specific properties
    end
	
    %% Constructor Block
    methods (Access = private)
        function obj = stim(block)
            obj@xcp.blkmasks.daqStimBase(block, 'STIM');
            
            obj.DialogHandle = DAStudio.Dialog(obj);
            installCloseListener(obj); 
        end
    end
    
    %% DDG Dialog Schema
    methods
        function dlgstruct = getDialogSchema(obj)
            dlgstruct = getDialogSchema@xcp.blkmasks.daqStimBase(obj);

            %Add STIM specific fields
            doc.Name           = sprintf(['Select measurements for a specified event to perform XCP data stimulation over ',obj.tlTypeStr, '.  The block sends the selected\nmeasurements to the slave at every simulation time step.']);
            doc.Type           = 'text';
            doc.RowSpan        = [1 10];
            doc.ColSpan        = [1 1];
            
            HeaderPanel.Type='group';
            HeaderPanel.Name=['XCP ',obj.tlTypeStr,' Data Stimulation'];
            HeaderPanel.Items={doc};
            
            ParametersPanel = dlgstruct.Items{1};          
            dlgstruct.Items = {HeaderPanel, ParametersPanel};
            dlgstruct.HelpMethod = 'xcp.blkmasks.utils.help';
            dlgstruct.HelpArgs =  {['xcp_',lower(obj.tlTypeStr),'_stim']};
        end
        
    end
    
    %% Set Methods/Callbacks
    methods
        function PreApplyMethod(obj)
            if (strcmp(get_param(bdroot(obj.BlockName),'BlockDiagramType'),'library'))
                return; %Don't do anything
            end
            PreApplyMethod@xcp.blkmasks.daqStimBase(obj);
            %No other STIM-specific properties to save
        end
 
    end
    
    %% Static Methods
	methods (Static = true)
        function openDialog(block)
            myBlkHandle = get_param(block, 'handle');
            dlgs = DAStudio.ToolRoot.getOpenDialogs;
            for i = 1 : numel(dlgs)
               dlg = dlgs(i);
               if ~isa(dlg.getSource, 'xcp.blkmasks.stim')
                   continue
               end
               if dlg.getSource.BlockHandle == myBlkHandle
                   % If we got here, we have a match.
                   dlg.show();
                   return
               end
            end
            xcp.blkmasks.stim(block);
        end
        
        function structToReturn = getWidgetTags()
            structToReturn = getWidgetTags@xcp.blkmasks.daqStimBase();
            %Nothing to Add
        end

	end
	
	
end
