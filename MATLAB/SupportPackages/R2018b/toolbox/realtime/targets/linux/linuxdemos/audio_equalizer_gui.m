function audio_equalizer_gui(state)
%AUDIO_EQUALIZER_GUI implementation for audio workflow demo.

% Copyright 2008-2012 The MathWorks, Inc.


persistent Fs NdB axisStyle

% Global persistent for controlling log or regular frequency axis. Choose
% 'log' if you want a logarithmic X-axis; if not, use 'normal'
axisStyle = 'normal';

color1 = [255 0 0]/255;     % Red
color2 = [0 0 255]/255;     % Blue 
color3 = [0 0 0]/255;       % Black
axisColor = [159 188 191]/255;
figColor = [211 226 226]/255;

if nargin==0 || strcmp(state,'reset')
    
    Owner=gcs; 
    %Set NdB . This value could also be parametrized in the model and 
    % set here using: NdB = str2num(get_param([Owner '/band1'],'NdB'));
    NdB = 0.707;
    
    Fs = 8000;
    if evalin('base', 'exist(''audiosamplingrate'')')
        Fs = evalin('base', 'audiosamplingrate');
    end
    
    if ~exist('eq_state')
        eq_state.BandWidth1 = .3 ;
        eq_state.CenterFreq1 = .1;
        eq_state.peakgain1 = 5 ;
        
        eq_state.BandWidth2 =.3  ;
        eq_state.CenterFreq2 = .2;
        eq_state.peakgain2 =  3;
        
        eq_state.BandWidth3 =.3  ;
        eq_state.CenterFreq3 = .3;
        eq_state.peakgain3 = -5 ;
    end
    
        
    bandw1 = eq_state.BandWidth1;
    centerfreq1 =eq_state.CenterFreq1;
    pk1= eq_state.peakgain1;
    
    bandw2= eq_state.BandWidth2;
    centerfreq2 = eq_state.CenterFreq2;
    pk2=eq_state.peakgain2;
    
    bandw3 =eq_state.BandWidth3;
    centerfreq3 = eq_state.CenterFreq3;
    pk3=eq_state.peakgain3;
    
    %Initial Creation of the filters
    %Filter1
    [b1 a1] = peq(0,pk1,centerfreq1,bandw1,NdB);
    [h1,w1] = freqz(b1,a1);
    %Filter2
    [b2 a2] = peq(0,pk2,centerfreq2,bandw2,NdB);
    [h2,w2] = freqz(b2,a2);
    %Filter3 
    [b3 a3] = peq(0,pk3,centerfreq3,bandw3,NdB);
    [h3,w3] = freqz(b3,a3);
    
    coeffsMatrix1 = [b1(1) b1(2) b1(3) a1(2) a1(3)]';
    coeffsMatrix2 = [b2(1) b2(2) b2(3) a2(2) a2(3)]';
    coeffsMatrix3 = [b3(1) b3(2) b3(3) a3(2) a3(3)]';
    
    % Write initial Filter values as to workspace as MPT Objects after
    % creating a variable first.
    assignin('base', 'CoeffsMatrix1', coeffsMatrix1);    
    %evalin(  'base', 'CoeffsMatrix1 = mpt.Parameter;');
    %evalin(  'base', 'CoeffsMatrix1.Value = coeffsMatrix1;');
    
    assignin('base', 'CoeffsMatrix2', coeffsMatrix2);    
    %evalin(  'base', 'CoeffsMatrix2 = mpt.Parameter;');
    %evalin(  'base', 'CoeffsMatrix2.Value = coeffsMatrix2;');
    
    assignin('base', 'CoeffsMatrix3', coeffsMatrix3);    
    %evalin(  'base', 'CoeffsMatrix3 = mpt.Parameter;');
    %evalin(  'base', 'CoeffsMatrix3.Value = coeffsMatrix3;');
    
    %Convert back to dB
    h1 = 20*log10(abs(h1));
    h2 = 20*log10(abs(h2));
    h3 = 20*log10(abs(h3));
         
    %% -------------------BAND ONE----------------------------------------
    %Create the plot
    figureName = 'Three Band Equalizer';
    % If figure already exists, bring to front
    hFig = findall(0, 'type', 'figure', 'Name', figureName );
    if ~isempty(hFig)
        figure(hFig);
    end

    if strcmp(axisStyle,'log')
        line1 = semilogx(w1,h1,'tag','line1','linewidth',2); hold on;
    elseif strcmp(axisStyle, 'normal')
        line1 = plot(w1,h1,'tag','line1','linewidth',2); hold on;  
    end;

    set(line1,'color',color1);
    %axis off;
    grid on;
    xlim(([0 1])*pi);
    ylim([-15 15]);
    
    %Customize the looks of the Figure Window
    set(gcf,'menubar','none');
    set(gcf,'Name',figureName);
    
    % and the axis
    xlabels=[.1:.1:3.0];   % setup 1 2 5 sequence for xlabels
    set(gca,'xtick',xlabels*pi);
    
    for k=1:length(xlabels)
        xstring{k} = sprintf('%3.0f',(xlabels(k)*Fs/2));
    end;
    set(gca,'xticklabel',xstring)
    
    set(gcf,'color',figColor);
    set(gca,'color',axisColor);
    ScreenSize = get(0,'screensize');
    if ( exist('state') && ~strcmp(state,'reset')) || (nargin==0)        
        set(gcf,'position',[min(ScreenSize(3)*2/3,507) min(ScreenSize(4)/2,417) 516 350]);        
    end
    set(gca,'position',[0.1000    0.2000    0.8150    0.6150]);
    set(gcf,'resize','off');
    set(gca,'xcolor','k','ycolor','k');

    set(get(gca,'xlabel'), 'String', 'Frequency in Hz', 'color','k', 'FontSize', 10);
    set(get(gca,'ylabel'), 'String', 'Gain in dB', 'color','k', 'FontSize', 10);
    
    %Create Help Text at the top of the Figure Window
    htext = uicontrol(gcf);
    set(htext,'position',[50 310 425 25], 'BackgroundColor', figColor, 'fontangle','oblique','fontweight','bold', ...
        'FontSize', 10, 'tag', 'text1', 'string', 'Click and drag on the Round Markers or the Lines');
    
    %Create Text box for Parameter Value display
    freqText  = text(0.0057,13.65, 'Center Frequency:', 'color', axisColor, 'tag', 'freqText', 'FontSize', 10);
    peakText  = text(1.30,13.65, 'Peak Value:', 'color', axisColor, 'tag', 'peakText', 'FontSize', 10);
    bandwText = text(2.30,13.65, 'Band Width:', 'color', axisColor, 'tag', 'bandwText', 'FontSize', 10);

    %Create the Note Text
    noteText = uicontrol(gcf);
    set(noteText,'position',[75 5 380 20], 'BackgroundColor', figColor, ...
        'string', 'The overall response (yellow dashed line) is centered at 0dB.', 'FontSize', 10);
    
    %Create a Reset Button
    reset = uicontrol(gcf);
    set(reset,'position',[460 5 50 15],'string','Reset');
    set(reset,'callback','audio_equalizer_gui(''reset'')');
    %Add Markers that will be used for manipulating the parameters
    if pk1>0
       [h1max,indexh1] = max(h1); 
   else
       [h1max,indexh1] = min(h1); 
   end
    
    w1max = w1(indexh1);
    % the marker is plotted as a line object
    gain1 = line(w1max,h1max,'Marker','o','MarkerEdgeColor','k', ...
        'MarkerFaceColor',color1,'tag','peakgain1','LineStyle','none','markersize',6);
    %-------------------END CODE FOR BAND ONE--------------------------------------
    
%% -------------------BAND TWO--------------------------------------------------
    
    %Create the plot
    %line2 = plot(w2*fs/(2*pi),h2,'b','tag','line2');
   % line2 = semilogx(w2,h2,'tag','line2');
    if strcmp(axisStyle,'log')
        line2 = semilogx(w2,h2,'tag','line2','linewidth',2);
    elseif strcmp(axisStyle, 'normal')
        line2 = plot(w2,h2,'tag','line2','linewidth',2);  
    end;
    set(line2,'color',color2);
    
    %Add Markers that will be used for manipulating the parameters
    if pk2>0
        [h2max,indexh2] = max(h2);    % this does not work, it can be a max or a min!
    else
        [h2max,indexh2] = min(h2);    % this does not work, it can be a max or a min!
    end;
    
    w2max = w2(indexh2);
    % the marker is plotted as a line object
    gain2 = line(w2max,h2max,'Marker','o','MarkerEdgeColor','k', ...
        'MarkerFaceColor',color2,'tag','peakgain2','LineStyle','none','markersize',6);
    %-------------------END CODE FOR BAND TWO--------------------------------------
%% --------------------------BAND THREE------------------------------------------
    %Create the plot
    %line3 = plot(w3*fs/(2*pi),h3,'m','tag','line3');
    %line3 = semilogx(w3,h3,'tag','line3');
    if strcmp(axisStyle,'log')
        line3 = semilogx(w3,h3,'tag','line3','linewidth',2);
    elseif strcmp(axisStyle, 'normal')
        line3 = plot(w3,h3,'tag','line3','linewidth',2);
    end;
    set(line3,'color',color3);
        
    %Add Markers that will be used for manipulating the parameters
    if pk3>0
       [h3max,indexh3] = max(h3);
    else
       [h3max,indexh3] = min(h3);
    end
    w3max = w3(indexh3);
    % the marker is plotted as a line object
    gain3 = line(w3max,h3max,'Marker','o','MarkerEdgeColor','k', ...
        'MarkerFaceColor',color3,'tag','peakgain3','LineStyle','none','markersize',6);
    %-------------------END CODE FOR BAND THREE--------------------------------------
%% Sum of all Bands    
    sumH = h1+h2+h3;
    %Normalize the sum of responses to value bet -15 & +15
    normSumH = sumNorm(sumH);
    %Plot sum of all responses
    line4 = plot(w2,normSumH,'y--','tag','line4','linewidth',1,'hittest','off');
    hold off;
    
    %Store sum of all response in GCF to display sum of responses
    allH = normSumH; 
    setappdata(gcf,'allH', allH);
    
    %Also save the equalizer responses and current parameters in a
    %structure: eqData.H ,eqData.centerFreq, eqData.bandW
    eqData.H = [h1 h2 h3];
    eqData.centerFreq = [centerfreq1 centerfreq2 centerfreq3];
    eqData.bandW = [bandw1 bandw2 bandw3];
    setappdata(gcf,'eqData', eqData);
    
    if nargin~=0
        try
            warning('off', 'Simulink:Engine:LineWithoutDst');
            warning('off', 'Simulink:Engine:LineWithoutSrc');
            set_param(bdroot,'SimulationCommand','update');
            warning('on', 'Simulink:Engine:LineWithoutDst');
            warning('on', 'Simulink:Engine:LineWithoutSrc');
        end
    end
    
    %Set the button down function
    set(gcf,'WindowButtonDownFcn','audio_equalizer_gui(''down'')');     
    
    %Set the mouse move while button down function
    set(gcf,'WindowButtonMotionFcn','','WindowButtonUpFcn','');

    % Execute the WindowButtonDownFcn
elseif strcmp(state,'down')
    
    %Get the current complete info on filter responses
    EqData = getappdata(gcf,'eqData');
    cfreq = EqData.centerFreq;
    
    %Identify the Band that was clicked
    htype = get(gco,'type');
    
    %If Line is clicked, then set the Point Down information in the Figure
    if strcmp(htype,'line')
        tag = get(gco,'tag');
        tagIndex = eval(tag(end));
        
        set(gcf,'WindowButtonMotionFcn','audio_equalizer_gui(''move'')', ...
            'WindowButtonUpFcn','audio_equalizer_gui(''up'')');  
        
        cp = get(gca,'CurrentPoint');
        xDown = cp(1,1);
        yDown = cp(1,2);
        
        setappdata(gcf,'pointDown',[xDown cfreq(tagIndex)]); 
        
        text1 = findobj(gcf,'tag','text1');
        line4 = findobj(gcf,'tag','line4');
        if strcmp(tag,'peakgain1')|strcmp(tag,'peakgain2')|strcmp(tag,'peakgain3') 
            set(text1,'string','Drag to move the peak around');
        elseif strcmp(tag,'line1')|strcmp(tag,'line2')|strcmp(tag,'line3')
            set(text1,'string','Drag to change the bandwidth');
        elseif strcmp(tag,'line4')
            set(text1,'string','This is the actual response. Change this by moving individual bands');
        end
    end
    
% Execute the WindowButtonMotionFcn    
elseif strcmp(state,'move')
    
    %Get the current complete info on filter responses
    EqData = getappdata(gcf,'eqData');
    cfreq = EqData.centerFreq;
    H = EqData.H;
    bandw = EqData.bandW;
    
    %Find handles of blocks in Simulink Model whose value is set here
    text1 = findobj(gcf,'tag','text1');
    
    line1 = findobj(gcf,'tag','line1');
    gain1 = findobj(gcf,'tag','peakgain1');

    line2 = findobj(gcf,'tag','line2');
    gain2 = findobj(gcf,'tag','peakgain2');
    
    line3 = findobj(gcf,'tag','line3');
    gain3 = findobj(gcf,'tag','peakgain3');
    
    line4 = findobj(gcf,'tag','line4');
   
    freqText = findobj(gcf,'tag','freqText');
    peakText = findobj(gcf,'tag','peakText');
    bandwText = findobj(gcf,'tag','bandwText');
     
    cp = get(gca,'CurrentPoint');

    %-----------------------------------
    %If the user drags the point out of the axis reset
    %the corresponding point to the axis limits
    x = cp(1,1); xlims = get(gca,'xlim'); 
    %if x<xlims(1), x = xlims(1);end;
    if x<(45*2*pi/Fs), x = (45*2*pi/Fs) ;end; % Center frequency cannot be lower than 45 Hz
    if x>xlims(2), x = xlims(2);end;
    
    y = cp(1,2); ylims = get(gca,'ylim'); 
    if y<ylims(1), y = ylims(1);end;
    if y>ylims(2), y = ylims(2);end;
    %------------------------------------
    
    tag = get(gco,'tag');
    if isempty(tag)
        return
    end
    tagIndex = eval(tag(end));

    switch tag(end)
        case '1'
            col = color1;
        case '2' 
            col = color2;
        case '3' 
            col = color3;
    end
    %Get the original ButtonDown x,y coordinates
    xyDown = getappdata(gcf,'pointDown');
    allH = getappdata(gcf,'allH');
    
    %IF THE GAIN POINT IS MOVED ==>
    if strcmp(tag,'peakgain1')||strcmp(tag,'peakgain2')||strcmp(tag,'peakgain3') 
        set(text1,'string','Change Center Frequency and Peak Gain of the frequency band');
        myH = H(:,tagIndex);
        
        %Change the Shape and color of Marker while it's moving
        set(eval(['gain' tag(end)]),'xdata',x,'ydata',y,'marker','diamond','markersize',12,'markerfacecolor','y');
        [newb, newa] = peq(0,y,x,bandw(tagIndex),NdB);
        [newh,neww] = freqz(newb,newa);
        newh = 20*log10(abs(newh));
        [watever maxW] = max(newh);
        
        set(eval(['line' tag(end)]),'ydata',newh,'xdata',neww,'linewidth',2);
        H(:,tagIndex) = newh;
        
        %Update the sum response plot to improve readability
        allH = sumNorm(sum(H,2));
        set(line4,'ydata',allH,'xdata',neww);

        %Set the new parameters for the modified band
        EqData.H = H;
        cfreq(tagIndex) = x; 
        EqData.centerFreq = cfreq;
        EqData.bandW = bandw;
        setappdata(gcf,'eqData',EqData);
        setappdata(gcf,'allH',allH);
        
        %Display the parameters as the user moves the UIobjects
        numFreq = numFormat(x,Fs);
        numBandw = numFormat(bandw(tagIndex),Fs);
        peakVal = sprintf('%0.1f',y);
        set(freqText,'string',['Center Frequency: ',numFreq],'color',col);
        set(peakText,'string',['Peak Value: ',peakVal,'dB'],'color',col);
        set(bandwText,'string',['Bandwidth: ',numBandw],'color',col);
        
        drawnow
    
    %IF THE LINE (Bandwidth) IS MOVED ==>   
    elseif strcmp(tag,'line1')||strcmp(tag,'line2')||strcmp(tag,'line3')
        set(text1,'string','Dragging the colored lines changes the bandwidth of the frequency band');
        %Get the response of the current band
        myH = H(:,tagIndex);
        %Change the Shape and color of line while it's moving
        set(eval(['line' tag(end)]),'color','c','linewidth',3);
        
        %Get the value of the peak gain
        peakG = get(eval(['gain' tag(end)]),'ydata');
        
        bwDiff = (x-xyDown(2));
        bandww = 2*abs(bwDiff);
        if bandww<50*2*pi/Fs
            bandww = 50*2*pi/Fs; %Minimum Bandwidth allowed is 50 hertz
        elseif bandww>(20000*2*pi/Fs) %Maximum Bandwidth allowed is 20000 hertz
            bandww = 20000*2*pi/Fs;
        end
        bandw(tagIndex) = bandww; 
        
        %Center Frequency cfreq does not change
        
        %Compute New Filter parameters
        [newb, newa] = peq(0,peakG,cfreq(tagIndex),bandww,NdB);
        [newh,neww] = freqz(newb,newa);
        newh = 20*log10(abs(newh));
        
        %Update Line for the chosen band
        set(eval(['line' tag(end)]),'ydata',newh,'xdata',neww);
        set(eval(['gain' tag(end)]),'Marker','o','MarkerEdgeColor','k',...
             'MarkerFaceColor',col,'LineStyle','none','markersize',6);

        H(:,tagIndex) = newh;
        EqData.H = H;
        %EqData.centerFreq = cfreq;
        EqData.bandW = bandw;
        setappdata(gcf,'eqData',EqData);
        
        allH = sumNorm(sum(H,2));
        setappdata(gcf,'allH',allH);
        set(line4,'ydata',allH,'xdata',neww);
         
        peakVal = sprintf('%.1f',peakG);
        numFreq = numFormat(cfreq(tagIndex),Fs);
        numBandw = numFormat(bandw(tagIndex),Fs);
        
        set(freqText,'string',['Center Frequency: ',numFreq],'color',col);
        set(peakText,'string',['Peak Value: ',peakVal,' dB'],'color',col);
        set(bandwText,'string',['Bandwidth: ',numBandw],'color',col);
        
        drawnow
    end;
    
% Execute the WindowButtonUpFcn        
elseif strcmp(state,'up')
    
    tag = get(gco,'Tag');
    if isempty(tag)
        return
    end
    tagIndex = eval(tag(end));

    switch tag(end)
        case '1', col = color1;
        case '2', col = color2;
        case '3', col = color3;
    end
    
    eqData = getappdata(gcf,'eqData');
    H = eqData.H;
    myH = H(:,tagIndex);
    hmax = max(myH);
    hmin = min(myH);
    
    if abs(hmax) < 0.00001
        hmax = hmin;
    end
    
    cf = eqData.centerFreq;
    cfreq = cf(tagIndex);
    bw = eqData.bandW;
    bandw = bw(tagIndex);

    text1 = findobj(gcf,'tag','text1');
    gain1 = findobj(gcf,'tag','peakgain1');
    line1 = findobj(gcf,'tag','line1');
    
    gain2 = findobj(gcf,'tag','peakgain2');
    line2 = findobj(gcf,'tag','line2');
    
    gain3 = findobj(gcf,'tag','peakgain3');
    line3 = findobj(gcf,'tag','line3');
    
    % Call the PEQ function to get the filter coefficients
    [b a] = peq(0,hmax,cfreq,bandw,0.707);
   
%     % Overwrite the initial Filter and Scale values of the appropriate band  
%     [newSos, newg]= tf2sos(num,den);

    disp(['Changing filter coefficients for band: ',tag(end)]);
    varName = ['CoeffsMatrix',tag(end)];
    %newCoeffMatrix = evalin('base',varName);
    newCoeffMatrix = [b(1) b(2) b(3) a(2) a(3)]';
    assignin('base', varName, newCoeffMatrix);
   % evalin('base',['CoeffsMatrix',tag(end),'.Value = ',varName,';']);
    
    % Update Model with new parameters.
    try
        warning('off', 'Simulink:Engine:LineWithoutDst');
        warning('off', 'Simulink:Engine:LineWithoutSrc');
        set_param(bdroot,'SimulationCommand','update');    
        warning('on', 'Simulink:Engine:LineWithoutDst');
        warning('on', 'Simulink:Engine:LineWithoutSrc');
    end

    set(text1,'string','Click and drag on the Round Markers or the Lines');
    set(eval(['gain' tag(end)]),'Marker','o','MarkerEdgeColor','k',...
            'MarkerFaceColor',col,'LineStyle','none','markersize',6);
    set(eval(['line' tag(end)]),'color',col,'linewidth',2);

    set(gcf,'WindowButtonMotionFcn','');
    set(gcf,'WindowButtonUpFcn','');
    
elseif strcmp(state,'save_state') 
    %eq_state.peakgain1 =
    %str2num(get_param([Owner,'/PeakGain1'],'value'));
    %eq_state.CenterFreq1= str2num(get_param([Owner,'/CenterFreq1'],'value'));
    %eq_state.BandWidth1=  str2num(get_param([Owner,'/BandWidth1'],'value'));
    
    %eq_state.peakgain2   =  str2num(get_param([Owner,'/PeakGain2'],'value'));
    %eq_state.CenterFreq2 =  str2num(get_param([Owner,'/CenterFreq2'],'value'));
    %eq_state.BandWidth2  =  str2num(get_param([Owner,'/BandWidth2'],'value'));
    
    %eq_state.peakgain3   =  str2num(get_param([Owner,'/PeakGain3'],'value'));
    %eq_state.CenterFreq3 =  str2num(get_param([Owner,'/CenterFreq3'],'value'));
    %eq_state.BandWidth3  =  str2num(get_param([Owner,'/BandWidth3'],'value'));
    
    %eq_state.AF_Gain   =    str2num(get_param([Owner,'/AF_Gain'],'gain'));
    
   %save EQ_State  eq_state
  
    
end

function out = numFormat(x,Fs)
%This function is for formatting the display of the frequency values
x = x*Fs/(2*pi); %Convert from radians/sec to absolute frequency in Hz
if (x/1000)<1
    out = [num2str(round(x)),'Hz'];
else
    s = sprintf('%0.3g',x/1000);
    out = [s,'kHz'];
end

function normSumH = sumNorm(x)
% Look for the center of the freq response range, and force this to be 0 dB.
normSumH= x; % -(max(x)+min(x))/2;

%% PEQ - Calculate Parametric Equalizer Coefficient
function [b, a] = peq(Gref, G0, w0, BW, NdB)

GBW = G0*NdB;
f = fdesign.parameq(...
      ['N,' 'F0,' 'BW,' 'Gref,' 'G0,' 'GBW'],...
        2,   w0,   BW,   Gref,   G0,   GBW, 2*pi);
myfilt = design(f);
[b,a]= tf(myfilt);
    
