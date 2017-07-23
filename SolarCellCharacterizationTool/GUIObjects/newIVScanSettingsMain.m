function [device_gui,device_obj] = newIVScanSettingsMain(parent,position,fontsize,style,log)    
    
    %# data elements of device
    device_obj = struct();
    
    current.ID = 'Main Scan Settings';
    
    current.minV = -0.5;
    current.maxV = 1;
    current.stepsizeV = 0.01;
    current.Spacing = 'LIN';
    current.delayTimeV = 0.01;
    current.IntegrationRateV = 1;
    
    current.activeDirectionF = 1;
    current.activeDirectionB = 0;
    current.activeLightIV = 1;
    current.activeDarkIV = 1;
    current.activeGeometry = 1;
    current.activeIllumination = 1;
    
    position = [position(1) position(2) 320 105];
    device_gui.Panel = gui_panel(parent,position,current.ID,fontsize.general,'ui_ScanSettings');
        device_gui.Illumination = gui_tbtn(device_gui.Panel,[5 55 65 25],'front',fontsize.smallbtn,'toggle illumination direction (front=glass, back=electrode)','tbtnIllumination',{@onChange_tbtnMeasurement});
            set(device_gui.Illumination,'Value',1,'BackgroundColor',style.color{11},'FontWeight','bold');
        device_gui.Geometry = gui_tbtn(device_gui.Panel,[75 55 65 25],'inverted',fontsize.smallbtn,'toggle measurement direction (inverted or regular)','tbtnGeometry',{@onChange_tbtnMeasurement});
            set(device_gui.Geometry,'Value',1,'BackgroundColor',style.color{11},'FontWeight','bold');   
        device_gui.DarkIV = gui_tbtn(device_gui.Panel,[145 55 65 25],'IV (dark)',fontsize.smallbtn,'activate/deactivate IV dark measurement','tbtnDarkIV',{@onChange_tbtnMeasurement});
            set(device_gui.DarkIV,'Value',1,'BackgroundColor',style.color{11},'FontWeight','bold');    
        device_gui.LightIV  = gui_tbtn(device_gui.Panel,[215 55 65 25],'IV (light)',fontsize.smallbtn,'activate/deactivate IV light measurement','tbtnLightIV',{@onChange_tbtnMeasurement});
            set(device_gui.LightIV,'Value',1,'BackgroundColor',style.color{11},'FontWeight','bold');
        device_gui.DirectionB = gui_tbtn(device_gui.Panel,[284 55 14 25],'<',fontsize.smallbtn,'activate/deactivate backward scan of IV light measurement','tbtnDirectionB',{@onChange_tbtnDirection});
            set(device_gui.DirectionB,'Value',1,'BackgroundColor',style.color{11},'FontWeight','bold');    
        device_gui.DirectionF = gui_tbtn(device_gui.Panel,[301 55 14 25],'>',fontsize.smallbtn,'activate/deactivate forward scan of IV light measurement','tbtnDirectionF',{@onChange_tbtnDirection});
            set(device_gui.DirectionF,'Value',1,'BackgroundColor',style.color{11},'FontWeight','bold');
                
        %# labels default parameter
        gui_txt(device_gui.Panel,[5 30 37 20], 'start:',fontsize.dir,'','left','');
        gui_txt(device_gui.Panel,[83 30 37 20], 'end:',fontsize.dir,'','left','');
        gui_txt(device_gui.Panel,[161 30 37 20], 'step:',fontsize.dir,'','left','');
        gui_txt(device_gui.Panel,[239 30 37 20], 'delay:',fontsize.dir,'','left','');

        %# variables default parameter
        device_gui.varMinV = gui_var(device_gui.Panel,[5 5 70 25],'start voltage for IV','center',fontsize.dir,'varMinV',{@onChange_varRangeV});
            set(device_gui.varMinV,'ForegroundColor',style.color{11},'BackgroundColor',style.color{end},'FontWeight','bold');
        device_gui.varMaxV = gui_var(device_gui.Panel,[80 5 70 25],'end voltage for IV','center',fontsize.dir,'varMaxV',{@onChange_varRangeV});
            set(device_gui.varMaxV,'ForegroundColor',style.color{11},'BackgroundColor',style.color{end},'FontWeight','bold');
        device_gui.varStepsizeV = gui_var(device_gui.Panel,[155  5 77.5 25],'voltage stepsize for IV','center',fontsize.dir,'StepsizeV',{@onChange_varStepsizeV});
            set(device_gui.varStepsizeV,'ForegroundColor',style.color{11},'BackgroundColor',style.color{end},'FontWeight','bold');
        device_gui.varDelayV = gui_var(device_gui.Panel,[237.5 5 77.5 25],'delay between each voltage step','center',fontsize.dir,'DelayV',{@onChange_varDelayV});
            set(device_gui.varDelayV,'ForegroundColor',style.color{11},'BackgroundColor',style.color{end},'FontWeight','bold');

    %# device functions
    device_obj.reset = @reset;
    device_obj.getCurrentValues = @getCurrentValues;
    device_obj.setCurrentValues = @setCurrentValues;

    reset();
    
    function reset()
        setRangeV(current.minV,current.maxV);
        setStepsizeV(current.stepsizeV);
        setDelayV(current.delayTimeV);
        
        setActiveDirection(current.activeDirectionF,current.activeDirectionB);
        setActiveGeometry(current.activeGeometry);
        
        setCurrentValues(current,'ignoreIllumination',1);
    end

    function currentValues = getCurrentValues()
        currentValues = current;
    end

    function setCurrentValues(currentValues,varargin)
        try
            input = inputParser;
            input.KeepUnmatched = true;
            addParameter(input,'minV',current.minV,@(x) isnumeric(x) && isscalar(x));
            addParameter(input,'maxV',current.maxV,@(x) isnumeric(x) && isscalar(x));
            addParameter(input,'stepsizeV',current.stepsizeV,@(x) isnumeric(x) && isscalar(x));
            addParameter(input,'Spacing',current.Spacing,@(x) any(validatestring(x,{'LIN','LOG'})));
            addParameter(input,'delayTimeV',current.delayTimeV,@(x) isnumeric(x) && isscalar(x));
            addParameter(input,'IntegrationRateV',current.IntegrationRateV,@(x) isnumeric(x) && isscalar(x));
            addParameter(input,'activeDirectionF',current.activeDirectionF,@(x) isnumeric(x) && isscalar(x));
            addParameter(input,'activeDirectionB',current.activeDirectionB,@(x) isnumeric(x) && isscalar(x));
            addParameter(input,'activeLightIV',current.activeLightIV,@(x) isnumeric(x) && isscalar(x));
            addParameter(input,'activeDarkIV',current.activeDarkIV,@(x) isnumeric(x) && isscalar(x));
            addParameter(input,'activeGeometry',current.activeGeometry,@(x) isnumeric(x) && isscalar(x));
            addParameter(input,'activeIllumination',current.activeIllumination,@(x) isnumeric(x) && isscalar(x));
            addParameter(input,'ignoreIllumination',0,@(x) isnumeric(x) && isscalar(x));
            parse(input,currentValues,varargin{:})
            
            if isfield(input.Results,'IntegrationRateV')
                current.IntegrationRateV = input.Results.IntegrationRateV;
            end
            
            if isfield(input.Results,'Spacing')
                current.Spacing = input.Results.Spacing;
            end

            if isfield(input.Results,'minV') && isfield(input.Results,'maxV')
                setRangeV(input.Results.minV,input.Results.maxV)
            end

            if isfield(input.Results,'stepsizeV')
                setStepsizeV(input.Results.stepsizeV)
            end

            if isfield(input.Results,'delayTimeV')
                setDelayV(input.Results.delayTimeV)
            end

            if isfield(input.Results,'activeDirectionF') && isfield(input.Results,'activeDirectionB')
                setActiveDirection(input.Results.activeDirectionF,input.Results.activeDirectionB)
            end

            if isfield(input.Results,'activeLightIV')
                setActiveLightIV(input.Results.activeLightIV)
            end

            if isfield(input.Results,'activeDarkIV')
                setActiveDarkIV(input.Results.activeDarkIV)
            end

            if isfield(input.Results,'activeGeometry')
                setActiveGeometry(input.Results.activeGeometry)
            end

            if ~input.Results.ignoreIllumination
                if isfield(input.Results,'activeIllumination')
                    setActiveIllumination(input.Results.activeIllumination)
                end
            end
        catch error        
            errordlg('Wrong type of input. Settings have to be given as Parameter, i.e., (''parameter_name'',value) or as struct, i.e., s.parameter_name = value.','Error');
            disp(error.message);
        end
    end

    function onChange_varRangeV(varargin)
        minV = str2double(device_gui.varMinV.String);
        maxV = str2double(device_gui.varMaxV.String);
        
        setRangeV(minV,maxV);
    end

    function onChange_varStepsizeV(hObject,varargin)
        setStepsizeV(str2double(get(hObject,'String')));
    end

    function onChange_varDelayV(hObject,varargin)
        setDelayV(str2double(get(hObject,'String')));
    end

    function onChange_tbtnDirection(hObject,varargin)
        switch get(hObject,'Tag')
            case 'tbtnDirectionF'
                setActiveDirection(get(hObject,'Value'),current.activeDirectionB);
            case 'tbtnDirectionB'
                setActiveDirection(current.activeDirectionF,get(hObject,'Value'));
        end
    end

    function onChange_tbtnMeasurement(hObject,varargin)
        switch get(hObject,'Tag')
            case 'tbtnLightIV'
                setActiveLightIV(get(hObject,'Value'));
            case 'tbtnDarkIV'
                setActiveDarkIV(get(hObject,'Value'));
            case 'tbtnGeometry'
                setActiveGeometry(get(hObject,'Value'));
            case 'tbtnIllumination'
                setActiveIllumination(get(hObject,'Value'));
        end
    end

    function setActiveDirection(activeF,activeB)
        try
            input = inputParser;
            addRequired(input,'activeF',@(x) isnumeric(x) && isscalar(x) && ~isnan(x) && (x==1 || x==0));
            addRequired(input,'activeB',@(x) isnumeric(x) && isscalar(x) && ~isnan(x) && (x==1 || x==0));
            parse(input,activeF,activeB)
            
            current.activeDirectionF = activeF;
            set(device_gui.DirectionF,'Value',activeF,'BackgroundColor',con_a_b(activeF,style.color{11},style.color{1}))
            current.activeDirectionB = activeB;
            set(device_gui.DirectionB,'Value',activeB,'BackgroundColor',con_a_b(activeB,style.color{11},style.color{1}))
            
            setActiveLightIV(con_a_b(activeF || activeB,1,0));
            setActiveDarkIV(con_a_b(activeF || activeB,1,0));
        catch error        
            errordlg('State has to be 1 (on) or 0 (off) in setActiveDirection.','Error');
            disp(error.message);
        end
    end

    function setActiveLightIV(state)
        try
            input = inputParser;
            addRequired(input,'state',@(x) isnumeric(x) && isscalar(x) && ~isnan(x) && (x==1 || x==0));
            parse(input,state)
            
            current.activeLightIV = state;
            set(device_gui.LightIV,'Value',state,'BackgroundColor',con_a_b(state,style.color{11},style.color{1}))
        catch error        
            errordlg('State has to be 1 (on) or 0 (off) in setActiveLightIV.','Error');
            disp(error.message);
        end
    end

    function setActiveDarkIV(state)
        try
            input = inputParser;
            addRequired(input,'state',@(x) isnumeric(x) && isscalar(x) && ~isnan(x) && (x==1 || x==0));
            parse(input,state)
            
            current.activeDarkIV = state;
            set(device_gui.DarkIV,'Value',state,'BackgroundColor',con_a_b(state,style.color{11},style.color{1}))
        catch error        
            errordlg('State has to be 1 (on) or 0 (off) in setActiveDarkIV.','Error');
            disp(error.message);
        end
    end

    function setActiveGeometry(state)
        try
            input = inputParser;
            addRequired(input,'state',@(x) isnumeric(x) && isscalar(x) && ~isnan(x) && (x==1 || x==0));
            parse(input,state)
            
            current.activeGeometry = input.Results.state;
            set(device_gui.Geometry,'String',con_a_b(input.Results.state,'inverted','regular'),'BackgroundColor',con_a_b(input.Results.state,style.color{11},style.color{14}))
        catch error        
            errordlg('State has to be 1 (on) or 0 (off) in setActiveGeometry.','Error');
            disp(error.message);
        end
    end

    function setActiveIllumination(state)
        try
            input = inputParser;
            addRequired(input,'state',@(x) isnumeric(x) && isscalar(x) && (x==1 || x==0));
            parse(input,state)
            
            state = input.Results.state;
            
            current.activeIllumination = state;
            set(device_gui.Illumination,'String',con_a_b(state,'front','back'),'BackgroundColor',con_a_b(state,style.color{11},style.color{14}))
            
            updateIllumination(con_a_b(state,'front','back'),'IV');
        catch error        
            errordlg('State has to be 1 (on) or 0 (off) in setActiveIllumination.','Error');
            disp(error.message);
        end
    end

    function setRangeV(minV,maxV)
        try
            input = inputParser;
            addRequired(input,'minV',@(x) isnumeric(x) && isscalar(x) && ~isnan(x) && x>=-10 && x<=10);
            addRequired(input,'maxV',@(x) isnumeric(x) && isscalar(x) && ~isnan(x) && x>=-10 && x<=10);
            parse(input,minV,maxV)
            
            if input.Results.minV<input.Results.maxV
                current.minV = input.Results.minV;
                current.maxV = input.Results.maxV;
            else
                errordlg('Start voltage has to be smaller than end voltage. Adjust scan-direction with buttons.', 'Error')
            end
        catch error        
            errordlg('Voltage has to be numeric and in the range of -10 V and 10 V.','Error');
            disp(error.message);
        end
        
        device_gui.varMinV.String = num2str(current.minV);
        device_gui.varMaxV.String = num2str(current.maxV);
    end

    function setStepsizeV(step)
        try
            input = inputParser;
            addRequired(input,'step',@(x) isnumeric(x) && isscalar(x) && ~isnan(x) && x>=0.00001 && x<=1);
            parse(input,step)
            
            current.stepsizeV = step;
        catch error        
            errordlg('Voltage stepsize has to be numeric and in the range of 0.00001 V and 1 V.','Error');
            disp(error.message);
        end
        
        device_gui.varStepsizeV.String = num2str(current.stepsizeV);
    end

    function setDelayV(step)
        try
            input = inputParser;
            addRequired(input,'step',@(x) isnumeric(x) && isscalar(x) && ~isnan(x) && x>=0 && x<=3600);
            parse(input,step)
            
            current.delayTimeV = step;
        catch error        
            errordlg('Voltage step delay has to be numeric and in the range of 0 s and 3600 s.','Error');
            disp(error.message);
        end
        
        device_gui.varDelayV.String = num2str(current.delayTimeV);
    end
end