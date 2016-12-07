
function extensions = extendNeuritesNew(nip, neuriteMask, cellBodyMask, extendedCellBodyMask, dilationSide)

% Assign a number to each extended cell body
[L, numLabels] = bwlabel(extendedCellBodyMask);

% Step 1: For each extended cell body, find the neurites that touch it, but do
% not touch an actual cell.  For each such neurite: (1) reduce it to just the
% pixels that touch the extended cell body, and then (2) further reduce it to
% a single pixel that is closest to the centroid of the pixels reduced in
% part (1).

% Label the pixels surrounding each extended cell body.  Assume that extended
% cell bodies have enough space between them so that no pixel is next to more
% than one extended cell body
L2 = imdilate(L, true(3));

% Locate neurites that: a) are next to the extended cell body border and b) do
% not touch the cell body.  These neurites are then stored in variable source

% Neurites connected to cell bodies
connected = imreconstruct(cellBodyMask, cellBodyMask | neuriteMask);
% Neurites not connected to cell bodies
unconnected = neuriteMask & ~connected;
% Portion of unconnected neurites outside of extended cell body mask
outsideUnconnected = unconnected & ~extendedCellBodyMask;
% Significantly large areas outside extended cell bodies. 
largeOutsideUnconnected = bwareaopen(outsideUnconnected, (dilationSide * 2)^2);
% Reduce to the fring pixels that touch the extended cell body
unconnectedFringe = largeOutsideUnconnected & L2;



neuritesOfInterest = L2 & neuriteMask;
connected = imreconstruct(cellBodyMask, cellBodyMask | neuritesOfInterest);
source = neuritesOfInterest & ~connected;
% Use just the portions of neurites that are next to the extended cell body
source = source & ~extendedCellBodyMask;

% Reduce each connected component of source to a single pixel in the connected
% component and closest to its centroid
cc = bwconncomp(source);
[centR centC] = cellfun(closestToCentroidCurried(cc.ImageSize), cc.PixelIdxList);
% Convert to linear indices and sort in the hopes that it will improve
% performance for the computation of centPixelLabel
[centIndices, sortKey] = sort(sub2ind(cc.ImageSize, centR, centC));
% For each pixel, determine the label of the extended cell body that it touches
centPixelLabel = L2(centIndices);

% Put centR and centC in order corresponding to the linear indices,
% centIndices, and labels, centPixelLabel
centR = centR(sortKey);
centC = centC(sortKey);


%%%%%%%%%%%%%%%%%
T = nip.getCellImage();
red = T; green = T; blue = T;
cellBodyBorder = cellBodyMask & ~imerode(cellBodyMask, true(3));
extendedCellBodyBorder = extendedCellBodyMask & ~imerode(extendedCellBodyMask, true(3));
neuriteBorder = neuriteMask & ~imerode(neuriteMask, true(3));
bodyBorder = cellBodyBorder | extendedCellBodyBorder;
red(bodyBorder) = 1;
green(bodyBorder) = 0;
blue(bodyBorder) = 0;
red(neuriteBorder) = 0;
green(neuriteBorder) = 1;
blue(neuriteBorder) = 0;

sourceCentIdx = sub2ind(size(neuriteMask), centR, centC);
red(sourceCentIdx) = 0;
green(sourceCentIdx) = 0;
blue(sourceCentIdx) = 1;

figure, imshow(cat(3, red, green, blue));
%%%%%%%%%%%%%%%%%

% Step 2: For each extended cell body locate the pixels forming each cell body
% it contains as well as the neurites connected to it. Restrict the neurites
% to the extended cell body.  The result are the targets that the pixels in
% Step 1 will connect to.  We will only need the border pixels.

connected = connected & extendedCellBodyMask;
% Keep only border pixels 
targets = connected & imerode(connected, true(3));
% The pixels found in Step 1 should be connected to target pixels in the same
% extended cell body.  To ensure this, find the label of each the extended cell
% body containing each target.
cc = bwconncomp(targets);
ccLabels = L(cellfun(@(pi)pi(1), cc.PixelIdxList));
% If an extended cell body contains more than 1 cell body (cluster), then more
% than one target (connected component) would have the same label.  Collect
% the connected components by label.
% ccIdxBylabel is a cell array where each element is a vector of
% cc.PixelIdxList indices for connected components of the same label.  For
% example, if ccIdxByLabel{3} is [1 2], then cc.PixelIdxList{1} and
% cc.PixelIdxList{2} are in extended cell body number 3
ccIdxByLabel = accumarray(ccLabels(:), 1:cc.NumObjects, [], @(x){x});


%%%%%%%%%%%
red = T; green = T; blue = T;
targetBorder = targets & ~imerode(targets, true(3)); 
red(targetBorder | bodyBorder) = 1;
green(targetBorder | bodyBorder) = 0;
blue(targetBorder | bodyBorder) = 0;
figure, imshow(cat(3, red, green, blue));
%%%%%%%%%%%


% Step3: Connect locations specified by centR and centC to their nearest
% locations in cc.PixelIdxList where the locations are labeled for the same
% extended cell body.

% For each point speciifed by centR and centC compute the point in targets to
% which it connects
[R2 C2] = arrayfun(@(r, c, lbl)connectToClosest(r, c, lbl, ccIdxByLabel, cc.PixelIdxList, cc.ImageSize), centR, centC, centPixelLabel);

impliedPixelIdxList = arrayfun(@(r1, c1, r2, c2){graphline(r1, c1, r2, c2, cc.ImageSize)}, centR, centC, R2, C2);



impliedNeurites = false(size(neuriteMask));
for i = 1:numel(impliedPixelIdxList)
    % skip any connections that are outside of the extended cell body
    if any(~extendedCellBodyMask(impliedPixelIdxList{i}))
        continue;
    end
    impliedNeurites(impliedPixelidxList{i}) = true;
end

end



% Graph line between (but not including) points (r1,c1) and (r2,c2);
function Idx = graphLine(r1, c1, r2, c2, sz)
% Walk along row or column, whichever has the greater range
if abs(r1 - r2) >= abs(c1 - c2)
    sgn = sign(r2 - r1);
    R = (r1+sgn):sgn:(r2-sgn);
    % Use point-slope formula: y = mx + b;
    m = (c2 - c1) / (r2 - r1);
    b = c1 - (m * r1);
    C = round((R * m) + b);
else
    sgn = sign(c2 - c1);
    C = (c1+sgn):sgn:(c2-sgn);
    % x = my + b;
    m = (r2 - r1) / (c2 - c1);
    b = r1 - (m * c1);
    R = round((C * m) + b);
end
Idx = sub2ind(sz, R, C);
end



function [r2 c2] = connectToClosest(r, c, lbl, ccIdxByLabel, pixelIdxList, sz)
    ccIdx = ccIdxByLabel{lbl};
    func = @(pixelIndices) connectToClosest2(r, c, pixelIndices, sz);
    [R C distSqr] = cellfun(func, pixelIdxList(ccIdx)); 
    [~, idx] = min(distSqr);
    r2 = R(idx);
    c2 = C(idx);
end

function [r2 c2 distSqr] = connectToClosest2(r, c, pixelIndices, sz)
    [pR pC] = ind2sub(sz, pixelIndices);
    distSqrList = arrayfun(@(pr, pc) (pr - r)^2 + (pc - c)^2, pR, pC);
    [distSqr, idx] = min(distSqrList);
    r2 = pR(idx);
    c2 = pC(idx);
end



% Curried version of closestToCentroid
function func = closestToCentroidCurried(sz)
    func = @(pixelIndices) closestToCentroid(sz, pixelIndices);
end

function [r c] = closestToCentroid(sz, pixelIndices)
    % Convert indices to row column values
    [R C] = ind2sub(sz, pixelIndices);
    % Compute centroid
    cr = sum(R(:)) / numel(R);
    cc = sum(C(:)) / numel(C);
    % Compute square of distance between centroid and each pixel location
    distSqr = arrayfun(@(r, c)(cr-r)^2 + (cc-c)^2, R, C);
    % Find pixel location closest to centroid
    [~, idx] = min(distSqr);
    r = R(idx);
    c = C(idx);
end


