function updateIllumination(type,varargin)
%UPDATEILLUMINATION Summary of this function goes here
%   Detailed explanation goes here

    input = inputParser;
    addRequired(input,'type',@(x) any(validatestring(x,{'front','back'})));
    addOptional(input,'calledBy','default',@(x) any(validatestring(x,{'default','IV','EQE'})));
    parse(input,type,varargin{:})
            
    global gui
    if isfield(gui.obj.(input.Results.calledBy),'Selection')
        gui.obj.(input.Results.calledBy).Selection.setIllumination(input.Results.type);
    end
end

