function status = firstNucleusSegmentation(nip)
    status = '';
    thresh1 = graythresh(nip.nucleusImage);
    thresh1 = min(1, thresh1 * nip.parameters.dapiThreshFactor1);
    nip.firstNucleusMask = im2bw(nip.nucleusImage, thresh1);
    nip.firstNucleusMask = imfill(nip.firstNucleusMask, 'holes');
    nip.state = NIPState.SegmentedNucleusImageOnce;
end

function status = secondNucleusSegmentation(nip)
    status = '';
    thresh2 = graythresh(nip.nucleusImage(~nip.firstNucleusMask));
    thresh2 = min(1, thresh2 * parameter.dapiThresholdFactor2);
    nip.secondNucleusMask = im2bw(nip.nucleusImage, thresh2) | nip.firstNucleusMask;
    nip.secondNucleusMask = imfill(nip.secondNucleusMask, 'holes');
    nip.state = NIPState.SegmentedNucleusImageTwice;
end

function status = openNucleusMask(nip)
    status = '';
    se = strel('disk', nip.parameters.nucleusOpenDiskRadius, 0);
    nip.openedNucleusMask = imopen(nip.secondNucleusMask, se);
    nip.state = NIPState.OpenedNucleusMask;
end

function status = identifyNucleusClusters(nip)
    status = '';
    % First, find unclustered nuclei
    [L numLabels] = bwlabel(nip.openedNucleusMask);
    nip.nucleusAllLabeled = L;

    areaArr = zeros(numLabels, 1);
    solidityArr = zeros(numLabels, 1);

    % Clear out previous contents of nucleusDataArr
    nip.nucleusDataArr = [];

    for l = numLabels:-1:1
        M = L == l;
        % Solidity is the ratio of the area of an object to the area of its
        % convex hull
        props = regionprops(M, 'Area','Solidity');
        solidity = props.Solidity;
        cluster = solidity < parameters.areaToConvexHullRatio;
        nip.nucleusDataArr(l) = NucleusData(l, props.Area, props.Solidity, cluster);
    end
    nip.state = NIPState.IdentifiedNucleusClusters;
end


function status = calculateNominalMeanNucleusArea(nip)
    status = '';
    areaArr = nip.nucleusDataArr.area;
    solidityArr = nip.nucleusDataArr.solidity;
    singleNucleusArea = areaArr(solidityArr >= parameters.areaToConvexHullRatio);
    medianSingleNucleusArea = median(singleNucleusArea);
    nip.nominalMeanNucleusArea = medianSingleNucleusArea * parameters.medianNucleusAdjustmentFactor;
    nip.state = NIPState.CalculatedNominalMeanNucleusArea;
end

function status = calculateMinNucleusArea(nip)
    status = '';
    nip.minNucleusArea = max(1, ceil(nip.medianNucleusArea / parameters.median2MinimumNucleusAreaRatio));
    for i = 1:numel(nip.nucleusDataArr)
        nip.nucluesDataArr(i).small = nip.nucleusDataArr(i).area < nip.minNucleusArea;
    end
    nip.state = NIPState.CalculatedMinNucleusArea;
end
