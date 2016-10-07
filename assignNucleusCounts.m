
% Updates cellBodyDataArr by setting the numberOfNuclei, totalNucleiArea, and
% countedNucleiArea of each NeuronBodyData object in cellBodyDataArr.  


function assignNucleusCount(cellBodyNumberGrid, nucleusNumberGrid, cellBodyDataArr, nucleusDataArr, nominalMeanNucleusArea, minNucleusArea)

if isempty(nucleusDataArr)
    return;
end

nucleusMask = nucleusNumberGrid > 0;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Match nuclei with tuj bodies                                        %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%fprintf('[assignNucleusCounts] %d cell bodies\n', numel(cellBodyDataArr));
for i = 1:numel(cellBodyDataArr)
    cbd = cellBodyDataArr(i);
    cellBodyMask = cellBodyNumberGrid == cbd.bodyNumber;
    % Keep portions of dapi object within tuj body
    cellNucleiMask = cellBodyMask & nucleusMask;
    nucleusCount = 0;
    totalNucleusArea = 0;
    countedNucleusArea = 0;
    cc = bwconncomp(cellNucleiMask);
    for n = 1:cc.NumObjects
        cellNucleusArea = numel(cc.PixelIdxList{n});
%fprintf('[assignNucleusCounts] cell body %d nucleus object %d area: %d (%d)\n', i, n, cellNucleusArea, minNucleusArea);
        totalNucleusArea = totalNucleusArea + cellNucleusArea; 
        nucleusNum = nucleusNumberGrid(cc.PixelIdxList{n}(1));
        nd = nucleusDataArr(nucleusNum);
        assert(nucleusNum == nd.labelNum, '[assignNucleusCounts] Nucleus label mismatch');
        % Ignore small nuclei
        if ~nd.small && cellNucleusArea >= minNucleusArea
%	  fprintf('[assignNucleusCounts] cell body %d nucleus object %d is not small\n',i,n);
            nc = round(cellNucleusArea / nominalMeanNucleusArea);
            if isnan(nc)
                error('[assignNucleusCounts] cellNucleusArea=%d nominalMeanNucleusArea=%f i=%d n=%d', cellNucleusArea, nominalMeanNucleusArea, i, n);
            end
            nucleusCount = nucleusCount + nc; 
            if nc > 0
                countedNucleusArea = countedNucleusArea + cellNucleusArea;
            end
%         fprintf('[assignNucleusCounts] cluster; nc: %d nucleusCount: %d\n', nc, nucleusCount);
        end
    end
    cellBodyDataArr(i).numberOfNuclei = nucleusCount;
%fprintf('Assigned %d nuclei to cell %d\n', nucleusCount, i);
    cellBodyDataArr(i).totalNucleiArea = totalNucleusArea;
    cellBodyDataArr(i).countedNucleiArea = countedNucleusArea;
end
%for i = 1:numel(cellBodyDataArr)
%fprintf('[assignNucleusCounts] %d: numberOfNuclei=%d\n', i, cellBodyDataArr(i).numberOfNuclei);
%end
end
