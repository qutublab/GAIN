
% Update this function.  Nuclei are now processed after this function call
% instead of before it.

function neuronBodyDataArr = processCellBodies(Bodies, bodyNumberGrid, numBodies, Nuclei, nominalMeanNucleusArea, minNucleusArea)
% If no nucleus data is present, fake it.
if isempty(Nuclei)
    Nuclei = false(size(Bodies));
    nominalMeanNucleusArea = 0;
    minNucleusArea = 0;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Match nuclei with tuj bodies                                        %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Keep portions of dapi objects within tuj bodies
Nuclei = Nuclei & Bodies;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Compute neuron body information                                     %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%fprintf('%d tuj bodies were detected\n', numBodies);
% Allocate space for array
if numBodies == 0
    neuronBodyDataArr = NeuronBodyData.empty;
else
    neuronBodyDataArr(numBodies) = NeuronBodyData();
end
bodiesWithNucleiCount = 0;

for j = 1:numBodies
    bodyMask = bodyNumberGrid == j;
    [R C] = find(bodyMask);
    area = numel(R);
    centroidRow = round(sum(R) / area);
    centroidCol = round(sum(C) / area);
    minR = min(R);
    maxR = max(R);
    minC = min(C);
    maxC = max(C);
    % Find maximum distance from centroid to each corner of cell bounding box
    d1Sqrd = (centroidRow - minR)^2 + (centroidCol - minC)^2;
    d2Sqrd = (centroidRow - minR)^2 + (centroidCol - maxC)^2;
    d3Sqrd = (centroidRow - maxR)^2 + (centroidCol - minC)^2;
    d4Sqrd = (centroidRow - maxR)^2 + (centroidCol - maxC)^2;
    radius = ceil(sqrt(max([d1Sqrd d2Sqrd d3Sqrd d4Sqrd])));
    nucleiMask = bodyMask & Nuclei;
    nucleiCount = 0;
    totalNucleiArea = 0;
    cc = bwconncomp(nucleiMask);
    for i = 1:cc.NumObjects
        nucArea = numel(cc.PixelIdxList{i});
        if nucArea >= minNucleusArea 
            numNuclei = round(nucArea / nominalMeanNucleusArea);
            nucleiCount = nucleiCount + numNuclei;
            totalNucleiArea = totalNucleiArea + nucArea;
        end
    end
    if nucleiCount > 0
        bodiesWithNucleiCount = bodiesWithNucleiCount + 1;
        nucleiIndex = bodiesWithNucleiCount;
    else
        nucleiIndex = -1;
    end
    nbd = NeuronBodyData(j, nucleiIndex, area, nucleiCount, centroidRow, centroidCol, radius, bodyMask, totalNucleiArea);
    neuronBodyDataArr(j)  = nbd;
end

end
