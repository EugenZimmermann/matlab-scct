function [default_var_dir, default_var_Namedata, default_var_assignment] = updatePreferences(var_dirPref,table_NamePrefs,default_var_assignment)
%UPDATEPREFERENCES save new Prefs in variables and refresh fields in other tabs
%   Detailed explanation goes here
    default_var_dir   = get(var_dirPref,'String');
    default_var_Namedata= get(table_NamePrefs,'Data');
    
    default_var_assignment_names = default_var_assignment(:,1);
    default_var_assignment_values = default_var_assignment(:,2);
    
    aaa = cell2mat(default_var_Namedata(:,4));
    new_default_var_assignment_names = default_var_Namedata(aaa,1);
    
    sizeNew = size(new_default_var_assignment_names,1);
    aaa_default_var_assignment_values = cell(sizeNew,1);
    for iii=1:sizeNew
        test=strcmp(default_var_assignment_names,new_default_var_assignment_names{iii,1});
        if sum(test)
%             disp('jop')
            aaa_default_var_assignment_values(iii) = default_var_assignment_values(test,1);
        end
    end

    default_var_assignment = horzcat(new_default_var_assignment_names,aaa_default_var_assignment_values);
    disp('updating preferences done')
end

