function VideoDisplayMSfcn(block)
%VideoDisplayMSfcn Display video in normal, accel, rapid accel and external
%mode simulations. Does not generate code.
%
%   Copyright 2016 The MathWorks, Inc.

%%
%% The setup method is used to set up the basic attributes of the
%% S-function such as ports, parameters, etc. Do not add any other
%% calls to the main body of the function.
%%
setup(block);
end

function setup(block)
% Register number of ports
block.NumInputPorts  = 3;
block.NumOutputPorts = 0;

% Setup port properties to be inherited or dynamic
block.SetPreCompInpPortInfoToDynamic;

% Register the properties of the input port
for k = 1:3
    block.InputPort(k).DatatypeID     = 3;  % uint8
    block.InputPort(k).Complexity     = 'Real';
    block.InputPort(k).DimensionsMode = 'Inherited';
end

% Register S-function parameters
block.NumDialogPrms = 1;
block.DialogPrmsTunable = {'Nontunable'};

% Register sample times
%  [0 offset]            : Continuous sample time
%  [positive_num offset] : Discrete sample time
%
%  [-1, 0]               : Inherited sample time
%  [-2, 0]               : Variable sample time
block.SampleTimes = [-1 0];

% Specify if Accelerator should use TLC or call back into MATLAB file
block.SetSimViewingDevice(true);
block.SetAccelRunOnTLC(false);
block.SimStateCompliance = 'HasNoSimState';  % this block is a viewer - do not save any state info

% Register methods
block.RegBlockMethod('PostPropagationSetup', @DoPostPropSetup);
block.RegBlockMethod('SetInputPortDimensions', @SetInpPortDims);
block.RegBlockMethod('Start', @Start);
block.RegBlockMethod('Outputs', @Outputs);     % Required
end

%% Required when input port dimensions are set dynamically
function SetInpPortDims(block, idx, di)
block.InputPort(idx).Dimensions = di;
end

%%
%% PostPropagationSetup:
%%   Functionality    : Setup work areas and state variables. Can
%%                      also register run-time methods here
%%   Required         : No
%%   C-Mex counterpart: mdlSetWorkWidths
%%
function DoPostPropSetup(block)
% Validate input port dimensions
param = block.DialogPrm(1).Data;
if param == 1
    % RGB
    assert(isequal(block.InputPort(1).DataType,'uint8'),...
        'Expected R to be ''uint8''. Instead its type was double.');
    assert(isequal(block.InputPort(2).DataType,'uint8'),...
        'Expected G to be ''uint8''. Instead its type was double.');
    assert(isequal(block.InputPort(3).DataType,'uint8'),...
        'Expected B to be ''uint8''. Instead its type was double.');
    dim1 = block.InputPort(1).Dimensions;
    dim2 = block.InputPort(2).Dimensions;
    dim3 = block.InputPort(3).Dimensions;
    assert(numel(dim1) == 2,'Expected R to be a two dimensional array.');
    assert(mod(dim1(1),2) == 0,'Expected number of rows of R to be even.');
    assert(all(dim1 == dim2),'Expected dimensions of the G to be the same as R.');
    assert(all(dim1 == dim3),'Expected dimensions of the B to be the same as R.');
else
    % YCbCr 4:2:2
    assert(isequal(block.InputPort(1).DataType,'uint8'),...
        'Expected Y to be ''uint8''. Instead its type was double.');
    assert(isequal(block.InputPort(2).DataType,'uint8'),...
        'Expected Cb to be ''uint8''. Instead its type was double.');
    assert(isequal(block.InputPort(3).DataType,'uint8'),...
        'Expected Cr to be ''uint8''. Instead its type was double.');
    dim1 = block.InputPort(1).Dimensions;
    dim2 = block.InputPort(2).Dimensions;
    dim3 = block.InputPort(3).Dimensions;
    assert(numel(dim1) == 2,'Expected Y to be a two dimensional array.');
    assert(mod(dim1(1),2) == 0,'Expected number of rows of Y to be even.');
    assert(all(dim1 == [2*dim2(1) dim2(2)]),'The number of rows of Y must be twice the number of rows of Cb.');
    assert(all(dim1 == [2*dim3(1) dim3(2)]),'The number of rows of Y must be twice the number of rows of Cr.');
end 
end


%%
%% Start:
%%   Functionality    : Called once at start of model execution. If you
%%                      have states that should be initialized once, this
%%                      is the place to do it.
%%   Required         : No
%%   C-MEX counterpart: mdlStart
%%
function Start(block)
dims = block.InputPort(1).Dimensions;
hFig = findobj('Name','SDL Video Display');
if ~isempty(hFig)
    hFig.NumberTitle = 'off';
    hFig.MenuBar = 'none';
    hFig.ToolBar = 'none';
else
    % On MAC OS-X, not specifying a position for figure window causes
    % figure window to open outside screen. We set the top left corner to
    % [100, 120] and width and height to the dimensions of the R/Y port.
    scrsz = get(groot,'ScreenSize');
    hFig = figure('Name','SDL Video Display', ...
        'NumberTitle','off',...
        'MenuBar','none',...
        'ToolBar','none',...
        'Position',[100 scrsz(4)-(dims(2)+120) dims(1) dims(2)]);
    % Position = [lef bottom width height]
end
ax = axes('Parent',hFig,'Visible','off');
hIm = imshow(zeros([dims(2),dims(1)],'uint8'),'parent',ax,'border','tight');
figure(hFig); % Bring figure window to foreground

% Store required handles in block user data
obj.Fig = hFig;
obj.Im = hIm;
set_param(block.BlockHandle,'UserData',obj);
end

%%
%% Outputs:
%%   Functionality    : Called to generate block outputs in
%%                      simulation step
%%   Required         : Yes
%%   C-MEX counterpart: mdlOutputs
%%
function Outputs(block)
obj = get_param(block.BlockHandle,'UserData');
if ishandle(obj.Im)
    param = block.DialogPrm(1).Data;
    if param == 1
        obj.Im.CData = cat(3,block.InputPort(1).Data.',...
            block.InputPort(2).Data',...
            block.InputPort(3).Data');
    else
        obj.Im.CData = yuv2rgb(block,obj.Im.CData);
    end
    drawnow;
end
end

%% Local functions
function rgb = yuv2rgb(block,rgb)
% Formula used here is:
% R = (298/256) * Y + (409/256) * Cr - 222.921
% G = (298/256) * Y - (100/256) * Cb - (208/256) * Cr + 135.576
% B = (298/256) * Y + (516/256) * Cb - 276.836
Mr = [298.082 0 408.583]/256;
Mrc = -222.921;
Mg = [298.082 -100.291 -208.120]/256;
Mgc = 135.576;
Mb = [298.082  516.412  0]/256;
Mbc = -276.836;

% Initialize loop variables
y = double(block.InputPort(1).Data);
cb = double(block.InputPort(2).Data);
cr = double(block.InputPort(3).Data);
N = size(y,1);
M = size(y,2);
for m = 1:M
    for n = 1:2:N
        ic = (n - 1)/2 + 1;
        rgb(m,n,1) = Mr(1) * y(n,m) + Mr(3) * cr(ic,m) + Mrc;
        rgb(m,n,2) = Mg(1) * y(n,m) + Mg(2) * cb(ic,m) + Mg(3) * cr(ic,m) + Mgc;
        rgb(m,n,3) = Mb(1) * y(n,m) + Mb(2) * cb(ic,m) + Mbc;
        
        rgb(m,n+1,1) = Mr(1) * y(n+1,m) + Mr(3) * cr(ic,m) + Mrc;
        rgb(m,n+1,2) = Mg(1) * y(n+1,m) + Mg(2) * cb(ic,m) + Mg(3) * cr(ic,m) + Mgc;
        rgb(m,n+1,3) = Mb(1) * y(n+1,m) + Mb(2) * cb(ic,m) + Mbc;
    end
end
end