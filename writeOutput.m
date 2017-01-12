
% Assumes outputDir already exists
function status = writeOutput(nip, inputFileName, outputDir)


% Determine prefix (including directory) for text and image output files
separatorIndices = strfind(inputFileName, filesep);
if isempty(separatorIndices)
    fileName = inputFileName;
else
    lastSeparatorIndex = separatorIndices(end);
    fileName = inputFileName((lastSeparatorIndex+1):end);
end

dotIndices = strfind(fileName, '.');
if isempty(dotIndices)
    prefix = fileName;
else
    lastDotIndex = dotIndices(end);
    prefix = fileName(1:(lastDotIndex-1));
end
% Add output directory to prefix
prefix = strcat(outputDir, filesep, prefix);


nbdArr = nip.getCellBodyData();

% Write tabular results
resultsFileName = strcat(prefix, '-results.csv');
[fid, message] = fopen(resultsFileName, 'w');
if ~isempty(message)
   status = sprintf('Unable to open output file: %s;  %s', resultsFileName, message);
   return;
end
fprintf(fid, 'Cell Body Cluster,Cell Body Area,Number of Nuclei,Total Nucleus Area,Minimum Neurite Length of Long Neurites,Number of Long Neurites,Neurite Lengths\n');
for i = 1:numel(nbdArr)
   nbd = nbdArr(i);
   fprintf(fid, '%d,%d,%d,%d,%f,%d',...
       nbd.bodyNumber, nbd.bodyArea, nbd.numberOfNuclei,...
       nbd.totalNucleiArea, nbd.minNeuriteLength,...
       nbd.longNeuriteCount);
   numLongPaths = numel(nbd.longPaths);
   numShortPaths = numel(nbd.shortPaths);
   numPaths = numLongPaths + numShortPaths;
   neuriteLengths = zeros(numPaths, 1);
   for p = 1:numLongPaths
       neuriteLengths(p) = nbd.longPaths{p}.distance;
   end
   for p = 1:numShortPaths
       neuriteLengths(p + numLongPaths) = nbd.shortPaths{p}.distance;
   end
   neuriteLengths = sort(neuriteLengths, 'descend'); 
   for p = 1:numPaths
       fprintf(fid, ',%f', neuriteLengths(p));
   end
   fprintf(fid, '\n');
end
successIsZero = fclose(fid);
if successIsZero ~= 0
    status = sprintf('Unable to successfully close file %s', resultsFileName);
    return;
end

% Write output image
I = nip.getResultsImage();
imageFileName = strcat(prefix, '-segmented.tif');
imwrite(I, imageFileName);

end



