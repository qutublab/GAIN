function I = readAGray(fileName, idx)
if nargin == 1 || idx == 1
    I = imread(fileName);
else
    I = imread(fileName, idx);
end
if size(I, 3) > 1
    I = rgb2gray(I);
end
end
