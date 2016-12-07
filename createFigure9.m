% Uses images created by processImage.m to create Figure 9

function createFigure9(dirName, prefix)

outputFile = [dirName, filesep, 'fig9b.tif'];

tujFile = [prefix, '-tuj.tif'];
dapiFile = [prefix, '-dapi.tif'];
cellLabelFile = [prefix, '-cellbodylabel.txt'];
longPathFile = [prefix, '-longPathSkel.tif'];
shortPathFile = [prefix, '-shortPathSkel.tif'];
unconnectedFile = [prefix, '-unconnected.tif'];
connectedFile = [prefix, '-connected.tif'];

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

rgb = cat(3, r, g, b);


numLabels = max(lblBodies(:));
for i = 1:numLabels
    M = (lblBodies == i);
    [R C] = find(M);
    centroidRow = sum(R(:)) / numel(R);
    centroidCol = sum(C(:)) / numel(C);
%     text(centroidCol, centroidRow, letterLabel(i), 'Color', [1 0 1]);
    %temp 10.26
    rgb = insertText(rgb, [centroidCol,centroidRow],letterLabel(i), 'TextColor',[1 0.5 1],'FontSize', 16,'Font', 'LucidaSansDemiBold', 'BoxOpacity',0);
%     text(centroidCol, centroidRow, letterLabel(i), 'Color', [1 0.5 1], 'FontSize', 16, 'FontWeight', 'bold');
end
imwrite(rgb,outputFile,'tif','Compression', 'none')
fprintf('Wrote file %s\n', outputFile);
end

function B = makeBorder(M)
B = M & ~imerode(M, true(3));
end

function M = thicken(M);
M = imdilate(M, true(2));
end
