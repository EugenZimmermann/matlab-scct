function err = measure_TRS(param,log)
%MEASUREMENT Summary of this function goes here
%   Detailed explanation goes here
    global gui
    global device
    global data
    
    calledBy = param.measType;
    saveDir = param.saveDir;
    illuminationType = param.illuminationType;
    scanDirection = param.scanDirection;
    calibSettings = param.calibSettings;
    cellDescription = param.cellDescription;
    scanSettings = param.scanSettings;
	scanSettingsStab = param.scanSettingsStab;
    scanSettingsAdv = param.scanSettingsAdv;
    repetition = param.repetition;
    
    temperature = struct([]);
    if isfield(param,'temperature') && isfield(param.temperature,'tempActive') && param.temperature.tempActive
        temperature = param.temperature;
        if device.TemperatureController.getConnectionStatus();
            temperature.device = device.TemperatureController;
        end
    end
    
    delay = scanSettings.delayTimeV; %s
    integrationrate = scanSettings.IntegrationRateV; %s
    geometry = scanSettings.activeGeometry;
    illuminationDirection = con_a_b(scanSettings.activeIllumination,'front','back');
    
    stepTime = scanSettingsAdv.trsStepTime;  

    if geometry %inverted
        scan.forward.start  =  scanSettings.minV;
        scan.forward.stop   =  scanSettings.maxV;
        scan.forward.step   =  scanSettings.stepsizeV;

        scan.backward.start =  scanSettings.maxV;
        scan.backward.stop  =  scanSettings.minV;
        scan.backward.step  = -scanSettings.stepsizeV;
    else %regular
        scan.forward.start  = -scanSettings.minV;
        scan.forward.stop   = -scanSettings.maxV;
        scan.forward.step   = -scanSettings.stepsizeV;

        scan.backward.start = -scanSettings.maxV;
        scan.backward.stop  = -scanSettings.minV;
        scan.backward.step  =  scanSettings.stepsizeV;
    end
    scan.forward.V = scan.forward.start:scan.forward.step:scan.forward.stop;
    scan.backward.V = scan.backward.start:scan.backward.step:scan.backward.stop;
    
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

    log.update(['start ',illuminationType,' TRS measurement in ',scanDirection,' direction ...'])
    for n1 = activePixel
        log.update(['Pixel: ', num2str(n1)])
        
        %# switch relais cell
        if isfield(device,'Relaisbox') && device.Relaisbox.getConnectionStatus()
            err = device.Relaisbox.setRelais(pixelOrder{n1});
            if err
                return;
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

		gui.obj.(calledBy).Control.update(0,['Pixel: ', num2str(n1), ' ...']);
        [outputData,err] = device.Keithley.measureTimeSweepV(scan.(scanDirection).start,scan.(scanDirection).stop,scan.(scanDirection).step,stepTime,delay,integrationrate,'plotHandle',gui.obj.IV.Plot);
        device.Keithley.setOutputState();
        measure.I = outputData.current*1000;
        measure.V = outputData.voltage;
        measure.Time = outputData.time;
        
        %# change all measurements to 1. quarter of graph
        if geometry
            measure.V = measure.V;
            measure.I = con_a_b(strcmp(scanDirection,'forward'),-measure.I,flipud(-measure.I));
        else
            measure.V = -measure.V;
            measure.I = con_a_b(strcmp(scanDirection,'forward'),measure.I,flipud(measure.I));
        end
        
        %# calculate current density
        measure.J = measure.I/activeArea;
        
        %# Check for Cancel and Skip button press
        if err == 88;
            gui.obj.(calledBy).Control.update(find(activePixel==n1)/length(activePixel),[illuminationType,'TRS skipped']);
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
        head.Type = [illuminationType,'TRS'];
        head.IlluminationDirection = illuminationDirection;
        head.ScanDirection = scanDirection;
        head.Delay = delay;
        head.Integrationrate = integrationrate;
		head.Repetition = repetition;
        
        head.LightSoaking = lsTime;
		head.Atmosphere = param.atmosphere;
        
        time_temp = clock;
        head.Date = datestr(time_temp,'yyyy-mm-dd');
        head.Time = datestr(time_temp,'HH:MM:SS');
        head.Filepath = [saveDir,head.Date,'\'];
        
		measureShort.V = unique(measure.V);
        for n2 = 1:length(measureShort.V)
            index = find(measure.V==measureShort.V(n2));
            measureShortStart.J(n2,1) = measure.J(index(1));
            measureShortStop.J(n2,1) = measure.J(index(end));
        end
        
        measureShortStart.I = measureShortStart.J/1000*activeArea;
        measureShortStop.I = measureShortStop.J/1000*activeArea;
        
        headShort = head;
        headShort.Type = [illuminationType,'TRSIV'];
        
        measureShortStart.V = measureShort.V;
        measureShortStop.V = measureShortStart.V;
        data_start.measurement = measureShortStart;
        data_stop.measurement = measureShortStop;
        
        %# analyse data
        data_start.header = analyze_IV(headShort,measureShortStart.V,measureShortStart.J,log);
            saveData(saveDir,filenames{n1},data_start);
        data_stop.header = analyze_IV(headShort,measureShortStop.V,measureShortStop.J,log);
            saveData(saveDir,filenames{n1},data_stop);
        
        %# update global data structure
        data.trs(n1).header = head;
        data.trs(n1).measurement = measure;
        
        %# save data
        saveData(saveDir,filenames{n1},data.trs(n1));
        
        %# update table
        gui.obj.summary.setData(head);

        %# update statistics
        gui.obj.prefs.record.update(1,'TRS');
        
        %# update progress bar
        gui.obj.(calledBy).Control.update(find(activePixel==n1)/length(activePixel),head.Type);
    end
    if isfield(device,'Shutter') && device.Shutter.getConnectionStatus()
        device.Shutter.close();
    end
    
    %# update progress bar last time
    gui.obj.(calledBy).Control.update(1,[illuminationType,'TRSIV',' done']);
    err = 0;
end