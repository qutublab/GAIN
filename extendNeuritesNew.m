
function extensions = extendNeuritesNew(nip, neuriteMask, cellBodyMask, extendedCellBodyMask, dilationSide)

% Ignore extended cell bodies that do not contain cell bodies
extendedCellBodyMask = imreconstruct(cellBodyMask, extendedCellBodyMask);

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


% Find neurites that touch an extended cell body but do not touch any cell
% body in it.  Note that one end of a neurite might touch an extended cell
% body an not touch a cell body, but the other end of the neurite may in fact
% touch a different cell body.  Because of this, restrict neurites to the
% portions within and just touching an extended cell body.

restrictedNeurites = neuriteMask & L2;
connectedRestricted = imreconstruct(cellBodyMask, cellBodyMask | restrictedNeurites);
unconnectedRestricted = restrictedNeurites & ~connectedRestricted;

% Keep unconnected neurites whose area outside the extended cell body is
% sufficiently large
unconnectedOutside = imreconstruct(unconnectedRestricted, neuriteMask) & ~extendedCellBodyMask;
largeUnconnectedOutside = bwareaopen(unconnectedOutside, (dilationSide * 2)^2);

% Keep just the pixels of unconnected neurites that are outside but touch the
% extended cell bodies
unconnectedFringe = unconnectedRestricted & largeUnconnectedOutside & ~extendedCellBodyMask;

% Reduce each fringe connected component to a single pixel in the connected
% component closest to its centroid
cc = bwconncomp(unconnectedFringe);
[centR centC] = cellfun(closestToCentroidCurried(cc.ImageSize), cc.PixelIdxList);
% Convert to linear indices
centIndices = sub2ind(cc.ImageSize, centR, centC);
% For each pixel, determine the label of the extended cell body that it touches
centPixelLabel = L2(centIndices);

% Step 2: For each extended cell body locate the pixels forming each cell body
% it contains as well as the neurites connected to it. Restrict the neurites
% to the extended cell body.  The result are the targets that the pixels in
% Step 1 will connect to.  We will only need the border pixels.

connectedECBM = connectedRestricted & extendedCellBodyMask;
% Keep only border pixels 
targets = connectedECBM & imerode(connectedECBM, true(3));
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


% Step3: Connect locations specified by centR and centC to their nearest
% locations in cc.PixelIdxList where the locations are labeled for the same
% extended cell body.

% For each point speciifed by centR and centC compute the point in targets to
% which it connects
[R2 C2] = arrayfun(@(r, c, lbl)connectToClosest(r, c, lbl, ccIdxByLabel, cc.PixelIdxList, cc.ImageSize), centR, centC, centPixelLabel);

impliedPixelIdxList = arrayfun(@(r1, c1, r2, c2){graphLine(r1, c1, r2, c2, cc.ImageSize)}, centR, centC, R2, C2);

impliedNeurites = false(size(neuriteMask));
for i = 1:numel(impliedPixelIdxList)
    % skip any connections that are outside of the extended cell body
    if any(~L2(impliedPixelIdxList{i}))
        continue;
    end
    impliedNeurites(impliedPixelIdxList{i}) = true;
end

extensions = imdilate(impliedNeurites, true(dilationSide));


%T = nip.getCellImage();
%figure, imshow(T);
%red = T; green = T; blue = T;
%cellBodyBorder = cellBodyMask & ~imerode(cellBodyMask, true(3));
%extendedCellBodyBorder = extendedCellBodyMask & ~imerode(extendedCellBodyMask, true(3));
%neuriteBorder = neuriteMask & ~imerode(neuriteMask, true(3));
%bodyBorder = cellBodyBorder | extendedCellBodyBorder;
%red(bodyBorder) = 1;
%green(bodyBorder) = 0;
%blue(bodyBorder) = 0;
%red(neuriteBorder) = 0;
%green(neuriteBorder) = 1;
%blue(neuriteBorder) = 0;
%red(extensions) = 0;
%green(extensions) = 0;
%blue(extensions) = 1;
%figure, imshow(cat(3, red, green, blue));


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


