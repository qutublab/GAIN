

%Return individualDiffs for use with lsqnonlin.
% Return sqrSum for use with fminsearch, fminunc, fsolve, fmincon
% Return matching for analysis

%function matching = segmentationError(paramVector)
function individualDiffs = segmentationError(paramVector)
%function sqrSum = segmentationError(paramVector)

numParams = numel(paramVector);
fprintf('parameters=[');
for i = 1:numParams
    numStr = trimDecimal(sprintf('%f', paramVector(i)));
    if i == numParams
        fprintf('%s]\n', numStr);
    else
        fprintf('%s ', numStr);
    end
end

params = Parameters();
params.assignFromVector(paramVector);
params.rectify();


dapiFileName = {'DAPI1.tif', 'DAPI2.tif', 'DAPI3.tif', ...
    'Snap14191.tif', 'Snap14193.tif', 'Snap14195.tif', 'Snap14199.tif'};

tujFileName = {'Tuj11.tif', 'Tuj12.tif', 'Tuj13.tif', ...
    'Snap14190.tif', 'Snap14192.tif', 'Snap14194.tif', 'Snap14194.tif'};


% Neuron image processor now expects both images to be in a single file.
% Files are numbered according to original tuj image file name.
fileName = {'paramopt-tuj11.tif','paramopt-tuj12.tif','paramopt-tuj13.tif',...
    'paramopt-tuj14190.tif','paramopt-tuj14192.tif','paramopt-tuj14194.tif',...
    'paramopt-tuj14198.tif'};
fileName = strcat('ImagesNoScaleBars/', fileName);


% Cell count data (row, col, radius, count) are in the following units: 
% a) row is in the fraction of the image height, b) col is in the fraction
% of the image width, and c) radius is in the fraction of the image height.

cc1 = [0.83451,0.12842,0.060647, 1; ...
    0.86814,0.34306,0.060984, 3; ...
    0.31223,0.41877,0.061321, 1; ...
    0.53122,0.49457,0.07783, 5; ...
    0.36281,0.50721,0.060647, 1; ...
    0.56425,0.71029,0.061658, 1; ...
    0.51519,0.78383,0.062332, 4; ...
    0.29543,0.75974,0.060647, 1; ...
    0.9019,0.78499,0.060647, 1; ...
    0.32912,0.886,0.060647, 3];


cc2 = [0.22871,0.015805,0.060148, 1; ...    %  1 A  1
    0.027087,0.041043,0.060148, 1; ...          %  2 B  1
    %0.8255,0.096031,0.053427, unsure; ...      %  3 C  unsure
    0.077551,0.14186,0.06082, 1; ...            %  4 D  1
    0.40482,0.13686,0.053091, 3.5; ...          %  5 E  3.5
    0.74037,0.14703,0.053427, 4; ...            %  6 F  4
    0.69149,0.21191,0.053091, 4; ...            %  7 K  4
    0.29594,0.16705,0.060484, 1; ...            %  8 G  1
    0.55635,0.20037,0.053763, 1; ...            %  9 H  1
    0.45628,0.20995,0.054772, 6.5; ...          % 10 J  6.5
    0.45594,0.28438,0.054099, 2; ...            % 11 M  2
    0.82552,0.222,0.053427, 3.5; ...            % 12 L  3.5
    0.97605,0.28504,0.053091, 1; ...            % 13 N  1
    0.17833,0.34341,0.06082, 1; ...             % 14 P  1
    0.43844,0.39841,0.053427, 1; ...            % 15 Q  1
    0.73278,0.45684,0.060148, 3; ...            % 16 R  3
    0.92636,0.45228,0.053091, 1; ...            % 17 S  1
    0.29595,0.46941,0.060484, 1; ...            % 18 T  1
    0.58154,0.46939,0.06082, 1.5; ...           % 19 U  1.5
    0.07754,0.50718,0.060484, 2; ...            % 20 V  2
    %1.0097,0.5027,0.053091, unsure; ...        % 21 W  unsure
    0.85911,0.51479,0.053091, 2; ...            % 22 X  2
    0.69912,0.69615,0.060148, 1; ...            % 23 Y  1
    0.13738,0.81559,0.052419, 2; ...            % 24 Z  2
    0.72464,0.85188,0.053091, 4; ...            % 25 AA 4
    0.84162,0.86748,0.052755, 1; ...            % 26 AB 1
    0.77451,0.92734,0.053091, 2; ...            % 27 AE 2
    0.18897,0.88863,0.051075, 2; ...            % 28 AC 2
    0.30197,0.9304,0.066196, 2; ...             % 29 AD 2
    0.65743,0.93348,0.053091, 1];               % 30 AF 1

cc3 = [0.21115,0.09049,0.061321, 1; ...
    0.34592,0.09049,0.061321, 1.5; ...
    0.71654,0.242,0.061321, 3; ...
    0.19435,0.33044,0.060647, 1; ...
    0.78392,0.41877,0.061321, 5.5; ...
    0.0089182,0.48191,0.060984, 1; ...
    0.73343,0.50721,0.060647, 1; ...
    0.24493,0.55766,0.060984, 1; ...
    0.53122,0.62083,0.060984, 3; ...
    0.93559,0.65873,0.060647, 1; ...
    0.43014,0.69659,0.060984, 2; ...
    0.076376,0.74706,0.061321, 1; ...
    0.14376,0.84807,0.061321, 2; ...
    0.16066,0.96176,0.060647, 2.5];

cc4 = [0.50596,0.069842,0.041451, 1; ...
    0.53186,0.16889,0.041451, 1; ...
    0.80337,0.19821,0.041451, 1; ...
    0.36341,0.30237,0.086528, 4; ...
    0.95886,0.26796,0.041451, 1; ...
    0.090906,0.33209,0.054404, 2; ...
    0.59611,0.32737,0.041451, 1; ...
    0.76503,0.41612,0.041451, 1; ...
    0.32461,0.52547,0.041451, 1; ...
    0.60958,0.5849,0.041451, 1; ...
    0.25933,0.61422,0.041451, 1; ...
    0.50596,0.61422,0.041451, 1; ...
    0.14326,0.74338,0.041451, 1; ...
    0.40233,0.75288,0.041451, 1; ...
    0.94638,0.79251,0.041451, 1; ...
    0.25933,0.80281,0.041451, 1; ...
    0.49249,0.89155,0.041451, 1];

cc5 = [0.043238,0.14011,0.040942, 1; ...
    0.18383,0.23895,0.040942, 1; ...
    0.47874,0.23892,0.040942, 1; ...
    0.90063,0.24842,0.040942, 1; ...
    0.6323,0.34726,0.040942, 1; ...
    0.79198,0.48587,0.059877, 2; ...
    0.49102,0.65379,0.04043, 1; ...
    0.70914,0.87111,0.04043, 1; ...
    0.29953,0.8909,0.04043, 2];

cc6 = [0.82163,0.032542,0.040933, 1; ...
    0.48468,0.11997,0.040933, 1; ...
    0.16019,0.13928,0.040933, 1; ...
    0.41937,0.18726,0.040933, 2; ...
    0.19958,0.26459,0.040933, 1; ...
    0.30322,0.2646,0.040933, 2; ...
    0.043789,0.33265,0.040933, 1; ...
    0.38099,0.37131,0.040933, 1; ...
    0.67877,0.41,0.041451, 1; ...
    0.75619,0.41923,0.041451, 1; ...
    0.39344,0.46798,0.040933, 1; ...
    0.082294,0.48734,0.0414511, 1; ...
    0.39494,0.61474,0.04456, 1; ...
    0.41782,0.64913,0.04456, 1.5; ...
    0.27731,0.62267,0.040933, 1; ...
    0.94461,0.69035,0.053886, 4; ...
    0.35507,0.70003,0.040933, 1; ...
    0.043792,0.79668,0.040933, 1; ...
    0.38098,0.90265,0.040933, 1; ...
    0.16018,0.9413,0.040933, 1; ...
    0.65265,0.94132,0.040933, 1; ...
    0.48468,0.95137,0.040933, 1];

cc7 = [0.56837,0.12986,0.042239, 1; ...
    0.46278,0.14964,0.042239, 1; ...
    0.59477,0.19948,0.042239, 1; ...
    0.37091,0.26831,0.042239, 1; ...
    0.56837,0.27859,0.042239, 1; ...
    0.64757,0.35771,0.042239, 1; ...
    0.22518,0.43682,0.042239, 1; ...
    0.39731,0.44631,0.042239, 1; ...
    0.76689,0.46609,0.042239, 1; ...
    0.5029,0.6441,0.042239, 1; ...
    0.2529,0.76299,0.044351, 1; ...
    0.31704,0.77294,0.044351, 1; ...
    0.54197,0.84188,0.042239, 1];




cellCountData = {cc1, cc2, cc3, cc4, cc5, cc6, cc7};


individualDiffs = [];

sqrSum = 0;

% Create a two-key map which takes a manual count as its first key and
% returns a second map which takes an automated count as its key and
% returns the number of times that the manual count was paired with the
% automated count.
matching = containers.Map('KeyType', 'double','ValueType','any');


for i = 1:numel(cellCountData)
    info = imfinfo(fileName{i});
    imageHeight = info(1).Height;
    imageWidth = info(1).Width;
    cellCircles = cellCountData{i};
    params.fileName = fileName{i};
    fprintf('[segmentationError] Begin processing file %s\n', params.fileName);

    nip = NeuronImageProcessor();
    neuronDataArr = nip.processForOptimization(params);
%    fprintf('[segmentationError] %s: medianSingleNucleusArea=%f\n', fileName{i}, nip.getMedianSingleNucleusArea());
    displaySegmentation(neuronDataArr, cellCircles, nip.getOpenedNucleusMask(),sprintf('seg%d.tif', i));
    continue;

    % Each row of cellCircles contains data on a group of cells that was
    % circled manually
    numCircles = size(cellCircles, 1);
    
    % cellCircleMatched records the first automatically identified cell
    % cluster matched to each manually circled cell group.  This allows the
    % tracking of cell circles that are matched to more than one
    % automatically identified cluster
    cellCircleMatched = zeros(numCircles, 1);
    
    % Track number of cells (by automatically identified cell group) that
    % are not matched to a manually circled cell group
    unmatchedPredictions = zeros(size(neuronDataArr));
    
    % Track count of automatically identifed cells with each manually
    % circled cell group
    predictedCellsByCircle = zeros(numCircles, 1);

% if i == 1
%     mskAuto = false(imageHeight, imageWidth);
%     mskManual = false(imageHeight, imageWidth);
%     cr = round(cellCircles(2, 1) * imageHeight);    
%     cc = round(cellCircles(2, 2) * imageWidth);    
%     r = round(cellCircles(2, 3) * imageHeight);    
%     manualCountStr = sprintf('%d', cellCircles(2, 4));
%     mskManual(cr, cc) = true;
%     mskManual = imdilate(mskManual, strel('disk', r, 0));
%     autoCountStr = '';
% end

    for n = 1:numel(neuronDataArr)
        nd = neuronDataArr(n);

% if i == 1 && (n == 3 || n == 4)
%     mskAuto = mskAuto | nd.mask;
%     autoCountStr = sprintf('%s %d', autoCountStr, nd.numberOfNuclei);
% end
        
        if nd.numberOfNuclei == 0 continue; end % Skip cells without nuclei
        
        ndRow = nd.centroidRow;
        ndCol = nd.centroidColumn;
        closest = -1;
        closestDistSqrd = Inf;
        % Match program cell count to manual cell count
        for c = 1:numCircles
            centerRelativeY = cellCircles(c, 1);
            centerRelativeX = cellCircles(c, 2);
            relativeRadius = cellCircles(c, 3);
            centerRow = centerRelativeY * imageHeight;
            centerCol = centerRelativeX * imageWidth;
            radius = relativeRadius * imageHeight;
            
            radiusSqrd = radius * radius;
            distSqrd = (ndRow - centerRow)^2 + (ndCol - centerCol)^2;
            if distSqrd <= radiusSqrd
                if distSqrd < closestDistSqrd
                    closestDistSqrd = distSqrd;
                    closest = c;
                end
            end
        end
        if closest > 0
            if cellCircleMatched(closest) ~= 0
%                fprintf('[segmentationError] Image: %d  More than one automatically segmented cell (%d and %d) matches manually identified cluster (%d)\n', i, cellCircleMatched(closest), n, closest);
            else
                cellCircleMatched(closest) = n;
            end
            % More than one automatically identified cell cluster may be
            % within a manually circled cell group.
            predictedCellsByCircle(closest) = predictedCellsByCircle(closest) + nd.numberOfNuclei;
        else
            unmatchedPredictions(n) = nd.numberOfNuclei;
        end
    end

    % After all automatic counts are processed, match manual counts and
    % automatic counts
    for c = 1:numel(cellCircleMatched)
        manualCount = cellCircles(c, 4);
        automaticCount = predictedCellsByCircle(c);
        % Track the number of times manual and automatic counts coincide
        incrementMap(matching, manualCount, automaticCount);
    end
    for u = 1:numel(unmatchedPredictions)
        if unmatchedPredictions(u) > 0
            incrementMap(matching, 0, unmatchedPredictions(u));
        end
    end
    
% if i == 1
%     rgb = double(cat(3, mskManual, mskAuto, mskAuto));
%     figure, imshow(rgb), title(sprintf('Manual Count: %s  ProgramCount:%s', manualCountStr, autoCountStr));
% end

    manualCellCounts = cellCircles(:, 4);
    % Calculate difference for automatically counted cell that correspond
    % to manually counted cells.  
    diff = predictedCellsByCircle(:) - manualCellCounts(:); % column vector

    % Program output is computed in two ways.  The first is a 
    % sum-of-squares approach for use by parameter optimizers such as
    % fminsearch which use a single error value.  Manual cell counts are
    % matched to automatic cell counts and the differences between
    % corresponding counts are squared and summed.  Note that since the
    % number of cell clusters found automatically can change as parameters
    % change the number of pairs of corresponding automatic and manual cell
    % counts can change because the number of automatically found cell
    % clusters can increase and decrease.
    sqrSumUnmatchedPredictions = sum(unmatchedPredictions.^2);
    sqrSum = sqrSum + sum(diff.^2) + sqrSumUnmatchedPredictions;
    
    % The second method is for parameter optimizers such as lsqnonlin which
    % require not a single sum of squares, but a vector of the individual
    % differences between computed and expected values.  Here, I assume
    % that the returned vector must be of a constant size.  However, the
    % unmatchedPredictions vector might not always be the same length for
    % the same input image.  My solution is to transform the
    % unmatchedPredictions vector into a single value that will have the
    % same effect when squared.
    
    individualDiffs = [individualDiffs; diff; sqrt(sqrSumUnmatchedPredictions)];
end

totalErr = 0.0;
outerKeys = cell2mat(matching.keys());
for i = 1:numel(outerKeys)
    ok = outerKeys(i);
    innerMap = matching(ok);
    innerKeys = cell2mat(innerMap.keys());
    for j = 1:numel(innerKeys)
        ik = innerKeys(j);
        count = innerMap(ik);
        totalErr = totalErr + (double(count) * ((ok - ik)^2));
    end
end

if sqrSum ~= totalErr
    error('sqrSum=%f  totalErr=%f\n', sqrSum, totalErr);
end




% Error check
expectedNumIndividualDiffs = sum(cellfun(@(a)size(a, 1), cellCountData)) + numel(cellCountData);
if numel(individualDiffs) ~= expectedNumIndividualDiffs
    error('[segmentationError] Incorrect number of measurements %d; expected %d', numel(individualDiffs), expectedNumIndividualDiffs);
end



end


function incrementMap(map, key1, key2)
if ~map.isKey(key1)
    map(key1) = containers.Map('KeyType', 'double','ValueType','uint64');
end
innerMap = map(key1);
if ~innerMap.isKey(key2)
    innerMap(key2) = 0;
end
innerMap(key2) = innerMap(key2) + 1;
end


function mask = makeCircleMask(radius, thickness)
dim = (2 * radius) + 1;
center = radius + 1;
mask = false(dim);
innerradius = radius - thickness;
for r = 1:dim
    for c = 1:dim
        d = sqrt((r - center)^2 + (c - center)^2);
        if (d <= radius) && (d >= innerradius)
            mask(r, c) = true;
        end
    end
end
end


function I = superimposeMask(I, row, col, mask, color)
iRows =size(I, 1);
iCols = size(I, 2);
[maskrows maskcols] = size(mask);
y = (maskrows - 1) / 2;
x = (maskcols - 1) / 2;
topRow = row - y;
bottomRow = row + y;
leftCol = col - x;
rightCol = col + x;
if topRow < 1   %row <= y
    mask = mask((2-topRow):end, :);     %mask((y+2-row):end, :);
    topRow = 1;
else
    if bottomRow > iRows    %row > (iRows - y)
        mask = mask(1:(end-(bottomRow - iRows)), :);     %mask(1:(end-(rows+y-iRows)), :);
        bottomRow = iRows;
    end
end
if leftCol < 1     %col <= x
    mask = mask(:, (2-leftCol):end);    %mask(:, (x+1-col):end);
    leftCol = 1;
else
    if rightCol > iCols    %col > (iCols - x)
        mask = mask(:, 1:(end-(rightCol - iCols)));    %mask(:, 1:(end-(cols+x-iCols)));
        rightCol = iCols;
    end
end

section = I(topRow:bottomRow, leftCol:rightCol, :);
rMask = double(mask) * color(1);
gMask = double(mask) * color(2);
bMask = double(mask) * color(3);
rgb = cat(3, rMask, gMask, bMask);
negMask = cat(3, ~mask, ~mask, ~mask);
section = (section .* double(negMask)) + rgb;
I(topRow:bottomRow, leftCol:rightCol, :) = section;
end
