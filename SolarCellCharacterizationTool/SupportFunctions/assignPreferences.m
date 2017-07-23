function [default_var_dir, default_var_Namedata, default_var_assignment, default_chk_GeneratorFlag, default_chk_ExtraFlag] = assignPreferences(preferences, PrefsCheck)
%ASSIGNPREFERENCES Summary of this function goes here
%   Detailed explanation goes here
    if PrefsCheck
        default_var_dir   = preferences{strcmp(preferences(:,1),'default_var_dir'),2};
        default_chk_GeneratorFlag = str2double(preferences{strcmp(preferences(:,1),'default_chk_GeneratorFlag'),2});
        default_chk_ExtraFlag = str2double(preferences{strcmp(preferences(:,1),'default_chk_ExtraFlag'),2});
        
        default_filter     = eval(preferences{strcmp(preferences(:,1),'default_trigger'),2});
        default_filter_format = eval(preferences{strcmp(preferences(:,1),'default_trigger_format'),2});
        default_definition  = eval(preferences{strcmp(preferences(:,1),'default_definition'),2});
        default_filter_assignment =  eval(preferences{strcmp(preferences(:,1),'default_trigger_assignment'),2});
        default_filter_assignment_temp(:,1) = cellfun(@(s) {logical(str2double(s))},default_filter_assignment(:,1));
        default_var_assignment_names = default_filter(cell2mat(default_filter_assignment_temp));
        default_var_assignment_values = cell(size(default_var_assignment_names,1),1);
        for i=1:size(default_var_assignment_names,1)
           default_var_assignment_values(i) = preferences(strcmp(preferences(:,1),default_var_assignment_names{i,1}),2); 
        end

        default_var_Namedata    = horzcat(default_filter,default_definition,default_filter_format,default_filter_assignment_temp);
        default_var_assignment  = horzcat(default_var_assignment_names,default_var_assignment_values);

    else
        default_var_dir     = '../Daten/';
        default_chk_GeneratorFlag = 0;
        default_chk_ExtraFlag = 0;

        default_filter          = {'uGroup';'Batch';'Cell';'HTM';'Time [min]';'Temperatur [°C]';'F';'Pixel';'Transparency';'Diode [V]';'Bias [V]';'';'';'';'';'';'';'';'';'';'';'';'';'';'';'';'';'';'';'';''};
        default_filter_format   = {'numeric';'bank';'numeric';'numeric';'numeric';'numeric';'numeric';'char';'char';'numeric';'numeric';'';'';'';'';'';'';'';'';'';'';'';'';'';'';'';'';'';'';'';''};
        default_definition      = {'G[0-9]*';'E[0-9]*';'[0-9]*';'P[0-9]*';'t[0-9]*';'T[0-9]*';'F[0-9]*';'[LMR]';'[Ss][BbFf]';'Diode';'Bias';'';'';'';'';'';'';'';'';'';'';'';'';'';'';'';'';'';'';'';''};
        default_filter_assignment={'0';'0';'0';'1';'0';'0';'1';'0';'0';'0';'0';'0';'0';'0';'0';'0';'0';'0';'0';'0';'0';'0';'0';'0';'0';'0';'0';'0';'0';'0';'0'};
        default_filter_assignment_temp(:,1) = cellfun(@(s) {logical(str2double(s))},default_filter_assignment(:,1));
        default_var_assignment_names = default_filter(cell2mat(default_filter_assignment_temp));
        default_var_assignment_values(1,1) = {'none,P3HTPCPDTBT,CuSCN,P3HT,MDMO-PPV,DEL5N,P3HTPCBM,PTB7,PCPDTBT,PBDTTT-CT,spiro-OMeTAD,WO3,PEDOT'}; 
        default_var_assignment_values(2,1) = {'none,,P3HT,MP4'};

        default_var_Namedata    = horzcat(default_filter,default_definition,default_filter_format,default_filter_assignment);
        default_var_assignment  = horzcat(default_var_assignment_names,default_var_assignment_values);

        savePreferences(default_var_dir,default_chk_GeneratorFlag,default_chk_ExtraFlag,default_var_Namedata,default_var_assignment,7+size(default_var_assignment,1));
    end
end

