function nip = step()
fileNameCA = strcat('/home/bl6/NeuronImages/GUI/NeuronGUI4b/ImagesNoScaleBars/', ...
    {'paramopt-tuj11.tif', 'paramopt-tuj12.tif', 'paramopt-tuj13.tif', ...
    'paramopt-tuj14190.tif', 'paramopt-tuj14192.tif', ...
    'paramopt-tuj14194.tif', 'paramopt-tuj14198.tif'});
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
p.tujThreshFactor1 = 0.75;
p.tujThreshFactor2 = 1.2;
p.tujThreshFactor3 = 1.8;
p.branchResolutionDistance = 17;




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


stepNum = 7;
nip.processImage(p, stepNum)
parameterNames = properties(Nume
while stepNum ~= 9 
    paramName = parameterNames(stepNum);
    paramVal = p.(paramName);
    inStr = strtrim(input(sprintf('%s [%f]: ', paramVal), 's'));
    if isempty(inStr)
        nip.processImage(p, 1);
        stepNum = stepNum + 1;
    else
        if strcomp(inStr, 'b')
            nip.back();
	    stepNum = max(stepNum - 1, 0);
        else
            newParamVal = str2num(inStr);
            if numel(newParamValue) ~= 1 | isnan(newParamValue)
                fprintf('Invalid input: %s\n', inStr);
            else
                typ = p.parameterType(paramName);
                status = typ.check(newParamValue)
                if ~isempty(status)
                    fprintf('%s\n', status);
                else
                    p.(paramName) = newParamVal;
                    nip.processImage(p, 1);
                    stepNum = stepNum + 1;
                end
            end
        end
    end

end
return;

nip.processImage(p);
%nip.processImage(p, 13);
%nip.processImage(p, 12);


% % 1 Read Images
% N0 = nip.getNucleusImage();
 C0 = nip.getCellImage();
% 
% % 2 First Nucleus Segmentation
% N1 = nip.getFirstNucleusMask();
% 
% % 3 Second Nucleus Segmentation
% N2 = nip.getSecondNucleusMask();
% 
% % 4 Open Nucleus Mask
% % 5 Identify Nucleus Clusters
% % 6 Calculate Mean Nucleus Area
% % 7 Calculate Minimum Nucleus Area
% 
% % 8 Segment Cell Bodies
% C1 =  nip.getFirstCellMask();
% 
% % 9 Isolate Cell Bodies
 C2 = nip.getOpenedCellBodyMask();
% C3 = nip.getFirstNeuriteMask();
% 
% % 10 Resegment for Neurites
% 
% C4 = nip.getSecondNeuriteMask();
 ECB = nip.getExtendedCellBodyMask();
 NE = nip.getNeuriteExtensions();
% 
% % 11 Resegment Neurites from Edges
% 
 C5 = nip.getThirdNeuriteMask();
% 
% % 12 Close Neurite mask
% 
% C6 = nip.getClosedNeuriteMask();
% C6c = nip.getClosedConnectedNeuriteMask();
% C6u = nip.getClosedUnconnectedNeuriteMask();
% 
% 
% % 13 Skeletonize Neurites
% 
% %CS = nip.getConnectedNeuriteSkeleton();
% %US = nip.getUnconnectedNeuriteSkeleton();

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

%figure, imshow(cat(3, r, g, b));
%return;

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

createFigure3(outputDir, prefix);
createFigure9(outputDir, prefix);


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

