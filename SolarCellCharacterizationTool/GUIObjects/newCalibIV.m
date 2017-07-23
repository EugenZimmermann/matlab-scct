function [guiObj,newObj] = newCalibIV(parent,position,fontsize,style,log) 
%NEWCALIBSTATUS Summary of this function goes here
%   Detailed explanation goes here
    
    %# data elements
    newObj = struct();
        
    %# default values
    newObj.defaultS.chkManual = 0;
    newObj.defaultS.varManual = 0;
    newObj.defaultS.Averages = 50;
    newObj.defaultS.activeArea = 0.125;
    newObj.defaultS.active = 1;
    newObj.defaultS.done = 0;
    newObj.defaultS.devices_ready = 0;
	
    newObj.defaultS.CVCurrent = 0;
    newObj.defaultS.CVLampPower = 0;
    newObj.defaultS.CVMeanLampPower = 0;
    
    %# values that can change during the run
    active = '';
    activeArea = '';
    done = '';
    last_calibration = struct();
        
    %# gui elements of device
    position = [position(1) position(2) 405 245];
    guiObj.MainPanel = gui_panel(parent,position,'IV Calibration',fontsize.general,'uiCalibIV');
        guiObj.tbtnIV = gui_tbtn(guiObj.MainPanel,[5 175 65 40],'IV',fontsize.bigtext,'activate/deactivate calibration of IV','tbtnCalibIV',{@toggleIV});
            set(guiObj.tbtnIV,'Value',1,'BackgroundColor',style.color{11},'FontWeight','bold');
        guiObj.varIV = gui_var(guiObj.MainPanel,[75 175 125 40],'status of IV calibration','center',fontsize.bigtext,'varStatusCalibrationIV','');
            set(guiObj.varIV,'Enable','inactive','ForegroundColor',style.color{1},'BackgroundColor',style.color{end});
            
        %# amount of data points for mean value
        gui_txt(guiObj.MainPanel,[ 5 140 130 20], '# averages:',fontsize.dir,'','left','');
        guiObj.varAverages = gui_var(guiObj.MainPanel,[ 95 140 105 25],'number of data points for mean value','center',fontsize.dir,'varMeanCalib',{@varAverages});
            set(guiObj.varAverages,'ForegroundColor',style.color{11},'BackgroundColor',style.color{end},'FontWeight','bold');

        %# manual calibration
        guiObj.ManualPanel = gui_panel(guiObj.MainPanel,[5 40 195 50],'manual calibration',fontsize.general,'uiManualPanel');
            guiObj.chkManual = gui_chk(guiObj.ManualPanel,[ 8 5  25 25],'','','chkManualCalib',{@chkManualCalib});
            guiObj.varManual = gui_var(guiObj.ManualPanel,[ 35 5 155 25],'manual calibration','center',fontsize.dir,'varManualCalib',{@varManualCalib});
                set(guiObj.varManual,'ForegroundColor',style.color{11},'BackgroundColor',style.color{end},'FontWeight','bold');
        
        %# start calibration button
        guiObj.start = gui_btn(guiObj.MainPanel,[5 5 195 30],'Calibrate IV',fontsize.btn,'Start calibration','btnCalibStart',{@onCalibrate});

        %# current values panel
        guiObj.CVCurrentPanel = gui_panel(guiObj.MainPanel,[205 155 195 70],'Current',fontsize.general,'uiCVCurrent');
            guiObj.varCVCurrent = gui_var(guiObj.CVCurrentPanel,[5 5 95 40],'current current in mA','right',fontsize.bigtext,'var_CVcurrent','');
                gui_txt(guiObj.CVCurrentPanel, [102 5  40  30], 'mA',16,'','left','');
                set(guiObj.varCVCurrent,'Enable','inactive','ForegroundColor',style.color{11},'BackgroundColor',style.color{end},'FontWeight','bold');
        guiObj.CVLampPowerPanel = gui_panel(guiObj.MainPanel,[205 80 195 70],'Lamp Power',fontsize.general,'ui_CVLampPower');
            guiObj.varCVLampPower = gui_var(guiObj.CVLampPowerPanel,[5 5 95 40],'current lamp power in mW/cm²','right',fontsize.bigtext,'var_CVLampPower','');
                gui_txt(guiObj.CVLampPowerPanel, [102 5  100  30], 'mW/cm²',16,'','left','');
                set(guiObj.varCVLampPower,'Enable','inactive','ForegroundColor',style.color{11},'BackgroundColor',style.color{end},'FontWeight','bold');
        guiObj.CVMeanLampPowerPanel = gui_panel(guiObj.MainPanel,[205 5 195 70],'Mean Lamp Power',fontsize.general,'ui_CVMeanLampPower');
            guiObj.varCVMeanLampPower = gui_var(guiObj.CVMeanLampPowerPanel,[5 5 95 40],'mean lamp power in mW/cm²','right',fontsize.bigtext,'var_CVMeanLampPower','');
                gui_txt(guiObj.CVMeanLampPowerPanel, [102 5  100  30], 'mW/cm²',16,'','left','');
                set(guiObj.varCVMeanLampPower,'Enable','inactive','ForegroundColor',style.color{11},'BackgroundColor',style.color{end},'FontWeight','bold');

    %# device functions
    newObj.reset = @reset;
    newObj.getSettings = @getSettings;
    newObj.getCalibration = @getCalibration;

    function reset()
        active = newObj.defaultS.active;
        done = newObj.defaultS.done;
        last_calibration = getSettings();
        activeArea = newObj.defaultS.activeArea;
        
        toggleIV();
        chkManualCalib();
        updateStatus();
        
        guiObj.varManual.String = num2str(newObj.defaultS.varManual);
        guiObj.varAverages.String = num2str(newObj.defaultS.Averages);
        
        setStatus(newObj.defaultS.CVCurrent,newObj.defaultS.CVLampPower,newObj.defaultS.CVMeanLampPower);
    end

    function settings = getSettings()
        settings.active = active;
        settings.done = done;
        settings.activeArea = activeArea;
        
        settings.chkManual = guiObj.chkManual.Value;
        settings.varManual = str2double(guiObj.varManual.String);
        settings.Averages = str2double(guiObj.varAverages.String);
        
        settings.status = getStatus();
    end

    function setCalibration()
        last_calibration = getSettings();
    end

    function cal = getCalibration()
        cal = last_calibration;
    end

    function updateStatus()
        guiObj.varIV.String = con_a_b(done,'done','not done');
        guiObj.varIV.ForegroundColor = con_a_b(done,style.color{11},style.color{2});
    end

    function status = getStatus()
        status.CVCurrent = str2double(guiObj.varCVCurrent.String);
        status.CVLampPower = str2double(guiObj.varCVLampPower.String);
        status.CVMeanLampPower = str2double(guiObj.varCVMeanLampPower.String);
    end

    function setStatus(varCVCurrent,varCVLampPower,varCVMeanLampPower)
        input = inputParser;
        addRequired(input,'varCVCurrent',@(x) isnumeric(x) && isscalar(x));
        addRequired(input,'varCVLampPower',@(x) isnumeric(x) && isscalar(x));
        addRequired(input,'varCVMeanLampPower',@(x) isnumeric(x) && isscalar(x));
        parse(input,varCVCurrent,varCVLampPower,varCVMeanLampPower);
        
        good_calib_condition = abs(input.Results.varCVMeanLampPower-100)<0.5;
        
        guiObj.varCVCurrent.String = num2str(input.Results.varCVCurrent,'%05.3f');
            guiObj.varCVCurrent.ForegroundColor = con_a_b(good_calib_condition,style.color{11},style.color{13});
 
        guiObj.varCVLampPower.String = num2str(input.Results.varCVLampPower,'%06.2f');
            guiObj.varCVLampPower.ForegroundColor = con_a_b(good_calib_condition,style.color{11},style.color{13});
            
        guiObj.varCVMeanLampPower.String = num2str(input.Results.varCVMeanLampPower,'%06.2f');
            guiObj.varCVMeanLampPower.ForegroundColor = con_a_b(good_calib_condition,style.color{11},style.color{13});
    end

    function chkManualCalib(varargin)
        isChecked = guiObj.chkManual.Value;
        guiObj.varManual.Enable = con_on_off(isChecked);
    end

    function varManualCalib(hObject,~,~)
        [result,status] = check_value(get(hObject,'String'),0,1000);
        hObject.String = con_a_b(status,num2str(result),newObj.defaultS.varManual);
    end

    function varAverages(hObject,~,~,varargin)
        [result,status] = check_value(get(hObject,'String'),1,500);
        hObject.String = con_a_b(status,num2str(result),newObj.defaultS.Averages);
    end

    function toggleIV(varargin)
        active = guiObj.tbtnIV.Value;
        guiObj.start.Enable = con_on_off(active);
        guiObj.tbtnIV.BackgroundColor = con_a_b(active,style.color{11},style.color{1});
    end

    function onCalibrate(varargin)
        guiObj.start.Enable = con_on_off(0);
        [calib,err] = calibrate_IV(getSettings(),log);
        if ~err
            done = 1;
            setStatus(calib.Current, calib.LampPower, calib.MeanLampPower);
            activeArea = calib.activeArea;
            setCalibration();
            updateStatus();
        end
        guiObj.start.Enable = con_on_off(1);
    end
end

