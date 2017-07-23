function [guiObj,newObj] = newIVTab(parent,fontsize,style,log)
    %# struct for public obj functions and variables
    newObj = struct();
    
    guiObj.main = uitab('parent',parent,'title','IV');
%     [guiObj.Selection,newObj.Selection] = newSelection(guiObj.main,[5 155],fontsize,style,log);
    [guiObj.CellDescription,newObj.CellDescription] = newCellDescription(guiObj.main,fontsize,style,'position',[5 55]);
%     [guiObj.Filename,newObj.Filename] = newFilename(guiObj.main,fontsize,style,'position',[5 55 652]);
    
    %# scan settings
    [guiObj.ScanSettingsMain,newObj.ScanSettingsMain] = newIVScanSettingsMain(guiObj.main,[5 595],fontsize,style,log);
    [guiObj.ScanSettingsStabilization,newObj.ScanSettingsStabilization] = newIVScanSettingsStabilization(guiObj.main,[5 490],fontsize,style,log);
    [guiObj.ScanSettingsRep,newObj.ScanSettingsRep] = newIVScanSettingsRep(guiObj.main,[5 415],fontsize,style,log);
    
    [guiObj.ScanSettingsAdv,newObj.ScanSettingsAdv] = newIVScanSettingsAdv(guiObj.main,[330 260],fontsize,style,log);

    %# control buttons (START STOP SKIP) and progress
    [guiObj.Control,newObj.Control] = objControl(guiObj.main,[5 5 650],fontsize,style,log,'controlIVLite');

    %# plot graphs
    [guiObj.Plot,newObj.Plot] = objPlot(guiObj.main,fontsize,style,'position',[665 250 600 450],'name','Preview');
end

