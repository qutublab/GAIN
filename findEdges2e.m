
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

% Create array that maps indices to vertex id numbers.  Locations that are not
% vertices are mapped to 0.
vertex = branchPoints | endPoints;
vertexIdx = find(vertex);
numVertices = numel(vertexIdx);
vertexIdMap = zeros(size(vertexIdx));
vertexIdMap(vertexIdx) = 1:numVertices;


% Remove elbows
h = [8 2 8; 1 4 1; 8 2 8];
elbows = imfilter(skeleton, h) == 7;
skeleton = skeleton & ~elbows;

branchPointNeighborhood = imdilate(branchPoints, true(3)) & skeleton;
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





% Create neighbor encodings for cc.PixelIdxList with same structure
neighborIndicators = cellfun(@(idxList)nextPathPixelFinder(idxList), cc.PixelIdxList, 'UniformOutput', false);

% Create lists of neighbors from neighbor encodings
numRows = cc.ImageSize(1);
[neighbor1IdxList neighbor2IdxList] = cellfun(@(pixelIdx, pixelNeighborEncoding)arrayfun(@(k, nextPixelEncoding)getNeighborIndices(k, nextPixelEncoding, numRows), pixelIdx, pixelNeighborEncoding), cc.PixelIdxList, neighborIndicators, 'UniformOutput', false);

% Create lists of indices in order of traversal
pathIdxList = cellfun(@findPath, cc.PixelIdxList, neighbor1IdxList, neighbor2IdxList, 'UniformOutput', false);


% Now process branch point neighborhood by connecting the paths started by
% branch points to paths in pathIdxList and then possibly to other branch
% points.

% Represent a branch neigborhood by its completed and uncompleted edges
% (and how it is to be completed). Uncompleted edges should be matched to
% other branch neighborhoods or paths
% For each path indicate which ends are completed


cc = bwconncomp(branchPointNeighborhood);

localVertexIdMap = cellfun(@(pixelIdx)vertexIdMap, cc.PixelIdxList, 'UniformOutput', false);

% Create neighbor encodings for branch point neighborhood
neighborIndicators = cellfun(@(idxList)nextPixelFinder(idxList), cc.PixelIdxList, 'UniformOutput', false);
% Identify indices of branch points and end points
branchPointLocalIndices = cellfun(@(idxList)branchPoints(idxList), cc.PixelIdxList, 'UniformOutput', false);
endPointLocalIndices = cellfun(@(idxList)endPoints(idxList), cc.PixelIdxList, 'UniformOutput', false);


%[r c] = ind2sub(size(skeleton), 1977)
%rgb = double(cat(3, skeleton, skeleton, branchPoints));
%figure, imshow(rgb((r-2):(r+2),(c-1):(c+2)), 'InitialMagnification', 'fit');
%figure, imshow(branchPoints((r-2):(r+2),(c-1):(c+2)), 'InitialMagnification', 'fit');



[completeEdges, incompleteEdges] = cellfun(@(pil, ni, bp, ep, vim)traceBranchPointNeighborhood(pil, ni, bp, ep, vim, cc.ImageSize), cc.PixelIdxList, neighborIndicators, branchPointLocalIndices, endPointLocalIndices, localVertexIdMap, 'UniformOutput', false);


% Check that completeEdges and incompleteEdges can reconstruct paths
for i = 1:cc.NumObjects
    fprintf('Object %d of %d\n', i, cc.NumObjects);
    pixelIdxList = cc.PixelIdxList{i};
    % Count occurrences of each pixel location
    map = containers.Map(pixelIdxList, zeros(1, numel(pixelIdxList)));
    edgeCA = {completeEdges{i}, incompleteEdges{i}};
    for j = 1:2
        edgeInfoCA = edgeCA{j};
        for k = 1:numel(edgeInfoCA)
            e = edgeInfoCA{k};
            for p = 1:numel(e.pathIdxList)
                map(e.pathIdxList(p)) = map(e.pathIdxList(p)) + 1;
            end
        end
    end

    for j = 1:numel(pixelIdxList)
        idx = pixelIdxList(j);
        count = map(idx);
        switch count
            case 0
                error('Unvisited location i=%d j=%d', i, j);
            case 1
                assert(~branchPoints(idx), 'Single branch point i=%d j=%d', i, j);
            otherwise
	    assert(branchPoints(idx), 'Multi nonbranch i=%d j=%d idx=%d count=%d', i, j, idx, count);
        end
    end
end

%for idx = 1:numel(cc.PixelIdxList)
%    fprintf('[findEdges2] idx=%d (of %d)\n', idx, cc.NumObjects);
%    traceBranchPointNeighborhood(cc.PixelIdxList{idx}, neighborIndicators{idx}, branchPointLocalIndices{idx}, endPointLocalIndices{idx}, localVertexIdMap{idx}, cc.ImageSize);
%end

%sz = cellfun(@numel, cc.PixelIdxList);
%uniqueSz = unique(sz) 
%mx = uniqueSz(end-12)
%mxIdx = find(sz == mx);
%numel(mxIdx)
%mxIdx = mxIdx(1);
%snbp = skeleton & ~branchPoints;
%rgb = double(cat(3, snbp, snbp, branchPoints));
%for i = 21:40 %numel(mxIdx)
%    [R C] = ind2sub(cc.ImageSize, cc.PixelIdxList{mxIdx(i)});
%    minR = min(R);
%    maxR = max(R);
%    minC = min(C);
%    maxC = max(C);
%    rgb2 = rgb(minR:maxR, minC:maxC, :);
%    figure, imshow(rgb2, 'InitialMagnification', 'fit');
%end




end

% Assume that kArr is sorted. Arguments branchPoint and endPoint are arrays of
% the same size as kArr.
function [completeEdges, incompleteEdges] = traceBranchPointNeighborhood(kArr, neighborIndicator, branchPoint, endPoint, vertexIdMap, sz)
sqrt2 = sqrt(2);
numBranchPoints = sum(double(branchPoint(:)));
% At most each branchpoint can have 4 edges
completeEdges = cell(4 * numBranchPoints, 1);
incompleteEdges = cell(4 * numBranchPoints, 1);
completeEdgeIdx = 0;
incompleteEdgeIdx = 0;
used = false(size(kArr));
for i = 1:numel(kArr)
    % Start tracing at a branch point
    if ~branchPoint(i) continue; end
    k = kArr(i);
    % starts contains both original indices but corresponding indices for kArr
%    starts = getStarts(k, neighborIndicator(i), numRows);
    starts = next(k, neighborIndicator(i), sz);
    for j = 1:numel(starts)
        prev = k;
        p = starts(j);
        % Indices k, p, prev, p2 are indices for the original image matrix.
        % However arrays neighborIndicator and used are the same size as kArr
        % and hence a local index is computed which indicates the position of
        % index p in kArr
        localIdx = binarySearch(p, kArr);
        assert(localIdx > 0, '[findEdges.traceBranchPointNeighborhood] Point %d has unexpected local index %d', p, localIdx)
        if used(localIdx) continue;
        else
            used(localIdx) = true;
        end
        path = zeros(size(kArr));
        path(1) = k;
        path(2) = p;
        pathIdx = 2;
        sideAdjacencyCount = 0;
        cornerAdjacencyCount = 0;
        if isSideAdjacent(p, k, sz)
            sideAdjacencyCount = sideAdjacencyCount + 1;
        else
            cornerAdjacencyCount = cornerAdjacencyCount + 1;
        end
        while localIdx > 0 && ~branchPoint(localIdx) && ~endPoint(localIdx)
            p2 = next(p, neighborIndicator(localIdx), sz, prev);
            assert(numel(p2) == 1, '[findEdges2.traceBranchPointNeighborhood] index %d has %d next locations', p, numel(p2));
            prev = p;
            p = p2;
            localIdx = binarySearch(p, kArr);
            % If localIdx is positive then p is in the branch point
            % neighborhood
            if localIdx > 0 
                pathIdx = pathIdx + 1;
                path(pathIdx) = p;
                % Do not mark a branch point as used until all of its incident
                % edges are examined
                if ~branchPoint(localIdx)
                    used(localIdx) = true;
                end
                % Track distance for points in neighborhood only 
                if isSideAdjacent(p, prev, sz)
                    sideAdjacencyCount = sideAdjacencyCount + 1;
                else
                    cornerAdjacencyCount = cornerAdjacencyCount + 1;
                end
            end
        end
        edgeLength = sideAdjacencyCount + (sqrt2 * cornerAdjacencyCount);
        % Remove extra zeros at end of path
        pathIdxList = path(1:pathIdx); 
        if localIdx <= 0
            % Code incomplete edge with a 0 as second vertex identity num
            edge = EdgeInfo(edgeLength, pathIdxList, [vertexIdMap(k), 0]);
            incompleteEdgeIdx = incompleteEdgeIdx + 1;
            incompleteEdges{incompleteEdgeIdx} = edge;
        else
            edge = EdgeInfo(edgeLength, pathIdxList, [vertexIdMap(k), vertexIdMap(localIdx)]);
            completeEdgeIdx = completeEdgeIdx + 1;
            completeEdges{completeEdgeIdx} = edge;
        end
    end
    % Mark branch point as used
    localIdx = binarySearch(k, kArr);;
    assert(localIdx > 0, '[findEdges.traceBranchPointNeighborhood] Point %d has unexpected local index %d', k, localIdx)
    used(localIdx) = true;
end
completeEdges = completeEdges(1:completeEdgeIdx);
incompleteEdges = incompleteEdges(1:incompleteEdgeIdx);
end


% Returns 1 when pixels share a side and returns 0 when they share a corner
% Assumes pixels are adjacent.
function s = isSideAdjacent(p1, p2, sz)
numRows = sz(1);
diff = abs(p1 - p2);
if diff == 1 || diff == numRows
    s = true;
else
    if diff == (numRows - 1) || diff == (numRows + 1)
        s = false;
    else
        error('[findEdges2.codedPixelDist] %d and %d are not adjacent (numRows=%d)', p1, p2, numRows)
    end
end
end

% Returns next index, k2, according to neighborIndicator
function k2 = next(k, neighborIndicator, sz, prevK)
% Extract bits in clockwise order starting at left side with wrap-around.
bit = logical(bitget(neighborIndicator, [8 1 5 2 6 3 7 4 8]));
% Remove corner neighbors next to a side neighbor
for i = [2 4 6 8]
    if bit(i) && (bit(i-1) || bit(i+1))
        bit(i) = false;
    end
end

grid = [bit(2) bit(3) bit(4); ...
        bit(1)   0    bit(5); ...
        bit(8) bit(7) bit(6)];

[nextR nextC] = find(grid);
% Convert nextR and nextC coordinates from being based on a 3x3 grid to being
% based on the original image
[kR kC] = ind2sub(sz, k);
r = kR + (nextR - 2);
c = kC + (nextC - 2);
k2 = sub2ind(sz, r, c);

% If optional previous location argument is present, then remove it from
% result.
if nargin > 3
    i = find(k2 == prevK);
    assert(numel(i) == 1, '[findEdges2.next] Found %d occurrences of previous location', numel(i));
    k2(i) = [];
end
end

% Returns next index, k2, according to neighborIndicator
function k2 = nextOLD2(k, prevK, neighborIndicator, numRows)
fprintf('[findEdges2.next] k=%d  neighborIndicator=%d\n', k, neighborIndicator);
k2 = 0;
offset = [-1 - numRows, -1 + numRows, 1 + numRows, 1 - numRows, ...
    -1, numRows, 1, -numRows];
% Check locations sharing a side first
for i = 5:8
    if bitget(neighborIndicator, i)
        candidateK2 = k + offset(i);
        if candidateK2 ~= prevK
            if k2 == 0
                k2 = candidateK2;
            else
                % More than 1 next location
                error('[findEdges2.next] Ambiguous neighbor indicator: %d', neighborIndicator);
            end
        end
    end
end
if k2 == 0
    % Check locations sharing a corner
    for i = 1:4
        if bitget(neighborIndicator, i)
            candidateK2 = k + offset(i); 
            if candidateK2 ~= prevK
                if k2 == 0
                    k2 = candidateK2;
                else
                    % More than 1 next location
                    error('[findEdges2.next] Ambiguous neighbor indicator: %d', neighborIndicator);
                end
            end
        end
    end
end

assert(k2 > 0, '[findEdges2.next] Unable to find neighbor');
end

function k2 = nextOLD(k, prevK, neighborIndicator, numRows)
fprintf('[findEdges2.next] k=%d\n', k);
k2 = 0;
offset = [-1 - numRows, -1 + numRows, 1 + numRows, 1 - numRows, ...
    -1, numRows, 1, -numRows];
for i = 1:8
    if bitget(k, i)
        candidateK2 = k + offset(i); 
        if candidateK2 ~= prevK
            if k2 == 0
                k2 = candidateK2;
            else
                % More than 1 next location
                error('[findEdges2.next] Ambiguous neighbor indicator: %d', neighborIndicator);
            end
        end
    end
end
assert(k2 > 0, '[findEdges2.next] Unable to find neighbor');
end





% Returns the indices of occupied adjacent locations.  Note that corner
% locations are valid only if they do not touch a side location.
function starts = getStarts(k, neighborIndicator, numRows)
hasTopNeighbor = bitget(neighborIndicator, 5) == 1;
if hasTopNeighbor
    topNeighborIndex = k - 1;
else
    topNeighborIndex = [];
end

hasRightNeighbor = bitget(neighborIndicator, 6) == 1;
if hasRightNeighbor
    rightNeighborIndex = k + numRows;
else
    rightNeighborIndex = [];
end

hasBottomNeighbor = bitget(neighborIndicator, 7);
if hasBottomNeighbor
    bottomNeighborIndex = k + 1;
else
    bottomNeighborIndex = [];
end

hasLeftNeighbor = bitget(neighborIndicator, 8);
if hasLeftNeighbor
    leftNeighborIndex = k - numRows;
else
    leftNeighborIndex = [];
end

hasUpperLeftNeighbor = bitget(neighborIndicator, 1);
if hasUpperLeftNeighbor && ~hasTopNeighbor && ~hasLeftNeighbor
    upperLeftNeighborIndex = (k - 1) - numRows;
 else
    upperLeftNeighborIndex = [];
end

hasUpperRightNeighbor = bitget(neighborIndicator, 2);
if hasUpperRightNeighbor && ~hasTopNeighbor && ~hasRightNeighbor
    upperRightNeighborIndex = (k - 1) + numRows;
 else
    upperRightNeighborIndex = [];
end

hasLowerRightNeighbor = bitget(neighborIndicator, 3);
if hasLowerRightNeighbor && ~hasBottomNeighbor && ~hasRightNeighbor
    lowerRightNeighborIndex = (k + 1) + numRows;
 else
    lowerRightNeighborIndex = [];
end

hasLowerLeftNeighbor = bitget(neighborIndicator, 4);
if hasLowerLeftNeighbor && ~hasBottomNeighbor && ~hasLeftNeighbor
    lowerLeftNeighborIndex = (k + 1) - numRows;
 else
    lowerLeftNeighborIndex = [];
end

starts = [topNeighborIndex leftNeighborIndex bottomNeighborIndex ...
    rightNeighborIndex upperLeftNeighborIndex upperRightNeighborIndex ...
    lowerRightNeighborIndex lowerLeftNeighborIndex];
end


% Return the sequence of indices of adjacent locations in kArr.  Each index in
% karr has at most two neighbors whose indices are in neighbor1 and neighbor2.
% A nonexistent neighbor is coded as a 0.  If the location at index k has only
% one neighbor, then its index is in n1 and the corresponding value in n2 is
% zero. This code assumes that there are no cycles in the path
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
    sequence = kArr;
    if numel(kArr) ~= 1
        error('[findEdges2.findPath] Unexpected pixel locations');
    end
    return;
else 
    if numel(Z) ~= 2
        error('[findEdges2.findPath] Unexpected number of endpoints: %d', numel(Z));
    end
end

% First two points on path
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


% Searches the first column of table for the target value.  Returns the row
% numer or 0 if the target is not found
function idx = binarySearch(target, table)
idx = 0;
lo = 1;
hi = size(table, 1);
while lo <= hi
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
                k2 = k + 1;
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



% Returns the count of immediately adjacent neighbors.  Because locations that
% share a side have precedence over neighbors that share a corner, corner
% locations might need to be ignored.  For example, location C in:
%
% 0 A B
% 0 C 0
% D 0 0
%
% has two immediately adjacent neighbors, A and D. Location B is immediately
% adjacent to A, but not C

% Assume kArrSorted is a sorted (low to high) column vector
function vertexStatus = isVertex(k, kArrSorted, numRows, maxK)
% Indices of potential side neighbors in clockwise order starting from top
% center
snIdx1 = k - 1;
snIdx2 = k + numRows;
snIdx3 = k + 1;
snIdx4 = k - numRows;

sideNeighborIndices = [snIdx1 snIdx2 snIdx3 snIdx4];
sideNeighbors = [false, false, false, false];
for i = 1:4
    sideNeighbors = binarySearch(sideNeighborIndices(i), kArrSorted) > 0;
end

sideNeighborCount = sum(sideNeighbors);

% If more than 2 neigbhors, location is a branch point and therefore a vertex
if sideNeighborCount > 2
    vertexStatus = true;
    return;
end


% Indices of potential corner neighbors in clockwise order starting from top
% left
cnIdx1 = (k - 1) + numRows;
cnIdx2 = k + 1 + numRows;
cnIdx3 = (k + 1) - numRows;
cnIdx4 = (k - 1) - numRows;

cornerNeighborIndices = [cnIdx1, cnIdx2, cnIdx3, cnIdx4];
cornerNeighbors = [false, false, false, false];
for i = 1:4
    cornerNeighbors(i) = binarySearch(cornerneighborIndices(i), kArrSorted) > 0;
end

% Add side neighbor index for wrap-around
sideNeighbors = [sideNeighbors, snIdx1];
% Ignore corner neigbors adjacent to side neighbors
countableCornerNeighbors = [false false false false];
for i = 1:numel(countableCornerNeighbors)
    countableCornerNeighbors(i) = cornerNeighbors(i) && ~sideNeighbors(i) && ~sideNeighbors(i+1);
end

cornerNeighborCount = sum(countableCornerNeighbors);

neighborCount = sideNeighborCount + cornerNeighborCount;
vertexStatus = (neighborCount ~= 2);

end

