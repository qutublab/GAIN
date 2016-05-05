function createImagePair(cellBodyImageFileName, nucleusImageFileName)
cellImage = imread(cellBodyImageFileName);
nucleusImage = imread(nucleusImageFileName);
outputFileName = 'pairedImages.tif';
imwrite(cellImage, outputFileName, 'tif', 'Compression', 'none');
imwrite(nucleusImage, outputFileName, 'tif', 'Compression', 'none', 'WriteMode', 'append');
fprintf('Wrote file %s\n', outputFileName);
end