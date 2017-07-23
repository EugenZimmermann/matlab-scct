function [guiObj,newObj,deviceObj] = newPreferences(parent,fontsize,style,log,varargin)    
    input = inputParser;
    addRequired(input,'parent');
    addRequired(input,'fontsize',@(x) isstruct(x) && isfield(x,'general'));
    addRequired(input,'style',@(x) isstruct(x) && isfield(x,'color'));
    addRequired(input,'log');
    addParameter(input,'name','',@(x) ischar(x));
    addParameter(input,'position',[0 0 432 400],@(x) isnumerc(x) && min(x)>0 && max(x)<1920 && length(x)<=4 && min(size(x))==1);
    parse(input,parent,fontsize,style,log,varargin{:});
    
    parent = input.Results.parent;
    fontsize = input.Results.fontsize;
    style = input.Results.style;
    log = input.Results.log;
    name = input.Results.name;
    position = input.Results.position;
        x_shift = 215; % default width of panels
        
    guiObj.menu = uimenu(ancestor(parent,'figure','toplevel'),'Label','Preference','ForegroundColor',style.color{end},'Callback',@onOpen);
    
    guiObj = struct();     
    guiObj.main = figure('Units','pixel','NumberTitle','off','MenuBar','none',...
                      'Name',[name,' Preferences'],'DockControls','off',...
                      'Position',position,'Resize','off', 'Tag','gui_main','Visible','off','CloseRequestFcn',@onClose);
    	movegui(guiObj.main,'center');
        
    disp(['#5.1 GUI: ', num2str(toc)])
    
    %# check if Intrument Control Toolbox is installed, otherwise use FileExchange function or just a list of possible COM ports
    hasICT = license('test', 'instr_control_toolbox');
    if hasICT
        HardwareInfo = instrhwinfo('serial');
        SerialPorts = HardwareInfo.SerialPorts;
    else
        if exist('getAvailableComPort','file')
            SerialPorts = getAvailableComPort();
        else
            helpdlg('Could not scan for accessable serial ports. Please check for Instrument Control Toolbox, CommonFileEx/GetAvailableComPort, or select manually.')
            sNumbers = num2cell(1:20);
            SerialPorts = cellfun(@(s) ['COM',num2str(s)],sNumbers,'UniformOutput',false);
        end
    end
    disp(['#5.2 SerialPorts: ', num2str(toc)])
    
    %# measurement settings
    [newObj.general,guiObj.general] = newPrefGeneral(guiObj.main,'fontsize',fontsize,'style',style,'log',log,'position',[5 position(4)-305]);
    disp(['#5.3 General: ', num2str(toc)])
    [guiObj.IV,newObj.IV] = newPrefIV(guiObj.main,[5+x_shift position(4)-165],fontsize,style,log);
    disp(['#5.4 IV: ', num2str(toc)])

    %# device settings
    [deviceObj.Keithley,deviceObj.KeithleySettings,guiObj.Keithley] = guiKeithley(guiObj.main,'fontsize',fontsize,'style',style,'position',[5+x_shift position(4)-150-175],'log',log,'SerialPorts',SerialPorts);
    disp(['#5.10 Keithley: ', num2str(toc)])

    %# record
    newObj.record = newRecord(log);
    disp(['#5.100 Record: ', num2str(toc)])
    
    function onOpen(varargin)
        guiObj.main.Visible = 'on';
		figure(guiObj.main);
    end

    function onClose(varargin)
        guiObj.main.Visible = 'off';
    end
end