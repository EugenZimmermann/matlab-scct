function err = measure_cycle(param,log)
%MEASUREMENT Summary of this function goes here
%   Detailed explanation goes here
    global gui
    global device
    global data

    calledBy = param.measType;
    saveDir = param.saveDir;
    illuminationType = param.illuminationType;
    calibSettings = param.calibSettings;
    cellDescription = param.cellDescription;
    scanSettings = param.scanSettings;
    scanSettingsAdv = param.scanSettingsAdv;
	scanSettingsStab = param.scanSettingsStab;
        lsTime = scanSettingsStab.lsTime;
        vsTime = scanSettingsStab.vsTime;
        
    repetition = param.repetition;
    
    temperature = struct([]);
    if isfield(param,'temperature') && isfield(param.temperature,'tempActive') && param.temperature.tempActive
        temperature = param.temperature;
        if device.TemperatureController.getConnectionStatus();
            temperature.device = device.TemperatureController;
        end
    end
    
    cycleManual = scanSettingsAdv.cycleManual;
    scanDirection = 'forward';
	
    stepsize = scanSettings.stepsizeV;
    delay = scanSettings.delayTimeV; %s
    integrationrate = scanSettings.IntegrationRateV; %s
    geometry = scanSettings.activeGeometry;
    illuminationDirection = con_a_b(scanSettings.activeIllumination,'front','back');
    
    if geometry %inverted
        scan.forward.start  =  scanSettings.minV;
        scan.forward.stop   =  scanSettings.maxV;
        scan.forward.step   =  scanSettings.stepsizeV;
    else %regular
        scan.forward.start  = -scanSettings.minV;
        scan.forward.stop   = -scanSettings.maxV;
        scan.forward.step   = -scanSettings.stepsizeV;
		
		stepsize = -stepsize;
    end
    scan.forward.V = scan.forward.start:scan.forward.step:scan.forward.stop;
    
    LI = con_a_b(strcmp(illuminationType,'light'),calibSettings.status.CVMeanLampPower,0);
    activeArea = param.prefsGeneral.ActiveArea;
    
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

    log.update(['start ',illuminationType,' Cycle measurement ...'])
    for n1 = activePixel
        log.update(['Pixel: ', num2str(n1)])
        
        %# switch relais cell
        if isfield(device,'Relaisbox') && device.Relaisbox.getConnectionStatus()
            err = device.Relaisbox.setRelais(pixelOrder{n1});
            if err
                return;
            end
        end
        
        if ~cycleManual
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
                vmpp = export_data.header.mppV;
                voc = export_data.header.VOC;
            else
                vmpp = -export_data.header.mppV;
                voc = -export_data.header.VOC;
            end
        else
            if geometry
                vmpp = scanSettingsAdv.cycleMPPV;
                voc = scanSettingsAdv.cycleVOC;
            else
                vmpp = -scanSettingsAdv.cycleMPPV;
                voc = -scanSettingsAdv.cycleVOC;
            end
        end
                
        %# go to cell position
        switch illuminationType
            case {'light'}
                %# light soaking
                if isfield(device,'Shutter') && device.Shutter.getConnectionStatus()
                    device.Shutter.open();
                    lsTime = scanSettingsStab.lsTime;
                    tic
                    while toc<lsTime
                        gui.obj.(calledBy).Control.update(round(toc/lsTime,2),'light soaking ...');
                    end
                else
                    lsTime = 0;
                end
            otherwise
                lsTime = 0;
        end
        
        %# replace stabilization by mpp tracking!
        %# time for stabilization of voltage
		err = device.Keithley.setPointV(vmpp,0);
        if err
            return;
        end
        tic
        while toc<vsTime
            gui.obj.(calledBy).Control.update(round(toc/vsTime,2),'stabilization ...');
        end
        
        gui.obj.(calledBy).Control.update(0,['Pixel: ', num2str(n1), ' ...']);
        [outputDataCycle,err] = device.Keithley.measureCycle(vmpp,voc,stepsize,delay,integrationrate,'plotHandle',gui.obj.IV.Plot);
        device.Keithley.setOutputState();
        measureCycle.I = outputDataCycle.current*1000;
        measureCycle.V = outputDataCycle.voltage;
        
        %# change all measurements to 1. quarter of graph
        if geometry
            measureCycle.V = measureCycle.V;
            measureCycle.I = -measureCycle.I;
        else
            measureCycle.V = -measureCycle.V;
            measureCycle.I = measureCycle.I;
        end
        
        %# calculate current density
        measureCycle.J = measureCycle.I/activeArea;
        
        %# Check for Cancel and Skip button press
        if err == 88;
            gui.obj.(calledBy).Control.update(find(activePixel==n1)/length(activePixel),[illuminationType,'Cycle skipped']);
            continue;
        elseif err == 99;
            gui.obj.(calledBy).Control.update(find(activePixel==n1)/length(activePixel),'aborted');
            return;
        elseif err
            gui.obj.(calledBy).Control.update(find(activePixel==n1)/length(activePixel),'not connected');
            return;
        end
                
        %# create header
        headCycle = struct();
        headCycle.Filename = filenames{n1};
        headCycle.Sample = sampleOrder; 
        headCycle.Cell = cellOrder(n1);
        headCycle.Pixel = pixelOrder{n1};
        headCycle.group = gn;
        headCycle.description = con_a_b(isempty(gd),'-',gd);
        headCycle.ActiveArea = activeArea;
        
        headCycle.LI = LI;
        headCycle.Type = 'Cycle';
        headCycle.IlluminationDirection = illuminationDirection;
        headCycle.Delay = delay;
        headCycle.Integrationrate = integrationrate;
        headCycle.Repetition = repetition;
        
        headCycle.LightSoaking = lsTime;
        headCycle.VoltageStabilization = vsTime;
        headCycle.Atmosphere = param.atmosphere;
        
        time_temp = clock;
        headCycle.Date = datestr(time_temp,'yyyy-mm-dd');
        headCycle.Time = datestr(time_temp,'HH:MM:SS');
        headCycle.Filepath = [saveDir,headCycle.Date,'\'];
        
        %# update global data structure
        data.cycle(n1).header = headCycle;
        data.cycle(n1).measurement = measureCycle;

        %# save data
        saveData(saveDir,filenames{n1},data.cycle(n1));
        
        %# update statistics
        gui.obj.prefs.record.update(1,'Cycle');
        
        %# update progress bar
        gui.obj.(calledBy).Control.update(find(activePixel==n1)/length(activePixel),headCycle.Type);
    end
    if isfield(device,'Shutter') && device.Shutter.getConnectionStatus()
        device.Shutter.close();
    end
    
    gui.obj.(calledBy).Control.update(1,['Cycle',' done']);
    err = 0;
end

