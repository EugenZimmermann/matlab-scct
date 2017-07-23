function err = measure_MPP(param,log)
%MEASUREMENT Summary of this function goes here
%   Detailed explanation goes here
    global gui
    global device
    global data
    
    calledBy = param.measType;
    saveDir = param.saveDir;
    calibSettings = param.calibSettings;
    cellDescription = param.cellDescription;
    scanSettings = param.scanSettings;
    scanSettingsStab = param.scanSettingsStab;
        lsTime = scanSettingsStab.lsTime;
        vsTime = scanSettingsStab.vsTime;
    scanSettingsAdv = param.scanSettingsAdv;
    repetition = param.repetition;
    
    temperature = struct([]);
    if isfield(param,'temperature') && isfield(param.temperature,'tempActive') && param.temperature.tempActive
        temperature = param.temperature;
        if device.TemperatureController.getConnectionStatus();
            temperature.device = device.TemperatureController;
        end
    end
    
    scanDirection = 'forward';
    integrationrate = scanSettings.IntegrationRateV; %s
    geometry = scanSettings.activeGeometry;
    
    mppDuration = scanSettingsAdv.mppDuration;
    delay = scanSettings.delayTimeV; %s
    mppManual = scanSettingsAdv.mppManual;
    
    LI = calibSettings.status.CVMeanLampPower;
    activeArea = param.prefsGeneral.ActiveArea;
    
    illuminationDirection = con_a_b(scanSettings.activeIllumination,'front','back');
    
    if isfield(param,'selection')
        selection = param.selection;
        activePixel = selection.activePixel;
        cellOrder = selection.cellOrder.(illuminationDirection);
        pixelOrder = selection.pixelOrder.(illuminationDirection);
        sampleOrder = selection.sampleOrder.(illuminationDirection);
        filenames = {param.filenames.(illuminationDirection)}';
    else
        activePixel = 1;
        cellOrder = 1;
        pixelOrder = {1};
        sampleOrder = 1;
        filenames = {[cellDescription.user,'_Rep',num2str(repetition,'%03d')]};
    end
    
    gd = cellDescription.groupDescription;
    gn = cellDescription.groupNumber;
    
    if geometry %inverted
        scan.forward.start  =  scanSettings.minV;
        scan.forward.stop   =  scanSettings.maxV;
        scan.forward.step   =  scanSettings.stepsizeV;
    else %regular
        scan.forward.start  = -scanSettings.minV;
        scan.forward.stop   = -scanSettings.maxV;
        scan.forward.step   = -scanSettings.stepsizeV;
    end
    scan.forward.V = scan.forward.start:scan.forward.step:scan.forward.stop;
    
    %# check if save directory exists, otherwise create it
    if ~exist(saveDir,'dir')
        mkdir(saveDir);
    end  
    
    if ~isempty(temperature)
        gui.obj.(calledBy).Control.update(0,'wait for temperature ...');
        log.update('temperature control active')
        log.update('set temperature ...')
        err = temperature.device.setTemp(temperature.startTemp);
        if err
            return;
        end

        log.update('enable heating ...')
        err = temperature.device.enableHeating();
        if err
            return;
        end

        pause(2);

        log.update('wait for stabilized temperature ...')
        err = temperature.device.waitForTemp();
        if err
            return;
        end
        log.update('temperature stabalized!')
    end

    log.update('start steady state tracking ...')
    for n1 = activePixel
        log.update(['Pixel: ', num2str(n1)])
        
        %# switch relais cell
        if isfield(device,'Relaisbox') && device.Relaisbox.getConnectionStatus()
            err = device.Relaisbox.setRelais(pixelOrder{n1});
            if err
                return;
            end
        end
        
		%# light soaking
        if isfield(device,'Shutter') && device.Shutter.getConnectionStatus()
            device.Shutter.open();
            tic
            while toc<lsTime
                gui.obj.(calledBy).Control.update(round(toc/lsTime,2),'light soaking ...');
            end
        else
            lsTime = 0;
        end
        
        if ~mppManual       
            %# time for stabilization of voltage
            err = device.Keithley.setPointV(scan.(scanDirection).start,0);
            if err
                return;
            end
            
            tic
            while toc<vsTime
                gui.obj.(calledBy).Control.update(round(toc/vsTime,2),'stabilization ...');
            end

            err = device.Keithley.setSweepV(scan.(scanDirection).start,scan.(scanDirection).stop,scan.(scanDirection).step,delay,integrationrate);
            if err
                return;
            end
            
            gui.obj.(calledBy).Control.update(0,['Pixel: ', num2str(n1), ' ...']);
%             [measure.I,measure.V,err,measure.Time] = device.Keithley.measureSweepV(calledBy);
%             device.Keithley.deactivateOutput();
%             measure.I = measure.I*1000;
            
            [outputData,err] = device.Keithley.measureSweepV('plotHandle',gui.obj.IV.Plot);
            device.Keithley.setOutputState();
            measure.I = outputData.current*1000;
            measure.V = outputData.voltage;
            measure.Time = outputData.time;

            %# change all measurements to 1. quarter of graph
            if geometry
                measure.V = (scan.forward.V)';
                measure.I = con_a_b(strcmp(scanDirection,'forward'),-measure.I,flipud(-measure.I));
            else
                measure.V = -(scan.forward.V)';
                measure.I = con_a_b(strcmp(scanDirection,'forward'),measure.I,flipud(measure.I));
            end

            %# calculate current density
            measure.J = measure.I/activeArea;
            
            %# Check for Cancel and Skip button press
            if err == 88;
                gui.obj.(calledBy).Control.update(find(activePixel==n1)/length(activePixel),[illuminationType,'MPP skipped']);
                continue;
            elseif err == 99;
                gui.obj.(calledBy).Control.update(find(activePixel==n1)/length(activePixel),'aborted');
                return;
            elseif err
                gui.obj.(calledBy).Control.update(find(activePixel==n1)/length(activePixel),'not connected');
                return;
            end
            
            %# create header
            head = struct();
            head.Filename = filenames{n1};
            head.Sample = sampleOrder; 
            head.Cell = cellOrder(n1);
            head.Pixel = pixelOrder{n1};
            head.group = gn;
            head.description = con_a_b(isempty(gd),'-',gd);
            head.ActiveArea = activeArea;

            head.LI = LI;
            head.Type = 'lightIV';
            head.Geometry = con_a_b(geometry,'inverted','regular');
            head.IlluminationDirection = illuminationDirection;
            head.ScanDirection = scanDirection;
            head.Delay = delay;
            head.Integrationrate = integrationrate;
            head.Repetition = repetition;
            if isfield(outputData,'temperature')
                head.Temperature = outputData.temperature;
            end
            
            head.LightSoaking = lsTime;
            head.VoltageStabilization = vsTime;
            head.Atmosphere = param.atmosphere;
            
            time_temp = clock;
                head.Date = datestr(time_temp,'yyyy-mm-dd');
                head.Time = datestr(time_temp,'HH:MM:SS');
                
            head.Filepath = [saveDir,head.Date,'\'];

            %# analyse data
            head = analyze_IV(head,measure.V,measure.J,log);

            %# update global data structure
            export_data.header = head;
            export_data.measurement = measure;

            %# save data
            saveData(saveDir,filenames{n1},export_data);

            %# update table
            gui.obj.summary.setData(head);
        
            if geometry
                mppV = export_data.header.mppV;
                voc = export_data.header.VOC;
            else
                mppV = -export_data.header.mppV;
                voc = -export_data.header.VOC;
            end
        else
            if geometry
                mppV = scanSettingsAdv.mppV;
                voc = 0.9;
            else
                mppV = -scanSettingsAdv.mppV;
                voc = -0.9;
            end
        end
        
%         if isfield(temperature,'tempActive') && temperature.tempActive    
%             err = temperature.device.startRamp(temperature.rate,varargin);
%             if err
%                 return;
%             end
%         end
            
        %# MPP-Tracking
        if scanSettingsAdv.mppMPP
%             [measureMPP.mpp,measureMPP.V,measureMPP.I,measureMPP.Time,err] = device.Keithley.measureMPP(mppV,mppDuration,delay,integrationrate,'temperatureController',temperature);
%             device.Keithley.deactivateOutput();
%             measureMPP.I = measureMPP.I'*1000;
            
            [outputData,err] = device.Keithley.measureSteadyState(mppV,mppDuration,delay,integrationrate,'temperatureController',temperature,'plotHandle',gui.obj.(calledBy).Plot);
            device.Keithley.setOutputState();
            measureMPP.mpp = outputData.power;
            measureMPP.V   = outputData.voltage;
            measureMPP.I   = outputData.current*1000;
            measureMPP.Time= outputData.time;
            if isfield(outputData,'temperature')
                measureMPP.Temperature = outputData.temperature-outputData.temperature(1);
            end

            measureMPP.J = measureMPP.I/activeArea;
            measureMPP.mpp = measureMPP.mpp*1000/activeArea;

%             %# Check for Cancel and Skip button press
%             if err == 88;
%                 gui.obj.(calledBy).Control.update(find(activePixel==n1)/length(activePixel),'MPP skipped');
%                 continue;
%             elseif err == 99;
%                 gui.obj.(calledBy).Control.update(find(activePixel==n1)/length(activePixel),'aborted');
%                 return;
%             elseif err == 77;
%                 gui.obj.(calledBy).Control.update(find(activePixel==n1)/length(activePixel),'voltage exceeds limit');
%             elseif err
%                 gui.obj.(calledBy).Control.update(find(activePixel==n1)/length(activePixel),'not connected');
%                 return;
%             end

            %# create header        
            headMPP = struct();
            headMPP.Filename = filenames{n1};
            headMPP.Sample = sampleOrder; 
            headMPP.Cell = cellOrder(n1);
            headMPP.Pixel = pixelOrder{n1};
            headMPP.group = gn;
            headMPP.description = con_a_b(isempty(gd),'-',gd);
            headMPP.ActiveArea = activeArea;

            headMPP.LI = LI;
            headMPP.Type = con_a_b(isempty(temperature),'MPP','MPPT');
            headMPP.IlluminationDirection = illuminationDirection;
            headMPP.Delay = delay;
            headMPP.Integrationrate = integrationrate;
            headMPP.Repetition = repetition;

            time_temp = clock;
            headMPP.Date = datestr(time_temp,'yyyy-mm-dd');
            headMPP.Time = datestr(time_temp,'HH:MM:SS');
            headMPP.Filepath = [saveDir,headMPP.Date,'\'];

            %# update global data structure
            data.mpp(n1).header = headMPP;
            data.mpp(n1).measurement = measureMPP;

            %# save data
            saveData(saveDir,filenames{n1},data.mpp(n1));
            
            %# Check for Cancel and Skip button press
            if err == 88;
                gui.obj.(calledBy).Control.update(find(activePixel==n1)/length(activePixel),'MPP skipped');
                continue;
            elseif err == 99;
                gui.obj.(calledBy).Control.update(find(activePixel==n1)/length(activePixel),'aborted');
                return;
            elseif err == 77;
                gui.obj.(calledBy).Control.update(find(activePixel==n1)/length(activePixel),'voltage exceeds limit');
            elseif err
                gui.obj.(calledBy).Control.update(find(activePixel==n1)/length(activePixel),'not connected');
                return;
            end

            %# update table
            gui.obj.summary.setData(headMPP);

            %# update statistics
            gui.obj.prefs.record.update(1,'MPP');
        end
        
        %# JSC-Tracking
        if scanSettingsAdv.mppJSC
            %# measure with keithley
            gui.obj.(calledBy).Control.update(0,['Pixel: ', num2str(n1), ' ...']);
%             [measureJSC.I,measureJSC.V,measureJSC.Time,err] = device.Keithley.measureTimePointV(0,max(60,mppDuration),delay,'integrationrate',integrationrate); %calledBy
%             device.Keithley.deactivateOutput();
%             measureJSC.I = measureJSC.I'*1000;
            
            [outputData,err] = device.Keithley.measureSteadyState(0,mppDuration,delay,integrationrate,'temperatureController',temperature,'track','jsc','plotHandle',gui.obj.(calledBy).Plot);
            device.Keithley.setOutputState();
            measureJSC.V   = outputData.voltage;
            measureJSC.I   = outputData.current*1000;
            measureJSC.Time= outputData.time;
            if isfield(outputData,'temperature')
                measureJSC.Temperature = outputData.temperature-outputData.temperature(1);
            end
            
            assignin('base','out',outputData)

            measureJSC.J = measureJSC.I/activeArea;

%             %# Check for Cancel and Skip button press
%             if err == 88;
%                 gui.obj.(calledBy).Control.update(find(activePixel==n1)/length(activePixel),'JSC tracking skipped');
%                 continue;
%             elseif err == 99;
%                 gui.obj.(calledBy).Control.update(find(activePixel==n1)/length(activePixel),'aborted');
%                 return;
%             elseif err
%                 gui.obj.(calledBy).Control.update(find(activePixel==n1)/length(activePixel),'not connected');
%                 return;
%             end

            gui.obj.(calledBy).Plot.update(measureJSC.Time,measureJSC.J,'xlabel','Time (s)','ylabel','Current Density (mA/cm²)');

            %# create header
            headJSC = struct();
            headJSC.Filename = filenames{n1};
            headJSC.Sample = sampleOrder;
            headJSC.Cell = cellOrder(n1);
            headJSC.Pixel = pixelOrder{n1};
            headJSC.group = gn;
            headJSC.description = con_a_b(isempty(gd),'-',gd);
            headJSC.ActiveArea = activeArea;

            headJSC.LI = LI;
            headJSC.Type = con_a_b(isempty(temperature),'JSC','JSCT');
            headJSC.Geometry = con_a_b(geometry,'inverted','regular');
            headJSC.IlluminationDirection = illuminationDirection;
            headJSC.Delay = delay;
            headJSC.Integrationrate = integrationrate;
            headJSC.Repetition = repetition;

            headJSC.LightSoaking = lsTime;
            headJSC.Atmosphere = param.atmosphere;

            time_temp = clock;
            headJSC.Date = datestr(time_temp,'yyyy-mm-dd');
            headJSC.Time = datestr(time_temp,'HH:MM:SS');
            headJSC.Filepath = [saveDir,headJSC.Date,'\'];

            %# update global data structure
            data.jsc(n1).header = headJSC;
            data.jsc(n1).measurement = measureJSC;

            %# save data
            saveData(saveDir,filenames{n1},data.jsc(n1));
            
            %# Check for Cancel and Skip button press
            if err == 88;
                gui.obj.(calledBy).Control.update(find(activePixel==n1)/length(activePixel),'JSC tracking skipped');
                continue;
            elseif err == 99;
                gui.obj.(calledBy).Control.update(find(activePixel==n1)/length(activePixel),'aborted');
                return;
            elseif err
                gui.obj.(calledBy).Control.update(find(activePixel==n1)/length(activePixel),'not connected');
                return;
            end

            %# update table
%             gui.obj.summary.setData(headJSC);

            %# update statistics
%             gui.obj.prefs.record.update(1,'JSC');
        end
        
        %# VOC-Tracking
        if scanSettingsAdv.mppVOC
%             [measureVOC.mpp,measureVOC.V,measureVOC.I,measureVOC.Time,err] = device.Keithley.measureVOC(voc,max(60,mppDuration),delay,integrationrate);
%             device.Keithley.deactivateOutput();
%             measureVOC.I = measureVOC.I'*1000;
            
            [outputData,err] = device.Keithley.measureSteadyState(voc,mppDuration,delay,integrationrate,'temperatureController',temperature,'track','voc','plotHandle',gui.obj.(calledBy).Plot);
            device.Keithley.setOutputState();
            measureVOC.mpp = outputData.power;
            measureVOC.V   = outputData.voltage;
            measureVOC.I   = outputData.current*1000;
            measureVOC.Time= outputData.time;
            if isfield(outputData,'temperature')
                measureVOC.Temperature = outputData.temperature-outputData.temperature(1);
            end

            measureVOC.J = measureVOC.I/activeArea;
            measureVOC.mpp = measureVOC.mpp*1000/activeArea;

%             %# Check for Cancel and Skip button press
%             if err == 88;
%                 gui.obj.(calledBy).Control.update(find(activePixel==n1)/length(activePixel),'VOC tracking skipped');
%                 continue;
%             elseif err == 99;
%                 gui.obj.(calledBy).Control.update(find(activePixel==n1)/length(activePixel),'aborted');
%                 return;
%             elseif err == 77;
%                 gui.obj.(calledBy).Control.update(find(activePixel==n1)/length(activePixel),'voltage exceeds limit');
%             elseif err
%                 gui.obj.(calledBy).Control.update(find(activePixel==n1)/length(activePixel),'not connected');
%                 return;
%             end

            %# create header        
            headVOC = struct();
            headVOC.Filename = filenames{n1};
            headVOC.Sample = sampleOrder; 
            headVOC.Cell = cellOrder(n1);
            headVOC.Pixel = pixelOrder{n1};
            headVOC.group = gn;
            headVOC.description = con_a_b(isempty(gd),'-',gd);
            headVOC.ActiveArea = activeArea;

            headVOC.LI = LI;
            headVOC.Type = con_a_b(isempty(temperature),'VOC','VOCT');
            headVOC.IlluminationDirection = illuminationDirection;
            headVOC.Delay = delay;
            headVOC.Integrationrate = integrationrate;
            headVOC.Repetition = repetition;

            time_temp = clock;
            headVOC.Date = datestr(time_temp,'yyyy-mm-dd');
            headVOC.Time = datestr(time_temp,'HH:MM:SS');
            headVOC.Filepath = [saveDir,headVOC.Date,'\'];

            %# update global data structure
            data.mpp(n1).header = headVOC;
            data.mpp(n1).measurement = measureVOC;

            %# save data
            saveData(saveDir,filenames{n1},data.mpp(n1));
            
            %# Check for Cancel and Skip button press
            if err == 88;
                gui.obj.(calledBy).Control.update(find(activePixel==n1)/length(activePixel),'VOC tracking skipped');
                continue;
            elseif err == 99;
                gui.obj.(calledBy).Control.update(find(activePixel==n1)/length(activePixel),'aborted');
                return;
            elseif err == 77;
                gui.obj.(calledBy).Control.update(find(activePixel==n1)/length(activePixel),'voltage exceeds limit');
            elseif err
                gui.obj.(calledBy).Control.update(find(activePixel==n1)/length(activePixel),'not connected');
                return;
            end

%             %# update table
%             gui.obj.summary.setData(headVOC);

            %# update statistics
            gui.obj.prefs.record.update(1,'MPP');
        end
        
        %# update progress bar
        gui.obj.(calledBy).Control.update(find(activePixel==n1)/length(activePixel),'steady state');
    end
    if isfield(device,'Shutter') && device.Shutter.getConnectionStatus()
        device.Shutter.close();
    end
    
    %# update progress bar last time
    gui.obj.(calledBy).Control.update(1,['Steady state tracking', ' done']);
	err = 0;
end