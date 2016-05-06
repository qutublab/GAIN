% Uses images created by processImage.m

function createFigure()
dirName = '/home/bl6/NeuronImages/GUI/NeuronGUI4b/ExampleResults';
tujFile = strcat(dirName, '/paramopt-tuj11-tuj.tif');
dapiFile = strcat(dirName, '/paramopt-tuj11-dapi.tif');
cellLabelFile = strcat(dirName, '/paramopt-tuj11-cellbodylabel.txt');
longPathFile = strcat(dirName, '/paramopt-tuj11-longPathSkel.tif');
shortPathFile = strcat(dirName, '/paramopt-tuj11-shortPathSkel.tif');
unconnectedFile = strcat(dirName, '/paramopt-tuj11-unconnected.tif');
connectedFile = strcat(dirName, '/paramopt-tuj11-connected.tif');

outputFile = 'output.tif';

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
% Use saveas to include text in image file
% saveas(gcf, outputFile);
% close(gcf);
% saveas includes a white border; remove it
I = mat2gray(imread(outputFile));
NW = I(:, :, 1) ~= 1 | I(:, :, 2) ~= 1 & I(:, :, 3) ~= 1;
nonWhiteCols = find(any(NW, 1));
nonWhiteRows = find(any(NW, 2));
topRow = nonWhiteRows(1);
bottomRow = nonWhiteRows(end);
leftColumn = nonWhiteCols(1);
rightColumn = nonWhiteCols(end);
I = I(topRow:bottomRow, leftColumn:rightColumn, :);
% imwrite(I, outputFile);
% fprintf('Wrote file %s\n', outputFile);
end

function B = makeBorder(M)
B = M & ~imerode(M, true(3));
end

function M = thicken(M);
% M = imdilate(M, true(2));
end
