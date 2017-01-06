function nip = processImage()
%fileNameCA = strcat('/home/bl6/NeuronImages/GUI/NeuronGUI4b/ImagesNoScaleBars/', ...
%    {'paramopt-tuj11.tif', 'paramopt-tuj12.tif', 'paramopt-tuj13.tif', ...
%    'paramopt-tuj14190.tif', 'paramopt-tuj14192.tif', ...
%    'paramopt-tuj14194.tif', 'paramopt-tuj14198.tif'});

fileNameCA = strcat('/home/bl6/NeuronImages/GUI/NeuronGUI4b/ImagesNoScaleBars/CroppedGray/', ...
    {'gray_combined_11.tif', 'gray_combined_12.tif', 'gray_combined_13.tif', ...
    'gray_combined_14170.tif', 'gray_combined_14172.tif', ...
    'gray_combined_14174.tif', 'gray_combined_14176.tif'});
fileName = fileNameCA{1};
%fileName = '/home/bl6/GitHub/CalibrationModel/combined1.tif';
p = Parameters();

% paramFileName = '/home/bl6/GitHub/GAIN-master/tuj11params.txt';
% status = p.readFromFile(paramFileName);
% if ~isempty(status)
%     error('[processImage] Unable to read parameters in file %s', paramFileName)
% end

p.initialize2();
p.fileName = fileName;
%p.tujThreshFactor1 = 0.75;
%p.tujThreshFactor2 = 1.2;
%p.tujThreshFactor3 = 1.5;
p.branchResolutionDistance = 10;
p.branchResolutionDistance = 15;


p.tujThreshFactor1 = 1;
p.tujThreshFactor2 = 1.2;
p.tujThreshFactor3 = 1.6;
p.branchResolutionDistance = 18;


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
nip.showWaitBar(true);
%nip.showWaitBar(false);
nip.showTiming(true);

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


nip.processImage(p);
%nip.processImage(p, 13);


T = nip.getCellImage();
figure, imshow(T);    % figure 1

CB = nip.getOpenedCellBodyMask();
CBb = CB & ~imerode(CB, true(3));
CN1 = nip.getFirstConnectedNeuriteMask();
UN1 = nip.getFirstUnconnectedNeuriteMask();
CN1b = CN1 & ~imerode(CN1, true(3));
UN1b = UN1 & ~imerode(UN1, true(3));
r = T; r(CBb | CN1b | UN1b) = 0; g = r; b = r;
r(CBb) = 1;
g(CN1b) = 1;
b(UN1b) = 1;
figure, imshow(cat(3, r, g, b));    % figure 2

ECB = nip.getExtendedCellBodyMask();
ECBb = ECB & ~imerode(ECB, true(3));
CN2 = nip.getSecondConnectedNeuriteMask();
UN2 = nip.getSecondUnconnectedNeuriteMask();
CN2b = CN2 & ~imerode(CN2, true(3));
UN2b = UN2 & ~imerode(UN2, true(3));
r = T; r(CBb | ECBb | CN2b | UN2b) = 0; g = r; b = r;
r(CBb | ECBb) = 1;
g(CN2b) = 1;
b(UN2b) = 1;
figure, imshow(cat(3, r, g, b));     % figure 3

CN3 = nip.getThirdConnectedNeuriteMask();
UN3 = nip.getThirdUnconnectedNeuriteMask();
CN3b = CN3 & ~imerode(CN3, true(3));
UN3b = UN3 & ~imerode(UN3, true(3));
r = T; r(CBb | ECBb | CN3b | UN3b) = 0; g = r; b = r;
r(CBb | ECBb) = 1;
g(CN3b) = 1;
b(UN3b) = 1;
figure, imshow(cat(3, r, g, b));      % figure 4

CN4 = nip.getClosedConnectedNeuriteMask();
UN4 = nip.getClosedUnconnectedNeuriteMask();
CN4b = CN4 & ~imerode(CN4, true(3));
UN4b = UN4 & ~imerode(UN4, true(3));
r = T; r(CBb | ECBb | CN4b | UN4b) = 0; g = r; b = r;
r(CBb | ECBb) = 1;
g(CN4b) = 1;
b(UN4b) = 1;
figure, imshow(cat(3, r, g, b));    % figure 5


 C0 = nip.getCellImage();
 C2 = nip.getOpenedCellBodyMask();
 ECB = nip.getExtendedCellBodyMask();
 NE = nip.getNeuriteExtensions();
 C5 = nip.getThirdNeuriteMask();

r = C0;
cellBodyBrdr = (C2 & ~imerode(C2, true(3))) | (ECB & ~imerode(ECB, true(3)));
% C6b = C6 & ~NE;
% neuriteBrdr = C6b & ~imerode(C6b, true(5));
C5b = C5 & ~NE;
neuriteBrdr = C5b & ~imerode(C5b, true(3));
neBrdr = NE & ~imerode(NE, true(3));
r(cellBodyBrdr | neuriteBrdr | neBrdr) = 0;
g = r; b = r;
r(cellBodyBrdr) = 1;
g(neuriteBrdr) = 1;
b(neBrdr) = 1;


imwrite(nip.getFirstCellMask(), [prefix, '-firstcellmask.tif'], 'tif', 'Compression', 'none');
imwrite(nip.getSecondCellMask(), [prefix, '-secondcellmask.tif'], 'tif', 'Compression', 'none');


imwrite(nip.getThirdNeuriteMask(), [prefix, '-thirdneuritemask.tif'], 'tif', 'Compression', 'none');
imwrite(nip.getThirdConnectedNeuriteMask(), [prefix, '-thirdconnectedneuritemask.tif'], 'tif', 'Compression', 'none');
imwrite(nip.getThirdUnconnectedNeuriteMask(), [prefix, '-thirdunconnectedneuritemask.tif'], 'tif', 'Compression', 'none');


I = nip.getCellImage();
D = nip.getNucleusImage();

imwrite(I, strcat(prefix,'-tuj.tif'), 'tif', 'Compression', 'none');
imwrite(D, strcat(prefix,'-dapi.tif'), 'tif', 'Compression', 'none');

B = nip.getOpenedCellBodyMask();
B2 = nip.getExtendedCellBodyMask();
imwrite(B, [prefix,'-cellbody.tif'], 'tif', 'Compression', 'none');
imwrite(B2, [prefix,'-extendedcellbody.tif'], 'tif', 'Compression', 'none');

neuriteExtensions = nip.getNeuriteExtensions();
imwrite(neuriteExtensions, [prefix, '-extensions.tif'], 'tif', 'Compression', 'none');

N3 = nip.getThirdNeuriteMask();
imwrite(N3, [prefix,'-thirdneuritemask.tif'], 'tif', 'Compression', 'none');


CN = nip.getClosedConnectedNeuriteMask();
UN = nip.getClosedUnconnectedNeuriteMask();
imwrite(CN, strcat(prefix,'-connectedneurites.tif'), 'tif', 'Compression', 'none');
imwrite(UN, strcat(prefix,'-unconnectedneurites.tif'), 'tif', 'Compression', 'none');

connectedSkel = nip.getConnectedNeuriteSkeleton();
unconnectedSkel = nip.getUnconnectedNeuriteSkeleton();
imwrite(unconnectedSkel, strcat(prefix,'-unconnected.tif'), 'tif', 'Compression', 'none');
imwrite(connectedSkel, strcat(prefix,'-connected.tif'), 'tif', 'Compression', 'none');

B = nip.getCellBodyAllLabeled();

dlmwrite(strcat(prefix,'-cellbodylabel.txt'), B);


BBorder = makeBorder(B > 0);

nbdArr = nip.getCellBodyData();
longPathSkel = false(size(connectedSkel));
shortPathSkel = false(size(connectedSkel));
for i = 1:numel(nbdArr)
   nbd = nbdArr(i);
   longPathSkel = addPaths(longPathSkel, nbd.longPaths);
   shortPathSkel = addPaths(shortPathSkel, nbd.shortPaths);
end

imwrite(longPathSkel, strcat(prefix,'-longPathSkel.tif'), 'tif', 'Compression', 'none');
imwrite(shortPathSkel, strcat(prefix,'-shortPathSkel.tif'), 'tif', 'Compression', 'none');


createFigure2(outputDir, prefix);
createFigure3(outputDir, prefix);
%createFigure9(outputDir, prefix);
fig9a = nip.getCellImage();
% Add 100-micron scale bar.  Note that the 100 micron scale bar is 154
% pixels long and 14 pixels high.
fig9a(((end-5) - (14 - 1)):(end-5), ((end-5) - (154 - 1)):(end-5)) = 1;
fig9b = nip.getResultsImage();

fig9aName = [outputDir, filesep, 'fig9a.tif'];
fig9bName = [outputDir, filesep, 'fig9b.tif'];
imwrite(fig9a, fig9aName, 'tif', 'Compression', 'none');
fprintf('Wrote file %s\n', fig9aName);
imwrite(fig9b, fig9bName, 'tif', 'Compression', 'none');
fprintf('Wrote file %s\n', fig9bName);


%figure, imshow(fig9a);
%figure, imshow(fig9b);


nbdArr = nip.getCellBodyData();
resultsFileName = strcat(prefix, '-results.csv');
[fid message] = fopen(resultsFileName, 'w');
if ~isempty(message)
   error('Unable to open file: %s;  %s', resultsFileName, message); 
end
fprintf(fid, 'Cell Body Number,Cell Body Area,Nuclei Count,Total Nuclei Area,Minimum Neurite Length,Number of Long Neurites,Neurite Lengths\n');
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
fclose(fid);

fprintf('Wrote file %s\n', resultsFileName);
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

