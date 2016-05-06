
% Median area of non-clustered nuclei in all images
% from development parameters: 452
% from optimized parameters: 519


function nucleusAreas()
fileName = {'paramopt-tuj11.tif','paramopt-tuj12.tif','paramopt-tuj13.tif',...
    'paramopt-tuj14190.tif','paramopt-tuj14192.tif','paramopt-tuj14194.tif',...
    'paramopt-tuj14198.tif'};
fileName = strcat('ImagesNoScaleBars/', fileName);

p = Parameters();
p.initialize2();

stack = Stack();

medianAreaPerImage = zeros(size(fileName));

for i = 1:numel(fileName)
    fprintf('Processing file %s ...\n', fileName{i});
    p.fileName = fileName{i};
    nip = NeuronImageProcessor();
    nip.processForOptimization(p);
    ndArr = nip.getNucleusData();
    medianSingleNucleusArea = nip.getMedianSingleNucleusArea();
    fprintf('Median single nucleus area: %s  Image: %s\n', trimDecimal(medianSingleNucleusArea), fileName{i})
    medianAreaPerImage(i) = medianSingleNucleusArea;
    clusterCount = 0;
    for n = 1:numel(ndArr)
       if ndArr(n).cluster
           clusterCount = clusterCount + 1;
       end
    end
    
    % Create row vectors of clustered and non-clustered nucleus areas
    clusterArea = zeros(1, clusterCount);
    nonClusterArea = zeros(1, numel(ndArr)-clusterCount);
    clusterIndex = 0;
    nonClusterIndex = 0;
    for n = 1:numel(ndArr)
        area = ndArr(n).area;
       if ndArr(n).cluster
           clusterIndex = clusterIndex + 1;
           clusterArea(clusterIndex) = area;
       else
           nonClusterIndex = nonClusterIndex + 1;
           nonClusterArea(nonClusterIndex) = area;
       end
    end
    
    % Create clustered nucleus area histogram
    minClusterArea = min(clusterArea(:));
    maxClusterArea = max(clusterArea(:));
    clusterRange = maxClusterArea - minClusterArea;
    clusterAreaFreq = zeros(clusterRange + 1, 1);
    for area = clusterArea
        index = (area - minClusterArea) + 1;
        clusterAreaFreq(index) = clusterAreaFreq(index) + 1;
    end
    
    % Non-clustered nucleus area histogram
    minNonClusterArea = min(nonClusterArea(:));
    maxNonClusterArea = max(nonClusterArea(:));
    nonClusterRange = maxNonClusterArea - minNonClusterArea;
    nonClusterAreaFreq = zeros(nonClusterRange + 1, 1);
    for area = nonClusterArea
        index = (area - minNonClusterArea) + 1;
        nonClusterAreaFreq(index) = nonClusterAreaFreq(index) + 1;
        % Track nonclusterd nucleus areas in all images
        stack.push(area);
    end

    figure, bar(minNonClusterArea:maxNonClusterArea, nonClusterAreaFreq), title(fileName{i});
    hold on;
    bar(medianSingleNucleusArea, max(nonClusterAreaFreq(:)), 'FaceColor', 'red', 'EdgeColor', 'red');
    
end

allNonClusterArea = cell2mat(stack.toCellArray());
medianArea = median(allNonClusterArea);
mn = min(allNonClusterArea);
mx = max(allNonClusterArea);
rng = mx - mn;
allNonClusterAreaFreq = zeros(rng + 1, 1);
N = 50;
mnN = ceil(min(allNonClusterArea) / N);
mxN = ceil(max(allNonClusterArea) / N);
rngN = mxN - mnN;
freqN = zeros(rngN + 1, 1);
for a = 1:numel(allNonClusterArea)
    area = allNonClusterArea(a);
    index = (area - mn) + 1;
    allNonClusterAreaFreq(index) = allNonClusterAreaFreq(index) + 1;
    
    areaN = ceil(area / N);
    indexN = (areaN - mnN) + 1;
    freqN(indexN) = freqN(indexN) + 1;
end

figure, bar(mn:mx, allNonClusterAreaFreq), title('Frequency of Non-Clustered Nucleus Areas');
xlabel('Area (pixels)');
ylabel('Frequency');
set(gca, 'YTick', 1:max(allNonClusterAreaFreq));
hold on;
bar(medianArea, max(allNonClusterAreaFreq(:)), 'FaceColor', 'red', 'EdgeColor', 'red');

figure, bar((mnN*N):N:(mxN*N), freqN, 'EdgeColor', 'white'), title('Frequency of Non-Clustered Nucleus Areas');
xlabel('Area (pixels)');
ylabel('Frequency');
set(gca, 'YTick', 0:10:max(freqN));
hold on;
bar(medianArea, max(freqN), 'FaceColor', 'red', 'EdgeColor', 'red');
% for i = 1:numel(medianAreaPerImage)
%    bar(medianAreaPerImage(i), max(freqN), 'FaceColor', 'green', 'EdgeColor', 'green');
% end



fprintf('Median non-clustered nucleus area: %s  (%d samples from %d images)\n', trimDecimal(medianArea), numel(allNonClusterArea), numel(fileName));

end



function increment(map, key)
if map.iskey(key)
    map(key) = map(key) + 1;
else
    map(key) = 1;
end
end
