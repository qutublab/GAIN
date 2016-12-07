function extensions = extendNeurites2(nip, neuriteMask, cellBodyMask, extendedCellBodyMask, dilationSide)

image = nip.getCellImage();

% Segment by intensity threshold computed for extended cell body without the
% cell body

extensions = false(size(cellBodyMask));
cc = bwconncomp(extendedCellBodyMask & ~cellBodyMask);
for i = 1:cc.NumObjects
    haloMask = false(cc.ImageSize);
    haloMask(cc.PixelIdxList{i}) = true;
    thresh = graythresh(image(cc.PixelIdxList{i}));
    extensions = extensions | (im2bw(image, thresh) & haloMask);
end


% Segment by edge detection with threshodl computed individually for each
% extended cell body less the actual cell body

G = imgradient(image);
extensions2 = false(size(cellBodyMask));
cc = bwconncomp(extendedCellBodyMask & ~cellBodyMask);
for i = 1:cc.NumObjects
    haloMask = false(cc.ImageSize);
    haloMask(cc.PixelIdxList{i}) = true;
    thresh = graythresh(G(cc.PixelIdxList{i}));
    extensions2 = extensions | (im2bw(image, thresh) & haloMask);
end

extensions2 = imclose(extensions2, dilationSide);
