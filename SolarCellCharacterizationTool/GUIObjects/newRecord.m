function device_obj = newRecord(log)    
    
    % data elements of device
    device_obj = struct();
    
    % fallback values in case preference file is broken
    device_obj.defaultS.ID = 'Record'; % !!! ALSO NAME OF GUI ELEMENTS AND SETTINGSFILE
    device_obj.defaultS.allTimeRecord = '0'; %# highest IV performance ever
    device_obj.defaultS.allTimeRecordName = ''; %# name of cell reached highest IV performance ever
    
    expectedTypes = {'IV','EQE','LIDIV','TRP','TRS','CYCLE','PP','MPP','PEROVSKITE'};
    for n1 = 1:length(expectedTypes)
        device_obj.defaultS.(['allTime',expectedTypes{n1}]) = '0';
    end
%     device_obj.defaultS.allTimeIV = '0'; %# total number of IV measurements
%     device_obj.defaultS.allTimeEQE = '0'; %# total number of EQE measurements
%     device_obj.defaultS.allTimeLIDIV = '0'; %# total number of light dependent IV measurements
                   
    % device functions
    device_obj.reset = @reset;
    device_obj.getSettings = @getSettings;
    device_obj.updateRecord = @updateRecord;
    device_obj.update = @update;
    
    function reset()
        loadSettings();
    end

    function settings = getSettings()
        settings = device_obj.default;
        settings.allTimeRecord = str2double(settings.allTimeRecord);
        settings.allTimeRecordName = settings.allTimeRecordName;
        for n2 = 1:length(expectedTypes)
            settings.(['allTime',expectedTypes{n2}]) = str2double(settings.(['allTime',expectedTypes{n2}]));
        end
%         settings.allTimeIV = str2double(settings.allTimeIV);
%         settings.allTimeEQE = str2double(settings.allTimeEQE);
%         settings.allTimeLIDIV = str2double(settings.allTimeLIDIV);
    end

    function loadSettings()
        try
            [pref_temp,pref_err] = loadPreferences(device_obj.defaultS.ID,log);
            if pref_err
                log.update(['Loading preferences failed. File not existing or damaged. Creating new preference file for ',device_obj.defaultS.ID,' ...'])
                device_obj.default = device_obj.defaultS;
                savePreferences(device_obj.defaultS.ID,device_obj.defaultS);
                log.update(['Creating ',device_obj.defaultS.ID,'.ini done.'])
            else
                device_obj.default = pref_temp;
            end
        catch error
            log.update(error.message)
            device_obj.default = device_obj.defaultS;
            savePreferences(device_obj.defaultS.ID,device_obj.defaultS);
        end
    end

    function saveSettings()
        savePreferences(device_obj.defaultS.ID,getSettings());
    end

    function updateRecord(record_value,record_name)
        device_obj.default.allTimeRecord = num2str(record_value);
        device_obj.default.allTimeRecordName = num2str(record_name);
        saveSettings()
    end

    function update(value,type)
        input = inputParser;
        addRequired(input,'value',@(x) isnumeric(x) && isscalar(x) && x>0);
        addRequired(input,'type',@(x) any(validatestring(upper(x),expectedTypes)));
        parse(input,value,type)
    	device_obj.default.(['allTime',upper(type)]) = num2str(str2double(device_obj.default.(['allTime',upper(type)]))+value);
    	saveSettings()
    end
end
