function [device_gui,device_obj] = newIVScanSettingsAdv(parent,position,fontsize,style,log)    
    
    %# data elements of device
    device_obj = struct();
    
    current.ID = 'Advanced Scan Settings';
       
    current.activeSPP = 0 ;
        current.sppVolt = -1 ;
        current.sppDuration = 1 ;
        current.sppDelay = 0.01;
        
    current.activeSMPP = 0;
        current.smppVolt = -1;
        current.smppRatio = 1 ;
    current.activeVMPP = 0;
        current.vmppVolt = -1;
        current.vmppRatio = 1 ;
    
    current.activeTRP = 0;
        current.trpVolt1 = 0;
        current.trpTime1 = 1;
        current.trpVolt2 = 1;
        current.trpTime2 = 1;
        current.trpVolt3 = 0;
        current.trpTime3 = 1;
        current.trpTimeStep = 0.01;
        
    current.activeTRS = 0;
        current.trsStepTime = 10;
        
    current.activeCycle = 0;
        current.cycleManual = 1;
%         current.cyclegetinfo = 0;
        current.cycleMPPV = 0.4;
        current.cycleVOC = 0.9;
    
    current.activeTracking = 0;
        current.mppDelay = 0.01;
        current.mppDuration = 60;
        current.mppV = 0.6;
        current.mppManual = 1;
        current.mppMPP = 1;
		current.mppJSC = 1;
        current.mppVOC = 1;
        
    current.activePerovskite = 0;
    
    current.activeMeasurement = struct();
    activeMeasurement = struct();
    
    position = [position(1) position(2) 327 440]; %[position(1) position(2) 327 570]; +PP
        position_pp = [5 position(4)-0-20 315 0]; %[5 position(4)-130-20 315 130]; +PP
        position_trp = [5 position_pp(2)-125-5 315 125];
        position_trs = [5 position_trp(2)-70-5 315 70];
        position_cycle = [5 position_trs(2)-70-5 315 70];
        position_MPP = [5 position_cycle(2)-70-5 315 70];
        position_Perovskite = [5 position_MPP(2)-55-5 315 55];
    device_gui.Panel = gui_panel(parent,position,current.ID,fontsize.general,'ui_ScanSettings');
        %# prepuls settings
        device_gui.Prepuls = gui_panel(device_gui.Panel,position_pp,'Prepuls',fontsize.general,'ui_ScanSettings');
            %# labels prepuls parameter
            gui_txt(device_gui.Prepuls,[ 90 90 60 20], 'Volt:',fontsize.dir,'','left','');
            gui_txt(device_gui.Prepuls,[165 90 60 20], 'Duration:',fontsize.dir,'','left','');
            gui_txt(device_gui.Prepuls,[240 90 60 20], 'Delay:',fontsize.dir,'','left','');

            %# create prepuls toggelbuttons
            device_gui.tbtnSPP = gui_tbtn(device_gui.Prepuls,[5 65 80 25],'S-Prepuls',fontsize.smallbtn,'activate/deactivate single prepuls','tbtnSPP',{@onChange_tbtnMeasurement}); 
                set(device_gui.tbtnSPP,'Value',1,'BackgroundColor',style.color{11},'FontWeight','bold');
           device_gui.tbtnSMPP  = gui_tbtn(device_gui.Prepuls,[5 35 80 25],'SM-Prepuls',fontsize.smallbtn,'activate/deactivate multiple static prepuls','tbtnSMPP',{@onChange_tbtnMeasurement});
                set(device_gui.tbtnSMPP,'Value',1,'BackgroundColor',style.color{11},'FontWeight','bold');
            device_gui.tbtnVMPP = gui_tbtn(device_gui.Prepuls,[5 5 80 25],'VM-Prepuls',fontsize.smallbtn,'activate/deactivate multiple variable prepuls','tbtnVMPP',{@onChange_tbtnMeasurement});
                set(device_gui.tbtnVMPP,'Value',1,'BackgroundColor',style.color{11},'FontWeight','bold');

            %# create prepuls variables voltage
            device_gui.varsppVolt = gui_var(device_gui.Prepuls,[90  65 70 25],'Voltage for single prepuls','center',fontsize.dir,'sppVolt',{@onChange_varVolt});
                set(device_gui.varsppVolt,'ForegroundColor',style.color{11},'BackgroundColor',style.color{end},'FontWeight','bold')
            device_gui.varsmppVolt = gui_var(device_gui.Prepuls,[90  35 70 25],'Voltage for static multiple prepuls','center',fontsize.dir,'smppVolt',{@onChange_varVolt});
                set(device_gui.varsmppVolt,'ForegroundColor',style.color{11},'BackgroundColor',style.color{end},'FontWeight','bold')
            device_gui.varvmppVolt = gui_var(device_gui.Prepuls,[90  5 70 25],'Voltage for variable multiple prepuls','center',fontsize.dir,'vmppVolt',{@onChange_varVolt});
                set(device_gui.varvmppVolt,'ForegroundColor',style.color{11},'BackgroundColor',style.color{end},'FontWeight','bold')

            %# create prepuls variable delay
            device_gui.varsppDelay = gui_var(device_gui.Prepuls,[165  65 69 25],'Duration for single prepuls','center',fontsize.dir,'sppDelay',{@onChange_varTime});
                set(device_gui.varsppDelay,'ForegroundColor',style.color{11},'BackgroundColor',style.color{end},'FontWeight','bold')

            %# create prepuls variable duration
            device_gui.varsppDuration = gui_var(device_gui.Prepuls,[239  65 69 25],'Duration for single prepuls','center',fontsize.dir,'sppDuration',{@onChange_varTime});
                set(device_gui.varsppDuration,'ForegroundColor',style.color{11},'BackgroundColor',style.color{end},'FontWeight','bold')

            %# create prepuls variable ratio
            gui_txt(device_gui.Prepuls,[165 33 69 25], 'PulsRatio:',fontsize.dir,'','right','');
            gui_txt(device_gui.Prepuls,[165 3 69 25], 'PulsRatio:',fontsize.dir,'','right','');
            device_gui.dropSMPP_Ratio  = gui_drop(device_gui.Prepuls, [239 35 69 25],{'1:1','1:2','1:3'},'dropSMPP_Ratio',{@onChange_PulseRation});
            device_gui.dropVMPP_Ratio  = gui_drop(device_gui.Prepuls, [239 5 69 25],{'1:1','1:2','1:3'},'dropVMPP_Ratio',{@onChange_PulseRation});

        %# time resolved point
        device_gui.trp = gui_panel(device_gui.Panel,position_trp,'Time Resolved Point',fontsize.general,'');
            device_gui.tbtnTRP = gui_tbtn(device_gui.trp,[5 55 80 25],'TR Point',fontsize.smallbtn,'activate/deactivate time resolution measurement','tbtnTRP',{@onChange_tbtnMeasurement}); 
            	set(device_gui.tbtnTRP,'Value',1,'BackgroundColor',style.color{11},'FontWeight','bold');
        
            gui_txt(device_gui.trp,[5 30 80 20], 'Time Step:',fontsize.dir,'','left','');
            gui_txt(device_gui.trp,[90 80 80 20], 'Volt 1:',fontsize.dir,'','left','');
            gui_txt(device_gui.trp,[165 80 80 20], 'Volt 2:',fontsize.dir,'','left','');
            gui_txt(device_gui.trp,[240 80 80 20], 'Volt 3:',fontsize.dir,'','left','');
            gui_txt(device_gui.trp,[90 30 80 20], 'Time Volt 1:',fontsize.dir,'','left','');
            gui_txt(device_gui.trp,[165 30 80 20], 'Time Volt 2:',fontsize.dir,'','left','');
            gui_txt(device_gui.trp,[240 30 80 20], 'Time Volt 3:',fontsize.dir,'','left','');
            
            device_gui.vartrpTimeStep = gui_var(device_gui.trp,[5 5 80 25],'Timeresolution in s','center',fontsize.dir,'trpTimeStep',{@onChange_varTime});
                set(device_gui.vartrpTimeStep,'ForegroundColor',style.color{11},'BackgroundColor',style.color{end},'FontWeight','bold');
            device_gui.vartrpVolt1 = gui_var(device_gui.trp,[90 55 70 25],'Voltage 1','center',fontsize.dir,'trpVolt1',{@onChange_varVolt});
                set(device_gui.vartrpVolt1,'ForegroundColor',style.color{11},'BackgroundColor',style.color{end},'FontWeight','bold');
            device_gui.vartrpVolt2 = gui_var(device_gui.trp,[165 55 70 25],'Voltage 2','center',fontsize.dir,'trpVolt2',{@onChange_varVolt});
                set(device_gui.vartrpVolt2,'ForegroundColor',style.color{11},'BackgroundColor',style.color{end},'FontWeight','bold');
            device_gui.vartrpVolt3 = gui_var(device_gui.trp,[240 55 70 25],'Voltage 3','center',fontsize.dir,'trpVolt3',{@onChange_varVolt});
                set(device_gui.vartrpVolt3,'ForegroundColor',style.color{11},'BackgroundColor',style.color{end},'FontWeight','bold');
            device_gui.vartrpTime1 = gui_var(device_gui.trp,[90  5 70 25],'Hold time of voltage 1','center',fontsize.dir,'trpTime1',{@onChange_varTime});
                set(device_gui.vartrpTime1,'ForegroundColor',style.color{11},'BackgroundColor',style.color{end},'FontWeight','bold');
            device_gui.vartrpTime2 = gui_var(device_gui.trp,[165  5 70 25],'Hold time of voltage 2','center',fontsize.dir,'trpTime2',{@onChange_varTime});
                set(device_gui.vartrpTime2,'ForegroundColor',style.color{11},'BackgroundColor',style.color{end},'FontWeight','bold');
            device_gui.vartrpTime3 = gui_var(device_gui.trp,[240  5 70 25],'Hold time for voltage 3','center',fontsize.dir,'trpTime3',{@onChange_varTime});
                set(device_gui.vartrpTime3,'ForegroundColor',style.color{11},'BackgroundColor',style.color{end},'FontWeight','bold');
                
        %# time resolved sweep
        device_gui.trs = gui_panel(device_gui.Panel,position_trs,'Time Resolved Sweep',fontsize.general,'');
            device_gui.tbtnTRS = gui_tbtn(device_gui.trs,[5 5 80 25],'TR Sweep',fontsize.smallbtn,'activate/deactivate time resolved IV measurement','tbtnTRS',{@onChange_tbtnMeasurement}); 
                 set(device_gui.tbtnTRS,'Value',1,'BackgroundColor',style.color{11},'FontWeight','bold');

            gui_txt(device_gui.trs,[90 30 120 20], 'Time per Step:',fontsize.dir,'','left','');
            device_gui.vartrsStepTime = gui_var(device_gui.trs,[90  5 100 25],'measurement duration of each voltage step','center',fontsize.dir,'trsStepTime',{@onChange_varTime});
             	set(device_gui.vartrsStepTime,'ForegroundColor',style.color{11},'BackgroundColor',style.color{end},'FontWeight','bold');
        %# cycle IV sweep
        device_gui.cycle = gui_panel(device_gui.Panel,position_cycle,'Cycle IV Sweep',fontsize.general,'');
            device_gui.tbtnCycle = gui_tbtn(device_gui.cycle,[5 5 80 25],'Cycle',fontsize.smallbtn,'activate/deactivate cycle IV measurement from MPP to JSC to VOC to JSC','tbtnCycle',{@onChange_tbtnMeasurement}); 
                 set(device_gui.tbtnCycle,'Value',1,'BackgroundColor',style.color{11},'FontWeight','bold');
            device_gui.tbtnCycleManual = gui_tbtn(device_gui.cycle,[90 5 70 25],'IV',fontsize.smallbtn,'activate/deactivate manual cycle start values','tbtnCycleManual',{@onChange_tbtnMeasurement}); 
                  set(device_gui.tbtnCycleManual,'Value',0,'BackgroundColor',style.color{11},'FontWeight','bold');
                  
            gui_txt(device_gui.cycle,[165 30 70 20], 'MPP V:',fontsize.dir,'','left','');
            gui_txt(device_gui.cycle,[240 30 70 20], 'VOC:',fontsize.dir,'','left','');
                
            device_gui.varcycleMPPV = gui_var(device_gui.cycle,[165  5 70 25],'Voltage of Maximum Power Point','center',fontsize.dir,'cycleMPPV',{@onChange_varVolt});
                set(device_gui.varcycleMPPV,'ForegroundColor',style.color{11},'BackgroundColor',style.color{end},'FontWeight','bold');
            device_gui.varcycleVOC = gui_var(device_gui.cycle,[240  5 70 25],'Open Circuit Voltage','center',fontsize.dir,'cycleVOC',{@onChange_varVolt});
                set(device_gui.varcycleVOC,'ForegroundColor',style.color{11},'BackgroundColor',style.color{end},'FontWeight','bold');

%             device_gui.getsetingsfromlist = gui_tbtn(device_gui.cycle,[180 55 70 25],'Get List Info',fontsize.smallbtn,'activate/deactivate service for getting MPP and JSC Voltage from SummaryList','cyclegetinfo',{@tbtn_MeasurementSelection_CallbackIV}); 
%                   set(device_gui.getsetingsfromlist,'Value',1,'BackgroundColor',style.color{11},'FontWeight','bold');

        %# MPP Tracking
        device_gui.MPP = gui_panel(device_gui.Panel,position_MPP,'Steady State Tracking',fontsize.general,'');    
            device_gui.tbtnTracking = gui_tbtn(device_gui.MPP,[5 5 80 25],'Tracking',fontsize.smallbtn,'activate/deactivate steady state tracking','tbtnTracking',{@onChange_tbtnMeasurement}); 
            	set(device_gui.tbtnTracking,'Value',1,'BackgroundColor',style.color{11},'FontWeight','bold');
            device_gui.tbtnMPPManual = gui_tbtn(device_gui.MPP,[165 30 70 20],'IV',fontsize.smallbtn,'activate/deactivate manual MPP tracking start voltage','tbtnMPPManual',{@onChange_tbtnMeasurement}); 
            	set(device_gui.tbtnMPPManual,'Value',0,'BackgroundColor',style.color{14},'FontWeight','bold');
                
            device_gui.tbtnMPPJSC = gui_tbtn(device_gui.MPP,[240 30 32 20],'JSC',fontsize.smallbtn,'activate/deactivate JSC tracking','tbtnMPPJSC',{@onChange_tbtnMeasurement}); 
            	set(device_gui.tbtnMPPJSC,'Value',1,'BackgroundColor',style.color{11},'FontWeight','bold');
            device_gui.tbtnMPPVOC = gui_tbtn(device_gui.MPP,[277 30 32 20],'VOC',fontsize.smallbtn,'activate/deactivate VOC tracking','tbtnMPPVOC',{@onChange_tbtnMeasurement}); 
            	set(device_gui.tbtnMPPVOC,'Value',1,'BackgroundColor',style.color{11},'FontWeight','bold');
            device_gui.tbtnMPPMPP = gui_tbtn(device_gui.MPP,[240 5 70 20],'MPP',fontsize.smallbtn,'activate/deactivate MPP tracking','tbtnMPPMPP',{@onChange_tbtnMeasurement}); 
            	set(device_gui.tbtnMPPMPP,'Value',1,'BackgroundColor',style.color{11},'FontWeight','bold');
            
            gui_txt(device_gui.MPP,[90 30 70 20], 'Duration:',fontsize.dir,'','left','');
      
            device_gui.varmppDuration = gui_var(device_gui.MPP,[90  5 70 25],'Time how long MPP is tracked in seconds','center',fontsize.dir,'mppDuration',{@onChange_varTime});
                set(device_gui.varmppDuration,'ForegroundColor',style.color{11},'BackgroundColor',style.color{end},'FontWeight','bold');
            device_gui.varmppV = gui_var(device_gui.MPP,[165  5 70 25],'manual set start Voltage','center',fontsize.dir,'mppV',{@onChange_varVolt});
                set(device_gui.varmppV,'Enable','inactive','ForegroundColor',style.color{end-1},'BackgroundColor',style.color{end},'FontWeight','bold');
            
        %# Perovskite
        device_gui.Perovskite = gui_panel(device_gui.Panel,position_Perovskite,'Perovskite Measurement Protocol',fontsize.general,'');    
            device_gui.tbtnPerovskite = gui_tbtn(device_gui.Perovskite,[5 5 80 25],'Perovskite',fontsize.smallbtn,'activate/deactivate Perovskite measurement protocol','tbtnPerovskite',{@onChange_tbtnMeasurement}); 
            	set(device_gui.tbtnPerovskite,'Value',1,'BackgroundColor',style.color{11},'FontWeight','bold');
                
    %# device functions
    device_obj.reset = @reset;
    device_obj.getCurrentValues = @getCurrentValues;
    device_obj.setCurrentValues = @setCurrentValues;

    reset();
    
    function reset()
        setVolt(current.sppVolt,'sppVolt');
        setVolt(current.smppVolt,'smppVolt');
        setVolt(current.vmppVolt,'vmppVolt');
        setTime(current.sppDelay,'sppDelay');
        setTime(current.sppDuration,'sppDuration');
        
        setVolt(current.trpVolt1,'trpVolt1');
        setVolt(current.trpVolt2,'trpVolt2');
        setVolt(current.trpVolt3,'trpVolt3');
        setTime(current.trpTime1,'trpTime1');
        setTime(current.trpTime2,'trpTime2');
        setTime(current.trpTime3,'trpTime3');
        setTime(current.trpTimeStep,'trpTimeStep');
        
        setTime(current.trsStepTime,'trsStepTime');
        
        setTime(current.mppDuration,'mppDuration');
        setTime(current.mppDelay,'mppDelay');
        setVolt(current.mppV,'mppV');
        onChange_tbtnMeasurement(device_gui.tbtnMPPManual);
        onChange_tbtnMeasurement(device_gui.tbtnMPPJSC);
        onChange_tbtnMeasurement(device_gui.tbtnMPPVOC);
        
        setVolt(current.cycleMPPV,'cycleMPPV');
        setVolt(current.cycleVOC,'cycleVOC');
        onChange_tbtnMeasurement(device_gui.tbtnCycleManual);

        setActiveMeasurement(current.activeSPP,'tbtnSPP');
        setActiveMeasurement(current.activeSMPP,'tbtnSMPP');
        setActiveMeasurement(current.activeVMPP,'tbtnVMPP');
        setActiveMeasurement(current.activeTRP,'tbtnTRP');
        setActiveMeasurement(current.activeTRS,'tbtnTRS');
        setActiveMeasurement(current.activeTRS,'tbtnCycle');
        setActiveMeasurement(current.activeTracking,'tbtnTracking');
        setActiveMeasurement(current.activePerovskite,'tbtnPerovskite');
    end

    function currentValues = getCurrentValues()
        currentValues = current;
    end

    function setCurrentValues(currentValues,varargin)
        try
%             input = inputParser;
%             input.KeepUnmatched = true;        
%             addParameter(input,'activeSPP',current.activeSPP,@(x) isnumeric(x) && isscalar(x));
%             addParameter(input,'activeSMPP',current.activeSMPP,@(x) isnumeric(x) && isscalar(x));
%             addParameter(input,'activeVMPP',current.activeVMPP,@(x) isnumeric(x) && isscalar(x));
%             addParameter(input,'sppVolt',current.sppVolt,@(x) isnumeric(x) && isscalar(x));
%             addParameter(input,'smppVolt',current.smppVolt,@(x) isnumeric(x) && isscalar(x));
%             addParameter(input,'vmppVolt',current.vmppVolt,@(x) isnumeric(x) && isscalar(x));
%             addParameter(input,'sppDuration',current.sppDuration,@(x) isnumeric(x) && isscalar(x));
%             addParameter(input,'sppDelay',current.sppDelay,@(x) isnumeric(x) && isscalar(x));
%             addParameter(input,'statmultiPP_Ratio',current.statmultiPP_Ratio,@(x) isnumeric(x) && isscalar(x));
%             addParameter(input,'varmultiPP_Ratio',current.varmultiPP_Ratio,@(x) isnumeric(x) && isscalar(x));

%             addParameter(input,'activeTRP',current.activeTRP,@(x) isnumeric(x) && isscalar(x));
%             addParameter(input,'sppDuration',current.sppDuration,@(x) isnumeric(x) && isscalar(x));
%             addParameter(input,'timeVolt1',current.timeVolt1,@(x) isnumeric(x) && isscalar(x));
%             addParameter(input,'timeVolt2',current.timeVolt2,@(x) isnumeric(x) && isscalar(x));
%             addParameter(input,'time1',current.time1,@(x) isnumeric(x) && isscalar(x));
%             addParameter(input,'time2',current.time2,@(x) isnumeric(x) && isscalar(x));
%             addParameter(input,'timesteps',current.timesteps,@(x) isnumeric(x) && isscalar(x));
            
%             addParameter(input,'activeCycle',current.activeCycle,@(x) isnumeric(x) && isscalar(x));
%             addParameter(input,'activeCycleGetPoint',current.cycleposition,@(x) isnumeric(x) && isscalar(x));
%             addParameter(input,'cyclegetinfo',current.cyclegetinfo,@(x) isnumeric(x) && isscalar(x));
%             addParameter(input,'cycleVMPP',current.cycleVMPP,@(x) isnumeric(x) && isscalar(x));
%             addParameter(input,'cycleVOC',current.cycleVOC,@(x) isnumeric(x) && isscalar(x));
            
%             addParameter(input,'activeMPPtracking',current.activeMPPtracking,@(x) isnumeric(x) && isscalar(x));
%             addParameter(input,'mpptduraton',current.mpptduraton,@(x) isnumeric(x) && isscalar(x));
            
%             addParameter(input,'activeTRS',current.activeTRS,@(x) isnumeric(x) && isscalar(x));
%             addParameter(input,'trsStepTime',current.trsStepTime,@(x) isnumeric(x) && isscalar(x));
%             addParameter(input,'trsDelay',current.trsDelay,@(x) isnumeric(x) && isscalar(x));
%             parse(input,currentValues,varargin{:})

%             if isfield(input.Results,'sppVolt')
%                 setSPPVoltage(input.Results.sppVolt)
%             end
%             
%             if isfield(input.Results,'smppVolt')
%                 setSMPVoltage(input.Results.smppVolt)
%             end
%             
%             if isfield(input.Results,'vmppVolt')
%                 setVMPVoltage(input.Results.vmppVolt)
%             end

%             addParameter(input,'activeTRP',current.activeTRP,@(x) isnumeric(x) && isscalar(x));
%             addParameter(input,'sppDuration',current.sppDuration,@(x) isnumeric(x) && isscalar(x));
%             addParameter(input,'timeVolt1',current.timeVolt1,@(x) isnumeric(x) && isscalar(x));
%             addParameter(input,'timeVolt2',current.timeVolt2,@(x) isnumeric(x) && isscalar(x));
%             addParameter(input,'time1',current.time1,@(x) isnumeric(x) && isscalar(x));
%             addParameter(input,'time2',current.time2,@(x) isnumeric(x) && isscalar(x));
%             addParameter(input,'timesteps',current.timesteps,@(x) isnumeric(x) && isscalar(x));
%             addParameter(input,'activeCycle',current.activeCycle,@(x) isnumeric(x) && isscalar(x));
%             addParameter(input,'cycleposition',current.cycleposition,@(x) isnumeric(x) && isscalar(x));
%             addParameter(input,'cyclegetinfo',current.cyclegetinfo,@(x) isnumeric(x) && isscalar(x));
%             addParameter(input,'cycleVMPP',current.cycleVMPP,@(x) isnumeric(x) && isscalar(x));
%             addParameter(input,'cycleVOC',current.cycleVOC,@(x) isnumeric(x) && isscalar(x));
%             addParameter(input,'activeMPPtracking',current.activeMPPtracking,@(x) isnumeric(x) && isscalar(x));
%             addParameter(input,'mpptduraton',current.mpptduraton,@(x) isnumeric(x) && isscalar(x));
%             addParameter(input,'activeTRS',current.activeTRS,@(x) isnumeric(x) && isscalar(x));
%             addParameter(input,'trsStepTime',current.trsStepTime,@(x) isnumeric(x) && isscalar(x));
%             addParameter(input,'trsDelay',current.trsDelay,@(x) isnumeric(x) && isscalar(x));
        catch error        
            errordlg('Wrong type of input. Settings have to be given as Parameter, i.e., (''parameter_name'',value) or as struct, i.e., s.parameter_name = value.','Error');
            disp(error.message);
        end
    end

    function onChange_varVolt(hObject,varargin)
        setVolt(str2double(get(hObject,'String')),get(hObject,'Tag'));
    end

    function onChange_varTime(hObject,varargin)
        setTime(str2double(get(hObject,'String')),get(hObject,'Tag'));
    end

    function onChange_PulseRation(hObject,varargin)
        switch get(hObject,'Tag')
            case 'dropSMPP_Ratio'
                current.smppRatio = get(hObject,'Value');
            case 'dropVMPP_Ratio' 
                current.vmppRatio = get(hObject,'Value');
        end
    end

    function onChange_tbtnMeasurement(hObject,varargin)
        state = get(hObject,'Value');
        switch get(hObject,'Tag')
            case {'tbtnSPP','tbtnSMPP','tbtnVMPP','tbtnTRP','tbtnTRS','tbtnCycle','tbtnTracking','tbtnPerovskite'}
                setActiveMeasurement(get(hObject,'Value'),get(hObject,'Tag'));
            case 'tbtnCycleManual'
                current.cycleManual = state;
                hObject.String = con_a_b(state,'manual','IV');
                hObject.BackgroundColor = con_a_b(state,style.color{11},style.color{14});
                device_gui.varcycleMPPV.ForegroundColor = con_a_b(state,style.color{11},style.color{end-1});
                device_gui.varcycleMPPV.Enable = con_a_b(state,'on','inactive');
                device_gui.varcycleVOC.ForegroundColor = con_a_b(state,style.color{11},style.color{end-1});
                device_gui.varcycleVOC.Enable = con_a_b(state,'on','inactive');
            case 'tbtnMPPManual'
                current.mppManual = state;
                hObject.String = con_a_b(state,'manual','IV');
                hObject.BackgroundColor = con_a_b(state,style.color{11},style.color{14});
                device_gui.varmppV.ForegroundColor = con_a_b(state,style.color{11},style.color{end-1});
                device_gui.varmppV.Enable = con_a_b(state,'on','inactive');
            case 'tbtnMPPMPP'
                current.mppMPP = state;
                hObject.BackgroundColor = con_a_b(state,style.color{11},style.color{1});
            case 'tbtnMPPJSC'
                current.mppJSC = state;
                hObject.BackgroundColor = con_a_b(state,style.color{11},style.color{1});
            case 'tbtnMPPVOC'
                current.mppVOC = state;
                hObject.BackgroundColor = con_a_b(state,style.color{11},style.color{1});
        end
    end

    function setActiveMeasurement(state,type)
        amf = {'tbtnSPP','tbtnSMPP','tbtnVMPP','tbtnTRP','tbtnTRS','tbtnCycle','tbtnTracking','tbtnPerovskite'};
        try
            input = inputParser;
            addRequired(input,'state',@(x) isnumeric(x) && isscalar(x) && (x==1 || x==0));
            addRequired(input,'type',@(x) any(validatestring(x,amf)));
            parse(input,state,type)
            
            state = input.Results.state;
            
            if ~state
                active = regexp(type,'tbtn','split');
                active = active{2};
                
                if isfield(activeMeasurement,active)
                    activeMeasurement = rmfield(activeMeasurement,active);
                end
                current.activeMeasurement = activeMeasurement;
                
                current.(['active',active]) = state;
                device_gui.(['tbtn',active]).Value = state;
                device_gui.(type).BackgroundColor = con_a_b(state,style.color{11},style.color{1});
            else
                for n1 = 1:length(amf)
                    active = regexp(amf{n1},'tbtn','split');
                    active = active{2};
                    
                    s = strcmp(amf{n1},type);
                    if s
                        activeMeasurement.(active) = 1;
                    elseif isfield(activeMeasurement,active)
                        activeMeasurement = rmfield(activeMeasurement,active);
                    end
                    
                    current.activeMeasurement = activeMeasurement;
                    current.(['active',active]) = s;
                    device_gui.(['tbtn',active]).Value = s;
                	device_gui.(['tbtn',active]).BackgroundColor = con_a_b(s,style.color{11},style.color{1});
                end
            end
        catch error        
            errordlg('State has to be 1 (on) or 0 (off) in setToggleButton.','Error');
            disp(error.message);
        end
    end

    function setVolt(step,type)
        try
            input = inputParser;
            addRequired(input,'step',@(x) isnumeric(x) && isscalar(x) && ~isnan(x) && x>=-10 && x<=10);
            addRequired(input,'type',@(x) any(validatestring(x,{'trpVolt1','trpVolt2','trpVolt3','sppVolt','smppVolt','vmppVolt','cycleMPPV','cycleVOC','mppV'})));
            parse(input,step,type)
            
            current.(type) = step;
        catch error        
            errordlg('Voltage has to be numeric and in the range of -10 V and 10 V.','Error');
            disp(error.message);
        end
        
        device_gui.(['var',type]).String = num2str(current.(type));
    end

    function setTime(step,type)
        try
            input = inputParser;
            addRequired(input,'step',@(x) isnumeric(x) && isscalar(x) && ~isnan(x) && x>=0 && x<=3*9999);
            addRequired(input,'type',@(x) any(validatestring(x,{'trpTime1','trpTime2','trpTime3','trpTimeStep','trsStepTime','trsDelay','sppDuration','sppDelay','repDelay','mppDuration','mppDelay'})));
            parse(input,step,type)
            
            current.(type) = step;
        catch error        
            errordlg('repNumbers has to be numeric and in the range of 0 s and 9999 s.','Error');
            disp(error.message);
        end
        
        device_gui.(['var',type]).String = num2str(current.(type));
    end
end
