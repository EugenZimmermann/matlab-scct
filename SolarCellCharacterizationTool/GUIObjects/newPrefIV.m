function [guiObj,newObj] = newPrefIV(parent,position,fontsize,style,log)    
    
    %# data elements of device
    newObj = struct();
    
    %# fallback values in case preference file is broken
    newObj.defaultS.ID = 'IV'; % !!! ALSO NAME OF GUI ELEMENTS AND SETTINGSFILE
    newObj.defaultS.delayTimeV = '0.01'; %s 0 to 9999.999
    newObj.defaultS.IntegrationRateV = '1'; %s 0.01 to 10
    newObj.defaultS.minV = '-0.5'; %V
    newObj.defaultS.maxV = '1.0'; %V
    newObj.defaultS.stepsizeV = '0.01'; %V
%     newObj.defaultS.repNumber = '1'; %Number of repetitions
%     newObj.defaultS.repDelay = '0'; %s
%     newObj.defaultS.lsTime = 300;
%     newObj.defaultS.activeSPP = '0' ;
%     newObj.defaultS.activeSMPP = '0';
%     newObj.defaultS.activeVMPP = '0';
%     newObj.defaultS.sppV = '-1' ;
%     newObj.defaultS.smppV = '-1';
%     newObj.defaultS.vmppV = '-1';
%     newObj.defaultS.sppDuration = '0.01' ;
%     newObj.defaultS.sppDelay = '0.01' ;
%     newObj.defaultS.smppRatio = '1' ;
%     newObj.defaultS.vmppRatio = '1' ;
% %     device_obj.defaultS.specialsetting = '0';
%     newObj.defaultS.activeTRP = '0';
%     newObj.defaultS.trpVolt1 = '1';
%     newObj.defaultS.trpVolt2 = '0';
%     newObj.defaultS.trpTime1 = '1';
%     newObj.defaultS.trpTime2 = '3';
%     newObj.defaultS.trpTimeStep = '0.01';
%     newObj.defaultS.activeCycle = '0';
%     newObj.defaultS.activeCycleGetPoint = '1';
% %     device_obj.defaultS.cyclegetinfo = '0';
%     newObj.defaultS.cycleMPPV = '0.4';
%     newObj.defaultS.cycleVOC = '0.9';
%     newObj.defaultS.activeMPP = '0';
%     newObj.defaultS.mppDuration = '5';
%     newObj.defaultS.activeTRS = '0';
%     newObj.defaultS.trsDuration = '1';
%     newObj.defaultS.trsDelay = '0.001';
    
    %# gui elements of device
    position = [position(1) position(2) 210 165];
    guiObj.Panel = gui_panel(parent,position,newObj.defaultS.ID,fontsize.general,['uiStatus',newObj.defaultS.ID]); 
            
        DeviceColumns     = {'Variable', 'Value'};
        DeviceFormat      = {'bank', 'bank'};
        DeviceEditable    = [false, true];
        DeviceColumnWidth = {99,99};
        guiObj.table  = gui_table(guiObj.Panel,[5 5 position(3)-10 position(4)-30],DeviceColumns,DeviceFormat,DeviceColumnWidth,DeviceEditable,[],['table',newObj.defaultS.ID],{@onTableEdit});
       
	%# create menupoint
    guiObj.menu = uimenu(ancestor(parent,'figure','toplevel'),'Label',newObj.defaultS.ID,'ForegroundColor',style.color{end});
        guiObj.loadPrefs = uimenu(guiObj.menu,'Label','load preferences','Callback',@loadSettings);
        guiObj.savePrefs = uimenu(guiObj.menu,'Label','save preferences','Callback',@saveSettings);
        guiObj.reset = uimenu(guiObj.menu,'Label','reset','ForegroundColor','red','Callback',@reset);
        
    %# device functions
    newObj.reset = @reset;
    newObj.getSettings = @getSettings;
                      
    function reset()
        loadSettings();
        
        table_fields = fieldnames(newObj.default);
        table_variables = cellfun(@(s) num2str(s),struct2cell(newObj.default),'UniformOutput',false);
        table_data = horzcat(table_fields,table_variables);
        guiObj.table.Data = table_data;
    end

    function settings = getSettings()
        settings = cell2struct(guiObj.table.Data(:,2),fieldnames(newObj.default),1);
        settings.delayTimeV = str2double(settings.delayTimeV);
        settings.IntegrationRateV = str2double(settings.IntegrationRateV);
        settings.minV = str2double(settings.minV);
        settings.maxV = str2double(settings.maxV);
        settings.stepsizeV = str2double(settings.stepsizeV);
%         settings.repNumber = str2double(settings.repNumber);
%         settings.repDelay = str2double(settings.repDelay);
%         settings.activeSPP = str2double(settings.activeSPP);
%         settings.activeSMPP = str2double(settings.activeSMPP);
%         settings.activeVMPP = str2double(settings.activeVMPP);
%         settings.sppV = str2double(settings.sppV);
%         settings.smppV = str2double(settings.smppV);
%         settings.vmppV = str2double(settings.vmppV);
%         settings.sppDuration = str2double(settings.sppDuration);
%         settings.sppDelay = str2double(settings.sppDelay);
%         settings.smppRatio = str2double(settings.smppRatio);
%         settings.vmppRatio = str2double(settings.vmppRatio);
% %         settings.specialsetting = eval(settings.specialsetting);
%         settings.activeTRP = str2double(settings.activeTRP);
%         settings.trpVolt1 = str2double(settings.trpVolt1);  
%         settings.trpVolt2 = str2double(settings.trpVolt2);  
%         settings.trpTime1 = str2double(settings.trpTime1);  
%         settings.trpTime2 = str2double(settings.trpTime2);  
%         settings.trpTimeStep = str2double(settings.trpTimeStep);  
%         settings.activeCycle = str2double(settings.activeCycle);
%         settings.activeCycleGetPoint = str2double(settings.activeCycleGetPoint);
% %         settings.cyclegetinfo = eval(settings.cyclegetinfo);
%         settings.cycleMPPV = str2double(settings.cycleMPPV);
%         settings.cycleVOC = str2double(settings.cycleVOC);
%         settings.activeMPP = str2double(settings.activeMPP);
%         settings.mppDuration = str2double(settings.mppDuration);
%         settings.activeTRS = str2double(settings.activeTRS);
%         settings.trsDuration = str2double(settings.trsDuration);
%         settings.trsDelay = str2double(settings.trsDelay);
    end

    function loadSettings()
        try
            [pref_temp,pref_err] = loadPreferences(newObj.defaultS.ID,log);
            if pref_err
                log.update(['Loading preferences failed. File not existing or damaged. Creating new preference file for ',guiObj.defaultS.ID,' ...'])
                newObj.default = newObj.defaultS;
                savePreferences(newObj.defaultS.ID,newObj.defaultS);
                log.update(['Creating ',newObj.defaultS.ID,'.ini done.'])
            else
                newObj.default = pref_temp;
            end
        catch error
            log.update(error.message)
            newObj.default = newObj.defaultS;
            savePreferences(newObj.defaultS.ID,newObj.defaultS);
        end
    end

    function saveSettings()
        savePreferences(newObj.defaultS.ID,getSettings());
    end

    function onTableEdit(hObject,action)
        temp = hObject.Data;  
        switch(temp{action.Indices(1),1})
            case 'ID'
                hObject.Data(action.Indices(1),action.Indices(2)) = {action.PreviousData};
                disp('don''t mess with this one')
            case 'delayTimeV'
                [result,status] = check_value(action.NewData,0,3600);
                hObject.Data(action.Indices(1),action.Indices(2)) = con_a_b(status,{num2str(result)},{action.PreviousData});
            case 'IntegrationRateV'
                [result,status] = check_value(action.NewData,0.01,10);
                hObject.Data(action.Indices(1),action.Indices(2)) = con_a_b(status,{num2str(result)},{action.PreviousData});
            case {'minV','maxV'}
                ind_min = find(ismember(hObject.Data(:,1),'minV'));
                ind_max = find(ismember(hObject.Data(:,1),'maxV'));
                
            	[result_min,status_min] = check_value(hObject.Data(ind_min,2),-10,10);
                [result_max,status_max] = check_value(hObject.Data(ind_max,2),-10,10);

                if status_min && status_max && result_min<result_max
                    hObject.Data(ind_min,2) = {num2str(result_min)};
                    hObject.Data(ind_max,2) = {num2str(result_max)};
                else
                    if result_min>result_max
                        errordlg('Start voltage has to be smaller than end voltage. Adjust scan-direction with buttons.', 'Error')
                    end
                    hObject.Data(action.Indices(1),action.Indices(2)) = {action.PreviousData};
                end
             case {'cycleMPPV','cycleVOC'}
                ind_min = find(ismember(hObject.Data(:,1),'cycleMPPV'));
                ind_max = find(ismember(hObject.Data(:,1),'cycleVOC'));
                
            	[result_min,status_min] = check_value(hObject.Data(ind_min,2),-10,10);
                [result_max,status_max] = check_value(hObject.Data(ind_max,2),-10,10);

                if status_min && status_max && result_min<result_max
                    hObject.Data(ind_min,2) = {num2str(result_min)};
                    hObject.Data(ind_max,2) = {num2str(result_max)};
                else
                    if result_min>result_max
                        errordlg('MPP voltage has to be smaller than VOC voltage. Adjust scan-direction with buttons.', 'Error')
                    end
                    hObject.Data(action.Indices(1),action.Indices(2)) = {action.PreviousData};
                end   
                
            case 'stepsizeV'
                [result,status] = check_value(action.NewData,0.00001,2);
                hObject.Data(action.Indices(1),action.Indices(2)) = con_a_b(status,{num2str(result)},{action.PreviousData});
            case 'repNumber'
                [result,status] = check_value(action.NewData,1,3600);
                hObject.Data(action.Indices(1),action.Indices(2)) = con_a_b(status,{num2str(result)},{action.PreviousData});
            case 'repDelay'
                [result,status] = check_value(action.NewData,0,3600);
                hObject.Data(action.Indices(1),action.Indices(2)) = con_a_b(status,{num2str(result)},{action.PreviousData});        
            case {'activeSPP','activeSMPP','activeVMPP','specialsetting','activeTRP','activeCycle','activeCycleGetPoint','cyclegetinfo','activeTRS'} %########## MM ############
                temp_port = regexpi(action.NewData,'(^true|^false|^[0-9])','match'); 	%(EZ: hier hab ich die möglichkeit geschaffen in der Tabelle entweder über 0/1 oder über true/false es zu aktivieren)
                if ~isempty(regexpi(action.NewData,'(^true|^false)','match')) 			%(EZ: regexp sucht dabei in der Eingabe, ob true, false oder eine Zahl vorhanden ist)
                    hObject.Data(action.Indices(1),action.Indices(2)) = lower(temp_port);
                elseif ~isempty(regexpi(action.NewData,'^[0-9]','match'))
                    [result,status] = check_value(temp_port,0,1);
                    if status
                        result = round(result);
                        hObject.Data(action.Indices(1),action.Indices(2)) = {con_a_b(result,'true','false')};
                    else
                        hObject.Data(action.Indices(1),action.Indices(2)) = {action.PreviousData};
                    end
                else
                    hObject.Data(action.Indices(1),action.Indices(2)) = {action.PreviousData};
                    errordlg('Settings can be ''true/1'' or ''false/0''.', 'Error')
                end    
            case {'sppV','smppV','vmppV','trpVolt1','trpVolt2'} %########## MM ############
                [result,status] = check_value(action.NewData,-5,5);
                hObject.Data(action.Indices(1),action.Indices(2)) = con_a_b(status,{num2str(result)},{action.PreviousData});
            case {'sppDuration'} %########## MM ############
                [result,status] = check_value(action.NewData,0.0001,100);
                hObject.Data(action.Indices(1),action.Indices(2)) = con_a_b(status,{num2str(result)},{action.PreviousData});
            case {'sppDelay','trpTime1','trpTime2','trsDelay'} %########## MM ############
                [result,status] = check_value(action.NewData,0,60);
                hObject.Data(action.Indices(1),action.Indices(2)) = con_a_b(status,{num2str(result)},{action.PreviousData}); 
            case {'trpTimeStep','trsDuration','mppDuration'}
                [result,status] = check_value(action.NewData,0,1000);
                hObject.Data(action.Indices(1),action.Indices(2)) = con_a_b(status,{num2str(result)},{action.PreviousData});
            otherwise
                log.update(['Unknown variable in ',newObj.defaultS.ID,' prefs.'])
        end
        saveSettings();
    end
end
