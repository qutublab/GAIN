
%version-2/9/17
%create intermediate images. Can be called by both GUI and batch mode
function [rgb,cluster] = createIntermediateImages(state,nip)
%Output:
%rgb = processed image
%cluster = an indicator shows whether any cluster has been identified

%iniitally, assume there is at least one cluster in an image; 
cluster = '';

%stateNum = state number in NIPState
% nip=NeuronImageProcessor;
rgb = [];
nipState = nip.getState();

if state > nipState
    error('[createIntermediateImages]: The desired state %s is greater than the image processor state %s.', char(state), char(nipState))
end
switch(state)
    
    case NIPState.ReadImages
        
        rgb = nip.getNucleusImage();
        
    case NIPState.SegmentedNucleusImageOnce
        
        I=nip.getFirstNucleusMask();
        J=nip.getNucleusImage();
        
        rgb = addBorder(J, I, [0, 0, 1]);
    case NIPState.SegmentedNucleusImageTwice
        I=nip.getSecondNucleusMask();
        J=nip.getNucleusImage();
        rgb = addBorder(J, I, [0, 0, 1]);
    case NIPState.OpenedNucleusMask
        I=nip.getOpenedNucleusMask;
        J=nip.getNucleusImage();
        rgb = addBorder(J, I, [0, 0, 1]);
        
    case NIPState.IdentifiedNucleusClusters
        ndA = nip.getNucleusData(); %The property names are shown on the control panel. Need to solve this problem
        L = nip.getNucleusAllLabeled(); %labeled nucleus image matrix
        Cluster=false(size(L));
        Single = false(size(L));
        for i = 1:numel(ndA)
            if ndA(i).cluster
                Cluster = L==i | Cluster;
            else
                Single = L==i | Single;
            end
        end
        J=nip.getNucleusImage();
        rgb = addBorder(J, Cluster, [0, 1, 1]);
        rgb = addBorder(rgb, Single, [0, 0, 1]);
    case NIPState.CalculatedNominalMeanNucleusArea
        ndA = nip.getNucleusData();
        J=nip.getNucleusImage();
        N = zeros(1, length(ndA)); %neuron count of each cluster
        P = zeros(2, length(ndA)); %position of each cluster
        for i = 1:numel(ndA)
            if ndA(i).cluster
                N(i) = ndA(i).numNuclei;
                center = ndA(i).centroid;
                P(1,i) = center(2);
                P(2, i) = center(1);
            end
        end
        
        L = nip.getNucleusAllLabeled(); %labeled nucleus image matrix
        Cluster=false(size(L));
        Single = false(size(L));
        for i = 1:numel(ndA)
            if ndA(i).cluster
                Cluster = L==i | Cluster;
            else
                Single = L==i | Single;
            end
        end
        
        
        Background = intersect(find(P(1,:) == 0),find(P(2,:) == 0)); %find the indices of background,i.e.coordinate(0,0)
        %It is meaningless if a cluster has a position of (0,0). In that case, the cluster is recognized as background and removed
        N(Background) = []; %Eliminate the count for the backgound
        P(:,Background) = [];
        
        %Check if there is any cluster %added on 1/10/17
        if isempty(P)
            %msgbox('No cluster has been identified in the image.');%create a message dialog box
            %If no cluster has been identified,change the message shown on
            %the legend of figure window
            cluster = 'No cluster has been identified';
            %Then, change nothing to the image.
            rgb = addBorder(J, Cluster, [0, 1, 1]);
            rgb = addBorder(rgb, Single, [0, 0, 1]);
        else
            NCluster = reshape(N, numel(N), 1);
            NClusterText = cellstr(num2str(NCluster));
            NClusterText = strtrim(NClusterText); %remove the leading white space from the strings
            PCluster = reshape(P,2, numel(P)/2);
            
            rgb = addBorder(J, Cluster, [0, 1, 1]);
            rgb = addBorder(rgb, Single, [0, 0, 1]);
            %overlay counts on clusters
            for n = 1:numel(NClusterText)
                label = NClusterText{n};
                row = PCluster(1,n);
                col = PCluster(2,n);
                heightInPixels = 30;
                color = [1 1 1];
                rgb = overLayText(rgb, label, [row col], heightInPixels, color);
            end
        end
        
    case NIPState.CalculatedMinNucleusArea
        
        ndA = nip.getNucleusData();
        L = nip.getNucleusAllLabeled(); %labeled nucleus image matrix
        Cluster=false(size(L));
        Single = false(size(L));
        for i = 1:numel(ndA)
            if ndA(i).cluster
                Cluster = L==i | Cluster;
            else
                Single = L==i | Single;
            end
        end
        Small=false(size(L));
        for i = 1:numel(ndA)
            if ndA(i).small
                Small = L==i | Small;
            end
        end
        N = zeros(1, length(ndA)); %neuron count of each cluster
        P = zeros(2, length(ndA)); %position of each cluster
        for i = 1:numel(ndA)
            if ndA(i).cluster
                N(i) = ndA(i).numNuclei;
                center = ndA(i).centroid;
                P(1,i) = center(2);
                P(2, i) = center(1);
            end
        end
        
        Background = intersect(find(P(1,:) == 0),find(P(2,:) == 0)); %find the indices of background,i.e.coordinate(0,0)
        N(Background) = []; %Eliminate the count for the backgound
        P(:,Background) = [];
        %Check if there is any cluster   %added on 1/10/17
        if isempty(P)
            %If no cluster has been identified, report on the legend
            cluster = 'No cluster has been identified';
            %Then, change nothing to the image.
            J=nip.getNucleusImage();
             rgb = addBorder(J, Cluster, [0, 1, 1]);%cyan
        rgb = addBorder(rgb, Single, [0, 0, 1]);%blue
        rgb = addBorder(rgb, Small, [1, 0, 1]);%magenta
        else
        NCluster = reshape(N, numel(N), 1);
        NClusterText = cellstr(num2str(NCluster));
        NClusterText = strtrim(NClusterText); %remove the leading white space from the strings
        PCluster = reshape(P,2, numel(P)/2);
        
        J=nip.getNucleusImage();
        rgb = addBorder(J, Cluster, [0, 1, 1]);%cyan
        rgb = addBorder(rgb, Single, [0, 0, 1]);%blue
        rgb = addBorder(rgb, Small, [1, 0, 1]);%magenta
        %         rgb = insertText(rgb,[PCluster(2,:)',PCluster(1,:)'],NClusterText,'TextColor','white','FontSize',28, 'BoxOpacity',0);
        
        %temp 10/28/16
        %overlay counts on clusters
        for n = 1:numel(NClusterText)
            label = NClusterText{n};
            row = PCluster(1,n);
            col = PCluster(2,n);
            heightInPixels = 30;
            color = [1 1 1];
            rgb = overLayText(rgb, label, [row col], heightInPixels, color);
        end   
        end
    case NIPState.SegmentedCells
        I = nip.getCellImage();
        CellMask = nip.getFirstCellMask();
        rgb = addBorder(I, CellMask, [1, 0, 0]);
    case NIPState.SeparatedBodiesFromNeurites
        %Still show the neurite segmentation from previous step
        CellMask = nip.getFirstCellMask();%from previous step: cell bodies and neurites
        cbd = nip.getCellBodyData();
        ocbm = nip.getOpenedCellBodyMask();%only cell bodies
        neuriteMask = CellMask & ~ocbm; %only neurites
        %                     cbaL = nip.getCellBodyAllLabeled();
        %                     fnm = nip.getFirstNeuriteMask;
        %                     fcnm = nip.getFirstConnectedNeuriteMask;
        %                     funm = nip.getFirstUnconnectedNeuriteMask;
        
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
        %check if there is any cell identified  %1/10/17
        if isempty(P)
            %If no cell has been identified, change nothing to the image.
             I = nip.getCellImage();
        rgb = addBorder(I, ocbm, [1, 0, 0]);
        %show the neurite in green
        rgb = addBorder(rgb,neuriteMask, [0,1,0]);
        else
        NCell = reshape(N, numel(N), 1);
        NCellText = cellstr(num2str(NCell));
        NCellText = strtrim(NCellText); %remove the leading white space from the strings
        PCell = reshape(P,2, numel(P)/2);
        
        I = nip.getCellImage();
        rgb = addBorder(I, ocbm, [1, 0, 0]);
        %show the neurite in green
        rgb = addBorder(rgb,neuriteMask, [0,1,0]);
        
        %         rgb = insertText(rgb,[PCell(2,:)',PCell(1,:)'],NCellText,'TextColor','white','FontSize',28, 'BoxOpacity',0);
        %temp 10/28/16
        %overlay counts on clusters
        for n = 1:numel(NCellText)
            label = NCellText{n};
            row = PCell(1,n);
            col = PCell(2,n);
            heightInPixels = 30;
            color = [1 1 1];
            rgb = overLayText(rgb, label, [row col], heightInPixels, color);
        end
        end
        
    case NIPState.ResegmentedNeurites
        cnm = nip.getSecondConnectedNeuriteMask();
        unm = nip.getSecondUnconnectedNeuriteMask();
        ocbm = nip.getOpenedCellBodyMask();%only cell bodies
        cbd = nip.getCellBodyData();
        I = nip.getCellImage();
        
        
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
         %check if there is any cell identified  %1/10/17
        if isempty(P)
              %If no cell has been identified, change nothing to the image.
             rgb = addBorder(I, ocbm, [1, 0, 0]);
        rgb = addBorder(rgb, cnm, [0, 1, 0]);
        rgb = addBorder(rgb, unm, [1, 1, 0]);
        else
        NCell = reshape(N, numel(N), 1);
        NCellText = cellstr(num2str(NCell));
        NCellText = strtrim(NCellText); %remove the leading white space from the strings
        PCell = reshape(P,2, numel(P)/2);
        %also have ngui.nip.getSecondNeuriteMask
        
        rgb = addBorder(I, ocbm, [1, 0, 0]);
        rgb = addBorder(rgb, cnm, [0, 1, 0]);
        rgb = addBorder(rgb, unm, [1, 1, 0]);
        %         rgb = insertText(rgb,[PCell(2,:)',PCell(1,:)'],NCellText,'TextColor','white','FontSize',28, 'BoxOpacity',0);
        %temp 10/28/16
        %overlay counts on clusters
        for n = 1:numel(NCellText)
            label = NCellText{n};
            row = PCell(1,n);
            col = PCell(2,n);
            heightInPixels = 30;
            color = [1 1 1];
            rgb = overLayText(rgb, label, [row col], heightInPixels, color);
        end
        end
        
    case NIPState.ResegmentedNeuriteEdges  %3rd Neurite Segmentation - added on 6/17/16
        cnm = nip.getThirdConnectedNeuriteMask();
        unm = nip.getThirdUnconnectedNeuriteMask();
        ocbm = nip.getOpenedCellBodyMask();%only cell bodies
        cbd = nip.getCellBodyData();
        
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
        %check if there is any cell identified  %1/10/17
        if isempty(P)
             %If no cluster has been identified, change nothing to the image.
             I = nip.getCellImage();
        rgb = addBorder(I, ocbm, [1, 0, 0]);
        rgb = addBorder(rgb, cnm, [0, 1, 0]);
        rgb = addBorder(rgb, unm, [1, 1, 0]);
        else
        NCell = reshape(N, numel(N), 1);
        NCellText = cellstr(num2str(NCell));
        NCellText = strtrim(NCellText); %remove the leading white space from the strings
        PCell = reshape(P,2, numel(P)/2);
        
        I = nip.getCellImage();
        rgb = addBorder(I, ocbm, [1, 0, 0]);
        rgb = addBorder(rgb, cnm, [0, 1, 0]);
        rgb = addBorder(rgb, unm, [1, 1, 0]);
        %         rgb = insertText(rgb,[PCell(2,:)',PCell(1,:)'],NCellText,'TextColor','white','FontSize',28, 'BoxOpacity',0);
        %temp 10/28/16
        %overlay counts on clusters
        for n = 1:numel(NCellText)
            label = NCellText{n};
            row = PCell(1,n);
            col = PCell(2,n);
            heightInPixels = 30;
            color = [1 1 1];
            rgb = overLayText(rgb, label, [row col], heightInPixels, color);
        end
        end
        
    case NIPState.ClosedNeuriteMask
        ccnm = nip.getClosedConnectedNeuriteMask();
        cunm = nip.getClosedUnconnectedNeuriteMask();
        ocbm = nip.getOpenedCellBodyMask();%only cell bodies
        cbd = nip.getCellBodyData();
        
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
         %check if there is any cell identified  %1/10/17
        if isempty(P)
             %If no cell has been identified, change nothing to the image.
             I = nip.getCellImage();
        rgb = addBorder(I, ocbm, [1, 0, 0]);
        rgb = addBorder(rgb, ccnm, [0, 1, 0]);
        rgb = addBorder(rgb, cunm, [1, 1, 0]);
        else
        NCell = reshape(N, numel(N), 1);
        NCellText = cellstr(num2str(NCell));
        NCellText = strtrim(NCellText); %remove the leading white space from the strings
        PCell = reshape(P,2, numel(P)/2);
        
        I = nip.getCellImage();
        rgb = addBorder(I, ocbm, [1, 0, 0]);
        rgb = addBorder(rgb, ccnm, [0, 1, 0]);
        rgb = addBorder(rgb, cunm, [1, 1, 0]);
        
        %         rgb = insertText(rgb,[PCell(2,:)',PCell(1,:)'],NCellText,'TextColor','white','FontSize',28, 'BoxOpacity',0);
        %temp 10/28/16
        %overlay counts on clusters
        for n = 1:numel(NCellText)
            label = NCellText{n};
            row = PCell(1,n);
            col = PCell(2,n);
            heightInPixels = 30;
            color = [1 1 1];
            rgb = overLayText(rgb, label, [row col], heightInPixels, color);
        end
        end
        
    case NIPState.Done
        
        %need to create the final image
        rgb = nip.getResultsImage;
        
end


end