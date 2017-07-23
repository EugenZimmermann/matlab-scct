function header = analyze_IV(header,voltage,currentdensity,log)
%ANALYZEIV Summary of this function goes here
%   Detailed explanation goes here
    if ~isfield(header,'Type')
        log.update('Field "Type" not found in header! Analysis skipped.')
        return;
    end

    % make spline interpolation for smooth point distribution (more exact calculations)
    stepSize = 0.001;
    voltage_temp = (min(voltage):stepSize:max(voltage))';
    new_currentdensity = interp1(voltage,currentdensity,voltage_temp,'spline');
    voltage = voltage_temp;
    
    differ = max(voltage)-min(voltage);
    countstep = differ./stepSize;
    d = round(countstep/10);
    
    [~,JSC_ind] = min(abs(voltage));
    header.('JSC') = new_currentdensity(JSC_ind);
    
    switch header.Type
        case {'lightIV','advLightIV','lightTRSIV'}
            [~,VOC_ind] = min(abs(new_currentdensity));
            header.('VOC') = min(voltage(VOC_ind));

            power = voltage.*new_currentdensity;
            [header.('mpp'),mpp_ind] = max(power);
            header.('mppV') = voltage(mpp_ind);
            header.('mppJ') = new_currentdensity(mpp_ind);

            header.('FF') = (header.('mpp'))./(header.('VOC').*header.('JSC'))*100;
    
            if isfield(header,'LI')
                header.('PCE') = header.('mpp')/header.LI*100;
            elseif isfield(header,'lightintensity')
                header.('PCE') = header.('mpp')/header.lightintensity*100;
            end
    end
    
    %# analyze electric resistance 
    % make average over the first/last fifth of the measuerpoints if change 5 if you want to increase or decrease averige building
    fvF = voltage(1:JSC_ind);
    fcF = new_currentdensity(1:JSC_ind);
    
    % fit line to data
    [c_fit_Rsh,~,err_Rsh] = polyfit(fvF,fcF,1);
   	c_tempRsh = c_fit_Rsh(1).*fvF+c_fit_Rsh(2); % generate curve out of fitparameters
    e = err_Rsh(2); % extract std
    
    % if std is bigger than 0.1 and there are remaining points
    while e>0.1 && ~isempty(fvF)
        c_abs = abs(fcF-c_tempRsh); % abs value of the difference
        c_conarea = bwconncomp(c_abs<median(c_abs)); % get median of values 
        [~,max_ind] = max(cellfun(@(s) length(s),c_conarea.PixelIdxList)); % find biggest connected area

        % restrict current and voltage to "better" fitting values
        fvF = fvF(c_conarea.PixelIdxList{max_ind});
        fcF = c_tempRsh(c_conarea.PixelIdxList{max_ind});
        
        % repeat fit
        [c_fit_Rsh,~,err_Rsh] = polyfit(fvF,fcF,1);
        c_tempRsh = c_fit_Rsh(1).*fvF+c_fit_Rsh(2);
        e = err_Rsh(2);
    end
    header.('Rsh') = 1/abs(c_fit_Rsh(1));
        
    lvF = voltage(end-d:end); % last measurepoints
    lcF = new_currentdensity(end-d:end);
    
    % fit line to data
    c_fit_Rs = polyfit(lvF,lcF,1);
%    	c_tempRs = c_fit_Rs(1).*lvF+c_fit_Rs(2);
    header.('Rs') = 1/abs(c_fit_Rs(1));
end

