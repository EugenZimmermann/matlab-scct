function [newObj,guiObj] = newPrefGeneral(parent,varargin)
    input = inputParser;
    addRequired(input,'parent');
    addParameter(input,'fontsize',0,@(x) isstruct(x) && isfield(x,'general'));
    addParameter(input,'style',0,@(x) isstruct(x) && isfield(x,'color'));
    addParameter(input,'name','General',@(x) ischar(x) && ~isempty(x));
    addParameter(input,'position',[5 5],@(x) isnumeric(x) && length(x)==2);
    addParameter(input,'log','',@(x) isstruct(x) && isfield(x,'update'));
    parse(input,parent,varargin{:});
    
    try
        if ~isstruct(input.Results.log)
            log.update = @objLogFallback;
            log.update('Log not specified. Use fallback.');
        else
            log = input.Results.log;
        end
    catch e
        disp(e.message)
        log.update = @(x) disp(x);
    end
    
    name = input.Results.name(1:min(length(input.Results.name),20));
    
    position = input.Results.position;
    fontsize = input.Results.fontsize;
    style = input.Results.style;
	
    % data elements of device
    newObj = struct();
    
    % fallback values in case preference file is broken
    newObj.defaultS.DefaultDir = 'C:\data\';
    newObj.defaultS.SiISC = '1.575'; %s 0.01 to 10
    newObj.defaultS.CalibrationAverages = '50';
    newObj.defaultS.ActiveArea = '0.125'; %V
    newObj.defaultS.activeLightIV = '1';
    newObj.defaultS.activeDirectionF = '1'; % forward scan
    newObj.defaultS.activeDirectionB = '0'; % backward scan
    newObj.defaultS.activeDarkIV = '1';
    newObj.defaultS.activeGeometry = 'inverted'; %1==inverted; 0==regular
    newObj.defaultS.activeIllumination = 'front'; %1=front; 0==back
    newObj.defaultS.lsTime = 5; %s
    newObj.defaultS.vsTime = 5; %s
    newObj.defaultS.atmosphere = 'N2';
    
    %# gui elements of device
    position = [position(1) position(2) 210 305];
    guiObj.Panel = gui_panel(parent,position,name,fontsize.general,['uiStatus',name]);
        DeviceColumns     = {'Variable', 'Value'};
        DeviceFormat      = {'bank', 'bank'};
        DeviceEditable    = [false, true];
        DeviceColumnWidth = {99,99};
        guiObj.table  = gui_table(guiObj.Panel,[5 5 position(3)-10 position(4)-30],DeviceColumns,DeviceFormat,DeviceColumnWidth,DeviceEditable,[],['table',name],{@onTableEdit});
        
    %# obj functions
    newObj.reset = @reset;
    newObj.getSettings = @getSettings;
    newObj.getDir = @getDir;
                      
    function reset(varargin)
        loadSettings();
        
        table_fields = fieldnames(newObj.default);
        table_variables = cellfun(@(s) num2str(s),struct2cell(newObj.default),'UniformOutput',false);
        table_data = horzcat(table_fields,table_variables);
        guiObj.table.Data = table_data;
    end

    function settings = getSettings()
        settings = cell2struct(guiObj.table.Data(:,2),fieldnames(newObj.default),1);
        settings.DefaultDir = con_a_b(strcmp(settings.DefaultDir(end),'\'),settings.DefaultDir,[settings.DefaultDir,'\']);
        settings.SiISC = str2double(settings.SiISC);
        settings.CalibrationAverages = str2double(settings.CalibrationAverages);
        settings.ActiveArea = str2double(settings.ActiveArea);
        settings.activeLightIV = str2double(settings.activeLightIV);
        settings.activeDirectionF = str2double(settings.activeDirectionF);
        settings.activeDirectionB = str2double(settings.activeDirectionB);
        settings.activeDarkIV = str2double(settings.activeDarkIV);
        settings.activeGeometry = con_a_b(ismember(settings.activeGeometry,{'1','inverted'}),1,0); %1==inverted; 0==regular
        settings.activeIllumination = con_a_b(ismember(settings.activeIllumination,{'1','front'}),1,0); %1=front; 0==back
        settings.lsTime = str2double(settings.lsTime);
        settings.vsTime = str2double(settings.vsTime);
    end

    function result_dir = getDir()
        settings = getSettings();
        result_dir = settings.DefaultDir;
    end

    function loadSettings()
        try
            [pref_temp,pref_err] = loadPreferences(name,log);
            if pref_err
                log.update(['Loading preferences failed. File not existing or damaged. Creating new preference file for ',guiObj.defaultS.ID,' ...']);
                newObj.default = newObj.defaultS;
                savePreferences(name,newObj.defaultS);
                log.update(['Creating ',name,'.ini done.']);
            else
                newObj.default = pref_temp;
            end
        catch error
            log.update(error.message)
            newObj.default = newObj.defaultS;
            savePreferences(name,newObj.defaultS);
        end
    end

    function saveSettings()
        savePreferences(name,getSettings());
    end

    function onTableEdit(hObject,action)
        temp = hObject.Data;  
        switch(temp{action.Indices(1),1})
            case 'ID'
                hObject.Data(action.Indices(1),action.Indices(2)) = {action.PreviousData};
                disp('don''t mess with this one')
            case 'DefaultDir'
                if exist(action.NewData,'dir')
                    hObject.Data(action.Indices(1),action.Indices(2)) = {action.NewData};
                else
                    %# Dialog to create folder
                    options.Interpreter = 'tex';
                    options.Default = 'Create';
                    switch questdlg('Create new folder?','Attention','Create','Cancel',options);
                        case 'Create'
                            try
                                mkdir(action.NewData);
                            catch error
                                log.update(['Couldn''t create folder: ',action.NewData])
                                log.update(error.message)
                                hObject.Data(action.Indices(1),action.Indices(2)) = {action.PreviousData};
                                return;
                            end
                            hObject.Data(action.Indices(1),action.Indices(2)) = {action.NewData};
                        case 'Cancel'
                            hObject.Data(action.Indices(1),action.Indices(2)) = {action.PreviousData};
                            return;
                    end
                end
            case {'SiISC','ActiveArea'}
                [result,status] = check_value(action.NewData,0.01,100);
                hObject.Data(action.Indices(1),action.Indices(2)) = con_a_b(status,{num2str(result)},{action.PreviousData});
            case {'activePixels'}
                [result,~,status] = check_pixel(action.NewData,1,48);
                hObject.Data(action.Indices(1),action.Indices(2)) = con_a_b(status,{num2str(result)},{action.PreviousData});
            case 'CalibrationAverages'
                [result,status] = check_value(action.NewData,1,1000);
                hObject.Data(action.Indices(1),action.Indices(2)) = con_a_b(status,{num2str(result)},{action.PreviousData});
            case {'lsTime','vsTime'}
				[result,status] = check_value(action.NewData,1,100);
                hObject.Data(action.Indices(1),action.Indices(2)) = con_a_b(status,{num2str(round(result))},{action.PreviousData});
            case {'activeLightIV','activeDirectionF','activeDirectionB','activeDarkIV','activeEQE'}
                [result,status] = check_boolean(action.NewData);
                hObject.Data(action.Indices(1),action.Indices(2)) = con_a_b(status,{num2str(result)},{action.PreviousData});
            case {'activeGeometry'}
                temp_port = regexpi(action.NewData,'(^inverted|^regular|^[0-9])','match');
                if ~isempty(regexpi(action.NewData,'(^inverted|^regular)','match'))
                    hObject.Data(action.Indices(1),action.Indices(2)) = lower(temp_port);
                elseif ~isempty(regexpi(action.NewData,'^[0-9]','match'))
                    [result,status] = check_value(temp_port,0,1);
                    if status
                        result = round(result);
                        hObject.Data(action.Indices(1),action.Indices(2)) = {con_a_b(result,'inverted','regular')};
                    else
                        hObject.Data(action.Indices(1),action.Indices(2)) = {action.PreviousData};
                    end
                else
                    hObject.Data(action.Indices(1),action.Indices(2)) = {action.PreviousData};
                    errordlg('Settings can be ''inverted/1'' or ''regular/0''.', 'Error')
                end
            case {'activeIllumination'}
                temp_port = regexpi(action.NewData,'(^front|^back|^[0-9])','match');
                if ~isempty(regexpi(action.NewData,'(^front|^back)','match'))
                    hObject.Data(action.Indices(1),action.Indices(2)) = lower(temp_port);
                elseif ~isempty(regexpi(action.NewData,'^[0-9]','match'))
                    [result,status] = check_value(temp_port,0,1);
                    if status
                        result = round(result);
                        hObject.Data(action.Indices(1),action.Indices(2)) = {con_a_b(result,'front','back')};
                    else
                        hObject.Data(action.Indices(1),action.Indices(2)) = {action.PreviousData};
                    end
                else
                    hObject.Data(action.Indices(1),action.Indices(2)) = {action.PreviousData};
                    errordlg('Settings can be ''front/1'' or ''back/0''.', 'Error')
                end
            case 'atmosphere'
                temp_port = regexpi(action.NewData,'(^N2|^Ar|^Ambient|^Vacuum)','match');
                if ~isempty(temp_port)
                    hObject.Data(action.Indices(1),action.Indices(2)) = lower(temp_port);
                else
                    hObject.Data(action.Indices(1),action.Indices(2)) = {action.PreviousData};
                    errordlg('Settings can be ''N2'', ''Ar'', or ''Ambient''.', 'Error')
                end
            otherwise
                hObject.Data(action.Indices(1),action.Indices(2)) = {action.PreviousData};
                log.update(['Unknown variable in ',name,' prefs.'])
        end
        saveSettings();
    end
end
