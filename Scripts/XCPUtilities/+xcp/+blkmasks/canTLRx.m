classdef canTLRx < xcp.blkmasks.canTLBase
    %XCP.BLKMASKS.CANTLRX - DDG based class to handle the block mask for
    %the XCP CAN Transport Layer Receive block.  An object of this class is
    %instantiated through the open callback of the block

%   Copyright 2018 The MathWorks, Inc.

    properties (SetObservable = true)
        %No additional properties
    end

    %% Constructor Block
    methods  (Access = private) 
        function obj = canTLRx(block)
            %canTLRX Construct XCP CAN Trasport Layer Receive object.
            obj@xcp.blkmasks.canTLBase(block);
            
            obj.DialogHandle = DAStudio.Dialog(obj);
            installCloseListener(obj);
        end  % canTLRx
    end
    
    %% DDG Dialog Schema
    methods
        function dlgstruct = getDialogSchema(obj, ~) 
           %GETDIALOGSCHEMA Generate a dynamic dialog object.
           %
           %    DLG = GETDIALOGSCHEMA(OBJ, ~) generates DLG, a dynamic dialog
           %    schema for OBJ, an XCP CAN TL Transmit block object.
           %
           %    This function is invoked every time a new mask needs to be generated,
           %    which occurs whenever the mask is opened or when the user interacts
           %    with any of the editable UI components on the mask.
           
            dlgstruct = getDialogSchema@xcp.blkmasks.canTLBase(obj);
            
            doc.Name           = sprintf('Processes the XCP messages received from protocol (CAN) receive\nblock to be used by other XCP blocks.');
            doc.Type           = 'text';
            doc.RowSpan        = [1 1];
            doc.ColSpan        = [1 1];

            HeaderPanel.Type='group';
            HeaderPanel.Name='XCP CAN Transport Layer Receive';
            HeaderPanel.Items={doc};
            
            ParametersPanel = dlgstruct.Items{1};
            maxmessages = ParametersPanel.Items{1};
            maxmessages.Visible = false;
            ParametersPanel.Items{1} = maxmessages;
            %ParametersPanel.
            dlgstruct.Items = {HeaderPanel, ParametersPanel};
            dlgstruct.HelpMethod = 'xcp.blkmasks.utils.help';
            dlgstruct.HelpArgs =  {'xcp_can_rx'};
        end
    end  
    
    %% Set Methods/Callbacks
    methods
       function PreApplyMethod(obj)
            PreApplyMethod@xcp.blkmasks.canTLBase(obj);
        end 
    end
    
    %% Static Methods
    methods (Static=true)
        function openDialog(block)
            myBlkHandle = get_param(block, 'handle');
            dlgs = DAStudio.ToolRoot.getOpenDialogs;
            for i = 1 : numel(dlgs)
               dlg = dlgs(i);
               if ~isa(dlg.getSource, 'xcp.blkmasks.canTLRx')
                   continue
               end
               if dlg.getSource.BlockHandle == myBlkHandle
                   % If we got here, we have a match.
                   dlg.show();
                   return
               end
            end
            xcp.blkmasks.canTLRx(block);
        end
        function structToReturn = getWidgetTags()
            structToReturn = getWidgetTags@xcp.blkmasks.canTLBase();
        end
    end % static methods

end  % classdef

