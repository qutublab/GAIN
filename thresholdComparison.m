% Comparsion of double thresholding to edge detection

function thresholdComparison()
fileName = {'paramopt-tuj11.tif','paramopt-tuj12.tif','paramopt-tuj13.tif',...
    'paramopt-tuj14190.tif','paramopt-tuj14192.tif','paramopt-tuj14194.tif',...
    'paramopt-tuj14198.tif'};
fileName = strcat('ImagesNoScaleBars/', fileName);

nip = NeuronImageProcessor();
p = Parameters();
p.initialize();
p.fileName = fileName{1};
nip.processForOptimization(p);
I = nip.getCellImage();


cellThresh1 = nip.getCellThresh1();
cellThresh2 = nip.getCellThresh2();
cm1 = im2bw(I, cellThresh1);
cm2 = im2bw(I, cellThresh2);


% Get image processor results before morphological closing of neurites
% firstCellBodyMask = nip.getOpenedCellBodyMask();
% firstNeuriteMask = nip.getFirstNeuriteMask();
% firstMask = firstCellBodyMask | firstNeuriteMask;
% secondNeuriteMask = nip.getSecondNeuriteMask();
% secondMask = secondNeuriteMask & ~firstMask;

firstBorder = border(cm1);
secondBorder = border(cm2) & ~firstBorder;


r = I;
g = I;
b = I;
r(firstBorder) = 1;
g(firstBorder) = 0;
b(firstBorder) = 0;

r(secondBorder) = 0;
g(secondBorder) = 1;
b(secondBorder) = 0;

rgb = cat(3, r, g, b);
%figure, imshow(rgb);


sobelMask = edge(I, 'sobel');
r = I;
g = I;
b = I;
r(sobelMask) = 1;
g(sobelMask) = 1;
b(sobelMask) = 0;
rgbSobel = cat(3, r, g, b);
%figure, imshow(cat(3, r, g, b));

logMask = edge(I, 'log');
r = I;
g = I;
b = I;
r(logMask) = 1;
g(logMask) = 1;
b(logMask) = 0;
rgbLOG = cat(3, r, g, b);
%figure, imshow(cat(3, r, g, b));


% % Keep bottom left of each image
% numRows = size(I, 1);
% numCols = size(I, 2);
% firstRow = round(numRows / 2);
% lastRow = numRows;
% firstCol = 1;
% lastCol = round(numCols / 2);

firstRow = 620;  %520;
lastRow = 940;   %1040;
firstCol = 100;    %1;
lastCol = 544;  %694;
%figure, imshow(rgb(firstRow:lastRow, firstCol:lastCol, :))

imwrite(rgb(firstRow:lastRow, firstCol:lastCol, :), 'sampleGAIN.tif', 'tif', 'Compression', 'none');
fprintf('Wrote file sampleGAIN.tif\n');

imwrite(I(firstRow:lastRow, firstCol:lastCol), 'sampleTuj.tif', 'tif', 'Compression', 'none');
fprintf('Wrote file sampleTuj.tif\n');

imwrite(rgbSobel(firstRow:lastRow, firstCol:lastCol, :), 'sampleSobel.tif', 'tif', 'Compression', 'none');
fprintf('Wrote file sampleSobel.tif\n');

imwrite(rgbLOG(firstRow:lastRow, firstCol:lastCol, :), 'sampleLOG.tif', 'tif', 'Compression', 'none');
fprintf('Wrote file sampleLOG.tif\n');

end

function B = border(M)
B = M & ~imerode(M, true(3));
end