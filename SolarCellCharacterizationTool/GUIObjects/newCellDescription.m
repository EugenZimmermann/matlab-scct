function [guiObj,newObj] = newCellDescription(parent,fontsize,style,varargin)
    input = inputParser;
    addRequired(input,'parent');
    addRequired(input,'fontsize',@(x) isstruct(x) && isfield(x,'general'));
    addRequired(input,'style',@(x) isstruct(x) && isfield(x,'color'));
    addParameter(input,'name','Filename',@(x) ischar(x));
    addParameter(input,'position',[5 5 450 75],@(x) isnumeric(x) && length(x)<=3 && length(x)>=2 && min(size(x))==1);
    parse(input,parent,fontsize,style,varargin{:});
    
    %# data elements of device
    newObj = struct();
    
    %# fallback values in case preference file is broken
    newObj.defaultS.ID = 'Cell Description'; % !!! ALSO NAME OF GUI ELEMENTS
	
    user = '';
    names = '';
    groupDescription = '';
    groupNumber = '';
    
    position = input.Results.position;
    %# switch between different postition lengths
    switch length(position)
        case 2
            position = [position(1) position(2) 320 100];
        case 3
            position = [position(1) position(2) position(3) 100];
    end
    
    %# gui elements of device
    guiObj.Panel = gui_panel(parent,position,newObj.defaultS.ID,fontsize.general,'');
        guiObj.varUser = gui_var(guiObj.Panel,[5 40 position(3)-13 30],'filename (no special characters)','center',fontsize.general,'varUser',@onChangeUser);
            set(guiObj.varUser,'ForegroundColor',style.color{13},'BackgroundColor',style.color{end},'FontWeight','bold');
        guiObj.varGroup = gui_var(guiObj.Panel,[5 5 position(3)-70 30],'comment/group for later analysis','center',fontsize.general,'varGroup',@onChangeGroup);
            set(guiObj.varGroup,'ForegroundColor',style.color{13},'BackgroundColor',style.color{end},'FontWeight','bold');
        guiObj.varGroupNr = gui_var(guiObj.Panel,[position(3)-60 5 52 30],'group number','center',fontsize.general,'varGroupNr',@onChangeGroupNr);
            set(guiObj.varGroupNr,'ForegroundColor',style.color{13},'BackgroundColor',style.color{end},'FontWeight','bold');
            
    %# device functions
    newObj.reset = @reset;
    newObj.getSettings = @getSettings;
    newObj.getNames = @getNames;
    newObj.getGroups = @getGroups;
    newObj.setNames = @setNames;
    
    reset();
    
    function reset()
        user = 'UnknownSample';
            guiObj.varUser.String = user;
            onChangeUser(guiObj.varUser)
            
        groupDescription ='Group1';
            guiObj.varGroup.String = groupDescription;
            onChangeGroup(guiObj.varGroup)
            
        groupNumber = 1;
            guiObj.varGroupNr.String = num2str(groupNumber);
            onChangeGroupNr(guiObj.varGroupNr)
    end

    function settings = getSettings()
        settings.user = user;
        settings.names = names;
        settings.groupDescription = groupDescription;
        settings.groupNumber = groupNumber;
    end

    function onChangeUser(hObject,varargin)
        [status,result] = check_string(hObject.String,'filename');
        user = con_a_b(status,result,user);
            names = cellfun(@(s) user, cell(3,1),'UniformOutput',false);
            hObject.String = user;
            hObject.ForegroundColor = con_a_b(isempty(hObject.String),style.color{13},style.color{11});
    end

    function onChangeGroup(hObject,varargin)
        [status,result] = check_string(hObject.String,'filename');
        groupDescription = con_a_b(status,result,groupDescription);
            hObject.String = groupDescription;
            hObject.ForegroundColor = con_a_b(isempty(hObject.String),style.color{13},style.color{11});
    end

    function onChangeGroupNr(hObject,varargin)
        [result,status] = check_value(hObject.String,0,999);
        groupNumber = con_a_b(status,result,groupNumber);
            hObject.String = num2str(groupNumber);
            hObject.ForegroundColor = con_a_b(isempty(hObject.String),style.color{13},style.color{11});
    end
end
