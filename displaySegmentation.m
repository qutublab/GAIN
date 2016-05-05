function displaySegmentation(neuronBodyDataArr, cellCircles, nucleusMask, saveFile)

if nargin == 3
    saveFile = [];
end

sz = size(neuronBodyDataArr(1).mask);
circleMask = false(sz);
cellBodyMask = false(sz);

imageHeight = sz(1);
imageWidth = sz(2);

borderDisk = strel('disk', 2, 0);
for i = 1:size(cellCircles, 1)
    cm = false(sz);
    cr = round(cellCircles(i, 1) * imageHeight);
    cc = round(cellCircles(i, 2) * imageWidth);
    rad = round(cellCircles(i, 3) * imageHeight);
    cm(cr, cc) = true;
    cm = imdilate(cm, strel('disk', rad, 0));
    cm = cm & ~imerode(cm, borderDisk);
    circleMask = circleMask | cm;
end

for i = 1:numel(neuronBodyDataArr)
   nbd = neuronBodyDataArr(i);
   cellBodyMask = cellBodyMask | nbd.mask;
end

nucleusMask = nucleusMask & cellBodyMask;

% White cell bodies
red = cellBodyMask;
green = cellBodyMask;
blue = cellBodyMask;

% Blue nuclei
red(nucleusMask) = 0;
green(nucleusMask) = 0;
blue(nucleusMask) = 1;

% Yellow circles
red(circleMask) = 1;
green(circleMask) = 1;
blue(circleMask) = 0;

rgb = double(cat(3, red, green, blue));
figure, imshow(rgb);

% Red nucleus counts
for i = 1:numel(neuronBodyDataArr)
    nbd = neuronBodyDataArr(i);
    if nbd.numberOfNuclei > 0
        text(nbd.centroidColumn, nbd.centroidRow, sprintf('%d', nbd.numberOfNuclei), 'Color', [1 0 0]);
    end
end

% Yellow cell counts
for i = 1:size(cellCircles, 1)
    cr = round(cellCircles(i, 1) * imageHeight);
    cc = round(cellCircles(i, 2) * imageWidth);
    count = cellCircles(i, 4);
    text(cc, cr, trimDecimal(sprintf('%f', count)), 'Color', [1 1 0]);
end

%% Green nucleus area
%[L numLabels] = bwlabel(nucleusMask);
%for i = 1:numLabels
%    N = L == i;
%    props = regionprops(N, 'Area', 'Centroid');
%    x = round(props.Centroid(1));
%    y = round(props.Centroid(2));
%    area = props.Area;
%    text(x, y, sprintf('%d', area), 'Color', [0 1 0]);
%end

if ~isempty(saveFile)
    saveas(gcf, saveFile);
    fprintf('Saved figure in %s\n', saveFile);
    close;
end

end
