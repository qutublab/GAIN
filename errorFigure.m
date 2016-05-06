function errorFigure()
fileName = 'ImagesNoScaleBars/paramopt-tuj12.tif';

outFileName = 'segmentation_problem.tif';

p = Parameters();
p.initialize2();
p.fileName = fileName;

nip=NeuronImageProcessor();
nbdArr=nip.processForOptimization(p);
T = nip.getCellImage();
D = nip.getNucleusImage();

M = nip.getCellBodyAllLabeled();
M = (M == 7);
M = M & ~imerode(M, true(5));

% Red Tuj, blue Dapi
red = T;
blue = D;
green = zeros(size(T));
% White cell border
red(M) = 1;
blue(M) = 1;
green(M) = 1;

% Yellow circles
cc2 = [0.74037,0.14703,0.053427, 4; ...            %  6 F  4
    0.69149,0.21191,0.053091, 4; ...            %  7 K  4
    ];
sz = size(T);
numRows = sz(1);
numCols = sz(2);
C = false(sz);
for i = 1:size(cc2, 1)
   row = round(cc2(i, 1) * numRows);
   col = round(cc2(i, 2) * numCols);
   rad = round(cc2(i, 3) * numRows);
   oneCircle = false(sz);
   oneCircle(row, col) = true;
   oneCircle = imdilate(oneCircle, strel('disk', rad, 0));
   oneCircle = oneCircle & ~imerode(oneCircle, true(3));
   C = C | oneCircle;
end
red(C) = 1;
green(C) = 1;
blue(C) = 0;

rgb = cat(3, red, green, blue);
imwrite(rgb, outFileName, 'tif', 'Compression', 'none');
fprintf('Wrote file %s\n', outFileName);


end
