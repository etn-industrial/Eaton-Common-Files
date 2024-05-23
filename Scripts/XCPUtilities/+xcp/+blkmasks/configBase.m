classdef configBase < handle
    %XCP.BLKMASKS.CONFIGBASE
    %   XCP.BLKMASKS.CANCONFIG and XCP.BLKMASKS.UDPConfig inherit from this
    %   base class
    
    %TODO:  Make sure two config blocks don't use the same A2L File -
    %Necessary???
    
    properties(SetObservable=true)
        % Mask Parameters
        SlaveName = '';
        A2LFile = '';
        SlaveID = 0;
        EnableSecurity = false;
        SeedKeyLib = '';
        EnableStatus = false;
        SampleTime = 0;

        % Generic Properties
        BlockHandle;
        BlockName;
        DialogHandle;
        CloseListener;
    end
    
    %% Constructor Block
    methods
        function obj = configBase(block)
            
            % Set the Generic Props
            obj.BlockName   = block;
            obj.BlockHandle = get_param(block, 'handle');
            
            %Set the Mask Properties based on Block Properties
            obj.SlaveName = get_param(block,'SlaveName');
            obj.A2LFile = get_param(block,'A2LFile');
            obj.SlaveID = get_param(block,'SlaveID');
            obj.EnableSecurity = xcp.blkmasks.utils.onOff2Logical(get_param(block,'EnableSecurity'));
            obj.SeedKeyLib = get_param(block,'SeedKeyLib');
            obj.EnableStatus = xcp.blkmasks.utils.onOff2Logical(get_param(block,'EnableStatus'));
            obj.SampleTime = get_param(block,'SampleTime');
            
        end
    end
    
    %% DDG Dialog Schema
    methods
        function dlgstruct = getDialogSchema(obj) 

            configname.Name           = 'Config Name:        ';
            configname.Type           = 'edit';
            configname.Tag            = 'configname_tag';
            configname.MatlabArgs     = {obj,'%value'};
            configname.MatlabMethod   = 'setConfigName';
            configname.Value = obj.SlaveName;
            configname.RowSpan        = [1 1];
            configname.ColSpan        = [1 16];
            
            a2lbrowse.Type = 'pushbutton';
            a2lbrowse.Name = 'Browse...';
            a2lbrowse.Tag = 'a2lbrowse_tag';
            a2lbrowse.RowSpan = [2,2];
            a2lbrowse.ColSpan = [14 16];
            a2lbrowse.MatlabArgs = {obj};
            a2lbrowse.MatlabMethod = 'a2LBrowseCB';
            a2lbrowse.DialogRefresh = 1;
            
            a2ledit.Type = 'edit';
            a2ledit.Name = 'A2L File:               ';
            a2ledit.Tag = 'a2ledit_tag';
            a2ledit.RowSpan = [2 2];
            a2ledit.ColSpan = [1 13];
            a2ledit.MatlabArgs = {obj, '%value'};
            a2ledit.MatlabMethod = 'setA2LFile';
            a2ledit.Value = obj.A2LFile;
            
            securitybox.Type = 'checkbox';
            securitybox.Name = 'Enable seed/key security';
            securitybox.Tag = 'securitybox_tag';
            securitybox.RowSpan = [3 3];
            securitybox.ColSpan = [1 3];
            securitybox.MatlabArgs = {obj,'%value'};
            securitybox.MatlabMethod = 'setSecurity';
            securitybox.Value = obj.EnableSecurity;
            securitybox.DialogRefresh = true;
            
            securitytext.Type = 'text';
            securitytext.Name = '       File (*.DLL):   ';
            securitytext.Tag = 'securitytext_tag';
            securitytext.Enabled = obj.EnableSecurity;
            securitytext.RowSpan = [4 4];
            securitytext.ColSpan = [1 1];
            
            securityedit.Type = 'edit';
            securityedit.Name = '';
            securityedit.Tag = 'securityedit_tag';
            securityedit.RowSpan = [4 4];
            securityedit.ColSpan = [2 13];
            securityedit.MatlabArgs = {obj, '%value'};
            securityedit.MatlabMethod = 'setSeedKeyLib';
            securityedit.Value = obj.SeedKeyLib;
            securityedit.Enabled = obj.EnableSecurity;
            
            securitybrowse.Type = 'pushbutton';
            securitybrowse.Name = 'Browse...';
            securitybrowse.Tag = 'securitybrowse_tag';
            securitybrowse.RowSpan = [4 4];
            securitybrowse.ColSpan = [14 16];
            securitybrowse.MatlabArgs = {obj};
            securitybrowse.MatlabMethod = 'seedKeyBrowseCB';
            securitybrowse.Enabled = obj.EnableSecurity;
            securitybrowse.DialogRefresh = true;
            
            connstatus.Type = 'checkbox';
            connstatus.Name = 'Output connection status';
            connstatus.Tag = 'connstatus_tag';
            connstatus.RowSpan = [5 5];
            connstatus.ColSpan = [1 5];
            connstatus.MatlabArgs = {obj,'%value'};
            connstatus.MatlabMethod = 'setEnableStatus';
            connstatus.Value = obj.EnableStatus;
            connstatus.DialogRefresh = true;

            sampletime.Type = 'edit';
            sampletime.Name = 'Sample Time:        ';
            sampletime.Tag = 'sampletime_tag';
            sampletime.RowSpan = [8 8];
            sampletime.ColSpan = [1 16];
            sampletime.MatlabArgs = {obj,'%value'};
            sampletime.MatlabMethod = 'setSampleTime';
            sampletime.Value = obj.SampleTime;

            ParametersPanel.Type = 'group';
            ParametersPanel.Name = 'Parameters';
            ParametersPanel.Tag = 'ParametersPanel_tag';
            ParametersPanel.LayoutGrid = [10 16];
            ParametersPanel.Items = {configname, a2ledit, a2lbrowse, securitybox, securitytext,...
                                     securityedit, securitybrowse, connstatus, sampletime};
            
            dlgstruct.DialogTitle = ['Block Parameters: ', get_param(obj.BlockHandle,'Name')];
            dlgstruct.StandaloneButtonSet = {'OK','Apply','Cancel','Help'};
            dlgstruct.EmbeddedButtonSet = {'OK','Apply','Cancel','Help'};
            dlgstruct.Items = {ParametersPanel};
            dlgstruct.PreApplyMethod = 'PreApplyMethod';
            
            if (strcmpi(get_param(bdroot(obj.BlockName),'BlockDiagramType'),'Library'))
                %When in library don't do anything, just return.
                dlgstruct.DisableDialog=true;
                return
            end
            
            % Disable the dialog if we're in External mode and connected or
            % running.  SimulationStatus is 'external' if we're either
            % connected or running in external mode.
            mode = get_param( bdroot(obj.BlockName), 'SimulationMode' );
            status = get_param( bdroot(obj.BlockName), 'SimulationStatus' );
            if strcmpi( mode, 'external' ) && ~strcmpi( status, 'stopped' )
                dlgstruct.DisableDialog = true;
            end
        end
    end
    
    %% Set Methods/Callbacks
    methods
        function PreApplyMethod(obj)
            if (strcmp(get_param(bdroot(obj.BlockName),'BlockDiagramType'),'library'))
                return; %Don't do anything
            end
            set_param(obj.BlockHandle,'SlaveName', obj.SlaveName, ...
                                      'A2LFile'  , obj.A2LFile, ...
                                      'EnableSecurity', xcp.blkmasks.utils.logical2OnOff(obj.EnableSecurity),...
                                      'SeedKeyLib', obj.SeedKeyLib,...
                                      'EnableStatus', xcp.blkmasks.utils.logical2OnOff(obj.EnableStatus),...
                                      'SampleTime', obj.SampleTime);
        end

        function setSampleTime(obj,value)
           obj.SampleTime = value; 
        end
        
        function setEnableStatus(obj,value)
            obj.EnableStatus = value;
        end
        
        function seedKeyBrowseCB(obj)
            % Open the dialog to select the shared library.
            [filename, pathname] = uigetfile({'*.dll', 'Seed&Key Library(*.dll)'},...
                                    'Select a Seed&Key External Library(DLL)', obj.SeedKeyLib);

            % Check if a selection was made. 
            if ~(isequal(filename,0) || isequal(pathname,0))
                % Set the value on the block dialog. 
                %dialog.setWidgetValue(tags.SeedKeyLib, [pathname filename]);
                obj.SeedKeyLib = [pathname filename];
            end
        end
        
        function setSeedKeyLib(obj, value)
            obj.SeedKeyLib = value;
        end
        
        function setConfigName(obj,value)
            obj.SlaveName = value;
        end
        
        function setSecurity(obj,value)
            obj.EnableSecurity = value;
        end
        
        function a2LBrowseCB(obj)
            % Open the dialog to select the A2L file.
            [filename, pathname] = uigetfile({'*.a2l', 'A2L File(*.a2l)'},...
                                    'Select an A2L file', obj.A2LFile);
            
            % Check if a selection was made.                     
            if ~(isequal(filename,0) || isequal(pathname,0))
                obj.setA2LFile(fullfile(pathname,filename));
            end
        end
        
        function setA2LFile(obj, fullPath)
            
            if isempty(fullPath)
                obj.A2LFile = fullPath;
                return;
            end
            
            % Check for A2L file validity
            success = false;
            try
                xcpA2L(fullPath);
                success = true;
            catch %#ok<CTCH>
                % Do nothing.
            end

            if success
                % Verify if a file with A2L extension was provided.
                obj.A2LFile = fullPath;
            else % Invalid A2L file specified.
                err = message('xcp:xcpblks:InvalidA2LFile', fullPath);
                errTitle = message('xcp:xcpblks:XCPErrorTitle');
                uiwait(errordlg(err.string, errTitle.string, 'modal'));
            end
        end

        %Helper Functions
        function installCloseListener(obj)
            mdl = get_param(bdroot(obj.BlockHandle), 'Object');
            obj.CloseListener = handle.listener(mdl, 'CloseEvent', ...
                {@xcp.blkmasks.configBase.modelCloseListener, obj});
        end
        
    end

   %% Static Methods
   methods (Static = true)

		function modelCloseListener(~, ~, obj)
			obj.DialogHandle.delete;
			obj.delete;
		end
        
		function index = getCTRSchemeIndex(schemeString)
			index = 0;
			switch schemeString
				case 'One counter for all CTOs and DTOs'
					index = 1;
				case 'Separate counters for (RES,ERR,EV,SERV) and (DAQ)'
					index = 2;
				case 'Separate counters for (RES,ERR), (EV,SERV) and (DAQ)'
					index = 3;	
			end	
        end
 
        function [protocolInfo, transportInfo, daqInfo, eventsInfo, measurementsInfo, slaveTag, tlTag] = ...
                    getConfigParams
                
            %XCP.BLKMASKS.CONFIGBASE.GETCONFIGPARAMS pulls configuration parameters from the A2L
            %
            %    [PROTOCOLINFO, TRANSPORTINFO, DAQINFO, EVENTS, MEASUREMENTS] = 
            %    GETCONFIGPARAMS returns the required parameters XCP
            %    Configuration block

            % Get current block name and handle
            blk = gcb;
            blkh = gcbh;
            TLTypeStr = xcp.blkmasks.utils.getTLTypeStr(blkh);

            % Initialize all output parameters
            protocolInfo = [];
            transportInfo = [];
            daqInfo = [];
            eventsInfo = [];
            measurementsInfo = [];

            % Parse A2L file.
            fileName = get_param(gcbh, 'A2LFile');
            simStatus = get_param(bdroot(gcb), 'SimulationStatus');
            if strcmpi(simStatus, 'stopped')
                protocolInfo = 0;
                transportInfo = 0;
                daqInfo = 0;
                eventsInfo = 0;
                measurementsInfo = 0;    
                slaveTag = '';
                tlTag = '';
                return;
            end

            if isempty(fileName)
                error(message('xcp:xcpblks:NoA2LSpecified', TLTypeStr,blk));
            end
            a2lObj = xcpA2L(fileName);

            % Block Information
            configName = get_param(blkh, 'SlaveName');
            slaveTag = strcat(bdroot(blk), ['_',TLTypeStr,'Slave_'], configName);
            switch TLTypeStr
                case 'UDP'
                    tlTag = strcat(bdroot(blk), '_UDPTL_', configName); %Need a unique tlTag for each UDP Configuration
                case 'CAN'
                    tlTag = strcat(bdroot(blk), '_CANTL'); %There can only be one CAN TL in a model 
                otherwise
                    assert(false,'Internal Error: Invalid Use Case');
            end
            % Protocol Information - [TIMEOUTS MAXCTO/DTO BYTEORDER ADDRGRAN]

            % Convert byte order to enum
            protocolStruct = a2lObj.ProtocolLayerInfo;
            switch protocolStruct.ByteOrder
                case 'BYTE_ORDER_MSB_LAST'
                    byteOrder =0;
                case 'BYTE_ORDER_MSB_FIRST'
                    byteOrder =1;
            end

            % Convert Address granularity to enum
            switch protocolStruct.AddressGranularity
                case 'ADDRESS_GRANULARITY_BYTE'
                    addrGran =1;
                case 'ADDRESS_GRANULARITY_WORD'
                    addrGran =2;
                case 'ADDRESS_GRANULARITY_DWORD'
                    addrGran =4;
            end

            protocolInfo = [1 double(protocolStruct.T1) ...
                            double(protocolStruct.T2) ...
                            double(protocolStruct.T3) ...
                            double(protocolStruct.T4) ...
                            double(protocolStruct.T5) ...
                            double(protocolStruct.T6) ...
                            double(protocolStruct.T7) ...
                            double(protocolStruct.MaxCTO) ...
                            double(protocolStruct.MaxDTO) ...
                            byteOrder, ...
                            addrGran];

            % Transport Layer Information

            if(strcmp(TLTypeStr,'CAN')) % CAN Transport Layer

                transportStruct = a2lObj.TransportLayerCANInfo;
                % Sample rate.
                sampleRate = 0; % 1 sample per bit
                
                %This was commented in the old blocks:
                % switch transportStruct.SampleRate,
                %     case 'SINGLE',  % 1 sample per bit
                %         sampleRate = 0;
                %     case 'TRIPLE',  % 3 samples per bit
                %         sampleRate = 1;
                % end

                % @TODO:
                numDAQ = 0;
                daqCANIDs = 0;
                maxDlcRequired = 0;
                % Append extended ID flag to the MSB of CANID passed into s-functions
                canIDMaster = a2lObj.TransportLayerCANInfo.CANIDMaster;
                if transportStruct.CANIDMasterIsExtended
                    canIDMaster = canIDMaster + 2^31;
                end
                canIDSlave = a2lObj.TransportLayerCANInfo.CANIDSlave;
                if transportStruct.CANIDSlaveIsExtended
                    canIDSlave = canIDSlave + 2^31;
                end

                if strcmp(transportStruct.MaxDLCRequired, 'MAX_DLC_REQUIRED')
                    maxDlcRequired = 1;
                end

                transportInfo = [1, ...
                                 -1, ... % transportStruct.CANIDBroadcast
                                 double(canIDMaster), ...
                                 double(canIDSlave), ...
                                 double(transportStruct.BaudRate), ...
                                 sampleRate, ...
                                 maxDlcRequired, ...
                                 numDAQ, ...
                                 daqCANIDs];

            elseif(strcmp(TLTypeStr,'UDP'))% UDP Transport Layer

                transportStruct = a2lObj.TransportLayerUDPInfo;
                transportInfo = [1, ...
                    transportStruct.Address, ...
                    double(transportStruct.Port)];
            else
                assert(false,'Internal Error: Invalid Use Case');
            end
            
            % DAQ Information
            daqStruct = a2lObj.DAQInfo;

            % Get Config Type.
            switch daqStruct.ConfigType
                case 'STATIC'
                    configType = 0;
                case 'DYNAMIC'
                    configType = 1;
            end

            % Optimization type.
            switch daqStruct.OptimizationType
                case 'OPTIMISATION_TYPE_DEFAULT'
                    optType=0;
                case 'OPTIMISATION_TYPE_ODT_TYPE_16'
                    optType=1;
                case 'OPTIMISATION_TYPE_ODT_TYPE_32'
                    optType=2;
                case 'OPTIMISATION_TYPE_ODT_TYPE_64'
                    optType=3;
                case 'OPTIMISATION_TYPE_ODT_TYPE_ALIGNMENT'
                    optType=4;
                case 'OPTIMISATION_TYPE_MAX_ENTRY_SIZE'
                    optType=5;
            end

            % Address extension
            switch daqStruct.AddressExtension
                case 'ADDRESS_EXTENSION_FREE'
                    addrExt=0;
                case 'ADDRESS_EXTENSION_ODT'
                    addrExt=1;
                case 'ADDRESS_EXTENSION_DAQ'
                    addrExt=2;
            end

            % Identification field.
            switch daqStruct.IdentificationFieldType
                case 'IDENTIFICATION_FIELD_TYPE_ABSOLUTE'
                    idField=0;
                case 'IDENTIFICATION_FIELD_TYPE_RELATIVE_BYTE'
                    idField=1;
                case 'IDENTIFICATION_FIELD_TYPE_RELATIVE_WORD'
                    idField=2;
                case 'IDENTIFICATION_FIELD_TYPE_RELATIVE_WORD_ALIGNED'
                    idField=3;
            end

            % Granularity ODT entry size.
            switch daqStruct.GranularityODTEntrySize
                case 'GRANULARITY_ODT_ENTRY_SIZE_DAQ_BYTE'
                    granularityODTEntryDAQ = 1;
                case 'GRANULARITY_ODT_ENTRY_SIZE_DAQ_WORD'
                    granularityODTEntryDAQ = 2;
                case 'GRANULARITY_ODT_ENTRY_SIZE_DAQ_DWORD'
                    granularityODTEntryDAQ = 4;
                case 'GRANULARITY_ODT_ENTRY_SIZE_DAQ_DLONG'
                    granularityODTEntryDAQ = 8;
            end

            % Overload indication.
            switch daqStruct.OverloadIndication
                case 'NO_OVERLOAD_INDICATION'
                    overload=0;
                case 'OVERLOAD_INDICATION_PID'
                    overload=1;
                case 'OVERLOAD_INDICATION_EVENT'
                    overload=2;
            end
            
            % Timestamp
            timestampTicks = double(daqStruct.Timestamp.Ticks);
            switch daqStruct.Timestamp.Size
                case 'SIZE_BYTE'
                    timestampSize = 1;
                case 'SIZE_WORD'
                    timestampSize = 2;
                case 'SIZE_DWORD'
                    timestampSize = 4;
                otherwise
                    timestampSize = 0; %No timestamp
            end
            
            switch daqStruct.Timestamp.Unit
                case 'UNIT_1NS'
                    timestampUnit = 0;
                case 'UNIT_10NS'
                    timestampUnit = 1;
                case 'UNIT_100NS'
                    timestampUnit = 2;
                case 'UNIT_1US'
                    timestampUnit = 3;
                case 'UNIT_10US'
                    timestampUnit = 4;
                case 'UNIT_100US'
                    timestampUnit = 5;
                case 'UNIT_1MS'
                    timestampUnit = 6;
                case 'UNIT_10MS'
                    timestampUnit = 7;
                case 'UNIT_100MS'
                    timestampUnit = 8;
                case 'UNIT_1S'
                    timestampUnit = 9;
                otherwise
                    timestampUnit = 0;  %Safely default to 'UNIT_1NS'
            end
                    
                    

            % @TODO: Not yet implemented.
            granularityODTEntrySTIM = 1;
            % switch daqStruct.GranularityODTEntrySizeStim
            %     case 'GRANULARITY_ODT_ENTRY_SIZE_STIM_BYTE'
            %         granularityODTEntrySTIM = 1;
            %     case 'GRANULARITY_ODT_ENTRY_SIZE_STIM_WORD'
            %         granularityODTEntrySTIM = 2;
            %     case 'GRANULARITY_ODT_ENTRY_SIZE_STIM_DWORD'
            %         granularityODTEntrySTIM = 4;
            %     case 'GRANULARITY_ODT_ENTRY_SIZE_STIM_DLONG'
            %         granularityODTEntrySTIM = 8;
            % end

            daqInfo = [1, ...
                       configType, ...
                       overload, ...
                       double(daqStruct.MaxDAQ), ...
                       double(daqStruct.MaxEventChannels), ...
                       double(daqStruct.MinDAQ), ...
                       optType, ...
                       addrExt, ...
                       idField, ...
                       granularityODTEntryDAQ, ...
                       double(daqStruct.MaxODTEntrySize), ... % We might have to prefix DAQ here.
                       granularityODTEntrySTIM, ...
                       -1, ... % daqStruct.MaxODTEntrySizeSTIM? or stimSTRUCT
                       -1, ... % STIM bit in STIM struct
                       timestampTicks, ...
                       timestampSize,  ...
                       timestampUnit];

            % Events 
            eventNames = a2lObj.Events;
            numEvents = length(eventNames);

            for idx = 1:numEvents
                % Get Event structure.
                eventStruct = a2lObj.getEventInfo(eventNames{idx});
                % Get the direction.
                switch eventStruct.Direction
                    case 'DAQ'
                        direction = 1;
                    case 'STIM'
                        direction = 2;
                    case 'DAQ_STIM'
                        direction = 3;
                end
                eventsInfo = [eventsInfo, ...
                              double(eventStruct.ChannelNumber), ...
                              direction, ...
                              double(eventStruct.MaxDAQList), ...
                              double(eventStruct.ChannelTimeCycle), ...
                              double(eventStruct.ChannelTimeUnit), ...
                              double(eventStruct.ChannelPriority)];
            end

            eventsInfo = [numEvents eventsInfo];

            % Measurements

            measurementNames = a2lObj.Measurements';
            numMeasurements = length(measurementNames);
            byteorder = 0;
            
            %Extract array of measurement structs and make sure they have
            %the same order as the measurement names.
            MeasurementInfo = values(a2lObj.MeasurementInfo);
            [~, indices] = sortrows(measurementNames);
            MeasurementInfo(indices) = MeasurementInfo(:);
            
            for idx = 1:numMeasurements
                % Get measurements structure. 
                measurementStruct = MeasurementInfo{idx};
                % Data type.
                datatype = 1;
                switch upper(measurementStruct.DataType)
                    case 'UBYTE'
                       datatype = 1;
                    case 'SBYTE'
                       datatype = 2;
                    case 'UWORD'
                       datatype = 3;
                    case 'SWORD'
                       datatype = 4;
                    case 'ULONG'
                       datatype = 5;
                    case 'SLONG'
                       datatype = 6;
                    case 'FLOAT32_IEEE'
                       datatype = 7;
                end

                % Initialize
                resolution = 0;
                conversion = -1;
                accuracy = 0;
                lowerLimit = 0;
                upperLimit = 0;
                scalingUnit = 0;
                rate = 0;
                ecuAddress = 0;

                if ~isempty(double(measurementStruct.Resolution))
                    resolution = double(measurementStruct.Resolution);
                end
                if ~isempty(double(measurementStruct.Accuracy))
                    accuracy = double(measurementStruct.Accuracy);
                end
                if ~isempty(double(measurementStruct.LowerLimit))
                    lowerLimit = double(measurementStruct.LowerLimit);
                end
                if ~isempty(double(measurementStruct.UpperLimit))
                    upperLimit = double(measurementStruct.UpperLimit);
                end
                if ~isempty(double(measurementStruct.ECUAddress))
                    ecuAddress = double(measurementStruct.ECUAddress);
                end    

                if ~isempty(measurementStruct.ByteOrder)
                    switch upper(measurementStruct.ByteOrder)
                        case 'MSB_FIRST'
                            byteorder = 1; %big endian
                        case 'MSB_LAST'
                            byteorder = 0; %little endian
                    end
                end

                measurementsInfo = [measurementsInfo, ...
                                    datatype, ... 
                                    conversion, ... % Conversion is a string.
                                    resolution, ...
                                    accuracy, ...
                                    lowerLimit, ...
                                    upperLimit, ... % Scaling Unit % Rate
                                    scalingUnit, ...
                                    rate, ...
                                    ecuAddress, ...
                                    byteorder]; %#ok<*AGROW>

            end
            measurementsInfo = [numMeasurements measurementsInfo];
        end
        
        function uniqueConfigID
            %    XCP.BLKMASKS.CONFIGBASE.UNIQUECONFIGID Determines a unique configuration ID for
            %    each XCP UDP or CAN Configuration block copied over in a model. 

            %    SS 06-15-12
            %    Copyright 2012-2018 The MathWorks, Inc.

            % Get the current block.
            blk = gcb;
            blkh = gcbh;
            TLTypeStr = xcp.blkmasks.utils.getTLTypeStr(gcbh);

            allConfigBlocks = find_system(bdroot, ...
                                          'FollowLinks', 'on', ...
                                          'IncludeCommented',   'on', ...
                                          'LookUnderMasks', 'on', ...
                                          'MaskType', ['XCP ',TLTypeStr,' Configuration']);
            currentBlockIndex = ismember(allConfigBlocks, blk);

            % Remove the current block from the list.
            allConfigBlocks(currentBlockIndex) = [];

            % Loop through config blocks and find slave ID indices.
            if isempty(allConfigBlocks) % Return, by default set to 1. 
                set_param(blkh, 'SlaveID', '1');
                set_param(blkh, 'SlaveName', [TLTypeStr,'_Config1']);
                return;
            end

            % Continue if we have multiple slaves.
            ids = zeros(1, length(allConfigBlocks));
            for idx = 1: length(allConfigBlocks)
                ids(idx) = str2double(get_param(allConfigBlocks{idx}, 'SlaveID'));
            end

            ids = [0 unique(ids)];
            diffs = diff(ids);
            indices = find(diffs~=1);
            if isempty(indices)
                uniqueSlaveID = length(ids);
            else
                uniqueSlaveID = indices(1);
            end

            % Set it on the current block.
            set_param(blkh, 'SlaveID', num2str(uniqueSlaveID));
            set_param(blkh, 'SlaveName', strcat(TLTypeStr,'_Config', num2str(uniqueSlaveID)));
        end
        
        function structToReturn = getWidgetTags()
            structToReturn.SlaveName = 'configname_tag';
            structToReturn.FileName = 'a2ledit_tag';
            structToReturn.AddFile = 'a2lbrowse_tag';
            structToReturn.EnableSecurity = 'securitybox_tag';
            structToReturn.SeedKeyLib = 'securityedit_tag';
            structToReturn.EnableStatus = 'connstatus_tag';
            structToReturn.SampleTime = 'sampletime_tag';
        end
		
   end
    
end



