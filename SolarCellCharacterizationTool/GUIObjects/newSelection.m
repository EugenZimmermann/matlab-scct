function [device_gui,device_obj] = newSelection(parent,position,fontsize,style,log)    
    
    %# data elements of device
    device_obj = struct();
    
    device_obj.defaultS.ID = 'Cell Selection';
    
    Illumination = '';
    ActivePixel = ones(6,1);
    numPixels = length(ActivePixel);
	maskPixels = 6;
    activeArea = 0.133;
    
    %# gui elements
    position = [position(1) position(2) 320 90];
    device_gui.Panel = gui_panel(parent,position,device_obj.defaultS.ID,fontsize.general,'ui_Selection');
    %# set position pixels
    positions = {[55 5], [30 5], [5 5],[55 40], [30 40], [5 40]};
    %# create all pixels in a loop, activate check box and color pixel green (active)
    for n1 = 1:numPixels
        device_gui.(['P',num2str(n1)]).tbtn = gui_tbtn(device_gui.Panel,[positions{n1} 20 30],num2str(n1,'%02.2d'),fontsize.smallbtn,['Pixel ',num2str(n1,'%02.2d')],['tbtnP',num2str(n1,'%02.2d')],{@onPixelToggle});
    end
    
    device_gui.drop = gui_drop(device_gui.Panel, [205 40 109 22.5], '','maskSelection', {@onMaskSelection});
     	set(device_gui.drop,'String',{'3 x 13.3 mm²','6 x 13.3 mm²','6 x 9.08 mm²'});

    %# buttons to activate and deactivate all pixels at once
    device_gui.ActAll   = gui_btn(device_gui.Panel,[90 5  110 30],'activate all',fontsize.smallbtn,'Activates all pixels','btn_ActAllPixels',{@on_ActAll});
    device_gui.DactAll  = gui_btn(device_gui.Panel,[205 5  110 30],'deactivate all',fontsize.smallbtn,'deactivates all pixels','btn_DactAllPixels',{@on_DeactAll});
 
    %# device functions
    device_obj.reset = @reset;
    device_obj.getSettings = @getSettings;
    device_obj.getPixel = @getPixel;
    device_obj.setPixel = @setPixel;
    device_obj.setIllumination = @setIllumination;
    device_obj.getCellOrder = @getCellOrder;
    device_obj.getPixelOrder = @getPixelOrder;
    device_obj.getSampleOrder = @getSampleOrder;
    device_obj.setActiveArea = @setActiveArea;
    
    function reset()
        for n2 = 1:numPixels
            device_gui.(['P',num2str(n2)]).tbtn.Value = 1;
            device_gui.(['P',num2str(n2)]).tbtn.BackgroundColor = style.color{11};
        end
        setIllumination('front');
        onMaskSelection(device_gui.drop,1,1);
    end

    function settings = getSettings()
        settings.activePixel = find(getPixel())';
        settings.cellOrder.front = getCellOrder('front');
        settings.cellOrder.back = getCellOrder('back');
        settings.pixelOrder.front = getPixelOrder('front');
        settings.pixelOrder.back = getPixelOrder('back');
        settings.sampleOrder.front = getSampleOrder('front');
        settings.sampleOrder.back = getSampleOrder('back');
        settings.activeArea = activeArea;
    end

    function actPix = getPixel()
        actPix = zeros(numPixels,1);
        for n2 = 1:numPixels
            actPix(n2) = device_gui.(['P',num2str(n2)]).tbtn.Value && strcmp(device_gui.(['P',num2str(n2)]).tbtn.Enable,'on');
        end
    end

    function setPixel(varargin)
        switch nargin
            case 1 % only list of values for all pixel
                pix_values = varargin{1};
                if length(pix_values) == numPixels && isnumeric(pix_values) && ~isnan(pix_values)
                    for n2 = 1:numPixels
                    	device_gui.(['P',num2str(n2)]).tbtn.Value = pix_values(n2);
                    end
                else
                    log.update('Wrong dimensions of pixel array or not numeric!')
                end
            case 2 % list of pixel and corresponding value
                pix = varargin{1};
                pix_values = varargin{2};
               if length(pix)==length(pix_values) && isnumeric(pix) && isnumeric(pix_values) && max(pix)<=numPixels
                    for n2 = 1:length(pix)
                       device_gui.(['P',num2str(pix(n2))]).tbtn.Value = pix_values(n2);
                    end
                else
                    log.update('Wrong dimensions of pixel array or not numeric!')
                end
            otherwise
                log.update('Wrong dimensions of pixel array!')
        end
    end

    function setIllumination(illum)
        if ismember(lower(illum),{'front','back'})
            Illumination = illum;
        else
            log.update('Wrong illumination type chosen in newSelection\setIllumination!');
            return;
        end
        
        ButtonOrder = getCellOrder(illum);
        for n2=1:maskPixels
            device_gui.(['P',num2str(n2)]).tbtn.String = num2str(ButtonOrder(n2),'%02.2d');
            device_gui.(['P',num2str(n2)]).tbtn.Value = ActivePixel(ButtonOrder(n2));
            device_gui.(['P',num2str(n2)]).tbtn.BackgroundColor = con_a_b(device_gui.(['P',num2str(n2)]).tbtn.Value,activeColor(),style.color{1});
            device_gui.(['P',num2str(n2)]).tbtn.Tag = ['tbtnP',num2str(ButtonOrder(n2),'%02.2d')];
        end
    end

    function cellorder = getCellOrder(illum)
        if ismember(lower(illum),{'front','back'})
            cellorder = con_a_b(strcmp(illum,'front'),1:maskPixels,maskPixels:-1:1)';
        else
            log.update('Wrong illumination type chosen in newSelection\cellorder!');
            return;
        end
    end

    function pixelorder = getPixelOrder(illum)
        if ismember(lower(illum),{'front','back'})
            switch maskPixels
                case 3
                    pixelorder = con_a_b(strcmp(illum,'front'),[{'R'} {'M'} {'L'}],[{'L'} {'M'} {'R'}])';
                case 6
                    pixelorder = con_a_b(strcmp(illum,'front'),[{'lR'} {'lM'} {'lL'} {'uR'} {'uM'} {'uL'}],[{'lL'} {'lM'} {'lR'} {'uL'} {'uM'} {'uR'}])';
                otherwise
                    log.update(['Number of pixels ', num2str(maskPixels), 'not supported!']);
            end
        else
            log.update('Wrong illumination type chosen in newSelection\pixelorder!!');
            return;
        end
    end

    function sampleorder = getSampleOrder(illum)
        if ismember(lower(illum),{'front','back'})
            %# always 1, since old IV does not have a stage
            sampleorder = 1;
        else
            log.update('Wrong illumination type chosen in newSelection\sampleorder!');
            return;
        end
    end

    function on_ActAll(varargin)
        ActivePixel(:) = 1;
        for n2 = 1:numPixels
            device_gui.(['P',num2str(n2)]).tbtn.Value = 1;
            device_gui.(['P',num2str(n2)]).tbtn.BackgroundColor = con_a_b(device_gui.(['P',num2str(n2)]).tbtn.Value,activeColor(),style.color{1});
        end
    end

    function on_DeactAll(varargin)
        ActivePixel(:) = 0;
        for n2 = 1:numPixels
            device_gui.(['P',num2str(n2)]).tbtn.Value = 0;
            device_gui.(['P',num2str(n2)]).tbtn.BackgroundColor = con_a_b(device_gui.(['P',num2str(n2)]).tbtn.Value,activeColor(),style.color{1});
        end
    end

    function ac = activeColor()
        switch Illumination
            case 'front'
                ac = style.color{11};
            case 'back'
                ac = style.color{14};
            otherwise
                ac = style.color{end};
        end
    end

    function onPixelToggle(hObject,~,~)
        pixel = str2double(regexp(get(hObject,'Tag'),'\d+','match'));
        ActivePixel(pixel) = hObject.Value;
        hObject.BackgroundColor = con_a_b(ActivePixel(pixel),activeColor(),style.color{1});
    end

    function onMaskSelection(hObject,~,~)
        selection = strsplit(hObject.String{hObject.Value},{' x ',' '});
        maskPixels = str2double(selection(1));
        activeArea = str2double(selection(2))/100;
        switch maskPixels
            case 3
                for n2 = 4:numPixels
                   device_gui.(['P',num2str(n2)]).tbtn.Value = 0;
                   device_gui.(['P',num2str(n2)]).tbtn.Enable = 'off';
                   device_gui.(['P',num2str(n2)]).tbtn.Visible = 'off';
                end
            case 6
                for n2 = 4:numPixels
                   device_gui.(['P',num2str(n2)]).tbtn.Value = 1;
                   device_gui.(['P',num2str(n2)]).tbtn.Enable = 'on';
                   device_gui.(['P',num2str(n2)]).tbtn.Visible = 'on';
                end
            otherwise
                log.update(['Number of pixels ', num2str(maskPixels), 'not supported!']);
        end
    end

    function setActiveArea(actArea)
        if isnumeric(actArea) && isscalar(actArea)
            activeArea = actArea;
        else
            log.update(['Active area has to be numeric and scalar.']);
        end
    end
end
