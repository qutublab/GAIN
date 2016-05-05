function [L N nucleusDataArr nominalMeanNucleusArea minNucleusArea] = segmentNucleus(I, parameters)
thresh1 = min(1, graythresh(I) * parameters.dapiThreshFactor1);
thresh2 = min(1, graythresh(I(I < thresh1)) * parameters.dapiThreshFactor2);
N = im2bw(I, thresh2);
N = imfill(N, 'holes');
% Open weakly connected nuclei
N = imopen(N, strel('disk', parameters.nucleusOpenDiskRadius, 0));

% Find unclustered nuclei
[L numLabels] = bwlabel(N);

minRatio = Inf;
maxRatio = -Inf;
areaArr = zeros(numLabels, 1);
solidityArr = zeros(numLabels, 1);
for l = 1:numLabels
    M = L == l;
    % Solidity is the ratio of the area of an object to the area of its
    % convex hull
    props = regionprops(M, 'Area','Solidity');
    areaArr(l) = props.Area;
    solidityArr(l) = props.Solidity;
end
nucleusArea = areaArr(solidityArr > parameters.areaToConvexHullRatio);
medianNucleusArea = median(nucleusArea);
nominalMeanNucleusArea = medianNucleusArea * parameters.medianNucleusAdjustmentFactor;

minNucleusArea = max(1, ceil(medianNucleusArea / parameters.median2MinimumNucleusAreaRatio));

% Remove small objects
N = bwareaopen(N, minNucleusArea);
L = L .* double(N);

for i = numLabels:-1:1
    area = areaArr(i);
    solidity = solidityArr(i);
    small = area < minNucleusArea;
    cluster = solidity < parameters.areaToConvexHullRatio;
    nucleusDataArr(2) = NucleusData(i, area, solidity, small, cluster);
end


end
