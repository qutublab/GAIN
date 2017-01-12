% Uses images created by processImage.m to create Figure 2

function createFigure2(dirName, prefix)

tujFile = [prefix, '-tuj.tif'];
firstCellMaskFile = [prefix, '-firstcellmask.tif'];
secondCellMaskFile = [prefix, '-secondcellmask.tif'];

T = im2double(imread(tujFile));
firstCellMask = imread(firstCellMaskFile);
secondCellMask = imread(secondCellMaskFile);

firstBorder = firstCellMask & ~imerode(firstCellMask, true(3));
secondBorder = secondCellMask & ~imerode(secondCellMask, true(3)) & ~firstBorder;

borders = firstBorder | secondBorder;

r = T; r(borders) = 0; g = r; b = r;

r(firstBorder) = 1;
g(secondBorder) = 1;
b(firstBorder | secondBorder) = 0;

rgb = cat(3, r, g, b);

% Image has 1040 rows and 1388 columns
r1 = 620; %600; %520;
r2 = 940; %920; %950; %1040;
c1 = 100; %90; %70; %50; %20; %1;
c2 = 545; %550; %560; %570; %600; %650; %694;


T = T(r1:r2, c1:c2);
% Add 100-micron scale bar.  Note that the 100 micron scale bar is 154
% pixels long and 14 pixels high.
T(((end-5) - (14 - 1)):(end-5), ((end-5) - (154 - 1)):(end-5)) = 1;

rgb = rgb(r1:r2, c1:c2, :);

outFileA = 'fig2a.tif';
outFileB = 'fig2b.tif';

imwrite(T, outFileA, 'tif', 'Compression', 'none');
fprintf('Wrote file %s\n', outFileA);

imwrite(rgb, outFileB, 'tif', 'Compression', 'none');
fprintf('Wrote file %s\n', outFileB);


end

