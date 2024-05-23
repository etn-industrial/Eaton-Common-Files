classdef daq < xcp.blkmasks.daqStimBase
	%XCP.BLKMASKS.DAQ - DDG based class to handle the block masks for
    %the XCP CAN and UDP Data Acquisition blocks.  An object of this class is
    %instantiated through the open callback of the block

%   Copyright 2018 The MathWorks, Inc.
    
    properties
        DAQPriority = 0;
        SampleTime = 0;
    end
	
    %% Constructor Block
    methods (Access = private)
        function obj = daq(block)
            obj@xcp.blkmasks.daqStimBase(block, 'DAQ');
            obj.DAQPriority   = get_param(block, 'DAQPriority');
            obj.SampleTime   = get_param(block,'SampleTime');
            
            obj.DialogHandle = DAStudio.Dialog(obj);
            installCloseListener(obj); 
        end
    end
    
    %% DDG Dialog Schema
    methods
        function dlgstruct = getDialogSchema(obj)
            dlgstruct = getDialogSchema@xcp.blkmasks.daqStimBase(obj);

            %Add DAQ-specific fields:
            doc.Name           = sprintf(['Select measurements for a specified event to perform XCP data acquisition over ',obj.tlTypeStr,'.  The block acquires the selected\nmeasurements from the slave and outputs to Simulink at every simulation time step.']);
            doc.Type           = 'text';
            doc.RowSpan        = [1 10];
            doc.ColSpan        = [1 1];
            
            HeaderPanel.Type='group';
            HeaderPanel.Name=['XCP ',obj.tlTypeStr,' Data Acquisition'];
            HeaderPanel.Items={doc};
            
            daqpriority.Name = 'DAQ list priority:    ';
            daqpriority.Type = 'edit';
            daqpriority.Tag = 'daqpriority_tag';
            daqpriority.RowSpan = [12,12];
            daqpriority.ColSpan = [1,16];
            daqpriority.MatlabArgs = {obj,'%dialog','%value'};
            daqpriority.MatlabMethod = 'setDAQPriority';
            daqpriority.ObjectProperty = 'DAQPriority';
            
            sampletime.Name = 'Sample time:         ';
            sampletime.Type = 'edit';
            sampletime.Tag = 'sampletime_tag';
            sampletime.RowSpan = [13,13];
            sampletime.ColSpan = [1,16];
            sampletime.MatlabArgs = {obj,'%dialog','%value'};
            sampletime.MatlabMethod = 'setSampleTime';
            sampletime.ObjectProperty = 'SampleTime';
            
            ParametersPanel = dlgstruct.Items{1};
            ParametersPanel.Items{end+1} = daqpriority;
            ParametersPanel.Items{end+1} = sampletime;
                       
            dlgstruct.Items = {HeaderPanel, ParametersPanel};
            dlgstruct.HelpMethod = 'xcp.blkmasks.utils.help';
            dlgstruct.HelpArgs =  {['xcp_',lower(obj.tlTypeStr),'_daq']};
        end
    end
    
    %% Set Methods/Callbacks
    methods
        function PreApplyMethod(obj)
            if (strcmp(get_param(bdroot(obj.BlockName),'BlockDiagramType'),'library'))
                return; %Don't do anything
            end
            %Save base class properties
            PreApplyMethod@xcp.blkmasks.daqStimBase(obj);
            %Save DAQ-specific properties
            set_param(obj.BlockHandle,'DAQPriority',obj.DAQPriority, 'SampleTime', obj.SampleTime);
        end
        
        function setSampleTime(obj, dialog, value)
            
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
        
        
        function setDAQPriority(obj, dialog, value)
            
           if (validateDAQPriority(value))
               obj.DAQPriority = value;
           else
               dialog.setEnabled('ParametersPanel_tag', false);
               err = message('xcp:xcpblks:InvalidDAQPriority');
               errTitle = message('xcp:xcpblks:XCPErrorTitle');
               uiwait(errordlg(err.string, errTitle.string, 'modal'));
               dialog.setWidgetValue('daqpriority_tag',obj.DAQPriority);
               dialog.setEnabled('ParametersPanel_tag', true);
           end
        end  
        
    end
    
    %% Static Methods
	methods (Static = true)
        function openDialog(block,varargin)
            myBlkHandle = get_param(block, 'handle');
            dlgs = DAStudio.ToolRoot.getOpenDialogs;
            for i = 1 : numel(dlgs)
               dlg = dlgs(i);
               if ~isa(dlg.getSource, 'xcp.blkmasks.daq')
                   continue
               end
               if dlg.getSource.BlockHandle == myBlkHandle
                   % If we got here, we have a match.
                   dlg.show();
                   return
               end
            end
            xcp.blkmasks.daq(block);
        end
        
        function structToReturn = getWidgetTags()
            structToReturn = getWidgetTags@xcp.blkmasks.daqStimBase();
            structToReturn.DAQPriority = 'daqpriority_tag';
            structToReturn.SampleTime = 'sampletime_tag';
        end
    end
	
end %classdef


%% Local Functions
function isValid = validateDAQPriority(value)
    % Convert sample time to number. 
    DAQPriority = str2num(value); %#ok<ST2NM>

    % Initialize
    isValid = true;

    % Allow variable names but do not allow NaN, i and j (complex) as
    % variables. If they are left undefined, it yields incorrect results.
    if isvarname(value) && ~ismember(lower(value), {'nan', 'i', 'j', 'inf'})  
        return;
    end

    % Check for non-numeric
    if  isempty(DAQPriority) || ~isscalar(DAQPriority) || ~isnumeric(DAQPriority) || ...
            isnan(DAQPriority) || DAQPriority<0 || DAQPriority>255 || ~isreal(DAQPriority)
        isValid = false;
        return;
    end

end
