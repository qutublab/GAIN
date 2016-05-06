% Assuming that variable n contains the NeuronImageProcessor after running
% the processImage function


tracingsFile = 'NeuriteTracerResults/ParamOpt/Neuron71Nucleus20Small100Large525/tracings.tif';
tracing = imread(tracingsFile, 'Index', 1);

skel = n.getNeuriteSkeleton();

% The image given to NeuriteTracer was trimmed to remove the scale bar at
% the bottom

numRows = size(tracing, 1);
numCols = size(tracing, 2);
skel = skel(1:numRows, :);

common = skel & tracing;
skelOnly = skel & ~tracing;
tracingOnly = tracing & ~skel;

% Thicken the skeleton to improve visibility.  This will cause overlap, so
% give lower priority to the common portion of the skeleton/tracing

d = 3;
common = imdilate(common, true(d));
skelOnly = imdilate(skelOnly, true(d));
tracingOnly = imdilate(tracingOnly, true(d));

I = n.getCellImage();
I = I(1:numRows, :);
r = I;
g = I;
b = I;

common = common & ~(skelOnly | tracingOnly);
diff = (skelOnly | tracingOnly) & ~common;
r(common) = 1;
g(common) = 1;
b(common) = 1;

r(diff) = 0;
g(diff) = 0;
b(diff) = 0;


g(skelOnly) = 1;

r(tracingOnly) = 1;
b(tracingOnly) = 1;

% Add cell body borders in blue.  NeuriteTracer does not compute this.
cellBodyMask = n.getOpenedCellBodyMask();
cellBodyMask = cellBodyMask(1:numRows, :);
cellBodyBorder = cellBodyMask & ~imerode(cellBodyMask, true(d*2));
r(cellBodyBorder) = 0;
g(cellBodyBorder) = 0;
b(cellBodyBorder) = 1;

rgb = double(cat(3, r, g, b));
figure, imshow(rgb);

fileName = 'NeuriteTracerComp.tif';
imwrite(rgb, fileName, 'tif', 'Compression', 'none');
fprintf('Wrote file %s\n', fileName);


cellMaskFile = 'NeuriteTracerResults/ParamOpt/Neuron71Nucleus20Small100Large525/Thresholded Neurons.tif';
cellMask = imread(cellMaskFile);
cellMask2 = n.getSecondCellMask();
cellMask2 = cellMask(1:numRows, :);
maskRGB = double(cat(3, cellMask, cellMask2, cellMask));
figure, imshow(maskRGB);

ntOnly = cellMask & ~cellMask2;
gOnly = cellMask2 & ~cellMask;

sum(double(ntOnly(:)))
sum(double(gOnly(:)))

figure, imshow(cellMaskFile);
figure, imshow(n.getSecondCellMask);