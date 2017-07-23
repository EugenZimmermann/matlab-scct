function [guiObj,newObj] = newFilename(parent,fontsize,style,varargin) 
    input = inputParser;
    addRequired(input,'parent');
    addRequired(input,'fontsize',@(x) isstruct(x) && isfield(x,'general'));
    addRequired(input,'style',@(x) isstruct(x) && isfield(x,'color'));
    addParameter(input,'name','Filename',@(x) ischar(x));
    addParameter(input,'position',[5 5 450 75],@(x) isnumeric(x) && length(x)<=3 && length(x)>=2 && min(size(x))==1);
    parse(input,parent,fontsize,style,varargin{:});

    %# data elements
    newObj = struct();
    
    %# current filename
    filename = '';
    
    position = input.Results.position;
    %# switch between different postition lengths
    switch length(position)
        case 2
            position = [position(1) position(2) 450 75];
        case 3
            position = [position(1) position(2) position(3) 75];
    end
    
    %# gui elements of device
    guiObj.MainPanel = gui_panel(parent,position,input.Results.name,fontsize.general,'');
        guiObj.varFilename = gui_var(guiObj.MainPanel,[5 5 position(3)-12 position(4)-30],'current filename','center',fontsize.bigtext,'varFilename',@onChangeFilename);
            set(guiObj.varFilename,'ForegroundColor',style.color{13},'BackgroundColor',style.color{end});

    %# device functions
    newObj.reset = @reset;
    newObj.getSettings = @getSettings;
    
    reset();

    function reset()
        filename = '';
        guiObj.varFilename.String = filename;
        guiObj.varFilename.ForegroundColor = con_a_b(isempty(filename),style.color{13},style.color{11});
    end

    function settings = getSettings()
        settings.filename = filename;
    end

    function onChangeFilename(hObject,varargin)
        [status,result] = check_string(hObject.String,'filename');
        hObject.String = con_a_b(status,result,filename);
        hObject.ForegroundColor = con_a_b(isempty(hObject.String),style.color{13},style.color{11});
        
        filename = con_a_b(status,result,filename);
    end
end

