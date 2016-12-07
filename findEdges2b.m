
% Neighbor Encoding
%
% Each skeleton location can be assigned a positive value indicating the
% locations of all neighboring pixels within a 3x3 grid.  We start by assigning
% positive powers of 2 to each of the eight neighbors surrounding a location:
%
%   1 16  2
% 128  _ 32
%   8 64  4
%
% Since pixels that share a side have a higher path precedence than those
% that share a corner, the side pixels are encoded by higher values than
% the corner pixels.
%
% The neighbors can be combined into a single number by summing them.  For
% example 16 + 2 + 64 = 82.  Since unique powers of 2 are summed,
% individual neighbors can be recovered.  Thus, when a location in a binary
% array has the following neighbors:
%
% 0 1 1
% 0 _ 0
% 0 1 0
%
% We can encode this situation with the single, positive value 82.  We can
% then replace each of the 1s in a binary array with other numbers that
% represent the neighbors of the skeleton locations.
%
% Note that the presence of a side neighbor always forces the sum to be
% greater than 15 which can be quickly tested.
%
% When tracing a path, if the encoding of the preceding neighbor is known,
% it can be subtracted from the sum leaving at most a single encoded
% neighbor (for non-branch points) indicating the next pixel in the path.
% Note that the identification of the next path location requires no
% additional information from the array. So we eliminate the checking of
% the array for potential neighbors.
%
% Thus we trade the checking for potential neighbors for the cost of
% replacing 1s in an array with neighbor encodings.  Fortunately, the
% Matlab imfilter function can do this realtively efficiently.
%


function findEdges2(skeleton, branchPoints, endPoints)
%function [edgeStack vertexLocations] = findEdges2(skeleton, branchPoints, endPoints)

% Remove elbows
h = [8 2 8; 1 4 1; 8 2 8];
elbows = imfilter(skeleton, h) == 7;
skeleton = skeleton & ~elbows;

branchPointNeighborhood = imdilate(branchPoints, true(3));
paths = skeleton & ~branchPointNeighborhood;

nextPixelFilter = [1 16 2; 128 0 32; 8 64 4];
nextPixelFinder = imfilter(uint8(skeleton), nextPixelFilter);
nextPathPixelFinder = imfilter(uint8(paths), nextPixelFilter);


% Check for ambiguities on paths
amb = (imfilter(double(paths), [1 1 1; 1 0 1; 1 1 1]) > 2) .* paths;
if any(amb(:))
    [R C] = find(amb);
    r1 = R(1);
    c1 = C(1);
    error('[findEdges2] Found path ambiguity at r=%d c=%d', r1, c1)
else
    fprintf('[findEdges2] No path ambiguities\n')
end

cc = bwconncomp(paths);
L = labelmatrix(cc);

% For each connected component, determine its pixel neighbors
%nextPixelsCA = cellfun(@(pixelIndices) nextPathPixelFinder(pixelIndices), cc.PixelIdxList, 'UniformOutput', false);

% Create neighbor encodings for cc.PixelIdxList with same structure
neighborIndicators = cellfun(@(idxList)nextPathPixelFinder(idxList), cc.PixelIdxList, 'UniformOutput', false);


P = false(size(paths));
numRows = size(paths, 1);
for i = 1:numel(cc.PixelIdxList)
    pixelIndices = cc.PixelIdxList{i};
    nextPixelsList = neighborIndicators{i};
    pixelIndices2 = zeros(numel(pixelIndices), 1);
    idx = 0;
    for j = 1:numel(nextPixelsList)
        k = pixelIndices(j);
if i == 1 & j == 52
  rgb = double(cat(3, skeleton, skeleton, branchPoints));
    [r c] = ind2sub(size(paths), k)
figure, imshow(rgb((r-25):(r+25),(c-25):(c+25),:), 'initialmagnification', 'fit');
end
        indicator = nextPixelsList(j);
        count = 0;
        for n = 1:8
            if bitget(indicator, n) == 1
                count = count + 1;
                switch n
                    case 1
                        k2 = (k - 1) - numRows;
                    case 2
                        k2 = (k - 1) + numRows;
                    case 3
                        k2 = (k + 1) + numRows;
                    case 4
                        k2 = (k + 1) - numRows;
                    case 5
                        k2 = k - 1;
                    case 6
                        k2 = k + numRows;
                    case 7
                        k2 = k + 1;
                    case 8
                        k2 = k - numRows;
                    otherwise
                        error('switch error')
                end
                idx = idx + 1;
                pixelIndices2(idx)= k2;
            end
        end
        if count > 2
            error('i=%d j=%d  count=%d  indicator=%d', i, j, count, indicator)
        end

    end
    pixelIndices2 = unique(pixelIndices2);
    if pixelIndices2(1)== 0
        pixelIndices2 = pixelIndices2(2:end);
    end
%if numel(pixelIndices) ~= numel(pixelIndices2)
%i
%      error()
%end
    pixelIndices = sort(pixelIndices);
    if any(pixelIndices ~= pixelIndices2)
        error('Pixel list %d', i);
    end
end
error('DONE');


% Create lists of neighbors from neighbor encodings
numRows = cc.ImageSize(1);
[neighbor1IdxList neighbor2IdxList] = cellfun(@(pixelIdx, pixelNeighborEncoding)arrayfun(@(k, nextPixelEncoding)getNeighborIndices(k, nextPixelEncoding, numRows), pixelIdx, pixelNeighborEncoding), cc.PixelIdxList, neighborIndicators, 'UniformOutput', false);

% Create lists of indices in order of traversal
pathIdxList = cellfun(@findPath, cc.PixelIdxList, neighbor1IdxList, neighbor2IdxList, 'UniformOutput', false);

end

% Return the sequence of indices in kArr.  kArr is an n-by-3 array where each
% row is structured as a sequence of values: k, n1, n2 where k is a pixel
% index and n1 and n2 are the indices of its neighbors.  A nonexistent
% neighbor is coded as a 0.  If k has only one neighbor, then n1 is non-zero
% and n2 is zero.  This code assumes that there are no cycles in the path
function sequence = findPath(kArr, neighbor1, neighbor2)
% Sort kArr by k value
[~, sortKey] = sort(kArr);
kArr = kArr(sortKey);
neighbor1 = neighbor1(sortKey);
neighbor2 = neighbor2(sortKey);

% Find a path end point and start from there
Z = find(neighbor2 == 0);
if numel(Z) == 1
    % A single end point means a path consisting of a single pixel
    sequence = Z;
    if numel(kArr) ~= 1
        error('[findEdges2.findPath] Unexpected pixel locations');
    end
    return;
else 
    if numel(Z) ~= 2
        error('[findEdges2.findPath] Unexpected number of endpoints: %d', numel(Z));
    end
end

% First two pints on path
prevK = kArr(Z(1));
k = neighbor1(Z(1));

sequence = zeros(size(kArr));
sequence(1) = prevK;
seqIdx = 1;
while k ~= 0
    seqIdx = seqIdx + 1;
    sequence(seqIdx) = k;
    i = binarySearch(k, kArr);
    n1 = neighbor1(i);
    if n1 == 0
        error('[findEdges2.findPath] Unexpected single pixel path')
    else
        if n1 ~= prevK
            prevK = k;
            k = n1;
        else
            prevK = k;
            k = neighbor2(i);
        end
    end
end

end

function idx = binarySearch(target, table)
idx = 0;
lo = 1;
hi = size(table, 1);
while lo < hi
    mid = round((lo + hi) / 2);
    val = table(mid, 1);
    if target == val
        idx = mid;
        return;
    else
        if target < val
            hi = mid - 1;
        else
            lo = mid + 1;
        end
    end
end
end


function [neighbor1 neighbor2] = getNeighborIndices(k, nextPixelVal, numRows);
neighbor1 = 0;
neighbor2 = 0;
for i = 1:8
    if bitget(nextPixelVal, i) == 1
        switch i
            case 1  % 1: Previous row and previous column
                k2 = (k - 1) - numRows;
            case 2  % 2: Previous row and next column
                k2 = (k - 1) + numRows;
            case 3  % 4: Next row and next column
                k2 = (k + 1) + numRows;
            case 4  % 8: Next row and previous column
                k2 = (k + 1) - numRows;
            case 5  % 16: Previous row and same column
               k2 = k - 1;
            case 6  % 32: Same row and next column
                k2 = k + numRows;
            case 7  % 64: Next row and same column
                k2 = k + 1
            case 8 % 128: Same row and previous column
                k2 = k - numRows;
            otherwise
                error('[findEdges2.getNeighborIndices] Unexpected index %d', i);
        end
        if neighbor1 == 0
            neighbor1 = k2;
        else
            if neighbor2 == 0
                neighbor2 = k2;
            else
                error('[findEdges2.getNeighborIndices] More than two neighbors encoded in %d', nextPixelValue)
            end
        end
    end
end
end

