function err =  measure_TRP(param,log)
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
    
    integrationrate = scanSettings.IntegrationRateV; %s
    geometry = scanSettings.activeGeometry;
    
    bias = [scanSettingsAdv.trpVolt1,scanSettingsAdv.trpVolt2,scanSettingsAdv.trpVolt3];
    if ~geometry
        bias = -bias;
    end

    time = [scanSettingsAdv.trpTime1,scanSettingsAdv.trpTime2,scanSettingsAdv.trpTime3];
    timeStep = scanSettingsAdv.trpTimeStep;
    
    LI = con_a_b(strcmp(illuminationType,'light'),calibSettings.status.CVMeanLampPower,0);
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

    log.update(['start ',illuminationType,' TRP measurement ...'])
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
        
        %# measure with keithley
		gui.obj.(calledBy).Control.update(0,['Pixel: ', num2str(n1), ' ...']);
        [outputData,err] = device.Keithley.measureTimePointV(bias,time,timeStep,'integrationrate',integrationrate,'plotHandle',gui.obj.IV.Plot);
		device.Keithley.setOutputState();
        measure.I = outputData.current*1000;
        measure.V = outputData.voltage;
        measure.Time = outputData.time;
        measure.J = measure.I/activeArea;
        
        %# Check for Cancel and Skip button press
        if err == 88;
            gui.obj.(calledBy).Control.update(find(activePixel==n1)/length(activePixel),[illuminationType,'TRP skipped']);
            continue;
        elseif err == 99;
            gui.obj.(calledBy).Control.update(find(activePixel==n1)/length(activePixel),'aborted');
            return;
        elseif err
            gui.obj.(calledBy).Control.update(find(activePixel==n1)/length(activePixel),'not connected');
            return;
        end
        
        gui.obj.(calledBy).Plot.update(measure.Time,measure.J,'xlabel','Time (s)','ylabel','Current Density (mA/cm²)');
        
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
        head.Type = [illuminationType,'TRP'];
        head.Geometry = con_a_b(geometry,'inverted','regular');
        head.IlluminationDirection = illuminationDirection;
        head.Delay = timeStep;
        head.Integrationrate = integrationrate;
		head.Repetition = repetition;
        
		head.LightSoaking = lsTime;
		head.Atmosphere = param.atmosphere;
        
        time_temp = clock;
        head.Date = datestr(time_temp,'yyyy-mm-dd');
        head.Time = datestr(time_temp,'HH:MM:SS');
        head.Filepath = [saveDir,head.Date,'\'];
        
        %# update global data structure
        data.trp(n1).header = head;
        data.trp(n1).measurement = measure;
        
        %# save data
        saveData(saveDir,filenames{n1},data.trp(n1));
        
        %# update table
        gui.obj.summary.setData(head);

        %# update statistics
        gui.obj.prefs.record.update(1,'TRP');

        %# update progress bar
        gui.obj.(calledBy).Control.update(find(activePixel==n1)/length(activePixel),head.Type);
    end
    if isfield(device,'Shutter') && device.Shutter.getConnectionStatus()
        device.Shutter.close();
    end
    
    %# update progress bar last time
    gui.obj.(calledBy).Control.update(1,[illuminationType,'TRP', ' done']);
    err = 0;
end

