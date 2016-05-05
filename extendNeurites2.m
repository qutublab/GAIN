function extensions = extendNeurites2(cellBodyMask, extendedCellBodyMask, image)
extensions = false(size(cellBodyMask));
cc = bwconncomp(extendedCellBodyMask & ~cellBodyMask);
for i = 1:cc.NumObjects
    haloMask = false(cc.ImageSize);
    haloMask(cc.PixelIdxList{i}) = true;
    thresh = graythresh(image(cc.PixelIdxList{i}));
    extensions = extensions | (im2bw(image, thresh) & haloMask);
end