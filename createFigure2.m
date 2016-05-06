% CreateFigure2 is a new version of createFigure that writes an output file
% just once instead of separately saving a figure window to a file and then
% altering the file.

% Uses images created by processImage.m

function createFigure2(dirName, prefix)

outputFile = [dirName, filesep, 'output2.tif'];

tujFile = strcat(prefix, '-tuj.tif');
dapiFile = strcat( prefix, '-dapi.tif');
cellLabelFile = strcat(prefix, '-cellbodylabel.txt');
longPathFile = strcat(prefix, '-longPathSkel.tif');
shortPathFile = strcat(prefix, '-shortPathSkel.tif');
unconnectedFile = strcat(prefix, '-unconnected.tif');
connectedFile = strcat(prefix, '-connected.tif');



T = mat2gray(imread(tujFile));
r = T;
g = T;
b = T;

% Skeleton of neurites connected to cell bodies
C = imread(connectedFile);
C = thicken(C);
r(C) = 0;
g(C) = 0;
b(C) = 1;

% Skeleton of neurites not connected to cell bodies
U = imread(unconnectedFile);
U = thicken(U);
r(U) = 1;
g(U) = 1;
b(U) = 0;

% Skeleton of long neurites connected to cell bodies
L = imread(longPathFile);
L = thicken(L);
r(L) = 0;
g(L) = 1;
b(L) = 0;

% Labeled cell bodies
lblBodies = dlmread(cellLabelFile);
bodyBorder = makeBorder(lblBodies > 0);
r(bodyBorder) = 1;
g(bodyBorder) = 0;
b(bodyBorder) = 0;

figure, imshow(cat(3, r, g, b));

numLabels = max(lblBodies(:));
for i = 1:numLabels
    M = (lblBodies == i);
    [R C] = find(M);
    centroidRow = sum(R(:)) / numel(R);
    centroidCol = sum(C(:)) / numel(C);
    text(centroidCol, centroidRow, letterLabel(i), 'Color', [1 0 1]);
end

I = getimage(gcf);
%close(gcf);
imwrite(I, outputFile);
fprintf('Wrote file %s\n', outputFile);
end

function B = makeBorder(M)
B = M & ~imerode(M, true(3));
end

function M = thicken(M);
M = imdilate(M, true(2));
end
