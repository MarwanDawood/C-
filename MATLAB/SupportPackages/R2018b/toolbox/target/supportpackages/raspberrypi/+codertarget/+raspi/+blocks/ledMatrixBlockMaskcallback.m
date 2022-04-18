function ledMatrixBlockMaskcallback(varargin)
%LEDMATRIX Block mask helper function for Joystick block.
%

% Copyright 2016 The MathWorks, Inc.

blk = gcbh;

% Execute "action" callback
action = varargin{1};
switch action
    case 'Mode'
        maskVisibilities = get_param(blk, 'MaskVisibilities');
        mode = get_param(gcb, 'Mode');
        ortsrc  =  get_param(gcb, 'OrientationSource');
        switch (mode)
            case 'Write Pixel'
                [maskVisibilities{2}] = deal('off');
                [maskVisibilities{3}] = deal('off');
                [maskVisibilities{4}] = deal('off');
            case 'Display Image'
                [maskVisibilities{2}] = deal('on');
                [maskVisibilities{3}] = deal('on');
                switch(ortsrc)
                    case 'Input port'
                        [maskVisibilities{4}] = deal('off');
                    case 'Block dialog'
                        [maskVisibilities{4}] = deal('on');
                end
        end
        updateSystemObjectParam(blk, 'Mode');
        set_param(blk, 'MaskVisibilities', maskVisibilities);
        
    case 'ImageSource'
        updateSystemObjectParam(blk, 'ImageSource');
        
    case 'OrientationSource'
        maskVisibilities = get_param(blk, 'MaskVisibilities');
        ortsrc  =  get_param(blk, 'OrientationSource');
        mode = get_param(blk, 'Mode');
        if strcmp (mode,'Display Image')
            switch(ortsrc)
                case 'Input port'
                    [maskVisibilities{4}] = deal('off');
                case 'Block dialog'
                    [maskVisibilities{4}] = deal('on');
            end
        else
            [maskVisibilities{4}] = deal('off');
        end
        updateSystemObjectParam(blk, 'OrientationSource');
        set_param(blk, 'MaskVisibilities', maskVisibilities);
        
    case 'LEDOrientation'
        updateSystemObjectParam(blk, 'LEDOrientation');
        
    case 'MaskInitialization'
        params = {'Mode','ImageSource', 'OrientationSource', ...
            'LEDOrientation'};
        updateSystemObjectParam(blk, params);
        updatePortLabels(blk);
    otherwise
        error('raspi:internal:UnknownCallback',...
            'Unknown callback action "%s"',action)
end
end

%--------------------------------------------------------------------------
function updatePortLabels(blk)
% Update port labels
eol = char(10);
platform = realtime.internal.getBlockDisplayText(gcb);
maskDisplayStr = ['image(imread(''sensehatLEDmatrix.png''),[0.35 0.15 0.35 0.55]);', eol];
maskDisplayStr = [maskDisplayStr, 'color(''blue'');', eol, ...
    'text(0.65, 0.90, ''' platform ''', ''horizontalAlignment'', ''right'');', eol ...
    'color(''black'');', eol, ...
    'imgsrc  =  get_param(gcbh, ''ImageSource'');', eol ...
    'ortSource  =  get_param(gcbh, ''OrientationSource'');', eol ...
    'mode = get_param(gcbh, ''Mode'');', eol ...
    'switch(mode)',eol ...
    'case ''Write Pixel''',eol ...
    'port_label(''input'', 1, ''Location'');', eol ...
    'port_label(''input'', 2, ''RGB'');', eol ...
    'case ''Display Image''',eol ...
    'switch(imgsrc)', eol ...
    'case ''One multidimensional signal''',eol ...
    'port_label(''input'', 1, ''Image'');', eol ...
    'if strcmp(ortSource,''Input port'')', eol ...
    'port_label(''input'', 2, ''Orient'');', eol ...
    'end', eol ...
    'case ''Separate color signals''',eol ...
    'port_label(''input'', 1, ''R'');', eol ...
    'port_label(''input'', 2, ''G'');', eol ...
    'port_label(''input'', 3, ''B'');', eol ...
    'if strcmp(ortSource,''Input port'')', eol ...
    'port_label(''input'', 4, ''Orient'');', eol ...
    'end', eol ...
    'end', eol ...
    'end', eol ...
    ];
set_param(blk,'MaskDisplay',maskDisplayStr);
end

% Internal function to update the parameters
function updateSystemObjectParam(blk, param)
if ~iscell(param)
    param = {param};
end
for k = 1:numel(param)
    val = get_param(blk, param{k});
    set_param(blk, [param{k} '_'], val);
end
end

%[EOF] ledmatrixBlockMaskcallback.M
