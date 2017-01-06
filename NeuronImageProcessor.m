% State                   Methods available in addition to methods available
%                         at earlier states
% --------------------------------------------------------------------------
% Ready
% ReadNucleusImage        getNucleusImage
% SegmentedNucleusImage   getNucleusMask, getNucleusAllLabeled, getNucleusData
% ReadCellImage           getCellImage
% SegmentedCellImage      getCellBodyMask, getConnectedNeuriteMask,
%                         getUnconnectedNeuriteMask
% CreatedGraph            getGraphImage, getCellBodyData
% ComputedPaths

classdef NeuronImageProcessor < handle
    properties (Access = private)
        optimization = false
        state
        fileName
%        nucleusFileName
%        cellFileName
        parameters
        processParameterUpdates
        nucleusThresh1
        nucleusThresh2
        cellThresh1
        cellThresh2
        nucleusImage
        firstNucleusMask
        secondNucleusMask
        openedNucleusMask
        nucleusAllLabeled
        nucleusDataArr
        medianSingleNucleusArea
        nominalMeanNucleusArea
        minNucleusArea
        cellImage
        firstCellMask
        cellBodyDataArr
        openedCellBodyMask
        extendedCellBodyMask
        gradientMag
        firstEdges
        secondEdges
        firstNeuriteMask
        firstConnectedNeuriteMask
        firstUnconnectedNeuriteMask
        cellBodyNumberGrid
        numCellBodies
        secondCellMask
        secondNeuriteMask
        secondConnectedNeuriteMask
        secondUnconnectedNeuriteMask
        neuriteExtensions
        originalNeurites
        thirdNeuriteMask
        thirdConnectedNeuriteMask
        thirdUnconnectedNeuriteMask
%         connectedNeuriteMask
%         unconnectedNeuriteMask
        closedNeuriteMask
        closedConnectedNeuriteMask
        closedUnconnectedNeuriteMask
        skeleton
        branchPoints
        endPoints
        connectedSkeleton
        unconnectedSkeleton
        waitBarFlag
        timingFlag
        graph
    end
    methods
        function nip = NeuronImageProcessor()
            nip.parameters = Parameters();
            nip.parameters.initialize();
            nip.state = NIPState.Ready;
            nip.processParameterUpdates = true;
        end

        function neuronBodyDataArr = processForOptimization(nip, parameters)
            nip.parameters = parameters;
            nip.processParameterUpdates = false;
            nip.state = NIPState.Ready;
            nip.optimization = true;
            while nip.state ~= NIPState.ClosedNeuriteMask
                status = nip.next();
                if ~isempty(status)
                    error(status);
                end
            end
            neuronBodyDataArr = nip.getCellBodyData();
            nip.optimization = false;
        end
        
        function status = oneProcess(nip, fileName, outputDir)
            status = '';
            status = createDir(outputDir);
            if ~isempty(status)
                return;
            end
            nip.parameters.fileName = fileName;
            nip.processParameterUpdates = false;
            nip.state = NIPState.Ready;
            while nip.state ~= NIPState.Done
               status = nip.next();
               if ~isempty(status)
                   return;
               end
            end
            
%             % Use filename (without extension) as a prefix for naming
%             % output files
%             dotIndices = strfind(fileName, '.');
%             if isempty(dotIndices)
%                 prefix = fileName;
%             else
%                 lastDotIndex = dotIndices(end);
%                 prefix = fileName(1:(lastDotIndex - 1));
%             end
%             fullPathPrefix = strcat(outputDir, filesep, prefix);
            
            writeOutput(nip, fileName, outputDir);
        end
        
        function resetState(nip)
            nip.state = NIPState.Ready;
        end

        function processImage(nip, parameters, steps)
            nip.parameters = parameters;
            nip.processParameterUpdates = false;
%            nip.state = NIPState.Ready;
            stepCount = 0;
            if nargin <= 2
                steps = Inf;
            end
            while nip.state ~= NIPState.Done & stepCount < steps
                status = nip.next();
                if ~isempty(status)
                    error(status);
                end
                stepCount = stepCount + 1;
            end
        end
        
        
        

        function status = readParametersFile(nip, fileName)        
            status = nip.parameters.readFromFile(fileName);
        end

        function status = writeParametersFile(nip, fileName)        
            status = nip.parameters.writeToFile(fileName);
        end

        function status = back(nip, oneParamArr)
            if nargin > 0
                status = nip.parameters.update(oneParamArr);
            end
            if ~strcmp(status, '') return; end
            if (nip.state ~= NIPState.Ready)
                nip.state = NIPState(uint16(nip.state) - 1); 
            end
        end
        
        function status = next(nip, oneParamArr)
            if nip.processParameterUpdates
                status = nip.parameters.update(oneParamArr);
                if ~strcmp(status, '') return; end
            end
            switch nip.state
                case NIPState.Ready
                    tstart = tic;
                    status = nip.readImageFile();
                    elapsedTime = toc(tstart);
                case NIPState.ReadImages
                    tstart = tic;
                    status = nip.firstNucleusSegmentation();
                    elapsedTime = toc(tstart);
                case NIPState.SegmentedNucleusImageOnce
                    tstart = tic;
                    status = nip.secondNucleusSegmentation();   
                    elapsedTime = toc(tstart);
                case NIPState.SegmentedNucleusImageTwice
                    tstart = tic;
                    status = nip.openNucleusMask();
                    elapsedTime = toc(tstart);
                case NIPState.OpenedNucleusMask
                    tstart = tic;
                    status = nip.identifyNucleusClusters();
                    elapsedTime = toc(tstart);
                case NIPState.IdentifiedNucleusClusters
                    tstart = tic;
                    status = nip.calculateNominalMeanNucleusArea();
                    elapsedTime = toc(tstart);
                case NIPState.CalculatedNominalMeanNucleusArea
                    tstart = tic;
                    status = nip.calculateMinNucleusArea();
                    elapsedTime = toc(tstart);
                case NIPState.CalculatedMinNucleusArea
                    tstart = tic;
                    status = nip.segmentCellBodies();
                    elapsedTime = toc(tstart);
                case NIPState.SegmentedCells
                    tstart = tic;
                    status = nip.isolateCellBodies();
                    elapsedTime = toc(tstart);
                case NIPState.SeparatedBodiesFromNeurites
                    tstart = tic;
                    status = nip.resegmentNeurites();
                    elapsedTime = toc(tstart);
                case NIPState.ResegmentedNeurites
                    tstart = tic;
                    status = nip.resegmentNeuriteEdges();
                    elapsedTime = toc(tstart);
                case NIPState.ResegmentedNeuriteEdges
                    tstart = tic;
                    status = nip.closeNeuriteMask();
                    elapsedTime = toc(tstart);
                case NIPState.ClosedNeuriteMask
                    tstart = tic;
                    status = nip.skeletonizeNeurites();
                    elapsedTime = toc(tstart);
                    if isempty(status)
                        status = nip.createNeuriteGraph();
                        elapsedTime(2) = toc(tstart);
                        if isempty(status)
                            status = nip.findLongPaths();
                            elapsedTime(3) = toc(tstart);
                        end
                    end
%                case NIPState.CreatedGraph
%                case NIPState.ComputedPaths
%                    status = '';
                case NIPState.Done
                    status = '';
                otherwise error('[NeuronImageProcessor.next] Unexpected state: %s', char(nip.state));
            end
            if isempty(status) && nip.state ~= NIPState.Done
                nip.state = NIPState(nip.state + 1);
                if nip.timingFlag
                    fprintf('State=%s: ', char(nip.state));
                    if numel(elapsedTime) == 1
                        fprintf('%f seconds\n', elapsedTime);
                    else
                        fprintf('%f seconds;', elapsedTime(end));
                        prevSum = 0;
                        for t = 1:numel(elapsedTime)
                            et = elapsedTime(t) - prevSum;
                            fprintf(' %f', et);
                            prevSum = prevSum + et;
                        end
                        fprintf('\n');
                    end
                end
            end
        end
        
        
        function oneParamArr = getParameters(nip)
            % generateOneParameterArr makes all OneParameters inactive
            oneParamArr = nip.parameters.generateOneParameterArr();
            switch nip.state
                case NIPState.Ready
                    activate = [];
                case NIPState.ReadImages
                    activate = 2;
                case NIPState.SegmentedNucleusImageOnce
                    activate = 3;
                case NIPState.SegmentedNucleusImageTwice
                    activate = 4;
                case NIPState.OpenedNucleusMask
                    activate = 5;
                case NIPState.IdentifiedNucleusClusters
                    activate = 6;
                case NIPState.CalculatedNominalMeanNucleusArea
                    activate = 7;
                case NIPState.CalculatedMinNucleusArea
                    activate = 8;
                case NIPState.SegmentedCells
                    activate = 9;
                case NIPState.SeparatedBodiesFromNeurites
                    activate = 10;
                case NIPState.ResegmentedNeurites
                    activate = 11;
                case NIPState.ResegmentedNeuriteEdges
                    activate = 12;
                case NIPState.ClosedNeuriteMask
                    activate = 13;
                case NIPState.Done
                    activate = [];
                otherwise error('[NeuronImageProcessor.getParameters] Unexpected state: %s', char(nip.state));
            end

            for i = 1:numel(activate)
                oneParamArr(activate(i)).active = true;
            end
        end
        
        function status = readImageFile(nip)
            status = '';
            imageFileName = nip.parameters.fileName;
            if isempty(imageFileName)
                status = 'File name not specified';
                return;
            end
            try
                info = imfinfo(imageFileName);
                numImages = numel(info);
                if numImages == 0
                    status = 'Image file is empty';
                    return;
                else
                    nip.cellImage = readAsGray(imageFileName);
                    % Rescale pixel values in an image of double values
                    nip.cellImage = mat2gray(nip.cellImage);
                    if numImages > 1
                        nip.nucleusImage = readAsGray(imageFileName, 2);
                        % Rescale pixel values in an image of double values
                        nip.nucleusImage = mat2gray(nip.nucleusImage);
                        sz1 = size(nip.cellImage);
                        sz2 = size(nip.nucleusImage);
                        if ~all(sz1 == sz2)
                            status = 'File images are not the same size';
                            return;
                        end
                    else
                        status = 'Image file does not contain 2 images';
                    end
                end
            catch E
                status = E.message;
            end
        end

        
        function status = firstNucleusSegmentation(nip)
            status = '';
            thresh1 = graythresh(nip.nucleusImage);
            thresh1 = min(1, thresh1 * nip.parameters.dapiThreshFactor1);
            nip.nucleusThresh1 = thresh1;
            nip.firstNucleusMask = im2bw(nip.nucleusImage, thresh1);
            nip.firstNucleusMask = imfill(nip.firstNucleusMask, 'holes');
        end

        function status = secondNucleusSegmentation(nip)
            status = '';
            thresh2 = graythresh(nip.nucleusImage(~nip.firstNucleusMask));
            thresh2 = min(1, thresh2 * nip.parameters.dapiThreshFactor2);
            nip.nucleusThresh2 = thresh2;
            nip.secondNucleusMask = im2bw(nip.nucleusImage, thresh2) | nip.firstNucleusMask;
            nip.secondNucleusMask = imfill(nip.secondNucleusMask, 'holes');
        end

        function status = openNucleusMask(nip)
            status = '';
            se = strel('disk', nip.parameters.nucleusOpenDiskRadius, 0);
            nip.openedNucleusMask = imopen(nip.secondNucleusMask, se);
        end

        function status = identifyNucleusClusters(nip)
            status = '';
            % First, find unclustered nuclei
            [L numLabels] = bwlabel(nip.openedNucleusMask);
            nip.nucleusAllLabeled = L;

%            minSolidity = Inf;
%            maxSolidity = -Inf;
            
%            areaArr = zeros(numLabels, 1);
%            solidityArr = zeros(numLabels, 1);

            % Clear out previous contents of nucleusDataArr
            nip.nucleusDataArr = NucleusData.empty;
            nonclusterCount = 0;

% Older, slower version
%            for l = numLabels:-1:1
%                M = L == l;
%                % Solidity is the ratio of the area of an object to the area
%                % of its convex hull
%                props = regionprops(M, 'Area','Solidity', 'Centroid');
%                solidity = props.Solidity;
%                cluster = solidity < nip.parameters.areaToConvexHullRatio;
%                if ~cluster
%                    nonclusterCount = nonclusterCount + 1;
%                end
%                centroid = props.Centroid;
%                nip.nucleusDataArr(l) = NucleusData(l, props.Area, props.Solidity, cluster, centroid);
%                
%%                minSolidity = min(minSolidity, solidity);
%%                maxSolidity = max(maxSolidity, solidity);
%            end

            % Newer, faster version
            props = regionprops(L, 'Area', 'Solidity', 'Centroid');
            cluster = [props.Solidity] < nip.parameters.areaToConvexHullRatio;
            nonclusterCount = numLabels - sum(cluster);
            for i = numLabels:-1:1
                nip.nucleusDataArr(i) = NucleusData(i, props(i).Area, props(i).Solidity, cluster(i), props(i).Centroid);
            end

            if (~nip.optimization) && (nonclusterCount == 0)
                status = sprintf('No non-clustered nuclei were found at an areaToConvexHullRatio of %f',...
                   nip.parameters.areaToConvexHullRatio); 
            end
        end


        function status = calculateNominalMeanNucleusArea(nip)
            status = '';
            areaArr = arrayfun(@(nd)nd.area, nip.nucleusDataArr);
            singleNuclei = arrayfun(@(nd)~nd.cluster, nip.nucleusDataArr);
            singleNucleusArea = areaArr(singleNuclei);
            if numel(singleNucleusArea) == 0
                % Normally, this point can be reached only during parameter
                % optimization because the identifyNucleusClusters method
                % returns a non-empty status string informing the user that
                % only clustered nuclei were found.
                % 
                % During parameter optimization, a nominalMeanNucleusArea
                % must be computed that will signal to the parameter
                % optimizer the poor choice of parameters.  An extremely
                % small positive value for the medianSingleNucleusArea
                % would result in large cell counts (provided that
                % minNucleusArea is also small).
                nip.medianSingleNucleusArea = realmin;
                nip.nominalMeanNucleusArea = realmin;
                fprintf('[NeuronImageProcessor.calculateNominalMeanNucleusArea] Forcing nominalMeanNucleusArea for parameter optimization!\n');
            else
                nip.medianSingleNucleusArea = median(singleNucleusArea);
                nip.nominalMeanNucleusArea = nip.medianSingleNucleusArea * nip.parameters.medianNucleusAdjustmentFactor;
            end
            for i = 1:numel(nip.nucleusDataArr)
                area = nip.nucleusDataArr(i).area;
                % The number of nuclei represented by an object is computed
                % in the same way regardless of the existence of a cluster
%                if nip.nucleusDataArr(i).cluster
                numNuclei = round(area / nip.nominalMeanNucleusArea);
%                else
%                    numNuclei = 1;
%                end
                nip.nucleusDataArr(i).numNuclei = numNuclei;
            end
        end

        function status = calculateMinNucleusArea(nip)
            status = '';
            nip.minNucleusArea = max(1, ceil(nip.medianSingleNucleusArea / nip.parameters.median2MinimumNucleusAreaRatio));
            for i = 1:numel(nip.nucleusDataArr)
                if nip.nucleusDataArr(i).area < nip.minNucleusArea
                    nip.nucleusDataArr(i).small = true;
                    nip.nucleusDataArr(i).numNuclei = 0;
                else
                    nip.nucleusDataArr(i).small = false;
                end
            end
%            assignNucleusCounts(nip.cellBodyNumberGrid, ...
%                nip.nucleusAllLabeled, nip.cellBodyDataArr, ...
%                nip.nucleusDataArr, nip.nominalMeanNucleusArea, ...
%                nip.minNucleusArea);
%for i = 1:numel(nip.cellBodyDataArr)
%fprintf('[NeuronImageProcessor.calculateMinNucleusArea] %d: numberOfNuclei=%d\n', i, nip.cellBodyDataArr(i).numberOfNuclei);
%end
        end


        function status = segmentCellBodies(nip)
            status = '';
            thresh1 = graythresh(nip.cellImage);
            thresh1 = min(1, thresh1 * nip.parameters.tujThreshFactor1);
            nip.cellThresh1 = thresh1;
            nip.firstCellMask = im2bw(nip.cellImage, thresh1);
%             nip.firstCellMask = imfill(nip.firstCellMask, 'holes');

        end

        function status = isolateCellBodies(nip)
            status = '';
            se = strel('disk', nip.parameters.neuriteRemovalDiskRadius, 0);
            nip.openedCellBodyMask = imfill(imopen(nip.firstCellMask, se), 'holes');
            nip.firstNeuriteMask = nip.firstCellMask & ~nip.openedCellBodyMask;
            % imopen can remove single pixels from cell bodies, so eliminate
            % all single pixel neurite sections
            nip.firstNeuriteMask = bwareaopen(nip.firstNeuriteMask, 2); 
            nip.firstConnectedNeuriteMask = imreconstruct(nip.openedCellBodyMask, nip.firstCellMask) & nip.firstNeuriteMask;
            nip.firstUnconnectedNeuriteMask = nip.firstNeuriteMask & ~ nip.firstConnectedNeuriteMask;
            [nip.cellBodyNumberGrid nip.numCellBodies] = bwlabel(nip.openedCellBodyMask);
            nip.cellBodyDataArr = processCellBodies(nip.openedCellBodyMask,...
                nip.cellBodyNumberGrid, nip.numCellBodies,...
                nip.openedNucleusMask, nip.nominalMeanNucleusArea,...
                nip.minNucleusArea);
        end

        function status = resegmentNeurites(nip)
            status = '';
            % Use thresholding on the background to find more signal
            thresh2 = graythresh(nip.cellImage(~nip.firstCellMask));
            thresh2 = min(1, thresh2 * nip.parameters.tujThreshFactor2);
            nip.cellThresh2 = thresh2;

            nip.secondCellMask = im2bw(nip.cellImage, thresh2) | nip.firstCellMask;
            
            % Use imopen to remove neurites leaving extended cell bodies
            se = strel('disk', nip.parameters.neuriteRemovalDiskRadius, 0);
            nip.extendedCellBodyMask = imopen(nip.secondCellMask, se);
            % Isolate neurites
            nip.secondNeuriteMask = (nip.secondCellMask & ~nip.extendedCellBodyMask) | nip.firstNeuriteMask;
            % imopen can remove single pixels from a body that should not be
            % recognized as neurites
            nip.secondNeuriteMask = bwareaopen(nip.secondNeuriteMask, 2);
            

            % Use edge detection as an additional way to find neurites
            nip.gradientMag = imgradient(nip.cellImage);
%            gmagThresh1 = min(1, graythresh(nip.gradientMag) * nip.parameters.tujThreshFactor2);
            gmagThresh1 = graythresh(nip.gradientMag);
            edges1 = im2bw(nip.gradientMag, gmagThresh1);
            
            nip.firstEdges = edges1;
            
            % Remove edges that fall within a cell body
%             edges1 = edges1 & ~nip.openedCellBodyMask;
            % Fill-in neurite edges
            edgeObjects = imclose(edges1, strel('disk', round(nip.parameters.neuriteRemovalDiskRadius / 2), 0));
            % Some edges are from the cell body and may be just outside the
            % already determined cell body.  When finding neurite edges,
            % these cell body edges can be (partially) eliminated by using
            % imopen on the combination of the edge objects and the already
            % determined cell body.
            edgeCellBodies = imopen(edgeObjects | nip.openedCellBodyMask, strel('disk', nip.parameters.neuriteRemovalDiskRadius, 0));
            edgeNeurites = edgeObjects & ~edgeCellBodies;
            
%             nip.secondNeuriteMask = nip.secondNeuriteMask | edgeNeurites;
            
            
%             nip.secondNeuriteMask = ((nip.secondCellMask | sobelNeurites) & ~nip.extendedCellBodyMask) | nip.firstNeuriteMask;
%             nip.secondNeuriteMask = ((nip.secondCellMask | edgeNeurites) & ~nip.extendedCellBodyMask) | nip.firstNeuriteMask;
%            figure, imshow(double(cat(3,sobelNeurites, sobelNeurites,nip.secondNeuriteMask)));
           


%            nip.neuriteExtensions = extendNeurites(nip, nip.secondNeuriteMask,%...
%                nip.openedCellBodyMask, nip.extendedCellBodyMask,...
%                round(nip.parameters.neuriteRemovalDiskRadius/2));

%            nip.originalNeurites = nip.secondNeuriteMask;


%            nip.secondNeuriteMask = nip.secondNeuriteMask | nip.neuriteExtensions;
            
%             nip.secondConnectedNeuriteMask = imreconstruct(nip.openedCellBodyMask, nip.secondCellMask) & nip.secondNeuriteMask;
            nip.secondConnectedNeuriteMask = imreconstruct(imdilate(nip.openedCellBodyMask, true(3)), nip.secondNeuriteMask);
            nip.secondUnconnectedNeuriteMask = nip.secondNeuriteMask & ~nip.secondConnectedNeuriteMask;
            
    
        end

        
        function status = resegmentNeuriteEdges(nip)
            status = '';
            % Edge background does not include cell bodies found by thresholding
            backgroundPixels = nip.gradientMag(~(nip.firstEdges | nip.openedCellBodyMask)); 
            thresh2 = nip.parameters.tujThreshFactor3 * graythresh(backgroundPixels);
            nip.secondEdges = im2bw(nip.gradientMag, thresh2);
            % Ignore edges that are within a cell body
            %edges2 = nip.secondEdges & ~nip.openedCellBodyMask; 
            
            % Fill-in edges to reconstruct neurites between edges
            filledEdges2 = imclose(nip.secondEdges, strel('disk', floor(nip.parameters.neuriteRemovalDiskRadius / 2), 0));
            
            % Extended cell bodies were found by applying a second
            % thresholding operation.  However not all of these extended
            % cell bodies contain cell bodies found by the first
            % thresholding operation.  Identify only those extended cell
            % bodies that contain an actual cell body.
            occupiedECB = imreconstruct(nip.openedCellBodyMask, nip.extendedCellBodyMask);
            
%             edgeNeurites2 = filledEdges2 & ~occupiedECB;
            
            cellBody = imopen(occupiedECB | filledEdges2, strel('disk', nip.parameters.neuriteRemovalDiskRadius, 0));
            edgeNeurites2 = filledEdges2 & ~cellBody;
            
            % Separate cell bodies from neurites; identify only neurites
            % outside of extended cell body because the lower threshold
            % finds undesirable objects near cell bodies.
            
            
            
%             bodies2 = imopen(filledEdges2 | nip.extendedCellBodyMask, strel('disk', nip.parameters.neuriteRemovalDiskRadius, 0));
            
            % Isolate neurites
%             sobelNeurites2 = filledEdges2 & ~bodies2;  
            
%             nip.thirdNeuriteMask = sobelNeurites2 | nip.secondNeuriteMask;
            nip.thirdNeuriteMask = edgeNeurites2 | nip.secondNeuriteMask;
            

            nip.neuriteExtensions = extendNeuritesNew(nip, nip.thirdNeuriteMask,...
                nip.openedCellBodyMask, nip.extendedCellBodyMask,...
                round(nip.parameters.neuriteRemovalDiskRadius/2));

            nip.originalNeurites = nip.thirdNeuriteMask;

            nip.thirdNeuriteMask = nip.thirdNeuriteMask | nip.neuriteExtensions;


            nip.thirdConnectedNeuriteMask = imreconstruct(imdilate(nip.openedCellBodyMask, true(3)), nip.thirdNeuriteMask);
            nip.thirdUnconnectedNeuriteMask = nip.thirdNeuriteMask & ~nip.thirdConnectedNeuriteMask;
            

%             occupiedECB = imreconstruct(nip.openedCellBodyMask, nip.extendedCellBodyMask);
% %             b = imopen(filledEdges2 | occupiedECB, strel('disk', nip.parameters.neuriteRemovalDiskRadius, 0));
%             n = filledEdges2 & ~occupiedECB;
%             masks = nip.firstNeuriteMask | nip.secondNeuriteMask | n;
%             ci = nip.cellImage;
%             ci(masks) = 0;
%             r = ci;
%             g = ci;
%             b = ci;
%             r(nip.firstNeuriteMask) = 1;
%             g(nip.secondNeuriteMask & ~nip.firstNeuriteMask) = 1;
%             b(n & ~(nip.secondNeuriteMask | nip.firstNeuriteMask)) = 1;
%             figure, imshow(cat(3, r, g, b));


%nip.thirdNeuriteMask = nip.secondNeuriteMask;
%nip.thirdConnectedNeuriteMask = nip.secondConnectedNeuriteMask;
%nip.thirdUnconnectedNeuriteMask = nip.secondUnconnectedNeuriteMask;
            

        end
        
        function status = secondNeuriteResegmentation(nip)
           status = '';
           background = nip.cellImage(~nip.secondCellMask);
           thresh3 = graythresh(background);
           thirdCellMask = im2bw(nip.cellImage, thresh3) | nip.secondCellMask;
           newRadius = floor(nip.parameters.neuriteRemovalDiskRadius / 2);
%            newRadius = nip.parameters.neuriteRemovalDiskRadius;
           se = strel('disk', newRadius, 0);
           thirdNeuriteMask = (thirdCellMask & ~imopen(thirdCellMask, se)) | nip.secondNeuriteMask;
           thirdNeuriteMask = imreconstruct(nip.secondNeuriteMask, thirdNeuriteMask);
           ni = adapthisteq(nip.nucleusImage);
           ci = adapthisteq(nip.cellImage);
           figure, imshow(ni);
           figure, imshow(ci);
%            figure, imshow(double(cat(3, thirdNeuriteMask & ~nip.secondNeuriteMask , thirdNeuriteMask, zeros(size(thirdCellMask)))))
           z = zeros(size(thirdNeuriteMask));
           figure, imshow(double(cat(3, ci, z, ni)));
           diff = thirdNeuriteMask & ~nip.secondNeuriteMask;
           figure, imshow(double(cat(3, diff|nip.openedCellBodyMask , diff, nip.secondNeuriteMask)))
%            figure, imshow(nip.secondNeuriteMask);
%            figure, imshow(thirdNeuriteMask);
        end
        
        function status = closeNeuriteMask(nip)
            status = '';
            % Close only neurite sections outside of the extended cell body
            % mask
	    closableNeurites = nip.thirdNeuriteMask & ~nip.extendedCellBodyMask;
            closedNeurites = imclose(closableNeurites, strel('disk', nip.parameters.tujClosingDiskRadius, 0));
            nip.closedNeuriteMask = nip.thirdNeuriteMask | closedNeurites;

%            nip.closedNeuriteMask = imclose(nip.thirdNeuriteMask, strel('disk', nip.parameters.tujClosingDiskRadius, 0));

            nip.closedConnectedNeuriteMask = imreconstruct(nip.thirdConnectedNeuriteMask, nip.closedNeuriteMask);
            nip.closedUnconnectedNeuriteMask = nip.closedNeuriteMask & ~nip.closedConnectedNeuriteMask;
%            nip.connectedNeuriteMask = imreconstruct(nip.openedCellBodyMask, M) & ~nip.firstCellMask;
%            nip.unconnectedNeuriteMask = M & ~(nip.openedCellBodyMask | nip.connectedNeurites);

        end

        function status = skeletonizeNeurites(nip)
            status = '';
            [nip.skeleton nip.branchPoints nip.endPoints] = skeletonize3(nip.closedNeuriteMask, nip.openedCellBodyMask);
            nip.connectedSkeleton = nip.skeleton & nip.closedConnectedNeuriteMask;
            nip.unconnectedSkeleton = nip.skeleton & ~nip.closedConnectedNeuriteMask;
        end
        
	function status = createNeuriteGraph(nip)
            status = '';
            nip.graph = createGraph(nip.skeleton, nip.branchPoints, nip.endPoints, nip.cellBodyNumberGrid, nip.parameters.neuriteRemovalDiskRadius*1.5);
            nip.graph.removeSpurs4();
            nip.graph.recordEdgeCount();
        end

        function status = processCells(nip)
            status = '';
            nip.graph = newcreategraph7(nip.closedConnectedNeuriteMask, nip.openedCellBodyMask, nip.cellBodyNumberGrid, nip.numCellBodies);
%             nip.graph = newcreategraph7(nip.connectedNeuriteMask, nip.firstCellMask, nip.cellBodyNumberGrid, nip.numCellBodies);
%             nip.graph.removeSpurs2(nip.parameters.neuriteRemovalDiskRadius);
%             nip.graph.recordEdgeCount();
        end
        
        
        function status = findLongPaths(nip)
            status = '';
            computeLongPaths(nip.cellBodyDataArr, nip.graph, nip.parameters.branchResolutionDistance, nip.waitBarFlag);
        end


        
        function t = getNucleusThresh1(nip)
            t = nip.nucleusThresh1;
        end

        function t = getNucleusThresh2(nip)
            t = nip.nucleusThresh2;
        end
        
        function t = getCellThresh1(nip)
            t = nip.cellThresh1;
        end
        
        function t = getCellThresh2(nip)
            t = nip.cellThresh2;
        end
        
        function I = getNucleusImage(nip)
            I = nip.nucleusImage;
        end
        
        function I = getFirstNucleusMask(nip)
            I = nip.firstNucleusMask;
        end
        
        function I = getSecondNucleusMask(nip)
            I = nip.secondNucleusMask;
        end
        
        function I = getOpenedNucleusMask(nip)
            I = nip.openedNucleusMask;
        end
        
        function I = getNucleusAllLabeled(nip)
            I = nip.nucleusAllLabeled;
        end
        
        function nda = getNucleusData(nip)
            for i = numel(nip.nucleusDataArr):-1:1
                nda(i) = nip.nucleusDataArr(i).copy();
            end
        end
        
        function m = getMinNucleusArea(nip)
            m = nip.minNucleusArea;
        end

        function n = getNominalMeanNucleusArea(nip)
            n = nip.nominalMeanNucleusArea;
        end

        function m = getMedianSingleNucleusArea(nip)
            m = nip.medianSingleNucleusArea;
        end
        
        function I = getCellImage(nip)
            I = nip.cellImage;
        end
        
        function I = getFirstCellMask(nip)
            I = nip.firstCellMask;
        end
        
        function I = getSecondCellMask(nip)
            I = nip.secondCellMask;
        end
        
        function I = getFirstNeuriteMask(nip)
           I = nip.firstNeuriteMask; 
        end
        
        function I = getFirstConnectedNeuriteMask(nip)
           I = nip.firstConnectedNeuriteMask; 
        end
        
        function I = getFirstUnconnectedNeuriteMask(nip)
           I = nip.firstUnconnectedNeuriteMask; 
        end
        
        function I = getSecondNeuriteMask(nip)
            I = nip.secondNeuriteMask;
        end
        
        function I = getSecondConnectedNeuriteMask(nip)
            I = nip.secondConnectedNeuriteMask;
        end
        
        function I = getSecondUnconnectedNeuriteMask(nip)
            I = nip.secondUnconnectedNeuriteMask;
        end
        
        function I = getThirdNeuriteMask(nip)
            I = nip.thirdNeuriteMask;
        end
        
        function I = getThirdConnectedNeuriteMask(nip)
            I = nip.thirdConnectedNeuriteMask;
        end
        
        function I = getThirdUnconnectedNeuriteMask(nip)
            I = nip.thirdUnconnectedNeuriteMask;
        end
        
        function I = getClosedNeuriteMask(nip)
            I = nip.closedNeuriteMask;
        end
        
        function I = getClosedConnectedNeuriteMask(nip)
            I = nip.closedConnectedNeuriteMask;
        end
        
        function I = getClosedUnconnectedNeuriteMask(nip)
            I = nip.closedUnconnectedNeuriteMask;
        end
        
        function cbd = getCellBodyData(nip)
            for i = numel(nip.cellBodyDataArr):-1:1
                cbd(i) = nip.cellBodyDataArr(i).copy();
            end
        end
        
        function I = getOpenedCellBodyMask(nip)
            I = nip.openedCellBodyMask;
        end
        
        function I = getExtendedCellBodyMask(nip)
            I = nip.extendedCellBodyMask;
        end
        
        function L = getCellBodyAllLabeled(nip)
            L = nip.cellBodyNumberGrid;
        end
        
        function I = getNeuriteSkeleton(nip)
            I = nip.skeleton;
        end
        
        function I = getNeuriteSkeletonBranchPoints(nip)
            I = nip.branchpoints;
        end
        
        function I = getNeuriteSkeletonEndPoints(nip)
            I = nip.endPoints;
        end
        
        function I = getConnectedNeuriteSkeleton(nip)
            I = nip.connectedSkeleton;
        end
        
        function I = getUnconnectedNeuriteSkeleton(nip)
            I = nip.unconnectedSkeleton;
        end
        
        function I = getNeuriteExtensions(nip)
            I = nip.neuriteExtensions;
        end
        
        function I = getOriginalNeurites(nip)
            I = nip.originalNeurites;
        end
        
        function I = getGraphImage(nip)
            I = nip.graph.createImage();
        end
        
        function s = getState(nip)
            s = nip.state;
        end
        
        function a = getActionName(nip)
           a = nextActionString(nip.state); 
        end

	function showWaitBar(nip, flag)
            nip.waitBarFlag = flag;
        end

        function showTiming(nip, flag)
            nip.timingFlag = flag;
        end

	function rgb = getResultsImage(nip)
            cellBodyBorder = nip.openedCellBodyMask & ~imerode(nip.openedCellBodyMask, true(3));
            connectedSkeleton = imdilate(nip.getConnectedNeuriteSkeleton, true(1));
            unconnectedSkeleton = imdilate(nip.getUnconnectedNeuriteSkeleton, true(1));
            nbdArr = nip.getCellBodyData;
            longPathSkeleton = false(size(cellBodyBorder));
            for n = 1:numel(nbdArr)
                nbd = nbdArr(n);
                numLongPaths = numel(nbd.longPaths);
                for p = 1:numLongPaths
                    stack = nbd.longPaths{p}.edgeStack;
                    while ~stack.empty()
                        e = stack.pop();
                        longPathSkeleton(e.pathIdxList) = true;
                    end
                end
            end
            longPathSkeleton = imdilate(longPathSkeleton, true(1)) & ~nip.getOpenedCellBodyMask;


all = cellBodyBorder | connectedSkeleton | unconnectedSkeleton | longPathSkeleton;

            red = nip.cellImage;
            green = nip.cellImage;
            blue = nip.cellImage;

%red(all) = 0;
%green(all) = 0;
%blue(all) = 0;

            red(cellBodyBorder) = 1;
            green(cellBodyBorder) = 0; %
            blue(cellBodyBorder) = 0;  %

            red(connectedSkeleton) = 0;   %
            green(connectedSkeleton) = 0; %
            blue(connectedSkeleton) = 1;

            % Set long paths to green after connected skeleton is set to blue
            % because long paths are a subset of connected skeleton
            red(longPathSkeleton) = 0;  %
            green(longPathSkeleton) = 1;
            blue(longPathSkeleton) = 0; %

            red(unconnectedSkeleton) = 1;
            green(unconnectedSkeleton) = 1;
            blue(unconnectedSkeleton) = 0; %

            rgb = cat(3, red, green, blue);

            for n = 1:numel(nbdArr)
                nbd = nbdArr(n);
                label = letterLabel(n);
                row = nbd.centroidRow;
                col = nbd.centroidColumn;
                heightInPixels = 30;
                color = [1 0.5 1];
                rgb = overLayText(rgb, label, [row col], heightInPixels, color);
            end

        end





    end
    
end

