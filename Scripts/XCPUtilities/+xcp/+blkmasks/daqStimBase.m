classdef daqStimBase < handle
    %XCP.BLKMASKS.DAQSTIMBASE
    %   XCP.BLKMASKS.DAQ and XCP.BLKMASKS.STIM inherit from this base class

%   Copyright 2018 The MathWorks, Inc.
    
    properties(SetObservable=true)
        % Mask Parameters
        SlaveName = '';
        EventName = '';
        A2LFile = '';
        AllMeasurements = '';
        SelectedMeasurements = '';
        EnableTimestamp = false;
        
        % Internal Parameters
        ConfigEnable = false;
        A2LParserObject = [];
        EventEntries = {};
        SearchField = '';
        FilteredMeasurements = {};
        Direction = '';
        tlTypeStr = ''; %UDP or CAN
        TimestampSupported = false;
        
        % Generic Properties
        BlockHandle;
        BlockName;
        DialogHandle;
        CloseListener;
    end
    
    %% Constructor Block
    methods
        function obj = daqStimBase(block, direction)
            obj.Direction = direction; %DAQ or STIM
            obj.tlTypeStr = xcp.blkmasks.utils.getTLTypeStr(block); %UDP or CAN
            
            % Set the Generic Props
            obj.BlockName   = block;
            obj.BlockHandle = get_param(block, 'handle');
            
            %Set the Mask Properties based on Block Properties
            obj.EventName     = get_param(block, 'EventName');
            obj.A2LFile = get_param(block,'A2LFile');
            obj.AllMeasurements    = get_param(block, 'AllMeasurements');
            obj.SelectedMeasurements= get_param(block, 'SelectedMeasurements');
            

            if (~ValidateSlaveName(block))
                err = message('xcp:xcpblks:InvalidConfigName', xcp.blkmasks.utils.getTLTypeStr(block), get_param(block, 'SlaveName'));
                errTitle = message('xcp:xcpblks:XCPErrorTitle');
                uiwait(errordlg(err.string, errTitle.string, 'modal'));
                obj.ConfigEnable = false;
                set_param(block,'SlaveName', '<Please select a config name>'); %Back to default
            else
                obj.ConfigEnable = true;
            end
            obj.SlaveName = get_param(block, 'SlaveName');
            if ~strcmp(obj.SlaveName, '<Please select a config name>')
                obj.ConfigEnable = true;
            end
            
            [obj.A2LParserObject, ~, obj.ConfigEnable] = ImportConfig(obj.SlaveName, block);
            if (~isempty(obj.A2LParserObject))
                [obj.EventEntries, obj.AllMeasurements] = getEventsAndMeasurements(obj.A2LParserObject, obj.Direction);
                if(~isempty(obj.EventEntries) && ~any(contains(obj.EventEntries,obj.EventName)))
                    warn = message('xcp:xcpblks:choosingDefaultEvent', obj.EventEntries{1});
                    uiwait(warndlg(warn.string, 'XCP Warning', 'modal'));
                    obj.EventName = obj.EventEntries{1};
                end
            end
            if (isempty(obj.EventEntries))
                obj.ConfigEnable = false;
            end
            
            %Timestamp
            obj.EnableTimestamp = xcp.blkmasks.utils.onOff2Logical(get_param(obj.BlockHandle,'EnableTimestamp'));
            if(~isempty(obj.A2LParserObject))
                timestampSize = obj.A2LParserObject.DAQInfo.Timestamp.Size;
                if(~strcmp(timestampSize,'SIZE_BYTE') && ~strcmp(timestampSize,'SIZE_WORD') && ~strcmp(timestampSize,'SIZE_DWORD'))
                    obj.EnableTimestamp = false;
                    set_param(obj.BlockHandle, 'EnableTimestamp', 'off');
                else
                    obj.TimestampSupported = true;
                end 
            end
                
        end
    end
    
    %% DDG Dialog Schema
    methods
        function dlgstruct = getDialogSchema(obj) 

            configname.Name           = 'Config Name:       ';
            configname.Mode           = 0;
            configname.Type           = 'combobox';
            configname.Tag            = 'configname_tag';
            configname.MatlabArgs     = {obj,'%dialog','%tag'};
            configname.MatlabMethod   = 'setConfigName';
            configname.Entries        = FindValidSlaveNames(obj.BlockHandle);
            configname.Value = obj.SlaveName;
            configname.DialogRefresh = 1;
            configname.RowSpan        = [1 1];
            configname.ColSpan        = [1 16];
            
            eventname.Name = 'Event Name:        ';
            eventname.Type = 'combobox';
            eventname.Tag = 'eventname_tag';
            eventname.MatlabArgs = {obj,'%dialog', '%tag'};
            eventname.MatlabMethod = 'setEventName';
            eventname.Entries = obj.EventEntries;
            eventname.Value = obj.EventName;
            eventname.RowSpan = [2 2];
            eventname.ColSpan  = [1 16];
            eventname.Enabled = obj.ConfigEnable;
            eventname.DialogRefresh = 1;
            
            allmeasurements.Name = 'All Measurements:';
            allmeasurements.Type = 'listbox';
            allmeasurements.Tag = 'allmeasurements_tag';
            allmeasurements.RowSpan = [4 10];
            allmeasurements.ColSpan = [1 7];
            allmeasurements.MinimumSize = [200 200];
            allmeasurements.Enabled = obj.ConfigEnable;
            %Apply Measurement Filter
            fullList = strsplit(obj.AllMeasurements,';');
            obj.FilteredMeasurements = getFilteredList(fullList, obj.SearchField);
            allmeasurements.Entries = obj.FilteredMeasurements;
            
            selectedmeasurements.Name = 'Selected Measurements:';
            selectedmeasurements.Type = 'listbox';
            selectedmeasurements.Tag            = 'selectedmeasurements_tag';
            selectedmeasurements.RowSpan = [4 10];
            selectedmeasurements.ColSpan = [9 15];
            selectedmeasurements.MinimumSize = [200 200];
            selectedmeasurements.Enabled = obj.ConfigEnable;
            selectedmeasurements.Entries = strsplit(obj.SelectedMeasurements,';');
            
            searchfield.Name = 'Search:';
            searchfield.Type = 'edit';
            searchfield.Tag = 'searchfield_tag';
            searchfield.RowSpan = [2 2];
            searchfield.ColSpan = [1,7];
            searchfield.Enabled = obj.ConfigEnable;
            searchfield.Clearable = true;
            searchfield.PlaceholderText = 'Find Measurements';
            searchfield.RespondsToTextChanged = true;
            searchfield.MatlabArgs = {obj,'%value'};
            searchfield.MatlabMethod = 'searchFieldCB';
            searchfield.DialogRefresh = true;
            
            addbutton.Type = 'pushbutton';
            addbutton.Tag = 'addbutton_tag';
            addbutton.RowSpan = [7,7];
            addbutton.ColSpan = [8 8];
            addbutton.Enabled = obj.ConfigEnable;
            addbutton.Alignment = 6;
            addbutton.FilePath = fullfile(matlabroot, 'toolbox', 'shared', 'dastudio', 'resources', 'add_row.gif');
            addbutton.MatlabArgs = {obj, '%dialog'};
            addbutton.MatlabMethod = 'addButtonCB';
            addbutton.DialogRefresh = 1;
            
            removebutton.Type = 'pushbutton';
            removebutton.Tag = 'removebutton_tag';
            removebutton.RowSpan = [8,8];
            removebutton.ColSpan = [8 8];
            removebutton.Enabled = obj.ConfigEnable;
            removebutton.Alignment = 6;
            removebutton.FilePath = fullfile(matlabroot, 'toolbox', 'shared', 'dastudio', 'resources', 'tte_delete.gif');
            removebutton.MatlabArgs = {obj, '%dialog'};
            removebutton.MatlabMethod = 'removeButtonCB';
            removebutton.DialogRefresh = 1;
            
            moveup.Type = 'pushbutton';
            moveup.Tag = 'moveup_tag';
            moveup.RowSpan = [7,7];
            moveup.ColSpan = [16 16];
            moveup.Enabled = obj.ConfigEnable;
            moveup.Alignment = 6;
            moveup.FilePath = fullfile(matlabroot, 'toolbox', 'shared', 'dastudio', 'resources', 'move_up.gif');
            moveup.MatlabArgs = {obj, '%dialog'};
            moveup.MatlabMethod = 'moveUpCB';
            moveup.DialogRefresh = 1;     
            
            movedown.Type = 'pushbutton';
            movedown.Tag = 'movedown_tag';
            movedown.RowSpan = [8,8];
            movedown.ColSpan = [16 16];
            movedown.Enabled = obj.ConfigEnable;
            movedown.Alignment = 6;
            movedown.FilePath = fullfile(matlabroot, 'toolbox', 'shared', 'dastudio', 'resources', 'move_down.gif');
            movedown.MatlabArgs = {obj, '%dialog'};
            movedown.MatlabMethod = 'moveDownCB';
            movedown.DialogRefresh = 1;  
            
            enabletimebox.Type = 'checkbox';
            enabletimebox.Name = '  Enable Timestamp';
            enabletimebox.Tag = 'enabletimebox_tag';
            enabletimebox.RowSpan = [9,9];
            enabletimebox.ColSpan = [1 16];
            enabletimebox.Enabled = obj.ConfigEnable & obj.TimestampSupported;
            enabletimebox.Value   = obj.EnableTimestamp;
            enabletimebox.Visible = obj.TimestampSupported;
            enabletimebox.MatlabArgs = {obj, '%value'};
            enabletimebox.MatlabMethod = 'setEnableTimestamp';
            enabletimebox.DialogRefresh = 1;
   
            MeasurementsPanel.Type='group';
            MeasurementsPanel.Name='Measurements';
            MeasurementsPanel.LayoutGrid=[10 16];
            MeasurementsPanel.Items={searchfield, allmeasurements, addbutton,removebutton, selectedmeasurements, moveup, movedown};
            MeasurementsPanel.ColSpan = [1 16];
            MeasurementsPanel.RowSpan = [3, 8];
            
            ParametersPanel.Type = 'group';
            ParametersPanel.Name = 'Parameters';
            ParametersPanel.Tag = 'ParametersPanel_tag';
            ParametersPanel.LayoutGrid = [13 16];
            ParametersPanel.Items = {configname,eventname, MeasurementsPanel, enabletimebox};
            
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
            set_param(obj.BlockHandle,'SlaveName',obj.SlaveName,'EventName',obj.EventName,...
                'AllMeasurements',obj.AllMeasurements, 'SelectedMeasurements',obj.SelectedMeasurements, ...
                'A2LFile', obj.A2LFile, 'EnableTimestamp', xcp.blkmasks.utils.logical2OnOff(obj.EnableTimestamp));
        end
        
        function setConfigName(obj,dialog, tag)
            if (strcmp(get_param(bdroot(obj.BlockName),'BlockDiagramType'),'library'))
                return;
            end
            if (strcmp(obj.SlaveName,dialog.getComboBoxText(tag)))
                isNewConfig = false;
            else
                isNewConfig = true;
                obj.SlaveName = dialog.getComboBoxText(tag); 
            end
            
            [obj.A2LParserObject, obj.A2LFile, obj.ConfigEnable] = ImportConfig(obj.SlaveName, obj.BlockHandle);
            
            %Timestamp
            if(~isempty(obj.A2LParserObject))
                timestampSize = obj.A2LParserObject.DAQInfo.Timestamp.Size;
                if(~strcmp(timestampSize,'SIZE_BYTE') && ~strcmp(timestampSize,'SIZE_WORD') && ~strcmp(timestampSize,'SIZE_DWORD'))
                    obj.EnableTimestamp = false;
	                set_param(obj.BlockHandle, 'EnableTimestamp', 'off');
                else
                    obj.TimestampSupported = true;
                end 
            end
            
            obj.EventEntries = {};
            
            if (obj.ConfigEnable)
                [obj.EventEntries, obj.AllMeasurements] = getEventsAndMeasurements(obj.A2LParserObject, obj.Direction);
                if (isempty(obj.EventEntries))
                    obj.ConfigEnable = false;
                    error(message('xcp:xcpblks:noEventsInA2L',obj.A2LFile)); %Will return
                end
                if (isempty(obj.EventName))
                    obj.EventName = obj.EventEntries{1};
                end
                if (isNewConfig)
                    obj.EventName = obj.EventEntries{1};
                    obj.SelectedMeasurements = '';
                end
            end
        end
        
        function setEventName(obj,dialog, tag)
            obj.EventName = dialog.getComboBoxText(tag);
        end
        
        function addButtonCB(obj,dialog)
            % Get the fields that are selected.
            values = dialog.getWidgetValue('allmeasurements_tag');

            % Return if none selected.
            if isempty(values)
                return;
            end

            % Make 1-based.
            values = values + 1;

            % Get all filtered measurements
            measurements = obj.FilteredMeasurements;
            measToAdd = measurements(values);

            % Get current list of selected measurements
            currentMeasList = strsplit(obj.SelectedMeasurements,';');

            % Get a final list.
            actualMeasToAdd = measToAdd(~ismember(measToAdd, currentMeasList));
            if isempty(actualMeasToAdd)
                indices = find(ismember(currentMeasList, measToAdd));
                dialog.setWidgetValue('selectedmeasurements_tag', []);
                dialog.setWidgetValue('selectedmeasurements_tag', indices-1);
                % Nothing to add.
                return;
            end
            measToAddStr = sprintf('%s;', actualMeasToAdd{:});
            if ~isempty(obj.SelectedMeasurements)
                obj.SelectedMeasurements = sprintf('%s;%s', obj.SelectedMeasurements, measToAddStr(1:end-1));
            else
                obj.SelectedMeasurements = measToAddStr(1:end-1);
            end
            
        end
        
        function removeButtonCB(obj,dialog)
            % Get the fields that are selected.
            values = dialog.getWidgetValue('selectedmeasurements_tag');

            % Return if none selected.
            if isempty(values) 
                return;
            end

            % Make 1-based.
            values = values + 1;

            listOfSelectedMeasurements = strsplit(obj.SelectedMeasurements,';');

            allList = 1:length(listOfSelectedMeasurements);

            finalList = listOfSelectedMeasurements(~ismember(allList, values));
            finalListStr = sprintf('%s;', finalList{:});
            obj.SelectedMeasurements = finalListStr(1:end-1);
            
            %TODO:  Delete this code if not needed:
            %Not sure why all this was needed
            % Select the ones deleted in the all measurements list.
%             deletedList = listOfSelectedMeasurements(ismember(allList, values));
%             allMeasList = strsplit(obj.AllMeasurements,';');
%             indices = find(ismember(allMeasList, deletedList));
%             dialog.setWidgetValue(allmeasurements_tag, []);
%             dialog.setWidgetValue(allmeasurements_tag, indices-1);
        end
        
        function moveUpCB(obj,dialog)
           obj.SelectedMeasurements = moveUpButton(dialog,obj.SelectedMeasurements);
        end
        
        function moveDownCB(obj,dialog)
           obj.SelectedMeasurements = moveDownButton(dialog,obj.SelectedMeasurements);
        end
        
        function searchFieldCB(obj, value)
            obj.SearchField = value;
        end
        
        function setEnableTimestamp(obj, value)
            obj.EnableTimestamp = value;
        end

        %Helper Functions
        function installCloseListener(obj)
            mdl = get_param(bdroot(obj.BlockHandle), 'Object');
            obj.CloseListener = handle.listener(mdl, 'CloseEvent', ...
                {@xcp.blkmasks.daqStimBase.modelCloseListener, obj});
        end
    end

   %% Static Methods
   methods (Static = true)

        function modelCloseListener(~, ~, obj)
            obj.DialogHandle.delete;
            obj.delete;
        end
        
        function [slaveID, eventsInfo, measurementsInfo, slaveTag, enableTimestamp] = getDaqStimParams
            %XCP.BLKMASKS.DAQSTIMBASE.GETDAQSTIMPARAMS Returns the required parameters XCP DAQ and STIM block
            %

            % Get current block name and handle
            blk = gcb;
            blkh = gcbh;
            
            TLTypeStr = xcp.blkmasks.utils.getTLTypeStr(blkh);
            
            % Initialize all output parameters
            slaveID = 0;
            eventsInfo = 0;
            measurementsInfo = 0;
            slaveTag = '';
            if(strcmpi(get_param(blkh,'EnableTimestamp'),'on'))
                enableTimestamp = 1;
            else
                enableTimestamp = 0;
            end

            % Find config block and get slave ID
            configName = get_param(blkh, 'SlaveName');
            configBlk = find_system(bdroot(blk), 'FollowLinks', 'on', ...
                                'LookUnderMasks', 'all', ...
                                'MaskType',['XCP ',TLTypeStr,' Configuration'],...
                                'SlaveName',configName);
            % No configuration block found.
            if isempty(configBlk) || strcmpi(configName, '<Please select a config name>')
                eventsInfo = 0;
                measurementsInfo = 0;
                return;
            end

            % Get slave id from the configuration block.
            slaveIDStr = get_param(configBlk{1}, 'SlaveID');
            slaveID = str2double(slaveIDStr);
            slaveTag = strcat(bdroot(blk),'_',TLTypeStr,'Slave_', configName);
            fileName = get_param(configBlk{1}, 'A2LFile');
            % Return if no A2L specified.
            if isempty(fileName)
                return;
            end

            % Do not do any S-Function initializations when just updating ports.
            simStatus = get_param(bdroot(gcb), 'SimulationStatus');
            if strcmpi(simStatus, 'stopped')
                return;
            end

            a2lObj = xcpA2L(fileName);
            allEvents = a2lObj.Events;
            selEvent = get_param(blkh, 'EventName');
            idx = strfind(selEvent, '(');
            selEvent = selEvent(1:idx-2); % Extract the name.
            eventIdx = find(ismember(allEvents, selEvent));
            if(isempty(eventIdx))
               error(message('xcp:xcpblks:noEventSelected', blk)); 
            end
            eventsInfo = [1 eventIdx-1]; % Make eventIdx zero based.

            % Get measurement information.
            allMeasurements = a2lObj.Measurements;
            selectedMeasurements = get_param(blkh, 'SelectedMeasurements');
            selectedMeasurements = strsplit(selectedMeasurements,';');
            [~, measIdx] = ismember(selectedMeasurements, allMeasurements);
            if measIdx == 0
                % If no matched measurement found (either no event in A2L file or no event 
                % been selected), measIdx returns 0. We should error out and prevent
                % the model from proceeding.
                error(message('xcp:xcpblks:noMeasurementsSelected', blk));
            else
                measurementsInfo = [length(measIdx) measIdx-1];
            end
            
            %Timestamp Enable
            timestampSize = a2lObj.DAQInfo.Timestamp.Size;
            if(~strcmp(timestampSize,'SIZE_BYTE') && ~strcmp(timestampSize,'SIZE_WORD') && ~strcmp(timestampSize,'SIZE_DWORD'))
                set_param(blkh,'EnableTimestamp','off');
                enableTimestamp = 0;
            end
            
        end
        
        function structToReturn = getWidgetTags()
            structToReturn.SlaveName = 'configname_tag';
            structToReturn.EventName = 'eventname_tag';
            structToReturn.SearchField = 'searchfield_tag';
            structToReturn.SelectedMeasurements = 'selectedmeasurements_tag';
            structToReturn.AllMeasurements = 'allmeasurements_tag';
            structToReturn.AddButton = 'addbutton_tag';
            structToReturn.RemoveButton = 'removebutton_tag';
            structToReturn.MoveDownButton = 'movedown_tag';
            structToReturn.MoveUpButton = 'moveup_tag';
            structToReturn.Timestamp    = 'enabletimebox_tag';
        end
   end
    
end %classdef



%% Local Functions %%

function [a2LParserObject, a2LFileName, configEnable] = ImportConfig(slaveName, daqStimBlock)
    TLTypeStr = xcp.blkmasks.utils.getTLTypeStr(daqStimBlock);

    configEnable = true;
    a2LParserObject = [];
    a2LFileName = '';

    out = find_system(bdroot, 'LookUnderMasks', 'all', 'MaskType', ['XCP ',TLTypeStr,' Configuration'], 'SlaveName', slaveName);
    if isempty(out) % The XCP UDP or CAN Configuration block has been deleted.
        configEnable = false;
        return;
    elseif (length(out)>1) 
        % Multiple XCP UDP or CAN Configuration blocks have been found.
        err = message('xcp:xcpblks:MoreThanOneConfigFound',TLTypeStr, slaveName);
        errTitle = message('xcp:xcpblks:XCPErrorTitle');
        uiwait(errordlg(err.string, errTitle.string, 'modal'));
        configEnable = false;
        return;
    end

    % Get the A2L file information.
    a2LFileName = get_param(out{1}, 'A2LFile');
    if isempty(a2LFileName) 
            err = message('xcp:xcpblks:NoA2LSpecified', TLTypeStr, out{1});
            errTitle = message('xcp:xcpblks:XCPErrorTitle');
            uiwait(errordlg(err.string, errTitle.string, 'modal'));
            configEnable = false;
        return;
    end

    a2lFileNameCell = localGetEntries(a2LFileName);
    try
        a2LParserObject = xcpA2L(a2lFileNameCell{1});
    catch e
        % Error here about invalid A2L file, just in case.
        err = message('xcp:xcpblks:ErrorOpeningA2LFile',TLTypeStr, slaveName, e.message);
        errTitle = message('xcp:xcpblks:XCPErrorTitle');
        uiwait(errordlg(err.string, errTitle.string, 'modal'));
        configEnable = false;
        return;
    end
end

function status = ValidateSlaveName(block)
    status = 1;
    [entries, ~] = FindValidSlaveNames(block);
    slaveName = get_param(block,'SlaveName');
    if (~ismember(slaveName, entries))
        status = 0;
    end
end

function [entries, blockNames] = FindValidSlaveNames(block)
    % Finds slave names based on other configuration blocks in the model.
    TLTypeStr = xcp.blkmasks.utils.getTLTypeStr(block);
    entries = {'<Please select a config name>'};
    blockNames = {};
    out = find_system(bdroot, 'LookUnderMasks', 'all', 'MaskType', ['XCP ',TLTypeStr,' Configuration']);
    for idx = 1:length(out)
        slaveName = get_param(out{idx}, 'SlaveName');
        if ~isempty(slaveName)
            if ismember(slaveName, entries) || isempty(get_param(out{idx}, 'A2LFile'))
                continue;
            end
            blockNames{end+1} = out{idx}; %#ok<*AGROW>
            entries{end+1} = slaveName;
        end
    end
end

function entriesCell = localGetEntries(entriesStr)
    if ~contains(entriesStr, ';')
        entriesCell = {entriesStr};
    else % We have more entries.
        entriesCell = strsplit(entriesStr, ';');
    end
end

function [events, measurements] = getEventsAndMeasurements(a2LParserObject, direction) %direction = DAQ or STIM
    measurements = '';

    cycleStr = getEventTimeInfo(a2LParserObject, a2LParserObject.Events);
    events = getEventsList(a2LParserObject, a2LParserObject.Events, cycleStr, direction);
    if ~isempty(events)
        measurementNameStr = sprintf('%s;', a2LParserObject.Measurements{:});
        measurements = measurementNameStr(1:end-1);
    end

end

function filteredList = getFilteredList(fullList, filterStr)
    filteredList = fullList;
    if ~isempty(filterStr)
        % Make sure no whitespace exists.
        filterStr = strtrim(filterStr);
        if ~isempty(filterStr)
            % use a case sensitive match if the filter string is mixed case
            % otherwise use a case insensitive match
            if strcmp(lower(filterStr), filterStr)
                matchingProperties = strfind(lower(filteredList), filterStr);
            else
                matchingProperties = strfind(filteredList, filterStr);
            end

            % filter!
            filteredList = filteredList(~cellfun('isempty', matchingProperties));        
        end
    end
end

function selectedMeasurements = moveUpButton(dialog,selectedMeasurements)
    % Get the fields that are selected.
    values = dialog.getWidgetValue('selectedmeasurements_tag');

    % Return if none selected.
    if isempty(values)
        return;
    end

    measurements = strsplit(selectedMeasurements,';');

    % Determine the rows to swap with. 
    rows = values;
    tempRows = values - 1;

    if isempty(find(tempRows<0, 1))
        % We can move successfully.
        measurementsToMove = cell(length(rows), 2);
        for idx = 1:length(rows)
            measurementToMove = measurements{rows(idx)+1};
            rowToMoveBefore = rows(idx)-1;
            if ~isempty(find(rows == rowToMoveBefore,1))
                rowToMoveBefore = rows(1)-1;
            end
            measurementToMoveBefore = measurements{rowToMoveBefore + 1};
            measurementsToMove{idx,1} = measurementToMove;
            measurementsToMove{idx,2} = measurementToMoveBefore;
        end
        if (length(rows)==1)
            measurements = swapMeasurements(measurements, measurementsToMove{1}, measurementsToMove{2});
        else
            for idx = 1:length(measurementsToMove)
                measurements = swapMeasurements(measurements, measurementsToMove{idx, 1}, measurementsToMove{idx, 2});
            end
        end
        finalMeasStr = sprintf('%s;', measurements{:});
        selectedMeasurements = finalMeasStr(1:end-1);

        dialog.setWidgetValue('selectedmeasurements_tag', []);
        dialog.setWidgetValue('selectedmeasurements_tag', rows-1);

    end
end

function selectedMeasurements = moveDownButton(dialog, selectedMeasurements)
    % Get the fields that are selected.
    values = dialog.getWidgetValue('selectedmeasurements_tag');

    % Return if none selected.
    if isempty(values)
        return;
    end

    measurements = strsplit(selectedMeasurements,';');

    % Determine the rows to swap with. 
    rows = values;
    tempRows = rows(end:-1:1);
    tempRows = tempRows + 1;
    if isempty(find(tempRows>(length(measurements)-1) , 1))
        % We can move successfully.
        measurementsToMove = cell(length(rows), 2);
        for idx = 1:length(rows)
            measurementToMove = measurements{rows(idx)+1};
            rowToMoveAfter = rows(idx)+1;
            if ~isempty(find(rows == rowToMoveAfter,1))
                rowToMoveAfter = rows(end)+1;
            end
            measurementToMoveAfter = measurements{rowToMoveAfter + 1};
            measurementsToMove{idx,1} = measurementToMove;
            measurementsToMove{idx,2} = measurementToMoveAfter;
        end
        if (length(rows)==1)
            measurements = swapMeasurements(measurements, measurementsToMove{1}, measurementsToMove{2});
        else
            num = length(measurementsToMove);
            for idx = 1:num
                measurements = swapMeasurements(measurements, measurementsToMove{num-idx+1, 1}, measurementsToMove{num-idx+1, 2});
            end
        end
        finalMeasStr = sprintf('%s;', measurements{:});
        selectedMeasurements = finalMeasStr(1:end-1);

        dialog.setWidgetValue('selectedmeasurements_tag', []);
        dialog.setWidgetValue('selectedmeasurements_tag', rows+1);
    end 
end

function measurements = swapMeasurements(measurements, p1, p2)
    id1 = find(strcmp(p1, measurements),1);
    id2 = find(strcmp(p2, measurements),1);
    tmpMeasurement = measurements{id1};
    measurements{id1} = measurements{id2};
    measurements{id2} = tmpMeasurement; 
end

function cycleStr = getEventTimeInfo(a2lObj, eventNames)
    cycleStr = cell(size(eventNames));
    for idx = 1:length(eventNames)
        eventStruct = a2lObj.getEventInfo(eventNames{idx});
        cycle = eventStruct.ChannelTimeCycle;
        units = eventStruct.ChannelTimeUnit;
        % Get unit information
        [unitStr, unitMultiple] = localGetUnitInfo(units);
        timing = cycle*unitMultiple;
        % Event times in strings.
        cycleStr{idx} = strcat(num2str(timing),unitStr);
    end
end

function events = getEventsList(a2LParserObject, eventNames, cycleStr, direction)
    a2lObj = a2LParserObject;
    events = strcat(eventNames(:), ' (', cycleStr(:), ')');
    allDirections = {};
    for idx = 1:length(eventNames)
        eventStruct = a2lObj.getEventInfo(eventNames{idx});
        allDirections = [allDirections {eventStruct.Direction}];
    end
    indices = ismember(allDirections, 'DAQ_STIM') | ismember(allDirections, direction);
    events = events(indices);
end

function [unitStr, unitMultiple] = localGetUnitInfo(unit)
    % Switch based on units. 
    switch unit
        case 0
            unitStr = 'ns';
            unitMultiple = 1;
        case 1
            unitStr = 'ns';
            unitMultiple = 10;
        case 2
            unitStr = 'ns';
            unitMultiple = 100;
        case 3
            unitStr = 'us';
            unitMultiple = 1;
        case 4
            unitStr = 'us';
            unitMultiple = 10;
        case 5
            unitStr = 'us';
            unitMultiple = 100;
        case 6
            unitStr = 'ms';
            unitMultiple = 1;
        case 7
            unitStr = 'ms';
            unitMultiple = 10;
        case 8
            unitStr = 'ms';
            unitMultiple = 100;
        case 9
            unitStr = 's';
            unitMultiple = 1;
        otherwise
    end
end
