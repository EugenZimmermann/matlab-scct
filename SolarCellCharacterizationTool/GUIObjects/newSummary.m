function [guiObj,newObj] = newSummary(parent,fontsize,style,varargin)

    %# check input
    if isa(parent,'matlab.ui.container.TabGroup')
        possible_gui = {'Panel','Window','Tab'};
    else
        possible_gui = {'Panel','Window'};
    end
    
    possible_types = {'lightIV','darkIV','advIV','TRP','TRS','MPP','EQE','advEQE','LID'};
    
    input = inputParser;
    addRequired(input,'parent');
    addRequired(input,'fontsize',@(x) isstruct(x) && isfield(x,'general'));
    addRequired(input,'style',@(x) isstruct(x) && isfield(x,'color'));
    addParameter(input,'pixels',48,@(x) validateattributes(x,{'numeric'},{'nonempty','scalar','nonnan','positive'}));
    addParameter(input,'name','Summary',@(x) ischar(x));
    addParameter(input,'guiStyle','Panel',@(x) any(validatestring(x,possible_gui)));
    addParameter(input,'types',{'lightIV','darkIV'},@(x) validateattributes(x,{'cell'},{'nonempty'}));
    addParameter(input,'log',struct(),@(x) isstruct(x) && isfield(x,'update'));
    addParameter(input,'position',[5 5 1260 285],@(x) isnumeric(x) && length(x)<=4 && length(x)>=2 && min(size(x))==1);
    parse(input,parent,fontsize,style,varargin{:});
    
    parent = input.Results.parent;
    fontsize = input.Results.fontsize;
    style = input.Results.style;
    pixels = input.Results.pixels;
    name = input.Results.name;
    guiStyle = input.Results.guiStyle;
    position = input.Results.position;
    
    if isfield(input.Results.log,'update')
        log = input.Results.log;
    else
        log.update = @objLogFallback;
    end
    
    %# switch between different postition lengths
    switch length(position)
        case 2
            position = [position(1) position(2) 1260 285];
        case 3
            position = [position(1) position(2) position(3) 285];
        case 4
            position = [position(1) position(2) position(3) position(4)];
    end
    position = [position(1) position(2) max(position(3),400) max(position(4),200)];
    
    %# struct for public obj functions and variables
    newObj = struct();
    
    %# private obj variables
    [nameStatus,tempName] = check_string(name,'filename');
    name = con_a_b(nameStatus,tempName,'Summary');

    %# gui elements of obj
    switch guiStyle
        case 'Panel'
            guiObj.main = parent;
            guiObj.Panel  = uipanel('Parent',parent,'Units','pixel','Position',position,...
                                    'Title',name,'Fontsize',fontsize.general,'Clipping','off');
              	guiObj.TabGroup = uitabgroup('parent',guiObj.Panel,'Units','normalized','Position', [0 0 1 1],'Tag','SummaryTabGroup');
                table_units = 'pixels';
                table_position = [3 5 1250 226];
        case 'Tab'
            guiObj.main = uitab('parent',parent,'title',name,'Tag',name);
                guiObj.TabGroup = uitabgroup('parent',guiObj.main,'Units','normalized','Position', [0 0 1 1],'Tag','SummaryTabGroup');
                table_units = 'normalized';
                table_position = [0 0 1 1];
        case 'Window'
            guiObj.menu = uimenu(ancestor(parent,'figure','toplevel'),'Label',name,'ForegroundColor',style.color{end},'Callback',@onOpen);
            guiObj.main = figure('Units','pixel','NumberTitle','off','MenuBar','none','Name',name,'DockControls','off','Position',position,...
                                'Resize','on','Visible','off','CloseRequestFcn',@onClose);
                movegui(guiObj.main,'center');
                
                guiObj.TabGroup = uitabgroup('parent',guiObj.main,'Units','normalized','Position', [0 0 1 1],'Tag','SummaryTabGroup');
                table_units = 'normalized';
                table_position = [0 0 1 1];
% 						iptwindowalign(ancestor(parent,'figure','toplevel'), 'bottom', guiObj.main, 'left');
    end

    %# define possible fields for table here and choose later which one should be displayed
    %# always: Name (string), format (bank,numeric,logical), field size (auto, 0, or any positiv integer), and editable (true, false)
    fields = {'Active', 'logical', 40, false;...
              'Cell', 'numeric', 40, false;...
              'Sample', 'numeric', 55, false;...
              'Repetition', 'numeric', 40, false;...
              'Group', 'numeric', 40, true;...
              'Description', 'bank', 150, true;...
              'Filename', 'bank', 200, false;...
              'Date', 'bank', 'auto', false;...
              'Time','bank', 'auto', false;...
              'Type', 'bank', 'auto', false;...
              'LI (mW/cm2)', 'numeric', 'auto', false;...
              'MPP (mW/cm2)', 'numeric', 'auto', false;...
              'MPPV (V)', 'numeric', 'auto', false;...
              'MPPJ (mA/cm2)', 'numeric', 'auto', false;...
              'JSC (mA/cm2)', 'numeric', 'auto', false;...
              'VOC (V)', 'numeric', 'auto', false;...
              'FF (%)', 'numeric', 'auto', false;...
              'PCE (%)', 'numeric', 'auto', false;...
              'RSH (Ohm/cm2)', 'numeric', 'auto', false;...
              'RS (Ohm/cm2)', 'numeric', 'auto', false;...
              'ScanDirection', 'bank', 'auto', false;...
              'IlluminationDirection', 'bank', 'auto', false;...
              'Integrationrate', 'numeric', 'auto', false;...
              'Delay', 'numeric', 'auto', false;... 
              'LightSoaking', 'numeric', 'auto', false;...
              'VoltageStabilization', 'numeric', 'auto', false;...
              'Lambda_max (nm)', 'numeric', 'auto', false;...
              'EQE_max (%)', 'numeric', 'auto', false;...
              'JSC_calc (mA/cm2)', 'numeric', 'auto', false;...
              'LockIn', 'numeric', 'auto', false;...
              'Bias (V)', 'numeric', 'auto', false;...
              'Geometry', 'bank', 'auto', false;...
              'ActiveArea', 'numeric', 'auto', false;...
              'Filepath','bank', 0, false}';
          
    f.darkIV    = logical([1 1 1 0 1 1 1 1 1 1 1 0 0 0 0 0 0 0 1 1 1 1 1 1 1 1 0 0 0 0 0 1 1 1]);
    f.lightIV   = logical([1 1 1 0 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 0 0 0 0 0 1 1 1]);
    f.advIV     = logical([1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 0 0 0 0 0 1 1 1]);
    f.TRP       = logical([1 1 1 1 1 1 1 1 1 1 1 0 0 0 0 0 0 0 0 0 0 1 1 1 1 0 0 0 0 0 0 1 1 1]);
	f.TRS       = logical([1 1 1 1 1 1 1 1 1 1 1 0 0 0 0 0 0 0 0 0 0 1 1 1 1 0 0 0 0 0 0 1 1 1]);
    f.MPP       = logical([1 1 1 1 1 1 1 1 1 1 1 0 0 0 0 0 0 0 0 0 0 1 1 0 0 0 0 0 0 0 0 1 1 1]);
%     f.Cycle     = logical([1 1 1 1 1 1 1 1 1 1 1 0 0 0 0 0 0 0 0 0 0 1 1 1 1 0 0 0 0 0 0 1 1 1]);

    f.EQE       = logical([1 1 1 0 1 1 1 1 1 1 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 1 1 0 0 1 1 1]);
    f.advEQE    = logical([1 1 1 0 1 1 1 1 1 1 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 1 1 1 1 1 1 1]);
    
    f.LID       = logical([1 1 1 0 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 0 0 0 0 0 1 1 1]);
    
    %# gui elements of summary tables
    types = input.Results.types(cellfun(@(s) ismember(s,possible_types),input.Results.types));
    for n2=1:length(types)
        guiObj.Tab.(types{n2}) = generateTable(guiObj.TabGroup,types{n2});
    end
     
    %# obj functions
    newObj.reset = @reset;
    newObj.getData = @getData;
    newObj.setData = @setData;
    newObj.saveData = @saveSummaryData;
    
    reset()
                      
    function reset(varargin)
        input = inputParser;
        addOptional(input,'type','',@(x) isempty(x) || any(validatestring(x,possible_types)));
        parse(input,varargin{:});
        
        if ~isempty(input.Results.type)
            setData(input.Results.type,generateData(input.Results.type,pixels));
        else
            for n3=1:length(types)
                setData(types{n3},generateData(types{n3},pixels));
            end
%             setData('lightIV',generateData('lightIV'));
%             setData('darkIV',generateData('darkIV'));
        end
    end

    function tableObj = generateTable(table_parent,tag)
        input = inputParser;
        addRequired(input,'table_parent');
        addRequired(input,'tag', @(x) any(validatestring(x,possible_types)));
        parse(input,table_parent,tag);
        
        tableObj.main = uitab('parent',table_parent,'title',tag);
        
        cNames = fields(1,f.(tag));
        cFormat = fields(2,f.(tag));
        cWidth = fields(3,f.(tag));
        cEditable = [fields{4,f.(tag)}];
        rNames = [];
            
        z = 255;
        tableObj.table = uitable('Parent',tableObj.main,'Units',table_units,'Position', table_position,...
                        'ColumnName', cNames, 'ColumnFormat', cFormat, 'ColumnWidth',cWidth,...
                        'ColumnEditable', cEditable, 'RowName',rNames,'Tag',tag,'RowStriping','on',...
                        'BackgroundColor', [246/z 246/z 246/z; 176/z 221/z 255/z],'CellEditCallback',{@onTableEdit});
    end

    function data = generateData(type,varargin)
        input = inputParser;
        addRequired(input,'type');
        addOptional(input,'pixels', @(x) any(validateattributes(x,{'numeric','scalar','nonnan','positive'})));
        parse(input,type,varargin{:});
        pix = input.Results.pixels;
        
        switch type
            case {'lightIV','darkIV','EQE'}
                switch pix
                    case 3
                        temp_data = cell(pix,length(guiObj.Tab.(type).table.ColumnName));
                        temp_data(:)   = {''};
                        temp_data(:,1) = {true};
                        temp_data(:,2) = num2cell((1:pix)');
                        temp_data(:,3) = num2cell(ones(pix,1));
                    otherwise
                        temp_data = cell(48,length(guiObj.Tab.(type).table.ColumnName));
                        temp_data(:)   = {''};
                        temp_data(:,1) = {true};
                        temp_data(:,2) = num2cell((1:48)');
                        temp_data(:,3) = num2cell(reshape(repmat(1:16,3,1),[1,48]));
                end
            case {'advIV','TRP','TRS','MPP','advEQE','LID'}
                temp_data = cell(1,length(guiObj.Tab.(type).table.ColumnName));
                temp_data(:)   = {''};
                temp_data(:,1) = {true};
            otherwise
                data = 0;
                disp(type)
                return;
        end

        data = temp_data;
    end

    function data = getData(type)
        data = guiObj.Tab.(type).table.Data;
    end

    function setData(varargin)
        switch nargin
            case 1 % update table via data.iv.header
                header_data = varargin{1};
                type = header_data.Type;
                if strcmp(type,'EQE_L') || strcmp(type,'EQE_K') || strcmp(type,'EQE_B')
                    type = 'EQE';
                elseif strcmp(type,'lightTRP') || strcmp(type,'darkTRP')
                    type = 'TRP';
                elseif strcmp(type,'lightTRS') || strcmp(type,'darkTRS')
                    type = 'TRS';
                end
                cn = guiObj.Tab.(type).table.ColumnName;
            case 2 % set complete table
                type = varargin{1};
                table_data = varargin{2};
                if strcmpi(table_data,'reset')
                    table_data = generateData(type);
                end
                guiObj.Tab.(type).table.Data = table_data;
                return;
        end

        header = fieldnames(header_data);
        switch type
            case {'advIV','TRP','TRS','MPP','advEQE','LID'}
                temp_pos = size(guiObj.Tab.(type).table.Data);
                pos_x = temp_pos(1);
                guiObj.Tab.(type).table.Data(pos_x(1),:) = cell(1,temp_pos(2));
                for n1=1:length(header)
                	head_temp = strsplit(header{n1},'_');
                    pos_y = logical(cellfun(@(s) sum(strcmpi(head_temp{1},strsplit(s))),cn));
                    if sum(pos_y)
                    	guiObj.Tab.(type).table.Data(pos_x,pos_y) = {header_data.(header{n1})};
                    end
                end
                guiObj.Tab.(type).table.Data(end+1,:) = cell(1,temp_pos(2));
            otherwise
                pos_x = header_data.Cell;
                for n1=1:length(header)
                	head_temp = strsplit(header{n1},'_');
                    pos_y = logical(cellfun(@(s) sum(strcmpi(head_temp{1},strsplit(s))),cn));
                    if sum(pos_y)
                    	guiObj.Tab.(type).table.Data(pos_x,pos_y) = {header_data.(header{n1})};
                    end
                end
        end
        saveSummaryData(type,pos_x);
    end

    function saveSummaryData(varargin)
        switch nargin
            case 1
                type = varargin{1};
                pos = 0;
            case 2
                type = varargin{1};
                pos = varargin{2};
            otherwise
                log.update('Wrong number of variables in saveSummaryData!')
        end
        
        status = saveSummary(guiObj.Tab.(type).table,pos,log);
        if ~status
            log.update('Something wrong in saveing SummaryTable')
        end
    end

    function onOpen(varargin)
        guiObj.main.Visible = 'on';
		figure(guiObj.main);
    end

    function onClose(varargin)
        guiObj.main.Visible = 'off';
    end

    function onTableEdit(hObject,action)
        type = hObject.Tag;
        field = hObject.ColumnName{action.Indices(2)};
        switch field
            case 'Group'
                [result,status] = check_value(action.NewData,1,100);
                if status
                    result = round(result);
                    hObject.Data(action.Indices(1),action.Indices(2)) = {result};
                else
                    hObject.Data(action.Indices(1),action.Indices(2)) = {action.PreviousData};
                end
            case 'Description'
                [status,result] = check_string(action.NewData,'nospecial');
                if status
                    hObject.Data(action.Indices(1),action.Indices(2)) = {result};
                else
                    hObject.Data(action.Indices(1),action.Indices(2)) = {action.PreviousData};
                end       
            otherwise
                log.update(['Unknown variable in ',newObj.defaultS.ID,' prefs.'])
        end
        saveSummaryData(type);
    end
end
