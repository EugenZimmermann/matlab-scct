function MainSCCT()

%# clear all, disconnect all devices, and close all windows
clc
% profile on % uncomment to activate profiling for tracking performance issues
tic
%# close all windows, clear command list and all variables
temp_devices = instrfind;
if ~isempty(temp_devices)
    fclose(temp_devices(:));
    delete(temp_devices(:));
end
close all hidden;
close all force;
disp(['#1 Delete Devices: ', num2str(toc)])

set(0,'RecursionLimit',1000)

%# check if GUI Layout Toolbox is installed!
% if ~exist('uix.VBox','class')
%     wd = warndlg('Please install GUI Layout Toolbox from http://de.mathworks.com/matlabcentral/fileexchange/47982-gui-layout-toolbox');
%     ch = allchild(wd);
%     ch(3).Children.ButtonDownFcn = sprintf('web(''%s'');','http://de.mathworks.com/matlabcentral/fileexchange/47982-gui-layout-toolbox');
% end

%# add some folders with further m-fiels
% current folder with all subfolders
addpath(genpath('.'))

% folders with shared components
% addpath('..\Common')
% addpath(genpath('..\CommonGUI'))
% addpath(genpath('..\CommonObject\'))
% addpath(genpath('..\CommonImpExp\'))
% 
% % device folders
% addpath(genpath('..\CommonDevice\Keithley'))

%# start creating GUI
global gui
gui = initializeGUI();

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%# declare settings, calibration and measurement variables as global and create empty struct 
global data
data = struct();
    %# needed constants
    data.constants = initializeConstants();
    
    %# min required devices
    data.min_devicesIV.Keithley = 1;
%     data.min_devicesIV.Relaisbox = 1;             % for multiple cells on substrate
%     data.min_devicesIV.Shutter = 1;               % for automatic light on/off
%     data.min_devicesIV.TemperatureControler = 1;  % for temperature dependent measurements
    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%# set devices to global and create empty struct
global device
device = struct();

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%# other default values

%# settings for "Log"
log_filename = 'SCCT_log';
log_style = 'Tab';

%# settings for "About" Screen
about_name = 'Solar Cell Characterization Tool';
about_text = [{'Solar Cell'};{'Characterization Tool'};{'written by'};{'Eugen Zimmermann'};{''};{'University of Konstanz'};{[char(169),' 2015']}];


disp(['#2 Set Default Values: ', num2str(toc)])

%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#
%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%# create GUI %#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#
%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%        Generate figure and elements        %%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
gui.main = figure('Units','pixels','NumberTitle','off','MenuBar','none',...
                  'Name','Solar Cell Characterization Software','DockControls','off',...
                  'Position',[0 0 1280 730],'Resize','off','Tag','gui_main',...
                  'Visible','off');           
    movegui(gui.main,'center');

%%%%%%%%%%%%%%%%%%%%%#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% menu bar
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%# menupoint workspace
gui.filemenu.workspace = uimenu(gui.main,'Label','Workspace');
    gui.filemenu.reset = uimenu(gui.filemenu.workspace,'Label','Reset','Callback',@btn_reset_Callback,'Accelerator','R');
    gui.filemenu.quit = uimenu(gui.filemenu.workspace,'Label','Quit','Callback',@btn_quit_Callback,'ForegroundColor','red','Separator','on','Accelerator','Q');

%# menupoint connection
gui.filemenu.connection = uimenu(gui.main,'Label','Connection');
    gui.filemenu.connect = uimenu(gui.filemenu.connection,'Label','Connect all','Callback',@btn_connect_Callback,'ForegroundColor','red','Accelerator','C'); 
    gui.filemenu.disconnect = uimenu(gui.filemenu.connection,'Label','Disconnect all','Callback',@btn_disconnect_Callback,'ForegroundColor','red','Accelerator','D'); 
    
disp(['#3 Filemenu: ', num2str(toc)])

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% each Tab is in its corresponding function
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
gui.TabGroup = uitabgroup('Parent',gui.main,'Units','normalized','Position', [0 0 1 1],'Tag','TabGroup');
    %# Tab for all logs and errors
    [gui.Tab.Log,gui.obj.log] = objLog(gui.TabGroup,gui.fontsize,gui.style,'name',log_filename,'gui_style',log_style);
        disp(['#4 Log: ', num2str(toc)])
        
    %# Preferences & Device Control Tab
    [gui.Tab.Preferences,gui.obj.prefs,device] = newPreferences(gui.TabGroup,gui.fontsize,gui.style,gui.obj.log,'name',about_name);
        disp(['#5 Tab Preferences: ', num2str(toc)])
 
    %# Advanved IV measurement Tab
    [gui.Tab.IV,gui.obj.IV] = newIVTab(gui.TabGroup,gui.fontsize,gui.style,gui.obj.log);
    
    % IV calibration panel
    [gui.Tab.Calibration.IV,gui.obj.calibration.IV] = newCalibIV(gui.Tab.IV.main,[860 5],gui.fontsize,gui.style,gui.obj.log);
        disp(['#6 Tab IV: ', num2str(toc)]) 
        
    %# About Window
    gui.Tab.About = objAbout(gui.TabGroup,gui.fontsize,gui.style,'name',about_name,'text',about_text,'position',225);
        disp(['#7 About: ', num2str(toc)])
        
    %# Summary
    [gui.Tab.Summary,gui.obj.summary] = newSummary(gui.TabGroup,gui.fontsize,gui.style,'guiStyle','Tab','types',{'lightIV','darkIV','advIV','MPP','TRP','TRS'},'pixels',3);

    %# select calibration tab as default
    gui.TabGroup.SelectedTab = gui.Tab.IV.main;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Final Settings
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%# call reset function to assign all preferences and settings to gui
btn_reset_Callback();

%# make the GUI visible
gui.main.Visible = 'on';

disp(['#9 GUI Visible: ', num2str(toc)])

%# assign major structs to global workspace for error analysis
assignin('base', 'gui', gui)
assignin('base', 'data', data)
assignin('base', 'device', device)

disp(['#10 Variables assigned: ', num2str(toc)])

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Button Callback Functions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%# BUTTON to reset all values to predefined default values
    function btn_reset_Callback(~,~,~)
        %# reset device objects to default values
        fn = fieldnames(device);
        for n1 = 1:length(fn)
            device.(fn{n1}).reset();
        end
        PrefKeithley = device.KeithleySettings.getSettings();

        %# reset calibration objects to default values
        fn = fieldnames(gui.obj.calibration);
        for n1 = 1:length(fn)
            gui.obj.calibration.(fn{n1}).reset();
        end

        %# reset preference objects to default values
        fn = fieldnames(gui.obj.prefs);
        for n1 = 1:length(fn)
            gui.obj.prefs.(fn{n1}).reset();
        end
        PrefGeneral = gui.obj.prefs.general.getSettings();
        PrefIV =  gui.obj.prefs.IV.getSettings();

        gui.obj.IV.Plot.reset();
    %     gui.obj.IV.Selection.reset();
        gui.obj.IV.ScanSettingsMain.reset();
            gui.obj.IV.ScanSettingsMain.setCurrentValues(PrefGeneral);
            gui.obj.IV.ScanSettingsMain.setCurrentValues(PrefIV);
            gui.obj.IV.ScanSettingsMain.setCurrentValues(PrefKeithley);
        gui.obj.IV.ScanSettingsRep.reset();
        gui.obj.IV.ScanSettingsStabilization.reset();
            gui.obj.IV.ScanSettingsStabilization.setCurrentValues(PrefGeneral);
            gui.obj.IV.ScanSettingsStabilization.setCurrentValues('shutterConnected',isfield(device,'Shutter'));
        gui.obj.IV.ScanSettingsAdv.reset();
        gui.obj.IV.Control.reset();
            gui.obj.IV.Control.toggleControlState('idle');

        gui.obj.summary.reset();

        %# check if save directory exists, otherwise create it
        save_dir = [gui.obj.prefs.general.getDir(),'Logs\'];
        if ~exist(save_dir,'dir')
            mkdir(save_dir);
        end

        gui.obj.log.setDir(save_dir);
        gui.obj.log.update('done loading GUI');
        disp(['#8 reset ', num2str(toc)])
    end

    function btn_connect_Callback(varargin)
        try
            state = 1;

            a = fieldnames(device);
            for n1 = 1:length(a)
                device.(a{n1}).connect(state);
            end
        catch error
            disp('Error in IVSetup\btn_connect_Callback');
            disp(error.identifier)
            disp(error.message)
        end
    end
    
    function btn_disconnect_Callback(varargin)
        try
            state = 0;

            a = fieldnames(device);
            for n1 = 1:length(a)
                device.(a{n1}).connect(state);
            end
        catch error
            disp('Error in IVSetup\btn_disconnect_Callback');
            disp(error.identifier)
            disp(error.message)
        end
    end

    function btn_quit_Callback(varargin)
        try
            btn_disconnect_Callback();
        catch error
            disp('Error in IVSetup\btn_quit_Callback');
            disp(error.identifier)
            disp(error.message)
        end
        close;
    end
end