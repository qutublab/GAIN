% Uses images created by processImage.m to create Figure 3

function createFigure3(dirName, prefix)

tujFile = [prefix, '-tuj.tif'];
cellBodyFile = [prefix, '-cellbody.tif'];
extendedCellBodyFile = [prefix, '-extendedcellbody.tif'];
neuriteExtensionsFile = [prefix, '-extensions.tif'];
thirdNeuriteFile = [prefix, '-thirdneuritemask.tif'];

T = mat2gray(imread(tujFile));

B = imread(cellBodyFile);
B2 = imread(extendedCellBodyFile);
N = imread(thirdNeuriteFile); 
NE = imread(neuriteExtensionsFile);

bodyBrdr = (B & ~imerode(B, true(3))) | (B2 & ~imerode(B2, true(3)));
N = N & ~NE;
neuriteBrdr = N & ~imerode(N, true(3));
extensionsBrdr = NE & ~imerode(NE, true(3));

allBrdr = bodyBrdr | neuriteBrdr | extensionsBrdr;
r = T;
r(allBrdr) = 0;
g = r;
b = r;
r(bodyBrdr) = 1;
g(neuriteBrdr) = 1;
b(extensionsBrdr) = 1;

rgb = cat(3, r, g, b);
% rgb is 1040r x 1388c
minR = 690;
maxR = 830;
minC = 1;
maxC = 190;
rgb = rgb(minR:maxR, minC:maxC, :);

T = T(minR:maxR, minC:maxC);
% Add 20-micron scale bar.  Note that the 100 micron scale bar is 154
% pixels long and 14 pixels high.
T(((end-5) - (3 - 1)):(end-5), ((end-5)-(31 - 1)):(end-5)) = 1;

fig3aName = [dirName, '/fig3a.tif'];
fig3bName = [dirName, '/fig3b.tif'];
imwrite(T, fig3aName, 'tif', 'Compression', 'none');
fprintf('Wrote file %s\n', fig3aName);
imwrite(rgb, fig3bName, 'tif', 'Compression', 'none');
fprintf('Wrote file %s\n', fig3bName);

end
