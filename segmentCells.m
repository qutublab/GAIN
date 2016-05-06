function [B CN UN] = segmentCell(I, parameters)
thresh1 = min(1, graythresh(I) * parameters.tujThreshFactor1);
thresh2 = min(1, graythresh(I(I < thresh1)) * parameters.tujThreshFactor2);

B = im2bw(I, thresh1);
B = imfill(B, 'holes');

% Remove fine structure from cell bodies
B = imopen(B, strel('disk', parameters.neuriteRemovalDiskRadius, 0));

% Rethreshold to capture more neurites
N = im2bw(I, thresh2);

% Close small gaps and crevices
N = imclose(N, true(parameters.tujClosingSquareSide));

% Identify neurites conncted to a cell  body
CN = imreconstruct(B, N) & ~B;

UN = N & ~(B | CN);
end
