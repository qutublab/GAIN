% Comparsion of double thresholding to edge detection

function createFigure1()
fileName = {'paramopt-tuj11.tif','paramopt-tuj12.tif','paramopt-tuj13.tif',...
    'paramopt-tuj14190.tif','paramopt-tuj14192.tif','paramopt-tuj14194.tif',...
    'paramopt-tuj14198.tif'};
fileName = strcat('/home/bl6/NeuronImages/GUI/NeuronGUI4b/ImagesNoScaleBars/', fileName);

nip = NeuronImageProcessor();
p = Parameters();
p.initialize();
p.fileName = fileName{4};
nip.processForOptimization(p);
N = nip.getNucleusImage();

m1 = nip.getFirstNucleusMask();
m2 = nip.getSecondNucleusMask();

m1Border = border(m1);
m2Border = border(m2);

r = N;
g = N;
b = N;

r(m1Border) = 0;
g(m1Border) = 0;
b(m1Border) = 1;

r(m2Border) = 0;
g(m2Border) = 1;
b(m2Border) = 0;

rgb = cat(3, r, g, b);

firstRow = 520; %1;
lastRow = 1040;
firstCol = 1;
lastCol = 694; %1388;

% figure, imshow(N(firstRow:lastRow, firstCol:lastCol));
% figure, imshow(rgb(firstRow:lastRow, firstCol:lastCol, :));

nucleusGrayFileName = 'fig1a.tif';
nucleusSegmentedFileName = 'fig1b.tif';

N2 = N(firstRow:lastRow, firstCol:lastCol);
rgb2 = rgb(firstRow:lastRow, firstCol:lastCol, :);

% Add 100-micron scale bar.  Note that the 100 micron scale bar is 154
% pixels long and 14 pixels high.
N2(((end-5) - (14 - 1)):(end-5), ((end-5) - (154 - 1)):(end-5)) = 1;

imwrite(N2, nucleusGrayFileName, 'tif', 'Compression', 'none');
imwrite(rgb2, nucleusSegmentedFileName, 'tif', 'Compression', 'none');
fprintf('Wrote file %s\n', nucleusGrayFileName);
fprintf('Wrote file %s\n', nucleusSegmentedFileName);
end


function B = border(M)
B = M & ~imerode(M, true(5));
end