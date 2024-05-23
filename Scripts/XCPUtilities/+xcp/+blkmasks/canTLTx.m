classdef canTLTx < xcp.blkmasks.canTLBase
    %XCP.BLKMASKS.CANTLRX - DDG based class to handle the block mask for
    %the XCP CAN Transport Layer Transmit block.  An object of this class is
    %instantiated through the open callback of the block

%   Copyright 2018 The MathWorks, Inc.

    properties (SetObservable = true)
        %No additional properties
    end

    
    %% Constructor Block
    methods  (Access = private)
        function obj = canTLTx(block)
            %canTLTx Construct XCP CAN Trasport Layer Transmit object.
            obj@xcp.blkmasks.canTLBase(block);
            
            obj.DialogHandle = DAStudio.Dialog(obj);
            installCloseListener(obj);
        end  % canTLTx
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
            
            doc.Name           = sprintf('Processes the queued XCP messages and sends to the protocol\n(CAN) transmit block for transmission.');
            doc.Type           = 'text';
            doc.RowSpan        = [1 1];
            doc.ColSpan        = [1 1];

            HeaderPanel.Type='group';
            HeaderPanel.Name='XCP CAN Transport Layer Transmit';
            HeaderPanel.Items={doc};
            
            ParametersPanel = dlgstruct.Items{1};       
            dlgstruct.Items = {HeaderPanel, ParametersPanel};
            dlgstruct.HelpMethod = 'xcp.blkmasks.utils.help';
            dlgstruct.HelpArgs =  {'xcp_can_tx'};
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
               if ~isa(dlg.getSource, 'xcp.blkmasks.canTLTx')
                   continue
               end
               if dlg.getSource.BlockHandle == myBlkHandle
                   % If we got here, we have a match.
                   dlg.show();
                   return
               end
            end
            xcp.blkmasks.canTLTx(block);
        end
        function structToReturn = getWidgetTags()
            structToReturn = getWidgetTags@xcp.blkmasks.canTLBase();
        end
    end % static methods

end  % classdef

