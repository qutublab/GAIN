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
        instructionTextbox
        flag
        parent
    end
    
    
    methods
        function handle=getHandle(ngui)
            if isempty(ngui.handle)
                ngui.handle=figure;
                handle=ngui.handle;
            else
                if ishandle(ngui.handle) %check if the window is open
                    handle=ngui.handle;
                else
                    ngui.handle=figure;
                    handle=ngui.handle;
                end
            end
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
            [editBoxes nextActionTextbox,instructionTextbox, h, Handles]=createControlPanel(ngui.parameters, ngui.nip.getActionName,@ngui.forwardButtonCallback, @ngui.backButtonCallback, @ngui.saveButtonCallback, @ngui.quitButtonCallback, @ngui.batchButtonCallback, @ngui.parameterButtonCallback)
            ngui.editBoxes=editBoxes;
            ngui.nextActionTextbox=nextActionTextbox;
            ngui.instructionTextbox = instructionTextbox;
            ngui.handle=[];
            ngui.controlHandles = Handles;
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
            for i=1:numel(ngui.editBoxes);
                valueString=get(ngui.editBoxes(i),'string');
                ngui.parameters(i).value=valueString;
            end
            status=ngui.nip.next(ngui.parameters);
            updateUser(ngui,status);
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
                    figure(ngui.getHandle());
                    imshow(J)
                case NIPState.SegmentedCells
                    I = ngui.nip.getCellImage();
                    CellMask = ngui.nip.getFirstCellMask();
                    rgb = addBorder(I, CellMask, [1, 0, 0]);
                    figure(ngui.getHandle);
                    imshow(rgb)
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
                    %                   rgb = addBorder(rgb, fnm, [0, 0, 1]);
                    %                   rgb = addorder(rgb, fcnm, [0, 1, 0]);
                    %                   rgb = addBorder(rbg, funm, [1, 1, 0]);
                    figure(ngui.getHandle);
                    imshow(rgb)
                    text(ngui.PCell(2,:),ngui.PCell(1,:),ngui.NCellText,'Color','red','FontSize',12,'FontWeight', 'bold')
                   
                case NIPState.ResegmentedNeurites
                    cnm = ngui.nip.getSecondConnectedNeuriteMask();
                    unm = ngui.nip.getSecondUnconnectedNeuriteMask();
                    I = ngui.nip.getCellImage();
                    
                    %also have ngui.nip.getSecondNeuriteMask
                    
                    %rgb = addBorder(I, ngui.Cluster, [0, 1, 1]);
                    %rgb = addBorder(rgb, ngui.Single, [0, 0, 1]);
                    %rgb = addBorder(rgb, ngui.Small, [1, 0, 1]);
                    %rgb = addBorder(rgb, CellMask, [1, 0, 0]);
                    rgb = addBorder(I, ngui.ocbm, [1, 0, 0]);
                    rgb = addBorder(rgb, cnm, [0, 1, 0]);
                    rgb = addBorder(rgb, unm, [1, 1, 0]);
                    figure(ngui.getHandle);
                    imshow(rgb)
                    text(ngui.PCell(2,:),ngui.PCell(1,:),ngui.NCellText,'Color','red','FontSize',12,'FontWeight', 'bold')
                    
                 case NIPState.ResegmentedNeuriteEdges  %3rd Neurite Segmentation - added on 6/17/16
                    cnm = ngui.nip.getThirdConnectedNeuriteMask();
                    unm = ngui.nip.getThirdUnconnectedNeuriteMask();
                    I = ngui.nip.getCellImage();
                    rgb = addBorder(I, ngui.ocbm, [1, 0, 0]);
                    rgb = addBorder(rgb, cnm, [0, 1, 0]);
                    rgb = addBorder(rgb, unm, [1, 1, 0]);
                    figure(ngui.getHandle);
                    imshow(rgb)
                    text(ngui.PCell(2,:),ngui.PCell(1,:),ngui.NCellText,'Color','red','FontSize',12,'FontWeight', 'bold')
                case NIPState.ClosedNeuriteMask
                    ngui.ccnm = ngui.nip.getClosedConnectedNeuriteMask();
                    ngui.cunm = ngui.nip.getClosedUnconnectedNeuriteMask();
                    I = ngui.nip.getCellImage();
                    
                    %Also have ngui.nip.getClosedNeuriteMask
                    
                    %rgb = addBorder(I, ngui.Cluster, [0, 1, 1]);
                    %rgb = addBorder(rgb, ngui.Single, [0, 0, 1]);
                    %rgb = addBorder(rgb, ngui.Small, [1, 0, 1]);
                    %rgb = addBorder(rgb, CellMask, [1, 0, 0]);
                    rgb = addBorder(I, ngui.ocbm, [1, 0, 0]);
                    rgb = addBorder(rgb, ngui.ccnm, [0, 1, 0]);
                    rgb = addBorder(rgb, ngui.cunm, [1, 1, 0]);
                    figure(ngui.getHandle);
                    imshow(rgb)
                    text(ngui.PCell(2,:),ngui.PCell(1,:),ngui.NCellText,'Color','red','FontSize',12,'FontWeight', 'bold')
                    [FileName, PathName]=uiputfile('*.*','Save parameters as');
                    parameterData=strcat(PathName, FileName)
                    ngui.nip.writeParametersFile(parameterData)
                    %             case NIPState.ReadNucleusImage
                    %                  I=ngui.nip.getNucleusImage();
                    %                  f = figure(ngui.getHandle());
                    %                  PFig = get(f, 'Position');
                    %                  PFig(1) = PFig(1) + 210;
                    %                  set(f,'Position', PFig);
                    %                  imshow(I)
                    
                    
                    %                  Preserve the zoomed frame
                    %                  newlimits = [];
                    %                  zoomfig = zoom;
                    %                  set(zoomfig,'ActionPostCallback',@updateLimits); %doing this after zoom
                    %                  set(zoomfig,'Enable','on'); %on
                case NIPState.SegmentedNucleusImageOnce;
                    I=ngui.nip.getFirstNucleusMask();
                    J=ngui.nip.getNucleusImage();
                    %Need to show stuff from before too
                    rgb = addBorder(J, ngui.ocbm, [1, 0, 0]);
                    rgb = addBorder(rgb, ngui.ccnm, [0, 1, 0]);
                    rgb = addBorder(rgb, ngui.cunm, [1, 1, 0]);
                    rgb = addBorder(rgb, I, [0, 0, 1]);
                    figure(ngui.getHandle);
                    imshow(rgb)
                case NIPState.SegmentedNucleusImageTwice
                    I=ngui.nip.getSecondNucleusMask();
                    J=ngui.nip.getNucleusImage();
                    rgb = addBorder(J, ngui.ocbm, [1, 0, 0]);
                    rgb = addBorder(rgb, ngui.ccnm, [0, 1, 0]);
                    rgb = addBorder(rgb, ngui.cunm, [1, 1, 0]);
                    rgb = addBorder(rgb, I, [0, 0, 1]);
                    figure(ngui.getHandle);
                    imshow(rgb)
                case NIPState.OpenedNucleusMask;
                    I=ngui.nip.getOpenedNucleusMask;
                    J=ngui.nip.getNucleusImage();
                    rgb = addBorder(J, ngui.ocbm, [1, 0, 0]);
                    rgb = addBorder(rgb, ngui.ccnm, [0, 1, 0]);
                    rgb = addBorder(rgb, ngui.cunm, [1, 1, 0]);
                    rgb = addBorder(rgb, I, [0, 0, 1]);
                    figure(ngui.getHandle);
                    imshow(rgb)
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
                    text(ngui.PCluster(2,:),ngui.PCluster(1,:),ngui.NClusterText,'Color','cyan','FontSize',8,'FontWeight', 'bold', 'BackgroundColor', [.4, .4, .4])
                    %works only if switch the order of P(1,:)
                    %and P(2,:)  ??
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
                    text(ngui.PCluster(2,:),ngui.PCluster(1,:),ngui.NClusterText,'Color',[0, 0.5, 0.5],'FontSize',12,'FontWeight', 'bold')
                    
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
                    text(ngui.PCell(2,:),ngui.PCell(1,:),ngui.NCellText,'Color','red','FontSize',12,'FontWeight', 'bold')
                    
                case NIPState.CreatedGraph
                    I=ngui.nip.getGraphImage;
                    figure(ngui.getHandle);
                    imshow(I)
                    
                    
                    %case NIPState.ComputedPaths
                    %[FileName, PathName]=uiputfile('*.*','Save parameters as');
                    %parameterData=strcat(PathName, FileName);
                    %disp(parameterData)
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
            
            set(ngui.nextActionTextbox,'string',ngui.nip.getActionName);
            set(ngui.instructionTextbox,'string',ngui.nip.getActionName);%instruction of each parameter; need to use an independent window to replace it
            ngui.parameters=ngui.nip.getParameters;
            for i=1:numel(ngui.parameters)
                if ngui.parameters(i).active
                    enbl='on';
                    ngui.parameters(i).description
                else
                    enbl='off';
                end
                set(ngui.editBoxes(i),'Enable',enbl);
            end
            
            %             Function for obtaining the zoomed X Y limiits for zoom
            %             preservation
            %              function updateLimits(~,evd) %Nested fucntion for preserving zooming limit
            %                 newlimits(2,:) = get(evd.Axes,'YLim');
            %                 newlimits(1,:) = get(evd.Axes,'XLim');
            %
            %              end
        end
        
        function backButtonCallback(ngui,UIhandle,x)
            status=ngui.nip.back();
            updateUser(ngui,status);
            
        end
        function quitButtonCallback(ngui,UIhandle, x)
            close all %need to check if that is sufficient
            rmpath(ngui.parent)   %remove the GAIN directory when the user quits the program
        end
        function batchButtonCallback(ngui,UIhandle, x)
            ngui.batch = figure;
            ngui.batch,%check if it is necessary
            processButtonHandle = uicontrol('Style', 'pushbutton', 'String', 'Process',...
                'Position', [410 0 150 50], 'Callback', @ngui.processButtonCallback, ...
                'Enable', 'Off');
            uicontrol('Style', 'pushbutton', 'String', 'Output Directory',...
                'Position', [0 350 100 25], 'Callback', {@ngui.outputButtonCallback, processButtonHandle});
            uicontrol('Style', 'pushbutton', 'String', 'Input Directory',...
                'Position', [0 275 100 25], 'Callback', {@ngui.inputButtonCallback, processButtonHandle});
            uicontrol('Style', 'pushbutton', 'String', 'Input Files',...
                'Position', [0 225 100 25], 'Callback', {@ngui.inputFileButtonCallback, processButtonHandle});
            controlPanelButtonHandle = uicontrol('Style', 'pushbutton', 'String', 'Back to Control Panel',...
                'Position', [0 0 150 50], 'Callback', {@ngui.controlPanelButtonCallback});
            
            ngui.flag = 0; %set the flag to be 0
            
            filename = uicontrol('Style', 'edit', 'Units', 'pixels',...
                'string', ' ', ...
                'Position', [110 350 300 25],'HorizontalAlignment','right', ...
                'Enable', 'off');
            output = uicontrol('Style', 'edit', 'String', ' ', 'Units', 'pixels',...
                'Position', [110 250 300 25],'HorizontalAlignment','right', ...
                'Enable', 'off');
            %             uicontrol('Style', 'pushbutton', 'String', 'Parameters File',...
            %                 'Position', [0 450 100 25], 'Callback', @ngui.parameterButtonCallback);
            %             parametername = uicontrol('Style', 'text', 'Units', 'pixels',...
            %                 'Position', [110 450 300 25],'HorizontalAlignment','right');
            %             for k = 1:length(ngui.editBoxes)
            %             set(ngui.editBoxes(k),'Enable', 'off'); %disable the editboxes in control panel
            %             end
            
            for k = 1:length(ngui.controlHandles)
                set(ngui.controlHandles{k},'Enable','off')
            end
            %             set(saveButtonHandle,'Enable','off')
            %             set(parameterButtonHandle,'Enable','off')
            %             set(quitButtonHandle,'Enable','off')
            %             set(backButtonHandle,'Enable','off')
            %             set(forwardButtonHandle,'Enable','off')
            %             set(batchButtonHandle,'Enable','off')
            
        end
        function controlPanelButtonCallback(ngui,UIhandle, x) %back to control panel
            %                 error('Terminate batch processing.')
            
            ngui.flag = 1;%clicking the button changes the flag - which terminates the processing
            close(ngui.batch)   %close batch processing window
            close(ngui.waitbar) %close the waitbar window
            for k = 1:length(ngui.controlHandles)
                set(ngui.controlHandles{k},'Enable','on')
            end
        end
        function inputButtonCallback(ngui, UIhandle, x, processButtonHandle)%get directory input
            ngui.dirin=uigetdir('*.*','Image File');
            filename = uicontrol('Style', 'edit', 'Units', 'pixels',...
                'string', ngui.dirin, ...
                'Position', [110 250 300 25],'HorizontalAlignment','left', ...
                'Enable', 'off');
            if ~isempty(ngui.dirin)
                ngui.enableProcessIn = 'On';
            end
            if strcmp(ngui.enableProcessOut, 'On') && strcmp(ngui.enableProcessIn, 'On')
                enableProcess = 'On';
            else
                enableProcess = 'Off';
            end
            set(processButtonHandle,'Enable',enableProcess);
        end
        
        function inputFileButtonCallback(ngui, UIhandle, x, processButtonHandle)%get files input
            [file,path]=uigetfile('*.*','Image File', 'MultiSelect','on');%same path for the files
            file = cellstr(file); %convert char to cell
            path = cellstr(path); %convert char to cell
            ngui.filein = cell(1, length(file));
            
            for i = 1: length(file)
                ngui.filein{i} = strcat(path,file{i});
            end
            filein = strcat(ngui.filein{1}, ', ', ngui.filein{2}, ', ', ngui.filein{3})
            %             x = celldisp(filein)
            %             class(x)
            
            %do we want to convert ngui.filein back to string so that we
            %can put it into the textbox below??
            filename = uicontrol('Style', 'edit', 'Units', 'pixels',...
                'string', filein, ...
                'Position', [110 250 300 25],'HorizontalAlignment','left', ...
                'Enable', 'off');% display the file names
            if ~isempty(ngui.dirin)
                ngui.enableProcessIn = 'On';
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
            ngui.altparam = ngui.nip.readParametersFile(strcat(PathName, FileName));
            if ~isempty(ngui.altparam)
                error(ngui.altparam)
            end
            ngui.parameters=ngui.nip.getParameters;
            [editBoxesnew] = updateControlPanel(ngui.parameters, ngui.h);
            ngui.editBoxes=editBoxesnew;
        end
        
        function outputButtonCallback(ngui, UIhandle, x, processButtonHandle)
            ngui.dirout=uigetdir('*.*','Store Data');
            output = uicontrol('Style', 'edit', 'Units', 'pixels',...
                'string', ngui.dirout, ...
                'Position', [110 350 300 25],'HorizontalAlignment','left', ...
                'Enable', 'off');
            ngui.enableProcessOut = 'On'; %do we need to check if ~isempty(ngui.dirin)??
            if strcmp(ngui.enableProcessOut, 'On') && strcmp(ngui.enableProcessIn, 'On')
                enableProcess = 'On';
            else
                enableProcess = 'Off';
            end
            set(processButtonHandle,'Enable',enableProcess);
        end
        
        function processButtonCallback(ngui, UIhandle, x)
            ngui.dirin;
            ngui.dirout;
            list=dir(ngui.dirin);
            namelist = cell(1,(length(list)-2));
            for i = 1:length(namelist)
                namelist{i} = list(i+2).name;
                namelist{i} = strcat(ngui.dirin, filesep, namelist{i});
            end
            tElapsed = 600;%initial guess of the processing time for an image = 10 min
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
        end
        
        function saveButtonCallback(ngui, UIhandle, x)
            [FileName, PathName]=uiputfile('*.*','Save parameters as');
            parameterData=strcat(PathName, FileName);
            ngui.nip.writeParametersFile(parameterData);
        end
        
        %         function
        %         end
    end
end
