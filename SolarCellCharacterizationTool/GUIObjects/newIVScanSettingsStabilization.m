function [device_gui,device_obj] = newIVScanSettingsStabilization(parent,position,fontsize,style,log)    
    
    %# data elements of device
    device_obj = struct();
    
    current.ID = 'Stabilization Settings';
    
    current.vsActive = 1;
    current.vsTime = 5;
    current.lsActive = 1;
    current.lsTime = 5;
    current.shutterConnected = 1;
    
    position = [position(1) position(2) 320 100];
    device_gui.Panel = gui_panel(parent,position,current.ID,fontsize.general,'ui_ScanSettings');
        gui_txt(device_gui.Panel,[215 30 80 50], 'Time:',fontsize.dir,'','left','');
        device_gui.tbtnVoltage = gui_tbtn(device_gui.Panel,[5 35 120 25],'Voltage Stabilization',fontsize.smallbtn,'activate/deactivate voltage stabilization of IV curve','tbtnVoltage',{@onChange_tbtnMeasurement}); 
            set(device_gui.tbtnVoltage,'Value',1,'BackgroundColor',style.color{11},'FontWeight','bold');
        device_gui.varvsTime = gui_var(device_gui.Panel,[215 35 100 25],'Voltage stabilization time in seconds','center',fontsize.dir,'vsTime',{@onChange_varTime});
            set(device_gui.varvsTime,'ForegroundColor',style.color{11},'BackgroundColor',style.color{end},'FontWeight','bold');
           
        device_gui.tbtnLightSoaking = gui_tbtn(device_gui.Panel,[5 5 120 25],'Light Soaking',fontsize.smallbtn,'activate/deactivate light soaking of IV curve','tbtnLightSoaking',{@onChange_tbtnMeasurement}); 
            set(device_gui.tbtnLightSoaking,'Value',1,'BackgroundColor',style.color{11},'FontWeight','bold');
        device_gui.varlsTime = gui_var(device_gui.Panel,[215 5 100 25],'Light soaking time in seconds','center',fontsize.dir,'lsTime',{@onChange_varTime});
            set(device_gui.varlsTime,'ForegroundColor',style.color{11},'BackgroundColor',style.color{end},'FontWeight','bold');  
                
    %# device functions
    device_obj.reset = @reset;
    device_obj.getCurrentValues = @getCurrentValues;
    device_obj.setCurrentValues = @setCurrentValues;

    reset();
    
    function reset()
        setActiveMeasurement(current.vsActive,'tbtnVoltage')
        setTime(current.vsTime,'vsTime');
        setActiveMeasurement(current.lsActive,'tbtnLightSoaking')
        setTime(current.lsTime,'lsTime');
    end

    function currentValues = getCurrentValues()
        currentValues = current;
    end

    function setCurrentValues(currentValues,varargin)
        try
            input = inputParser;
            input.KeepUnmatched = true;
            addParameter(input,'vsActive',current.vsActive,@(x) isnumeric(x) && isscalar(x) && (x==1 || x==0));
            addParameter(input,'vsTime',current.vsTime,@(x) isnumeric(x) && isscalar(x));
            addParameter(input,'lsActive',current.lsActive,@(x) isnumeric(x) && isscalar(x) && (x==1 || x==0));
            addParameter(input,'lsTime',current.lsTime,@(x) isnumeric(x) && isscalar(x));
            addParameter(input,'shutterConnected',1,@(x) isnumeric(x) && isscalar(x) && (x==1 || x==0) || islogical(x));
            parse(input,currentValues,varargin{:})
            
            if isfield(input.Results,'vsActive')
                setActiveMeasurement(input.Results.vsActive,'tbtnVoltage')
            end
            
            if isfield(input.Results,'vsTime')
                setTime(input.Results.vsTime,'vsTime')
            end
            
            if isfield(input.Results,'lsActive')
                setActiveMeasurement(input.Results.lsActive,'tbtnLightSoaking')
            end
            
            if isfield(input.Results,'shutterConnected') && input.Results.shutterConnected
                current.shutterConnected = 1;
                if isfield(input.Results,'lsTime')
                    setActiveMeasurement(1,'tbtnVoltage');
                    setTime(input.Results.lsTime,'lsTime');
                    device_gui.tbtnLightSoaking.Enable = 'on';
                end
            else
                current.shutterConnected = 0;
                setActiveMeasurement(0,'tbtnLightSoaking');
                setTime(0,'lsTime');
                device_gui.tbtnLightSoaking.Enable = 'inactive';
                device_gui.tbtnLightSoaking.BackgroundColor = style.color{end-1};
            end
        catch error        
            errordlg('Wrong type of input. Settings have to be given as Parameter, i.e., (''parameter_name'',value) or as struct, i.e., s.parameter_name = value.','Error');
            disp(error.message);
        end
    end

    function onChange_varTime(hObject,varargin)
        setTime(str2double(hObject.String),hObject.Tag);
    end

    function onChange_tbtnMeasurement(hObject,varargin)
        setActiveMeasurement(hObject.Value,hObject.Tag);
    end

    function setActiveMeasurement(state,type)
        try
            input = inputParser;
            addRequired(input,'state',@(x) isnumeric(x) && isscalar(x) && (x==1 || x==0));
            addRequired(input,'type',@(x) any(validatestring(x,{'tbtnVoltage','tbtnLightSoaking'})));
            parse(input,state,type)

            switch input.Results.type
                case 'tbtnLightSoaking'
                    current.lsActive = state;
                    device_gui.tbtnLightSoaking.Value = state;
                    device_gui.tbtnLightSoaking.BackgroundColor = con_a_b(state,style.color{11},style.color{1});
                case 'tbtnVoltage'
                    current.vsActive = state;
                    device_gui.tbtnVoltage.Value = state;
                    device_gui.tbtnVoltage.BackgroundColor = con_a_b(state,style.color{11},style.color{1});
            end
        catch error        
            errordlg('State has to be 1 (on) or 0 (off) in setToggleButton.','Error');
            disp(error.message);
        end
    end

    function setTime(step,type)
        try
            input = inputParser;
            addRequired(input,'step',@(x) isnumeric(x) && isscalar(x) && ~isnan(x) && x>=0 && x<=3600);
            addRequired(input,'type',@(x) any(validatestring(x,{'lsTime','vsTime'})));
            parse(input,step,type)
            
            current.(type) = step;
        catch error        
            errordlg('lsTime has to be numeric and in the range of 0 s and 3600 s.','Error');
            disp(error.message);
        end
        
        device_gui.(['var',type]).String = num2str(current.(type));
    end
end
