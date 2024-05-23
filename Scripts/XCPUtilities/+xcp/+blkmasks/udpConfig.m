classdef udpConfig < xcp.blkmasks.configBase
    %XCP.BLKMASKS.UDPCONFIG - DDG based class to handle the block mask for
    %the UDP Configuration block.  An object of this class is instantiated through the open callback
    %of the block

%   Copyright 2018 The MathWorks, Inc.

    properties
        HeaderErrDet = true;
		CTRScheme = '';
		LocalAddress = '';
		LocalPort = 0;
    end
    
    %% Constructor Block
    methods (Access = private)
        function obj = udpConfig(block)
            obj@xcp.blkmasks.configBase(block);
            
            obj.HeaderErrDet = xcp.blkmasks.utils.onOff2Logical(get_param(block,'HeaderErrDet'));
			obj.CTRScheme = get_param(block,'CTRScheme');
			obj.LocalAddress = get_param(block,'LocalAddress');
			obj.LocalPort = get_param(block,'LocalPort');
            
            obj.DialogHandle = DAStudio.Dialog(obj);
            installCloseListener(obj); 
        end
    end
    
    %% DDG Dialog Schema
    methods
        function dlgstruct = getDialogSchema(obj)
            dlgstruct = getDialogSchema@xcp.blkmasks.configBase(obj);
            
            %Add UDP XCP Configuration specific fields
            doc.Name           = sprintf('Configures the XCP slave for UDP using the specified ASAP2 Database (A2L) file');
            doc.Type           = 'text';
            doc.RowSpan        = [1 10];
            doc.ColSpan        = [1 1];
            
            HeaderPanel.Type='group';
            HeaderPanel.Name='XCP UDP Configuration';
            HeaderPanel.Items={doc};

            disablectr.Type = 'checkbox';
            disablectr.Name = 'Disable CTR error detection';
            disablectr.Tag = 'disablectr_tag';
            disablectr.RowSpan = [6 6];
            disablectr.ColSpan = [1 16];
            disablectr.MatlabArgs = {obj,'%value'};
            disablectr.MatlabMethod = 'setHeaderErrDet';
            disablectr.Value = obj.HeaderErrDet;
            disablectr.DialogRefresh = true;
			
			ctrschem.Name           = '     Error detection scheme: ';
            ctrschem.Type           = 'combobox';
			ctrschem.Tag            = 'ctrschem_tag';
            ctrschem.MatlabArgs     = {obj,'%dialog', '%tag'};
            ctrschem.MatlabMethod   = 'setCTRScheme';
            ctrschem.Entries        = {'One counter for all CTOs and DTOs',...
									   'Separate counters for (RES,ERR,EV,SERV) and (DAQ)',...
									   'Separate counters for (RES,ERR), (EV,SERV) and (DAQ)'};
            ctrschem.Value = obj.CTRScheme;
            ctrschem.DialogRefresh = 1;
            ctrschem.RowSpan        = [7 7];
            ctrschem.ColSpan        = [1 16];
			ctrschem.Visible		= ~obj.HeaderErrDet;
            
            advancedpanel.Name = 'Advanced';
            advancedpanel.Type = 'togglepanel';
            advancedpanel.RowSpan = [9 10];
            advancedpanel.ColSpan = [1 16];
            advancedpanel.LayoutGrid = [2 1];
            
			localaddress.Type = 'edit';
			localaddress.Name = 'Local IP Address:  ';
            localaddress.Tag = 'localaddress_tag';
			localaddress.RowSpan = [1 1];
			localaddress.ColSpan = [1 1];
			localaddress.Value = obj.LocalAddress;
            localaddress.MatlabArgs = {obj, '%value'};
            localaddress.MatlabMethod = 'setLocalAddress';
			
			localport.Type = 'edit';
			localport.Name = 'Local Port:            ';
            localport.Tag = 'localport_tag';
			localport.RowSpan = [2 2];
			localport.ColSpan = [1 1];
			localport.Value = obj.LocalPort;
            localport.MatlabArgs = {obj, '%value'};
            localport.MatlabMethod = 'setLocalPort';
            
            advancedpanel.Items = {localaddress, localport};
            
            %Rearrange/Update the dlgstruct:
            ParametersPanel = dlgstruct.Items{1};
            sampletime = ParametersPanel.Items{end};
            ParametersPanel.Items = [ParametersPanel.Items(1:end-1), disablectr, ctrschem, sampletime, advancedpanel];
            
            dlgstruct.Items = {HeaderPanel, ParametersPanel};
            dlgstruct.HelpMethod = 'xcp.blkmasks.utils.help';
            dlgstruct.HelpArgs =  {'xcp_udp_config'};
        end
    end
    
    %% Set Methods/Callbacks
    methods
        function PreApplyMethod(obj)
            if (strcmp(get_param(bdroot(obj.BlockName),'BlockDiagramType'),'library'))
                return; %Don't do anything
            end
            PreApplyMethod@xcp.blkmasks.configBase(obj);
            %Save XCP UDP Configuration specific properties
            set_param(obj.BlockHandle,'HeaderErrDet', xcp.blkmasks.utils.logical2OnOff(obj.HeaderErrDet),...
									  'CTRScheme', obj.CTRScheme,...
                                      'LocalAddress', obj.LocalAddress, ...
                                      'LocalPort', obj.LocalPort);
            
        end
        
        function setLocalAddress(obj,value)
            obj.LocalAddress = value;
        end
        
        function setLocalPort(obj,value)
            obj.LocalPort = value;
        end
        
		function setHeaderErrDet(obj,value)
			obj.HeaderErrDet = value;
		end
		
		function setCTRScheme(obj,dialog, tag)
			obj.CTRScheme = dialog.getComboBoxText(tag);
        end
 
    end
    
    
    %% Static Methods
    methods (Static = true)
        function openDialog(block)
            myBlkHandle = get_param(block, 'handle');
            dlgs = DAStudio.ToolRoot.getOpenDialogs;
            for i = 1 : numel(dlgs)
               dlg = dlgs(i);
               if ~isa(dlg.getSource, 'xcp.blkmasks.udpConfig')
                   continue
               end
               if dlg.getSource.BlockHandle == myBlkHandle
                   % If we got here, we have a match.
                   dlg.show();
                   return
               end
            end
            xcp.blkmasks.udpConfig(block);
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
        
        function [port, address] = finalizePortAndAddress(port, address)
            if strcmpi(address, 'auto')
                address = '0.0.0.0';
            end
            address = xcp.ipaddr(address);

            if strcmpi(port, 'auto')
                port = 0;
            else
                port = str2double(port);
            end
        end
        
        function structToReturn = getWidgetTags()
            structToReturn = getWidgetTags@xcp.blkmasks.configBase();
            structToReturn.DisableCTR = 'disablectr_tag';
            structToReturn.CTRScheme = 'ctrschem_tag';
            structToReturn.LocalAddress = 'localaddress_tag';
            structToReturn.LocalPort = 'localport_tag';
        end

	end
    
    
end

