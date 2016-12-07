
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


function [edges vertexLocations maxVVEdgeCount] = findEdges2(skeleton, branchPoints, endPoints)
%function [edgeStack vertexLocations] = findEdges2(skeleton, branchPoints, endPoints)

% Create array that maps indices to vertex id numbers.  Locations that are not
% vertices are mapped to 0.
vertex = branchPoints | endPoints;
vertexIdx = find(vertex);
numVertices = numel(vertexIdx);
vertexIdMap = zeros(size(vertex));
vertexIdMap(vertexIdx) = 1:numVertices;


[vertexRow vertexCol] = ind2sub(size(skeleton), vertexIdx);
vertexLocations = [vertexRow vertexCol];

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
end

cc = bwconncomp(paths);

localVertexIdMap = cellfun(@(pixelIdx)vertexIdMap(pixelIdx), cc.PixelIdxList, 'UniformOutput', false);


% Create neighbor encodings for cc.PixelIdxList with same structure
neighborIndicators = cellfun(@(idxList)nextPathPixelFinder(idxList), cc.PixelIdxList, 'UniformOutput', false);

% Create lists of neighbors from neighbor encodings
numRows = cc.ImageSize(1);
[neighbor1IdxList neighbor2IdxList] = cellfun(@(pixelIdx, pixelNeighborEncoding)arrayfun(@(k, nextPixelEncoding)getNeighborIndices(k, nextPixelEncoding, numRows), pixelIdx, pixelNeighborEncoding), cc.PixelIdxList, neighborIndicators, 'UniformOutput', false);


% Create lists of indices in order of traversal
[completeEdgesPath incompleteEdgesPath] = cellfun(@(pil, n1, n2, vim)findPath(pil, n1, n2, vim, cc.ImageSize), cc.PixelIdxList, neighbor1IdxList, neighbor2IdxList, localVertexIdMap, 'UniformOutput', false);


% Now process branch point neighborhood by connecting the paths started by
% branch points to paths in pathIdxList and then possibly to other branch
% points.

% Represent a branch neigborhood by its completed and uncompleted edges
% (and how it is to be completed). Uncompleted edges should be matched to
% other branch neighborhoods or paths
% For each path indicate which ends are completed


cc = bwconncomp(branchPointNeighborhood);
bpnLabels = labelmatrix(cc);

localVertexIdMap = cellfun(@(pixelIdx)vertexIdMap(pixelIdx), cc.PixelIdxList, 'UniformOutput', false);

% Create neighbor encodings for branch point neighborhood
neighborIndicators = cellfun(@(idxList)nextPixelFinder(idxList), cc.PixelIdxList, 'UniformOutput', false);
% Identify indices of branch points and end points
branchPointLocalIndices = cellfun(@(idxList)branchPoints(idxList), cc.PixelIdxList, 'UniformOutput', false);
endPointLocalIndices = cellfun(@(idxList)endPoints(idxList), cc.PixelIdxList, 'UniformOutput', false);


[completeEdgesBranch, incompleteEdgesBranch] = cellfun(@(pil, ni, bp, ep, vim)traceBranchPointNeighborhood(pil, ni, bp, ep, vim, cc.ImageSize), cc.PixelIdxList, neighborIndicators, branchPointLocalIndices, endPointLocalIndices, localVertexIdMap, 'UniformOutput', false);

% In order to match incomplete edges assign lables to connected components.
% labels for branch point neighborhoods are positive and labels for branchless
% paths are negative.
pathLabels = bwlabel(paths);
bpnLabels = bwlabel(branchPointNeighborhood);
% Create a single label matrix with paths labeled with negative numbers
L = bpnLabels - pathLabels;

% Recover next pixel locations (stored as negative vertex id nums) from
% incomplete edges in the branch point neighborhood
nextCA = cellfun(@(iceCA)cellfun(@(ice)-ice.vertices(2), iceCA), incompleteEdgesBranch, 'UniformOutput', false);

% Store next pixel locations in a one-dimensional array, nextArr
count = 0;
for i = 1:numel(nextCA)
    count = count + numel(nextCA{i});
end
nextArr = zeros(count, 1);
idx = 0;
for i = 1:numel(nextCA)
    for j = 1:numel(nextCA{i})
        idx = idx + 1;
        nextArr(idx) = nextCA{i}(j);
    end
end
nextArr = sort(nextArr);
nextLabelArr = L(nextArr);


% Allocate space for currently complete edges and edges to be completed
completeEdgeCount = 0;
for i = 1:numel(completeEdgesBranch)
    completeEdgeCount = completeEdgeCount + numel(completeEdgesBranch{i});
end
for i = 1:numel(completeEdgesPath)
    completeEdgeCount = completeEdgeCount + numel(completeEdgesPath{i});
end

incompleteEdgesBranchCount = 0;
for i = 1:numel(incompleteEdgesBranch)
    incompleteEdgesBranchCount = incompleteEdgesBranchCount + numel(incompleteEdgesBranch{i});
end

% Separate counts of incomplete edges that connect to one edge and counts of
% incomplete edges that connect to two edges
incompleteEdgesPath1Count = 0;
incompleteEdgesPath2Count = 0;
incompleteEdgesPathLoneVertexCount = 0;
for i = 1:numel(incompleteEdgesPath)
    for j = 1:numel(incompleteEdgesPath{i})
        ice = incompleteEdgesPath{i}{j};
        if ice.vertices(1) > 0 && ice.vertices(1) == ice.vertices(2)
            if ice.distance == 0
                incompleteEdgesPathLoneVertexCount = incompleteEdgesPathLoneVertexCount + 1;
            else
                error('[findEdges2] Unexpected edge linking %d to %d of length %f', ice.vertices(1), ice.vertices(2), ice.distance)
            end
        else
            if ice.vertices(1) <= 0 && ice.vertices(2) <= 0
                incompleteEdgesPath2Count = incompleteEdgesPath2Count + 1;
            else
                if ice.vertices(1) <= 0 || ice.vertices(2) <= 0
                    incompleteEdgesPath1Count = incompleteEdgesPath1Count + 1;
                else
                    error('[findEdges2] Unexpected vertex %d to vertex %d edge', ice.vertices(1), ice.vertices(2))
                end
            end
        end
    end
end

%fprintf('completeEdgeCount=%d\n', completeEdgeCount );
%fprintf('incompleteEdgesBranchCount=%d\n', incompleteEdgesBranchCount);
%fprintf('incompleteEdgesPath1Count=%d\n', incompleteEdgesPath1Count);
%fprintf('incompleteEdgesPath2Count=%d\n', incompleteEdgesPath2Count);
%fprintf('incompleteEdgesPathLoneVertexCount=%d\n', incompleteEdgesPathLoneVertexCount);

% Incomplete paths must be matched to incomplete branch edges.  Some paths
% start from an endpoint vertes and need only one incomplete branch edge.
% Other paths neither start nor finish at an end point and need two incomplete
% branch edges.
incompleteBranchEdgesNeeded = incompleteEdgesPath1Count + (2 * incompleteEdgesPath2Count);
assert(incompleteBranchEdgesNeeded <= incompleteEdgesBranchCount, '[findEdges2] Need %d incomplete branch edges but only have %d', incompleteBranchEdgesNeeded, incompleteEdgesBranchCount);

% Any remining incomplete branch edges can be terminated by another incomplete
% branch edge or a lone vertex path edge.  Assume unmatched lone vertex path
% edges are single pixel edges touching a cell body and hence can form their
% own edges.  The number of edges formed in this way is maximized by by
% pairing incomplete branch edges with each other.
remainingIncompleteBranchEdges = incompleteEdgesBranchCount - incompleteBranchEdgesNeeded;

numEdges = completeEdgeCount + incompleteEdgesPath1Count + incompleteEdgesPath2Count + round(remainingIncompleteBranchEdges / 2) + incompleteEdgesPathLoneVertexCount;

% Count of edges between each pair of vertices.  Always use smaller vertex
% number as first index and larger vertex number as second index
vvEdgeCount = sparse(numVertices, numVertices);

%fprintf('Allocating space for %d edges\n', numEdges)
edges = cell(numEdges, 1);
edgeIdx = 0;
for i = 1:numel(completeEdgesPath)
    for j = 1:numel(completeEdgesPath{i})
        edgeIdx = edgeIdx + 1;
        e = completeEdgesPath{i}{j};
        edges{edgeIdx} = e;
        minV = min(e.vertices);
        maxV = max(e.vertices);
        vvEdgeCount(minV, maxV) = vvEdgeCount(minV, maxV) + 1;
    end
end
for i = 1:numel(completeEdgesBranch)
    for j = 1:numel(completeEdgesBranch{i})
        edgeIdx = edgeIdx + 1;
        e = completeEdgesBranch{i}{j};
        edges{edgeIdx} = e;
        minV = min(e.vertices);
        maxV = max(e.vertices);
        vvEdgeCount(minV, maxV) = vvEdgeCount(minV, maxV) + 1;
    end
end


% Incomplete branch edges have the negated value of the next path location
% stored in the second element of the vertices field of the edge
% Incomplete path edges have their zeros stored in the vertices field of the
% edge when the path did not start or end in an endpoint vertex.


% Match incomplete edges
sqrt2 = sqrt(2);
for i = 1:numel(incompleteEdgesBranch)
    iceb = incompleteEdgesBranch{i};
    for j = 1:numel(iceb)
%        fprintf('i=%d of %d  j=%d of %d\n', i, numel(incompleteEdgesBranch), j, numel(iceb));
        ice = iceb{j};
        if isempty(ice)
            continue;
        end
        if ice.useCount ~= 0
            continue;
        end
        k = -ice.vertices(2);
        labelIdx = binarySearch(k, nextArr);
        assert(labelIdx > 0, 'Unable to find index for i=%d j=%d', i, j);
        label = nextLabelArr(labelIdx);
        if label > 0
            iceb2 = incompleteEdgesBranch{label};
        else
            iceb2 = incompleteEdgesPath{-label};
        end
        found = false;
        for j2 = 1:numel(iceb2)
            ice2 = iceb2{j2};
            if isempty(ice2)
                continue;
            end
            if k == ice2.pathIdxList(1) || k == ice2.pathIdxList(end)
                found = true;

% Connect edges ice and ice2
                if isSideAdjacent(k, ice.pathIdxList(end), cc.ImageSize)
                    len = ice.distance + ice2.distance + 1;
                else
                    len = ice.distance + ice2.distance + sqrt2;
                end

                if k == ice2.pathIdxList(1)
                    pathIdxList = [ice.pathIdxList; ice2.pathIdxList];
                    vertices = [ice.vertices(1) ice2.vertices(2)];
                else
                    pathIdxList = [ice.pathIdxList; flip(ice2.pathIdxList)];
                    vertices = [ice.vertices(1) ice2.vertices(1)];
                end
		ice2.distance = len;
                ice2.pathIdxList = pathIdxList;
                ice2.vertices = vertices;
                % Remove the initiatig partial edge
                incompleteEdgesBranch{i}{j} = [];
                % If the edge is complete, then add it to the edges cell array
                % and remove the completing partial edge.  If the edge is
                % incomplete, then since ice2 was updated, leave it in place
                 % to be found by the completing partial edge
                if vertices(2) > 0
                    edgeIdx = edgeIdx + 1;
                    edges{edgeIdx} = ice2;
                    minV = min(ice2.vertices);
                    maxV = max(ice2.vertices);
                    vvEdgeCount(minV, maxV) = vvEdgeCount(minV, maxV) + 1;
                    if label > 0
                        incompleteEdgesBranch{label}{j2} = [];
                    else
                        incompleteEdgesPath{-label}{j2} = [];
                    end
                end
                ice2.useCount = ice2.useCount + 1;
                ice.useCount = ice.useCount + 1;
                break;
            end
        end
        assert(found, 'Unable to complete edge  i=%d j=%d');
    end
end


%for i = 1:numel(incompleteEdgesPath)
%    if numel(incompleteEdgesPath{i}) == 0 continue; end
%    ice = incompleteEdgesPath{i}{1};
%%fprintf('i=%d  %s\n', i, class(ice))
%    if isempty(ice)
%        continue;
%    end
%    if ice.distance == 0 && ice.vertices(1) > 0 && ice.vertices(1) == ice.vertices(2)
%        edgeIdx = edgeIdx + 1;
%        edges{edgeIdx} = ice;
%        minV = min(ice.vertices);
%        maxV = max(ice.vertices);
%        vvEdgeCount(minV, maxV) = vvEdgeCount(minV, maxV) + 1;
%        incompleteEdgesPath{i}{1} = [];
%    end
%end

%fprintf('Stored %d complete edges\n', edgeIdx);
edges = edges(1:edgeIdx);
maxVVEdgeCount = max(vvEdgeCount(:));

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
    kVertexId = vertexIdMap(i);
    % starts contains the first pixel locations for paths leading from k
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
            % Code incomplete edge with next location as a negative number to
            % differentiate from a vertex id number
            edge = EdgeInfo(edgeLength, pathIdxList, [kVertexId, -p]);
            incompleteEdgeIdx = incompleteEdgeIdx + 1;
            incompleteEdges{incompleteEdgeIdx} = edge;
        else
            edge = EdgeInfo(edgeLength, pathIdxList, [kVertexId, vertexIdMap(localIdx)]);
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


% Return the sequence of indices of adjacent locations in kArr.  Each index in
% karr has at most two neighbors whose indices are in neighbor1 and neighbor2.
% A nonexistent neighbor is coded as a 0.  If the location at index k has only
% one neighbor, then its index is in n1 and the corresponding value in n2 is
% zero. This code assumes that there are no cycles in the path and that kArr is
% sorted.
function [completeEdges incompleteEdges] = findPath(kArr, neighbor1, neighbor2, vertexIdMap, sz)

% Find a path end point and start from there
Z = find(neighbor2 == 0);
if numel(Z) == 1
    % A single end point means a path consisting of a single pixel
    if numel(kArr) ~= 1 || neighbor1(Z(1)) ~= 0
        error('[findEdges2.findPath] Unexpected pixel locations');
    end
    vId = vertexIdMap(Z(1));
    % Even though the edge could be a single pixel extending from a cell body,
    % consider the edge incomplete because it could be the termination of an
    % edge starting from a branch point
    incompleteEdges = {EdgeInfo(0, kArr, [vId vId])};
    completeEdges = {};
    return;
else 
    if numel(Z) ~= 2
        error('[findEdges2.findPath] Unexpected number of endpoints: %d', numel(Z));
    end
end

% If possble, start at vertex
if vertexIdMap(Z(1)) > 0
    start = Z(1);
else
    start = Z(2);
end
startVertex = vertexIdMap(start);


% First two points on path
%prevK = kArr(Z(1));
%k = neighbor1(Z(1));
prevK = kArr(start);
k = neighbor1(start);

path = zeros(size(kArr));
path(1) = prevK;
pathIdx = 1;
sideAdjacencyCount = 0;
cornerAdjacencyCount = 0;
while k ~= 0
    pathIdx = pathIdx + 1;
    path(pathIdx) = k;
    if isSideAdjacent(k, prevK, sz)
        sideAdjacencyCount = sideAdjacencyCount + 1;
    else
        cornerAdjacencyCount = cornerAdjacencyCount + 1;
    end
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
assert(pathIdx == numel(path), '[findEdges2.findPath] unexpected path length');
endVertex = vertexIdMap(i);
if startVertex == 0 && endVertex ~= 0
    error('[findEdges2.findPath] Path ended at a vertex but did not start at a vertex');
end
edgeLength = sideAdjacencyCount + (sqrt(2) + cornerAdjacencyCount);
edge = EdgeInfo(edgeLength, path, [startVertex, endVertex]);
if startVertex ~= 0  && endVertex ~= 0
    completeEdges = {edge};
    incompleteEdges = {};
else
    completeEdges = {};
    incompleteEdges = {edge};
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

