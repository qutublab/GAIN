
% Assumes outputDir already exists
function status = writeOutput(nip, inputFileName, outputDir)

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

imageFileName = strcat(prefix, '-segmented.tif');

T = nip.getCellImage();
r = T;
g = T;
b = T;

% Skeleton of neurites connected to cell bodies
C = nip.getConnectedNeuriteSkeleton();
C = thicken(C);
r(C) = 0;
g(C) = 0;
b(C) = 1;

% Skeleton of neurites not connected to cell bodies
U = nip.getUnconnectedNeuriteSkeleton();
U = thicken(U);
r(U) = 1;
g(U) = 1;
b(U) = 0;

% Skeleton of long neurites connected to cell bodies
L = false(size(C));
for i = 1:numel(nbdArr)
   nbd = nbdArr(i);
   L = addPaths(L, nbd.longPaths);
end
L = thicken(L);
r(L) = 0;
g(L) = 1;
b(L) = 0;

% Labeled cell bodies
lblBodies = nip.getCellBodyAllLabeled();
bodyBorder = makeBorder(lblBodies > 0);
r(bodyBorder) = 1;
g(bodyBorder) = 0;
b(bodyBorder) = 0;

h = figure;
imshow(cat(3, r, g, b));

numLabels = max(lblBodies(:));
for i = 1:numLabels
    M = (lblBodies == i);
    [R C] = find(M);
    centroidRow = sum(R(:)) / numel(R);
    centroidCol = sum(C(:)) / numel(C);
    text(centroidCol, centroidRow, letterLabel(i), 'Color', [1 0 1]);
end


I = getimage(gcf);
close(h);
imwrite(I, imageFileName);

end



function border = makeBorder(M)
border = M & ~imerode(M, true(3));
end

function M = addPaths(M, paths)
for i = 1:numel(paths)
    p = paths{i};
    stack = p.edgeStack();
    while ~stack.empty()
        e = stack.pop();
        M(e.pathIdxList) = 1;
    end
end
end

function M = thicken(M);
M = imdilate(M, true(2));
end
