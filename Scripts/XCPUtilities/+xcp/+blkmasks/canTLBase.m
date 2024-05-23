classdef canTLBase < handle
    %XCP.BLKMASKS.CANTLBASE - DDG based class to handle the block mask for
    %   XCP.BLKMASKS.CANTLRX and XCP.BLKMASKS.CANTLTX inherit from this
    %   base class

%   Copyright 2018 The MathWorks, Inc.

    properties (SetObservable = true)
        %Mask Parameters
        TLID = '';
        MaxNumMessages = '';
        SampleTime = '';
        %Generic Properties
        BlockName;
        BlockHandle;
        DialogHandle;
        CloseListener;
    end

    %% Constructor Block
    methods 
        function obj = canTLBase(block)
        %canTLBase Construct Base XCP CAN Trasport Layer object.
        
        % Set the Generic Props
        obj.BlockName   = block;
        obj.BlockHandle = get_param(block, 'handle');

        %Set the Mask Properties based on Block Properties
        obj.TLID     = get_param(block, 'TLID');
        obj.MaxNumMessages = get_param(block,'MaxNumMessages');
        obj.SampleTime    = get_param(block, 'SampleTime');
        
        end  % xcpcantltx
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
           
            maxmessages.Name           = 'Maximum Number of Messages:';
            maxmessages.Type           = 'edit';
            maxmessages.Tag            = 'maxmessages_tag';
            maxmessages.MatlabArgs     = {obj,'%dialog','%value'};
            maxmessages.MatlabMethod   = 'setMaxNumMessages';
            maxmessages.Value = obj.MaxNumMessages;
            maxmessages.Visible        = true;
            maxmessages.RowSpan        = [1 1];
            maxmessages.ColSpan        = [1 10];

            sampletime.Name            = 'Sample Time:';
            sampletime.Type            = 'edit';
            sampletime.Tag             = 'sampletime_tag';
            sampletime.MatlabArgs      = {obj,'%dialog','%value'};
            sampletime.MatlabMethod    = 'setSampleTime';
            sampletime.Value           = obj.SampleTime;
            sampletime.RowSpan         = [2,2];
            sampletime.ColSpan         = [1 10];
            
            ParametersPanel.Type = 'group';
            ParametersPanel.Name = 'Parameters';
            ParametersPanel.Tag  = 'ParametersPanel_tag';
            ParametersPanel.LayoutGrid = [3,10];
            ParametersPanel.Items = {maxmessages, sampletime};
            
            dlgstruct.DialogTitle = ['Block Parameters: ', get_param(obj.BlockHandle,'Name')];
            dlgstruct.StandaloneButtonSet = {'OK','Apply','Cancel','Help'};
            dlgstruct.EmbeddedButtonSet = {'OK','Apply','Cancel','Help'};
            dlgstruct.Items = {ParametersPanel};
            dlgstruct.PreApplyMethod = 'PreApplyMethod';
            
            % Disable the dialog if we're in External mode and connected or
            % running.  SimulationStatus is 'external' if we're either
            % connected or running in external mode.
            mode = get_param( bdroot(obj.BlockName), 'SimulationMode' );
            status = get_param( bdroot(obj.BlockName), 'SimulationStatus' );
            if strcmpi( mode, 'external' ) && ~strcmpi( status, 'stopped' )
                dlgstruct.DisableDialog = true;  %TODO:  Confirm this part of the code is working
            end
        end
    end  
    
    %% Set Methods/Callbacks
    methods
                function PreApplyMethod(obj)
            set_param(obj.BlockHandle,'MaxNumMessages',obj.MaxNumMessages,'SampleTime', obj.SampleTime);
        end
        
        function setMaxNumMessages(obj,dialog,value)
           if (validateTLMaxMessages(value))
               obj.MaxNumMessages = value;
           else
               dialog.setEnabled('ParametersPanel_tag', false);
               err = message('xcp:xcpblks:InvalidMaxNumMessages');
               errTitle = message('xcp:xcpblks:XCPErrorTitle');
               uiwait(errordlg(err.string, errTitle.string, 'modal'));
               dialog.setWidgetValue('maxmessages_tag',obj.MaxNumMessages);
               dialog.setEnabled('ParametersPanel_tag', true);
           end
        end

        function setSampleTime(obj,dialog,value)
           if (xcp.blkmasks.utils.validateSampleTime(value))
               obj.SampleTime = value;
           else
               dialog.setEnabled('ParametersPanel_tag', false);
               err = message('xcp:xcpblks:InvalidSampleTime');
               errTitle = message('xcp:xcpblks:XCPErrorTitle');
               uiwait(errordlg(err.string, errTitle.string, 'modal'));
               dialog.setWidgetValue('sampletime_tag',obj.SampleTime);
               dialog.setEnabled('ParametersPanel_tag', true);
           end
        end
        
        function installCloseListener(obj)
            mdl = get_param(bdroot(obj.BlockHandle), 'Object');
            obj.CloseListener = handle.listener(mdl, 'CloseEvent', ...
                {@xcp.blkmasks.canTLBase.modelCloseListener, obj});
        end
    end
    
    %% Static Methods
    methods (Static=true)
        function modelCloseListener(~, ~, obj)
            obj.DialogHandle.delete;
            obj.delete;
        end
        function structToReturn = getWidgetTags()
            structToReturn.MaxNumMessages = 'maxmessages_tag';
            structToReturn.SampleTime = 'sampletime_tag';
        end
    end % static methods

end  % classdef


%% Local Functions
function isValid = validateTLMaxMessages(value)
    maxMessages = str2num(value); %#ok<ST2NM>

    isValid = true;

    % Check for non-numeric and negative values.
    if isempty(maxMessages) || ~isscalar(maxMessages) || ~isnumeric(maxMessages) || ...
            isnan(maxMessages) || ~isreal(maxMessages) || floor(maxMessages)~=maxMessages || ...
            maxMessages<=0 || isinf(maxMessages)
        isValid = false;
        return;
    end

end


