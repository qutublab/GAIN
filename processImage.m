function nip = processImage(fileName)

p = Parameters();

p.fileName = fileName;

% Set GAIN parameters
p.dapiThreshFactor1 = 1;
p.dapiThreshFactor2 = 1;
p.nucleusOpenDiskRadius = 3;
p.areaToConvexHullRatio = 0.95;
p.medianNucleusAdjustmentFactor = 1;
p.median2MinimumNucleusAreaRatio = 2;
p.tujThreshFactor1 = 1;
p.tujThreshFactor2 = 1;
p.neuriteRemovalDiskRadius = 5;
p.tujClosingSquareSide = 3;



outputDir = 'ExampleResults';
existVal = exist(outputDir);
switch exist(outputDir)
    case 0
        % Directory does not exist
        [success message messageid] = mkdir(outputDir);
    case 7
        % Directory already exists
        success = true;
    otherwise
        % Some other object possibly a file exists with the name
        delete(outputDir);
        [success message messageid] = mkdir(outputDir);
end
if ~success
    error('Unable to successfully create %s directory: %s', outputDir, message);
end

nip = NeuronImageProcessor();

% Extract file name 
% Ignore directory names
slashIndices = strfind(p.fileName, filesep);
if isempty(slashIndices)
    prefix0 = p.fileName;
else
    prefix0 = p.fileName((slashIndices(end)+1):end);
end
% Ignore file extension
dotIndices = strfind(prefix0, '.');
if ~isempty(dotIndices)
    prefix0 = prefix0(1:(dotIndices(end) - 1));
end
    
% Add directory to prefix
prefix = [outputDir, filesep, prefix0];


%p.tujClosingSquareSide = 7;
nip.processImage(p);
nbdArr = nip.getCellBodyData();

resultsFileName = strcat(prefix, '-results.csv');
[fid message] = fopen(resultsFileName, 'w');
if ~isempty(message)
   error('Unable to open file: %s;  %s', resultsFileName, message); 
end
fprintf(fid, 'Cell Body Number,Cell Body Area,Nuclei Count,Total Nuclei Area,Counted Nuclei Area,Minimum Neurite Length,Number of Long Neurites,Neurite Lengths\n');
for i = 1:numel(nbdArr)
   nbd = nbdArr(i);
   fprintf(fid, '%d,%d,%d,%d,%d,%f,%d',...
       nbd.bodyNumber, nbd.bodyArea, nbd.numberOfNuclei,...
       nbd.totalNucleiArea, nbd.countedNucleiArea, nbd.minNeuriteLength,...
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
fclose(fid);

fprintf('Wrote file %s\n', resultsFileName);

I = nip.getCellImage();
D = nip.getNucleusImage();

imwrite(I, strcat(prefix,'-tuj.tif'), 'tif', 'Compression', 'none');
imwrite(D, strcat(prefix,'-dapi.tif'), 'tif', 'Compression', 'none');




connectedSkel = nip.getConnectedNeuriteSkeleton();
unconnectedSkel = nip.getUnconnectedNeuriteSkeleton();
imwrite(unconnectedSkel, strcat(prefix,'-unconnected.tif'), 'tif', 'Compression', 'none');
imwrite(connectedSkel, strcat(prefix,'-connected.tif'), 'tif', 'Compression', 'none');

B = nip.getCellBodyAllLabeled();

dlmwrite(strcat(prefix,'-cellbodylabel.txt'), B);


BBorder = makeBorder(B > 0);

longPathSkel = false(size(connectedSkel));
shortPathSkel = false(size(connectedSkel));
for i = 1:numel(nbdArr)
   nbd = nbdArr(i);
   longPathSkel = addPaths(longPathSkel, nbd.longPaths);
   shortPathSkel = addPaths(shortPathSkel, nbd.shortPaths);
end

imwrite(longPathSkel, strcat(prefix,'-longPathSkel.tif'), 'tif', 'Compression', 'none');
imwrite(shortPathSkel, strcat(prefix,'-shortPathSkel.tif'), 'tif', 'Compression', 'none');

createFigure(outputDir, prefix);

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

