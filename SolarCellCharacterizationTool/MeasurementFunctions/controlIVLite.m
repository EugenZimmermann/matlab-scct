function newObj = controlIVLite(log)
    global gui
    global data
    global device
    
    %# data elements
    newObj = struct();

    %# obj functions
    newObj.start = @start;
    newObj.cancel = @cancel;
    newObj.skip = @skip;
    
    %# start button callback
    function start(varargin)
%         try
            err = device.Keithley.setOutputState();
            if err
                errordlg('Keithley not connected!');
                return;
            end
            
            measType = 'IV';
            log.update(['start ',measType,' measurement'])
            
            param.measType = measType;
            param.prefsGeneral = gui.obj.prefs.general.getSettings();
            param.atmosphere = param.prefsGeneral.atmosphere;
            saveDir = param.prefsGeneral.DefaultDir;
                [~,n] = fileparts(saveDir);
                param.tempSaveDir = [saveDir,con_a_b(~isempty(n),'\','')];
                
            param.calibSettings = gui.obj.calibration.IV.getSettings();
            param.cellDescription = gui.obj.(measType).CellDescription.getSettings();
            if isfield(gui.obj.IV,'Selection')
                param.selection = gui.obj.IV.Selection.getSettings();
            
                temp_filenames = param.cellDescription.names;
                filenames = struct([]);
                for illuminationDirection = {'front','back'} 
                    %# check if cells have a name
                    for n0 = param.selection.activePixel
                        filenames(n0).(illuminationDirection{1}) = [temp_filenames{param.selection.cellOrder.(illuminationDirection{1})(n0)},'_',param.selection.pixelOrder.(illuminationDirection{1}){n0}];
                    end
                end
                param.filenames = filenames;
            end
            
            param.temperature = gui.obj.temperature.getCurrentValues();
            param.scanSettings = gui.obj.(measType).ScanSettingsMain.getCurrentValues();
            
            param.scanSettingsStab = gui.obj.(measType).ScanSettingsStabilization.getCurrentValues();
            param.scanSettingsAdv = gui.obj.(measType).ScanSettingsAdv.getCurrentValues();
                activeMeasurement = fieldnames(param.scanSettingsAdv.activeMeasurement);
                if isempty(activeMeasurement)
                    activeMeasurement = 'none';
                else
                    activeMeasurement = activeMeasurement{1};
                end
            
            param.scanSettingsRep = gui.obj.(measType).ScanSettingsRep.getCurrentValues();
                if param.scanSettingsRep.repActive
                    repNumber = param.scanSettingsRep.repNumber;
                else
                    repNumber = 1;
                end
            
            for n2 = 1:repNumber
                param.repetition = n2;
                switch activeMeasurement
                    case 'TRP'
                        param.saveDir = [param.tempSaveDir,'TRP\'];
                        err = mTRP(param);
                        if err == 99
                            log.update('TRP measurement aborted by user')
                            return;
                        elseif err < 0
                            return;
                        end
                    case 'TRS'
                        param.saveDir = [param.tempSaveDir,'TRS\'];
                        err = mTRS(param);
                        if err == 99
                            log.update('TRS measurement aborted by user')
                            return;
                        elseif err < 0
                            return;
                        end
                    case 'Cycle'
                        param.saveDir = [param.tempSaveDir,'Cycle\'];
                        err = mCycle(param);
                        if err == 99
                            log.update('Cycle measurement aborted by user')
                            return;
                        elseif err < 0
                            return;
                        end
                    case 'Tracking'
                        param.saveDir = [param.tempSaveDir,'MPP\'];
                        err = mMPP(param);
                        if err == 99
                            log.update('MPP measurement aborted by user')
                            return;
                        elseif err < 0
                            return;
                        end
                    case 'Perovskite'
                        param.scanSettings.activeDarkIV = 1;
                        param.saveDir = [param.tempSaveDir,'Perovskite\'];
                        err = mIV(param);
                        if err == 99
                            log.update('IV measurement aborted by user')
                            return;
                        elseif err < 0
                            return;
                        end
                        
                        param.scanSettings.activeDarkIV = 0;
                        err = mMPP(param);
                        if err == 99
                            log.update('MPP measurement aborted by user')
                            return;
                        elseif err < 0
                            return;
                        end
                        
                        err = mCycle(param);
                        if err == 99
                            log.update('Cycle measurement aborted by user')
                            return;
                        elseif err < 0
                            return;
                        end
                        
                        param.scanSettings.stepsizeV = 0.05;
                        err = mTRS(param);
                        if err == 99
                            log.update('TRS measurement aborted by user')
                            return;
                        elseif err < 0
                            return;
                        end
                        
                        param.scanSettings.stepsizeV = 0.01;
                        err = mIV(param);
                        if err == 99
                            log.update('IV measurement aborted by user')
                            return;
                        elseif err < 0
                            return;
                        end
                    otherwise
                        param.saveDir = [param.tempSaveDir,'IV\'];
                        err = mIV(param);
                        if err == 99
                            log.update('IV measurement aborted by user')
                            return;
                        elseif err < 0
                            return;
                        end
                end
                if n2 ~= repNumber
                    %# repetition delay
                    tic
                    while toc<param.scanSettingsRep.repDelay
                        pause(param.scanSettingsRep.repDelay/100);
                        gui.obj.(measType).Control.update(round(toc/param.scanSettingsRep.repDelay,2),'repDelay ...');
                    end
                end
            end
    end

    %# skip button callback
    function skip(varargin)
        device.Keithley.abort();
    end

    %# cancel button callback
    function cancel(varargin)
        device.Keithley.abortAll();
        if isfield(device,'TemperatureController')
            device.TemperatureController.startRamp(0);
        end
    end

    function err = mIV(param)
        err = device.Keithley.setOutputState();
        if param.scanSettings.activeDarkIV
            param.illuminationType = 'dark';
            if param.scanSettings.activeDirectionF
                param.scanDirection = 'forward';
                err = measure_IV(param,log);
                if err
                    return;
                end
            end

            if param.scanSettings.activeDirectionB
                param.scanDirection = 'backward';
                err = measure_IV(param,log);
                if err
                    return;
                end
            end
        end

        if ~param.scanSettingsStab.shutterConnected && ~param.scanSettingsRep.repActive && param.scanSettings.activeDarkIV
            choice = questdlg('Remove the cover of the lamp!', 'IV measurement in light', ...
            'Done','Abort','Abort');
        
            % Handle response
            switch choice
                case 'Done'
                case 'Abort'
                    err = 99;
                    return;
            end
        end
        if param.scanSettings.activeLightIV
            param.illuminationType = 'light';
            gui.obj.summary.reset([param.illuminationType,'IV']);
            if param.scanSettings.activeDirectionF
                param.scanDirection = 'forward';
                err = measure_IV(param,log);
                if err
                    return;
                end
            end

            if param.scanSettings.activeDirectionB
                param.scanDirection = 'backward';
                err = measure_IV(param,log);
                if err
                    return;
                end
            end
        end
    end

    function err = mTRP(param)
        err = 0;
        data.trp = struct();
        if param.scanSettings.activeDarkIV
            param.illuminationType = 'dark';
            err = measure_TRP(param,log);
            if err
                return;
            end
        end
        
%         if ~param.scanSettingsStab.shutterConnected
%             choice = questdlg('Remove the cover of the lamp!', 'IV measurement in light', ...
%             'Done','Abort','Abort');
%         
%             % Handle response
%             switch choice
%                 case 'Done'
%                 case 'Abort'
%                     err = 99;
%                     return;
%             end
%         end
        if param.scanSettings.activeLightIV
            param.illuminationType = 'light';
            err = measure_TRP(param,log);
            if err
                return;
            end
        end
    end

    function err = mTRS(param)
        err = 0;
        data.trs = struct();
        if param.scanSettings.activeDarkIV
            param.illuminationType = 'dark';

            if param.scanSettings.activeDirectionF
                param.scanDirection = 'forward';
                err = measure_TRS(param,log);
                if err
                    return;
                end
            end

            if param.scanSettings.activeDirectionB
                param.scanDirection = 'backward';
                err = measure_TRS(param,log);
                if err
                    return;
                end
            end
        end
        
%         if ~param.scanSettingsStab.shutterConnected
%             choice = questdlg('Remove the cover of the lamp!', 'IV measurement in light', ...
%             'Done','Abort','Abort');
%         
%             % Handle response
%             switch choice
%                 case 'Done'
%                 case 'Abort'
%                     err = 99;
%                     return;
%             end
%         end
        if param.scanSettings.activeLightIV
            param.illuminationType = 'light';

            if param.scanSettings.activeDirectionF
                param.scanDirection = 'forward';
                err = measure_TRS(param,log);
                if err
                    return;
                end
            end

            if param.scanSettings.activeDirectionB
                param.scanDirection = 'backward';
                err = measure_TRS(param,log);
                if err
                    return;
                end
            end
        end
    end

    function err = mCycle(param)
        data.cycle = struct();
%         if param.scanSettings.activeDarkIV
%             param.illuminationType = 'dark';
%             err = measure_cycle(param,log);
%             if err
%                 return;
%             end
%         end
        
%         if ~param.scanSettingsStab.shutterConnected
%             choice = questdlg('Remove the cover of the lamp!', 'IV measurement in light', ...
%             'Done','Abort','Abort');
%         
%             % Handle response
%             switch choice
%                 case 'Done'
%                 case 'Abort'
%                     err = 99;
%                     return;
%             end
%         end
        if param.scanSettings.activeLightIV
            param.illuminationType = 'light';
            err = measure_cycle(param,log);
            if err
                return;
            end
        end
    end

    function err = mMPP(param)
        data.mpp = struct();
        err = measure_MPP(param,log);
        if err
            return;
        end
    end
end