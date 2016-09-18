%Version - 9.18.2016
classdef NeuronGUI < handle
    properties
        nip
        handle
        editBoxes
        parameters
        nextActionTextbox
        ndA
        L
        nucleusBorder
        Cluster
        Single
        Small
        NClusterText
        PCluster
        cellBorder
        figaxis
        PCell
        NCellText
        ocbm
        ccnm
        cunm
        dirin
        dirout
        filein
        altparam
        h
        enableProcessOut
        enableProcessIn
        waitbar
        batch
        controlHandles
        flag
        parent
        batchInput
        batchOutput
        hSlider
        hControlpanel
        subPanel
        legend
        legend2
        badDataWarning = false; % flag indicating if the user has been notified about invalid parameter in editbox
    end
    
    
    methods
        function handle=getHandle(ngui)
            if isempty(ngui.handle)%check if the figure window has be created
                ngui.handle=figure;
                handle=ngui.handle;
            else
                if ishandle(ngui.handle) %check if the figure window is currently open
                    handle=ngui.handle;
                else
                    ngui.handle=figure;
                    handle=ngui.handle;
                end
            end
            set(handle,  'name', 'Figure Window','numbertitle','off')
            set(handle, 'Units', 'normalized', 'Position', [ 0.32    0.05   0.636   0.8])
            ngui.subPanel = uipanel('Parent',handle,...
                'BackgroundColor','white',...
                'units', 'normalized',...
                'Position',[0.005,0.72,0.12,0.18]);
            ngui.legend = uicontrol('Parent', ngui.subPanel,...
                'Style','text',... %instruction for each parameter
                'units', 'normalized',...
                'FontSize', 10,...%11.5 - 7/6
                'BackgroundColor', [0.9, 0.9, 0.9],...
                'HorizontalAlignment','left',...
                'position',[0, 0.5, 1, 0.5]);
            ngui.legend2 = uicontrol('Parent', ngui.subPanel,...
                'Style','text',... %instruction for each parameter
                'units', 'normalized',...
                'FontSize', 10,...%11.5 - 7/6
                'BackgroundColor', [0.9, 0.9, 0.9],...
                'HorizontalAlignment','left',...
                'position',[0, 0, 1, 0.5]);
        end
        function ngui=NeuronGUI(varargin)
            %             addpath('..')
            p = mfilename('fullpath');
            indices = strfind(p,filesep);
            ngui.parent = p(1:indices(end)); %find GUI's parent dir(GAIN folder)
            addpath(ngui.parent) %add the GAIN directory into the path
            
            ngui.nip=NeuronImageProcessor; %create and store the image processor obj
            if nargin>0
                status = ngui.nip.readParametersFile(varargin{1})
                if ~isempty(status)
                    error(status)
                end
            end
            ngui.parameters=ngui.nip.getParameters;
            p = ngui.parameters(12);
            [editBoxes, nextActionTextbox, controlpanelHandle, buttonHandles, sliderHandles]=createControlPanel(ngui.parameters, ngui.nip.getActionName,@ngui.forwardButtonCallback, @ngui.backButtonCallback, @ngui.saveButtonCallback, @ngui.quitButtonCallback, @ngui.batchButtonCallback, @ngui.parameterButtonCallback, @ngui.sliderCallback, @ngui.editBoxCallback);
            ngui.editBoxes=editBoxes;
            ngui.hSlider = sliderHandles;
            ngui.nextActionTextbox=nextActionTextbox;
            ngui.handle=[];
            ngui.controlHandles = buttonHandles; %handles of buttons on control panel
            ngui.hControlpanel = controlpanelHandle; %handle of control panel window
            %hide the Figure Toolbar of the control panel window, name it,
            %and hide the number of the figure
            set(ngui.hControlpanel, 'menubar', 'none', 'name', 'Control Panel','numbertitle','off');
        end
        function forwardButtonCallback(ngui,UIhandle,x)
            state=ngui.nip.getState();
            if state==NIPState.Ready
                [FileName, PathName]=uigetfile('*.*','Select the Nucleus Image File');
                nucleusImageFile=strcat(PathName,FileName);
                set(ngui.editBoxes(1),'string',nucleusImageFile);
                j=findjobj(ngui.editBoxes(1));%findjobj is a function from external resource
                j.setCaretPosition(length(get(ngui.editBoxes(1),'string')));
            end
            
            if ngui.badDataWarning%if user has been notified about invalid parameter in editbox
                ngui.badDataWarning=false;%flip the flag
            else
                for i=1:numel(ngui.editBoxes);
                    valueString=get(ngui.editBoxes(i),'string');
                    ngui.parameters(i).value=valueString;
                end
                status=ngui.nip.next(ngui.parameters);%call NIP
                updateUser(ngui,status);
            end
            %             cnt = 0;%count invalid values
            %             for i=1:numel(ngui.editBoxes)-1;
            %                 valueString=get(ngui.editBoxes(i+1),'string');
            %                 ngui.parameters(i+1).value=valueString;
            %                 number = str2num(ngui.parameters(i+1).value);
            %                 if isempty(number) || isnan(number) || numel(number) ~= 1
            %                     cnt = cnt+1;
            %                 end
            %
            %             end
            %             ngui.parameters(1).value = get(ngui.editBoxes(1),'string');%first edit box = image path
            %             if cnt == 0
            %             status=ngui.nip.next(ngui.parameters);
            %             updateUser(ngui,status);
            %             end
            %
            
            
        end
        
        function updateUser(ngui,status)
            state=ngui.nip.getState();
            fprintf('%s\n',char(state))
            if ~isempty(status)
                errordlg(status,'Error')
                return
            end
            fprintf('%s \n', char(state))
            switch(state)
                case NIPState.ReadImages
                    I = ngui.nip.getCellImage();
                    J = ngui.nip.getNucleusImage();
                    h = figure(ngui.getHandle());
                    imshow(J)
                    %                     set(ngui.instructionTextbox, 'string', 'Original nucleus image')%instruction textbox on control panel
                    set(ngui.legend,'string',sprintf('%s\n%s\n%s','Original', 'Nucleus', 'Image'),'ForegroundColor', 'k')
                    
                    
                    %                     %Automatically update graphs when variables change
                    %                     for i = 2:numel(ngui.editBoxes)
                    %                         paraValue(i) = str2num(get(ngui.editBoxes(k+1),'String'));
                    %                     end
                    %                     linkdata on
                    
                case NIPState.SegmentedNucleusImageOnce;
                    I=ngui.nip.getFirstNucleusMask();
                    J=ngui.nip.getNucleusImage();
                    %Need to show stuff from before too
                    rgb = addBorder(J, ngui.ocbm, [1, 0, 0]);%ocbm = opened cell body mask; empty here
                    rgb = addBorder(rgb, ngui.ccnm, [0, 1, 0]);
                    rgb = addBorder(rgb, ngui.cunm, [1, 1, 0]);
                    rgb = addBorder(rgb, I, [0, 0, 1]);
                    figure(ngui.getHandle());
                    imshow(rgb)
                    figure(ngui.getHandle());%without this command, the subPanel will not be shown (?)
                    %                    set(ngui.instructionTextbox, 'string', sprintf('blue - nuclei')) %instruction textbox on control panel
                    set(ngui.legend, 'String', sprintf('%s\n%s', 'Blue:', 'nuclei'), 'ForegroundColor', 'b')
                case NIPState.SegmentedNucleusImageTwice
                    I=ngui.nip.getSecondNucleusMask();
                    J=ngui.nip.getNucleusImage();
                    rgb = addBorder(J, ngui.ocbm, [1, 0, 0]);
                    rgb = addBorder(rgb, ngui.ccnm, [0, 1, 0]);
                    rgb = addBorder(rgb, ngui.cunm, [1, 1, 0]);
                    rgb = addBorder(rgb, I, [0, 0, 1]);
                    figure(ngui.getHandle);
                    imshow(rgb)
                    set(ngui.legend, 'String', sprintf('%s\n%s', 'Blue:', 'nuclei'), 'ForegroundColor', 'b')
                case NIPState.OpenedNucleusMask;
                    I=ngui.nip.getOpenedNucleusMask;
                    J=ngui.nip.getNucleusImage();
                    rgb = addBorder(J, ngui.ocbm, [1, 0, 0]);
                    rgb = addBorder(rgb, ngui.ccnm, [0, 1, 0]);
                    rgb = addBorder(rgb, ngui.cunm, [1, 1, 0]);
                    rgb = addBorder(rgb, I, [0, 0, 1]);
                    figure(ngui.getHandle);
                    imshow(rgb)
                    set(ngui.legend, 'String', sprintf('%s\n%s', 'Blue:', 'nuclei'), 'ForegroundColor', 'b')
                case NIPState.IdentifiedNucleusClusters
                    ngui.ndA = ngui.nip.getNucleusData(); %The property names are shown on the control panel. Need to solve this problem
                    ngui.L = ngui.nip.getNucleusAllLabeled(); %labeled nucleus image matrix
                    ngui.Cluster=false(size(ngui.L));
                    ngui.Single = false(size(ngui.L));
                    for i = 1:numel(ngui.ndA)
                        if ngui.ndA(i).cluster
                            ngui.Cluster = ngui.L==i | ngui.Cluster;
                        else
                            ngui.Single = ngui.L==i | ngui.Single;
                        end
                    end
                    J=ngui.nip.getNucleusImage();
                    rgb = addBorder(J, ngui.ocbm, [1, 0, 0]);
                    rgb = addBorder(rgb, ngui.ccnm, [0, 1, 0]);
                    rgb = addBorder(rgb, ngui.cunm, [1, 1, 0]);
                    rgb = addBorder(rgb, ngui.Cluster, [0, 1, 1]);
                    rgb = addBorder(rgb, ngui.Single, [0, 0, 1]);
                    figure(ngui.getHandle);
                    imshow(rgb)
                    %                     set(ngui.instructionTextbox, 'string', 'cyan - nuclei clusters')
                    set(ngui.legend, 'String', sprintf('%s\n%s', 'Cyan:', 'nuclei clusters'), 'ForegroundColor', [0, 0.8, 0.8])
                case NIPState.CalculatedNominalMeanNucleusArea
                    ngui.ndA = ngui.nip.getNucleusData();
                    J=ngui.nip.getNucleusImage();
                    N = zeros(1, length(ngui.ndA)); %neuron count of each cluster
                    P = zeros(2, length(ngui.ndA)); %position of each cluster
                    for i = 1:numel(ngui.ndA)
                        if ngui.ndA(i).cluster
                            N(i) = ngui.ndA(i).numNuclei;
                            center = ngui.ndA(i).centroid;
                            P(1,i) = center(2);
                            P(2, i) = center(1);
                        end
                    end
                    Background = intersect(find(P(1,:) == 0),find(P(2,:) == 0)); %find the indices of background,i.e.coordinate(0,0)
                    N(Background) = []; %Eliminate the count for the backgound
                    P(:,Background) = [];
                    NCluster = reshape(N, numel(N), 1);
                    ngui.NClusterText = cellstr(num2str(NCluster));
                    ngui.PCluster = reshape(P,2, numel(P)/2);
                    rgb = addBorder(J, ngui.ocbm, [1, 0, 0]);
                    rgb = addBorder(rgb, ngui.ccnm, [0, 1, 0]);
                    rgb = addBorder(rgb, ngui.cunm, [1, 1, 0]);
                    rgb = addBorder(rgb, ngui.Cluster, [0, 1, 1]);
                    rgb = addBorder(rgb, ngui.Single, [0, 0, 1]);
                    figure(ngui.getHandle);
                    imshow(rgb)
                    text(ngui.PCluster(2,:),ngui.PCluster(1,:),ngui.NClusterText,'Color','white','FontSize',12,'FontWeight', 'bold') %'Color','cyan', 'BackgroundColor', [.4, .4, .4] - 7/5
                    %works only if switch the order of P(1,:)
                    %and P(2,:)  ??
                    set(ngui.legend, 'String', sprintf('%s\n%s', 'Cyan:', 'nuclei clusters'), 'ForegroundColor', [0, 0.8, 0.8])
                case NIPState.CalculatedMinNucleusArea
                    ngui.ndA = ngui.nip.getNucleusData();
                    ngui.Small=false(size(ngui.L));
                    for i = 1:numel(ngui.ndA)
                        if ngui.ndA(i).small
                            ngui.Small = ngui.L==i | ngui.Small;
                        end
                    end
                    J=ngui.nip.getNucleusImage();
                    rgb = addBorder(J, ngui.ocbm, [1, 0, 0]);
                    rgb = addBorder(rgb, ngui.ccnm, [0, 1, 0]);
                    rgb = addBorder(rgb, ngui.cunm, [1, 1, 0]);
                    rgb = addBorder(rgb, ngui.Cluster, [0, 1, 1]);
                    rgb = addBorder(rgb, ngui.Single, [0, 0, 1]);
                    rgb = addBorder(rgb, ngui.Small, [1, 0, 1]);
                    figure(ngui.getHandle);
                    imshow(rgb)
                    text(ngui.PCluster(2,:),ngui.PCluster(1,:),ngui.NClusterText,'Color','white','FontSize',12,'FontWeight', 'bold')%'Color',[0, 0.5, 0.5]
                    %                     set(ngui.instructionTextbox, 'string', 'magenta - nuclei too small')
                    set(ngui.legend, 'String', sprintf('%s\n%s','Magenta:', sprintf('%s\n%s', 'Nuclei too small', 'to be accepted')), 'ForegroundColor', 'magenta')
                case NIPState.SegmentedCells
                    I = ngui.nip.getCellImage();
                    CellMask = ngui.nip.getFirstCellMask();
                    rgb = addBorder(I, CellMask, [1, 0, 0]);
                    figure(ngui.getHandle);
                    imshow(rgb)
                    %                     set(ngui.instructionTextbox, 'string', 'red - cell bodies and neurites')
                    set(ngui.legend, 'String', sprintf('%s\n%s\n%s','Cell', 'Image', 'Opened'))
                    set(ngui.legend2, 'String', 'Red: cell bodies and neurites', 'ForegroundColor', 'r')
                case NIPState.SeparatedBodiesFromNeurites
                    cbd = ngui.nip.getCellBodyData();
                    ngui.ocbm = ngui.nip.getOpenedCellBodyMask();
                    cbaL = ngui.nip.getCellBodyAllLabeled();
                    fnm = ngui.nip.getFirstNeuriteMask;
                    fcnm = ngui.nip.getFirstConnectedNeuriteMask;
                    funm = ngui.nip.getFirstUnconnectedNeuriteMask;
                    
                    N = zeros(1, length(cbd)); %neuron count of each cluster
                    P = zeros(2, length(cbd)); %position of each cluster
                    for i = 1:numel(cbd)
                        N(i) = cbd(i).numberOfNuclei;
                        P(1,i) = cbd(i).centroidRow;
                        P(2, i) = cbd(i).centroidColumn;
                    end
                    Background = intersect(find(P(1,:) == 0),find(P(2,:) == 0)); %find the indices of background,i.e.coordinate(0,0)
                    N(Background) = []; %Eliminate the count for the backgound
                    P(:,Background) = [];
                    NCell = reshape(N, numel(N), 1);
                    ngui.NCellText = cellstr(num2str(NCell));
                    ngui.PCell = reshape(P,2, numel(P)/2);
                    
                    I = ngui.nip.getCellImage();
                    rgb = addBorder(I, ngui.ocbm, [1, 0, 0]);
                    figure(ngui.getHandle);
                    imshow(rgb)
                    text(ngui.PCell(2,:),ngui.PCell(1,:),ngui.NCellText,'Color','white','FontSize',12,'FontWeight', 'bold')
                    set(ngui.legend, 'String', sprintf('%s\n%s','Red:', 'cell bodies'), 'ForegroundColor', 'r')
                case NIPState.ResegmentedNeurites
                    cnm = ngui.nip.getSecondConnectedNeuriteMask();
                    unm = ngui.nip.getSecondUnconnectedNeuriteMask();
                    I = ngui.nip.getCellImage();
                    
                    %also have ngui.nip.getSecondNeuriteMask
                    
                    rgb = addBorder(I, ngui.ocbm, [1, 0, 0]);
                    rgb = addBorder(rgb, cnm, [0, 1, 0]);
                    rgb = addBorder(rgb, unm, [1, 1, 0]);
                    figure(ngui.getHandle);
                    imshow(rgb)
                    text(ngui.PCell(2,:),ngui.PCell(1,:),ngui.NCellText,'Color','white','FontSize',12,'FontWeight', 'bold')
                    %                     set(ngui.instructionTextbox, 'string', sprintf('%s\n%s,', 'green - connected neurites', 'yellow - unconnected neurites'))
                    set(ngui.legend, 'String', sprintf('%s\n%s','Green:', 'connected neurites'), 'ForegroundColor', [0, 0.9, 0])
                    set(ngui.legend2, 'String', sprintf('%s\n%s', 'Yellow:', 'unconnected neurites'), 'ForegroundColor', [0.78, 0.78, 0])
                case NIPState.ResegmentedNeuriteEdges  %3rd Neurite Segmentation - added on 6/17/16
                    cnm = ngui.nip.getThirdConnectedNeuriteMask();
                    unm = ngui.nip.getThirdUnconnectedNeuriteMask();
                    I = ngui.nip.getCellImage();
                    rgb = addBorder(I, ngui.ocbm, [1, 0, 0]);
                    rgb = addBorder(rgb, cnm, [0, 1, 0]);
                    rgb = addBorder(rgb, unm, [1, 1, 0]);
                    figure(ngui.getHandle);
                    imshow(rgb)
                    text(ngui.PCell(2,:),ngui.PCell(1,:),ngui.NCellText,'Color','white','FontSize',12,'FontWeight', 'bold')
                    set(ngui.legend, 'String', sprintf('%s\n%s','Green:', 'connected neurites'), 'ForegroundColor', [0, 0.9, 0])
                    set(ngui.legend2, 'String', sprintf('%s\n%s', 'Yellow:', 'unconnected neurites'), 'ForegroundColor', [0.78, 0.78, 0])
                case NIPState.ClosedNeuriteMask
                    ngui.ccnm = ngui.nip.getClosedConnectedNeuriteMask();
                    ngui.cunm = ngui.nip.getClosedUnconnectedNeuriteMask();
                    I = ngui.nip.getCellImage();
                    
                    %Also have ngui.nip.getClosedNeuriteMask
                    
                    rgb = addBorder(I, ngui.ocbm, [1, 0, 0]);
                    rgb = addBorder(rgb, ngui.ccnm, [0, 1, 0]);
                    rgb = addBorder(rgb, ngui.cunm, [1, 1, 0]);
                    figure(ngui.getHandle);
                    imshow(rgb)
                    text(ngui.PCell(2,:),ngui.PCell(1,:),ngui.NCellText,'Color','white','FontSize',12,'FontWeight', 'bold')
                    %commented for shooting video - 7/26/2016
                    [FileName, PathName]=uiputfile('*.*','Save parameters as');
                    parameterData=strcat(PathName, FileName)
                    ngui.nip.writeParametersFile(parameterData)
                    set(ngui.legend, 'String', sprintf('%s\n%s','Green:', 'connected neurites'), 'ForegroundColor', [0, 0.9, 0])
                    set(ngui.legend2, 'String', sprintf('%s\n%s', 'Yellow:', 'unconnected neurites'), 'ForegroundColor', [0.78, 0.78, 0])
                case NIPState.SkeletonizedNeurites
                    cns = ngui.nip.getConnectedNeuriteSkeleton();
                    uns = ngui.nip.getUnconnectedNeuriteSkeleton();
                    I = ngui.nip.getCellImage();
                    rgb = addBorder(I, ngui.ocbm, [1, 0, 0]);
                    rgb = addBorder(rgb, ngui.ccnm, [0, 1, 0]);
                    rgb = addBorder(rgb, ngui.cunm, [1, 1, 0]);
                    rgb = addBorder(rgb, ngui.ocbm, [1, 0, 0]);
                    rgb = addBorder(rgb,cns,[0, 1, 0]);
                    rgb = addBorder(rgb,uns,[1, 1, 0]);
                    figure(ngui.getHandle);
                    imshow(rgb)
                    text(ngui.PCell(2,:),ngui.PCell(1,:),ngui.NCellText,'Color','white','FontSize',12,'FontWeight', 'bold')
                    set(ngui.legend, 'String', sprintf('%s\n%s','Green:', 'connected neurites'), 'ForegroundColor', [0, 0.9, 0])
                    set(ngui.legend2, 'String', sprintf('%s\n%s', 'Yellow:', 'unconnected neurites'), 'ForegroundColor', [0.78, 0.78, 0])
                case NIPState.CreatedGraph
                    I=ngui.nip.getGraphImage;
                    figure(ngui.getHandle);
                    imshow(I)
                    set(ngui.legend, 'String', sprintf('%s\n%s','Green:', 'connected neurites'), 'ForegroundColor', [0, 0.9, 0])
                    set(ngui.legend2, 'String', sprintf('%s\n%s', 'Yellow:', 'unconnected neurites'), 'ForegroundColor', [0.78, 0.78, 0])
                    
                case NIPState.ComputedPaths
                    %writeParametersFile()
                    %
                    %
                    %                     y = figure;
                    %                     y
                    %                     size(y)
                    %                     y,uicontrol('Style', 'pushbutton', 'String', 'Quit', ...
                    %                         'Position', [0 0 150 70], 'Callback', @quitButtonCallback);
                    %                     uicontrol('Style', 'pushbutton', 'String', 'Continue',...
                    %                         'Position', [410 0 150 70], 'Callback', @continueButtonCallback)
                    %
                    
                otherwise
                    error('[NeuronGUI.updateUser] Unexpected State: %s', char(state));
            end
            
            
            %check if ngui.nip.getActionName will go beyond one line
            
            %edited on 7/5
            if length(ngui.nip.getActionName) < 26 %Hard-coded. Don't know how to check if a line in textbox is full
                actionStr = sprintf('\n%s',ngui.nip.getActionName); %if only one line, move it to the bottom of the textbox
            else
                actionStr = ngui.nip.getActionName;
            end
            set(ngui.nextActionTextbox,'string',actionStr);
            
            %             set(ngui.instructionTextbox,'string',ngui.nip.getActionName);%instruction of each parameter;
            ngui.parameters=ngui.nip.getParameters;
            for i=1:numel(ngui.parameters)
                if ngui.parameters(i).active
                    enbl='on';
                    ngui.parameters(i).description % descriptions are empty now
                else
                    enbl='off';
                end
                set(ngui.editBoxes(i),'Enable',enbl);
                if i>1
                    set(ngui.hSlider(i-1),'Enable',enbl);
                end
            end
            
        end
        
        function backButtonCallback(ngui,UIhandle,x)
            
            if ngui.badDataWarning
                ngui.badDataWarning = true;
                
            else
%                 ngui.badDataWarning
                %                 %If any parameter value is empty, cannot go back
                %             for i=2:numel(ngui.editBoxes)
                %                 if isempty(get(ngui.editBoxes(i),'String'))
                %                     warndlg('Empty parameter value is not allowed. Please select a value')
                %                     return
                %                 end
                %             end
                for i=1:numel(ngui.editBoxes);
                    valueString=get(ngui.editBoxes(i),'string');
                    ngui.parameters(i).value=valueString;
                end
                status=ngui.nip.back(ngui.parameters);
                updateUser(ngui,status);
                
            end
        end
        
        
        function quitButtonCallback(ngui,UIhandle, x)
            %             close all %need to check if that is sufficient
            if ishandle(ngui.handle)
                close(ngui.handle)%close the figure window
            end
            close(ngui.hControlpanel)%close the control panel window
            
            rmpath(ngui.parent)   %remove the GAIN directory when the user quits the program
        end
        function batchButtonCallback(ngui,UIhandle, x)% "Exit to batch processing" button
            ngui.batch = figure;
            %hide the figure toolbar
            set(ngui.batch, 'menubar', 'none', 'name', 'Settings for Batch Processing','numbertitle','off');
            ngui.batch,%check if it is necessary
            %temp
            ngui.batch.Position(4) = 5/6*ngui.batch.Position(4); %decrease the height of the batch window - 9.18 
            wBatch = 560; %the wdith of batch window - calibrated
            hBatch = 350; %the height of batch window - calibrated
            
            bottom = 0;
            processButtonHandle = uicontrol('Style', 'pushbutton', 'String', 'Process',...
                'units', 'normalized',...
                'Position', [410/wBatch bottom 150/wBatch 50/hBatch], 'Callback', @ngui.processButtonCallback, ...
                'Enable', 'Off');
            uicontrol('Style', 'pushbutton', 'String', 'Cancel',...%original name: Back to Control Panel - 9.16.2016
                 'units', 'normalized',...
                 'Position', [0 bottom 150/wBatch 50/hBatch], 'Callback', {@ngui.controlPanelButtonCallback});%close batch wondow and back to controlpanel
            bottom_out = bottom + 125/hBatch;
            uicontrol('Style', 'pushbutton', 'String', 'Output Directory',...
                 'units', 'normalized',...
                'Position', [0 bottom_out 100/wBatch 25/hBatch], 'Callback', {@ngui.outputButtonCallback, processButtonHandle});
            bottom_infile = bottom +215/hBatch;
            bottom_indir = bottom_infile+75/hBatch;
            uicontrol('Style', 'pushbutton', 'String', 'Input Files',...
                 'units', 'normalized',...
                'Position', [0 bottom_infile 100/wBatch 25/hBatch], 'Callback', {@ngui.inputFileButtonCallback, processButtonHandle});
            uicontrol('Style', 'pushbutton', 'String', 'Input Directory',...
                 'units', 'normalized',...
                'Position', [0 bottom_indir 100/wBatch 25/hBatch], 'Callback', {@ngui.inputButtonCallback, processButtonHandle});
            
            %             set(ngui.batch, 'Position', [0.01 0.06 wControlPanel_rel hgtControlPanel_rel]);%Auto resize the window to fit the user's screen
            uicontrol('Style','text',... % a sign between "input dir" and "input files" buttons
                'units', 'normalized',...
                'string','Or',...
                'FontUnits', 'normalized',...
                'FontSize', 0.8,...
                'position', [35/wBatch bottom_infile+40/hBatch 30/wBatch 20/hBatch])
            
            ngui.flag = 0; %set the flag to be 0
            
            ngui.batchOutput = uicontrol('Style', 'edit', 'String', ' ',  'units', 'normalized',...
                'Position', [110/wBatch bottom_out-25/hBatch 400/wBatch 50/hBatch],'HorizontalAlignment','left', ...
                'Max', 100, 'Enable', 'on');
            jOutput=findjobj(ngui.batchOutput,'nomenu'); %get the UIScrollPane container
            jOutput=jOutput.getComponent(0).getComponent(0);
            set(jOutput,'Editable',0);
            
            ngui.batchInput = uicontrol('Style', 'edit',  'units', 'normalized',...
                'string', ' ', ...
                'Max', 100,...
                'Position', [110/wBatch bottom_infile 400/wBatch 100/hBatch],'HorizontalAlignment','left', ...
                'Enable', 'on');%off 6/28
            
            jInput=findjobj(ngui.batchInput,'nomenu'); %get the UIScrollPane container
            jInput=jInput.getComponent(0).getComponent(0);
            set(jInput,'Editable',0);
            
            
            for k = 1:length(ngui.controlHandles)
                set(ngui.controlHandles{k},'Enable','off')
            end
            
            %figure close call back
            % close batch processing window when a user clicks "back to
            % control panel"
            set(ngui.batch, 'CloseRequestFcn',@ngui.controlPanelButtonCallback)
            
        end
        function controlPanelButtonCallback(ngui,UIhandle, x) %back to control panel(cancel button)
            %                 error('Terminate batch processing.')
            
            ngui.flag = 1;%clicking the button changes the flag - which terminates the processing
            if ishandle(ngui.batch)
            close(ngui.batch)   %close batch processing window
            end
            %             if ishandle(ngui.waitbar), close(ngui.waitbar), end %close the waitbar window if it is open
            %             close(ngui.waitbar)
            for k = 1:length(ngui.controlHandles)
                set(ngui.controlHandles{k},'Enable','on')
            end
        end
        
        function outputButtonCallback(ngui, UIhandle, x, processButtonHandle)
            ngui.dirout=uigetdir('*.*','Store Data');
            
            if ischar(ngui.dirout) %if the directory is valid (is a string)
                set(ngui.batchOutput,'string', ngui.dirout);
            else
                set(ngui.batchOutput,'string', '');%if not, don't show it on the editbox
            end
           
            
            if ~isempty(ngui.dirout) && ischar(ngui.dirout) %matlab returns numerical 0 when nothing is selected
                ngui.enableProcessOut = 'On';
            else
                ngui.enableProcessOut = 'Off';
            end
            %             if ngui.dirout == 0, ngui.enableProcessOut = 'Off'; end %Click output  button but not select anything
            %             ngui.enableProcessOut = 'On'; %do we need to check if ~isempty(ngui.dirin)??
            if strcmp(ngui.enableProcessOut, 'On') && strcmp(ngui.enableProcessIn, 'On')
                enableProcess = 'On';
            else
                enableProcess = 'Off';
            end
            set(processButtonHandle,'Enable',enableProcess);
        end
        
        function inputButtonCallback(ngui, UIhandle, x, processButtonHandle)%get directory input
            %reset ngui.filein, since ngui.dirin is going to be used, not ngui.filein
            ngui.filein = [];
            ngui.dirin=uigetdir('*.*','Image File');
            if ischar(ngui.dirin)%if the directory is valid (is a string)
            set(ngui.batchInput, 'string', ngui.dirin)
            else set(ngui.batchInput,'string', '');%if not, don't show it on the editbox
            end
                
            if ~isempty(ngui.dirin) && ischar(ngui.dirin) %matlab returns numerical 0 when nothing is selected
                ngui.enableProcessIn = 'On';
            else
                ngui.enableProcessIn = 'Off';
            end
            if strcmp(ngui.enableProcessOut, 'On') && strcmp(ngui.enableProcessIn, 'On')
                enableProcess = 'On';
            else
                enableProcess = 'Off';
            end
            set(processButtonHandle,'Enable',enableProcess);
        end
        
        function inputFileButtonCallback(ngui, UIhandle, x, processButtonHandle)%get files input
            %reset ngui.dirin, since ngui.filein is going to be used, not ngui.dirin
            ngui.dirin = [];
            [file,path]=uigetfile('*.*','Image File', 'MultiSelect','on');%same path for the files
            if iscell(file) %if more then 1 file is selected (cell array)
                ngui.filein = cell(1, length(file));
                for i = 1: length(file)
                    ngui.filein{i} = strcat(path,file{i});
                end
                fileNames = sprintf('%s\n',ngui.filein{:});%convert a cell of char vectors to a multi-line char vector
            else       %if only one file is selected (a character vector)
                ngui.filein = strcat(path,file);
                fileNames = ngui.filein;
            end
            set(ngui.batchInput, 'string', fileNames)
            
            if ~isempty(ngui.filein)
                ngui.enableProcessIn = 'On';
            else
                ngui.enableProcessIn = 'Off';
            end
            if strcmp(ngui.enableProcessOut, 'On') && strcmp(ngui.enableProcessIn, 'On')
                enableProcess = 'On';
            else
                enableProcess = 'Off';
            end
            set(processButtonHandle,'Enable',enableProcess);
        end
        
        
        function parameterButtonCallback(ngui, UIhandle, x) %call back for button "Open Parameter File"
            [FileName, PathName] = uigetfile('*.*', 'Select Parameters File');
            ngui.altparam = ngui.nip.readParametersFile(strcat(PathName, FileName));%check the status    
            if ~isempty(ngui.altparam)
                errordlg(ngui.altparam,'Error')
                return
            end
            
            ngui.parameters=ngui.nip.getParameters;
            
            [editBoxesnew, hSlidernew] = updateControlPanel(ngui.editBoxes, ngui.parameters, ngui.h, ngui.hSlider);
            ngui.editBoxes=editBoxesnew;
            ngui.hSlider=hSlidernew;
        end
        
        function processButtonCallback(ngui, UIhandle, x)
            if ~isempty(ngui.dirin)  %if the input is a directory
                list=dir(ngui.dirin); %get the list of the file names under the directory
                namelist = cell(1,(length(list)-2));
                for i = 1:length(namelist)
                    namelist{i} = list(i+2).name;
                    namelist{i} = strcat(ngui.dirin, filesep, namelist{i});
                end
            elseif ~isempty(ngui.filein) %if the input is files
                namelist = ngui.filein;
            else
                error('The input cannot be empty')
            end
            tElapsed = 600;%initial guess of the processing time for an image = 10 min
            
            if iscell(namelist) % if the input is more than one file
                currentWait = round(tElapsed*(length(namelist))/60,1);
                ngui.waitbar = waitbar(1/length(namelist), ['Processing Image 1 of ' num2str(length(namelist)) ' Approximate Time: ' num2str(currentWait) 'minutes'])
                for i = 1:length(namelist)
                    if ngui.flag == 1, break,end %check the flag. If button "back to control panel" is clicked, flag = 1, otherwise flag = 0
                    tStart = tic;
                    ngui.nip.oneProcess(namelist{i}, ngui.dirout);
                    tElapsed = toc(tStart)
                    currentWait = round(tElapsed*(length(namelist)-i)/60,1);
                    
                    if i<length(namelist)
                        waitbar((i+1)/length(namelist), ngui.waitbar, ['Processing Image ' num2str(i+1) 'of ' num2str(length(namelist)) ' Approximate Time: ' num2str(currentWait) 'minutes'])
                    else
                        close(ngui.waitbar)
                    end
                end
            else  %if the input is only one file
                currentWait = round(tElapsed/60,1);
                ngui.waitbar = waitbar(1, ['Processing Image 1 of 1  Approximate Time: ' num2str(currentWait) 'minutes'])
                tStart = tic;
                ngui.nip.oneProcess(namelist, ngui.dirout);
                tElapsed = toc(tStart)
                close(ngui.waitbar)
            end
        end
        
        function saveButtonCallback(ngui, UIhandle, x)
            
            [FileName, PathName]=uiputfile('*.*','Save parameters as');
            %Do nothing if the file name or path name is a character array
            %when the user cancels the pop-up window, FileName and PathName
            %will be 0 (double).
            if ischar(FileName) && ischar(PathName)
                parameterData=strcat(PathName, FileName);
                %get status
                
                status = ngui.nip.writeParametersFile(parameterData);
                if ~isempty(status)
                    errordlg(status,'Error')
                    return
                end
                
            end
        end
        
        function sliderCallback(ngui, UIhandle, x)
            %(1) Update edit boxes
            num = length(ngui.hSlider);%num of sliders
            sliderValue = cell(1,num);
            for k = 1:num
                sliderValue{k} = num2str(get(ngui.hSlider(k),'Value'));
                set(ngui.editBoxes(k+1),'String', sliderValue{k})
            end
            
            
            
            
        end
        
        function editBoxCallback(ngui, UIhandle, x, paraName,subtype, editBoxID)
            newValueStr = get(UIhandle, 'String');
            newValueNum = str2num(newValueStr);
            status = subtype.check(newValueNum);
            if isempty(status)
                ngui.badDataWarning = false;%no bad data
                textValue = newValueNum;
                sliderID = editBoxID-1;
                set(ngui.hSlider(sliderID),'Value', textValue)
                if (newValueNum > ngui.hSlider(sliderID).Max) && (newValueNum ~= inf)
                    set(ngui.hSlider(sliderID),'Max', newValueNum)
                end
            else
                ngui.badDataWarning = true;%badData has been detected
                errordlg(strcat('Parameter',{' '} , paraName, {': '}, status))
            end
            %             if isempty(newValueNum)
            %                 errordlg(strcat('The value of parameter', paraName, 'is invalid. It must be a number or Inf.'))
            %                 ngui.badDataWarning = true;%badData has been detected
            %             elseif  isnan(newValueNum)
            %                 errordlg(strcat('The value of parameter', paraName, ' is Not a Number. It must be a number or Inf.'))
            %                 ngui.badDataWarning = true;%badData has been detected
            %             elseif numel(newValueNum) ~= 1
            %                 errordlg(strcat('The value of parameter', paraName, ' is not a single number'))
            %                 ngui.badDataWarning = true;%badData has been detected
            %             else
            %                 ngui.badDataWarning = false;%no bad data
            %                 textValue = newValueNum;
            %                 set(ngui.hSlider,'Value', textValue)
            %                 if (newValueNum > ngui.hSlider.Max) && (newValueNum ~= inf)
            %                     set(ngui.hSlider,'Max', newValueNum)
            %                 end
            %                 ngui.badDataWarning
            %             num = length(ngui.hSlider);%num of sliders
            %             textValue = zeros(1,num);
            %             for k = 1:num
            %                 newValueStr = get(ngui.editBoxes(k+1),'String'); %new parameter value string
            %                 newValueNum = str2num(newValueStr); %new parameter value number
            %                 if isempty(newValueNum)
            %                     errordlg(strcat('The value of parameter', num2str(k), 'is invalid. It must be a number or Inf.'))
            %                     ngui.badDataWarning = true;%badData has been detected
            %                 elseif  isnan(newValueNum)
            %                     errordlg(strcat('The value of parameter', num2str(k), ' is Not a Number. It must be a number or Inf.'))
            %                     ngui.badDataWarning = true;%badData has been detected
            %                 elseif numel(newValueNum) ~= 1
            %                     errordlg(strcat('The value of parameter', num2str(k), ' is not a single number'))
            %                     ngui.badDataWarning = true;%badData has been detected
            %                 else
            %                     ngui.badDataWarning = false;%no bad data
            %                     textValue(k) = newValueNum;
            %                     set(ngui.hSlider(k),'Value', textValue(k))
            %                     if (newValueNum > ngui.hSlider(k).Max) && (newValueNum ~= inf)
            %                     set(ngui.hSlider(k),'Max', newValueNum)
            %                     end
            %                  end
            
            
        end
        
        
        
    end
    
    
    %         function
    %         end
end








