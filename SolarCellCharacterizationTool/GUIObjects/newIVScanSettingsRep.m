function [device_gui,device_obj] = newIVScanSettingsRep(parent,position,fontsize,style,log)    
    
    %# data elements of device
    device_obj = struct();
    
    current.ID = 'Repetition Scan Settings';
    
    current.repActive = 0;
    current.repNumber = 1;
    current.repDelay = 0;
    
    position = [position(1) position(2) 320 70];
    device_gui.Panel = gui_panel(parent,position,current.ID,fontsize.general,'ui_ScanSettings');
            device_gui.tbtnRep = gui_tbtn(device_gui.Panel,[5 5 100 25],'Repetition',fontsize.smallbtn,'activate/deactivate repetition of IV curve','tbtnRep',{@onChange_tbtnMeasurement}); 
            	set(device_gui.tbtnRep,'Value',1,'BackgroundColor',style.color{11},'FontWeight','bold');
            %# creat repeation stuff  
            gui_txt(device_gui.Panel,[110 30 80 20], 'Number:',fontsize.dir,'','left','');     
            gui_txt(device_gui.Panel,[215 30 80 20], 'Delay:',fontsize.dir,'','left','');

            device_gui.varrepNumber = gui_var(device_gui.Panel,[110  5 100 25],'Number of repetitions of IV curve','center',fontsize.dir,'repNumber',{@onChange_varrepNumber});
                set(device_gui.varrepNumber,'ForegroundColor',style.color{11},'BackgroundColor',style.color{end},'FontWeight','bold');
            device_gui.varrepDelay = gui_var(device_gui.Panel,[215 5 100 25],'Delay in seconds','center',fontsize.dir,'repDelay',{@onChange_varTime});
                set(device_gui.varrepDelay,'ForegroundColor',style.color{11},'BackgroundColor',style.color{end},'FontWeight','bold');  
                
    %# device functions
    device_obj.reset = @reset;
    device_obj.getCurrentValues = @getCurrentValues;
    device_obj.setCurrentValues = @setCurrentValues;

    reset();
    
    function reset()
        setActiveMeasurement(current.repActive)
        setrepNumber(current.repNumber);
        setTime(current.repDelay,'repDelay');
    end

    function currentValues = getCurrentValues()
        currentValues = current;
    end

    function setCurrentValues(currentValues,varargin)
        try
            input = inputParser;
            input.KeepUnmatched = true;
            addParameter(input,'repActive',current.repActive,@(x) isnumeric(x) && isscalar(x) && (x==1 || x==0));
            addParameter(input,'repNumber',current.repNumber,@(x) isnumeric(x) && isscalar(x));
            addParameter(input,'repDelay',current.repDelay,@(x) isnumeric(x) && isscalar(x));
            parse(input,currentValues,varargin{:})
            
            if isfield(input.Results,'repActive')
                setActiveMeasurement(input.Results.repActive)
            end

            if isfield(input.Results,'repNumber')
                setrepNumber(input.Results.repNumber)
            end
            
            if isfield(input.Results,'repDelay')
                setrepDelay(input.Results.repDelay)
            end
        catch error        
            errordlg('Wrong type of input. Settings have to be given as Parameter, i.e., (''parameter_name'',value) or as struct, i.e., s.parameter_name = value.','Error');
            disp(error.message);
        end
    end

    function onChange_varrepNumber(hObject,varargin)
        setrepNumber(str2double(hObject.String));
    end

    function onChange_varTime(hObject,varargin)
        setTime(str2double(hObject.String),hObject.Tag);
    end

    function onChange_tbtnMeasurement(hObject,varargin)
        setActiveMeasurement(hObject.Value);
    end

    function setActiveMeasurement(state)
        try
            input = inputParser;
            addRequired(input,'state',@(x) isnumeric(x) && isscalar(x) && (x==1 || x==0));
            parse(input,state)

            current.repActive = state;
            device_gui.tbtnRep.Value = state;
            device_gui.tbtnRep.BackgroundColor = con_a_b(state,style.color{11},style.color{1});
        catch error        
            errordlg('State has to be 1 (on) or 0 (off) in setToggleButton.','Error');
            disp(error.message);
        end
    end

    function setrepNumber(step)
        try
            input = inputParser;
            addRequired(input,'step',@(x) isnumeric(x) && isscalar(x) && ~isnan(x) && x>=0 && x<=1000);
            parse(input,step)
            
            current.repNumber = step;
        catch error        
            errordlg('Number of repetitions has to be numeric and in the range of 0 and 1000.','Error');
            disp(error.message);
        end
        
        device_gui.varrepNumber.String = num2str(current.repNumber);
    end

    function setTime(step,type)
        try
            input = inputParser;
            addRequired(input,'step',@(x) isnumeric(x) && isscalar(x) && ~isnan(x) && x>=0 && x<=3600);
            addRequired(input,'type',@(x) any(validatestring(x,{'repDelay'})));
            parse(input,step,type)
            
            current.(type) = step;
        catch error        
            errordlg('repNumbers has to be numeric and in the range of 0 s and 3600 s.','Error');
            disp(error.message);
        end
        
        device_gui.(['var',type]).String = num2str(current.(type));
    end
end
