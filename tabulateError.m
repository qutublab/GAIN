
% Add maximum diff
% get individual false positives

function tabulateError()

fprintf('[tabulateError] Make sure that segmentationError output is appropriate!\n\n');

p = Parameters();
p.initialize2();
v = p.toVector();


predictionMap = segmentationError(v);
% predictionMap is a map that pairs numeric keys to secondary (inner) maps
% that themselves pair numeric keys to numeric values.
% The first numeric key corresponds to the size of manually counted
% clusters.  The second (inner) numeric key represents the size of
% automatically counted clusters.  The value stored in an inner map is the
% number of manually counted clusters of a size indicated by the first key
% that were automatically counted as clusters of a size indicated by the
% second key.


% Create vectors of unique manual predictions (outer keys) and automatic
% predictions (inner keys)
manualPredictions = cell2mat(predictionMap.keys());
automaticPredictions = [];
for outerKey = manualPredictions
   innerMap = predictionMap(outerKey);
   innerKeys = cell2mat(innerMap.keys());
   automaticPredictions = union(automaticPredictions, innerKeys);
end

% Make automatic predictions a row vector
automaticPredictions = automaticPredictions';   %'

manualPredictions = sort(manualPredictions);
automaticPredictions = sort(automaticPredictions);

fileName = 'prediction_table.csv';
fid = fopen(fileName, 'w');
fprintf(fid, 'Manual Prediction, Automatic Prediction, Count\n');
for mp = manualPredictions
    innerMap = predictionMap(mp);
    mpLabel = trimDecimal(mp);
    for ap = automaticPredictions
        if innerMap.isKey(ap)
            fprintf(fid, '%s,%d,%d\n', mpLabel, ap, innerMap(ap));
        end
    end
end
fclose(fid);
fprintf('Wrote file %s\n', fileName);

end
