
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


function [edgeStack vertexLocations] = findEdges(skeleton, branchPoints, endPoints)

fprintf('[findEdges] Prep...\n');
tic;
skeleton = uint8(skeleton);
% Identify vertices
vertex = uint8(branchPoints | endPoints);
vertexIdx = find(vertex);
[vertexRow vertexCol] = ind2sub(size(skeleton), vertexIdx);
vertexLocations = [vertexRow, vertexCol];
numVertices = numel(vertexIdx);
% Assign a vertex number to each vertex pixel
vertexNumber = zeros(size(vertex));
vertexNumber(vertexIdx) = 1:numVertices;

% Determine the neighboring pixels of each skeleton pixel
nextPixelFilter = [1 16 2; 128 0 32; 8 64 4];
nextPixelFinder = uint8(imfilter(skeleton, nextPixelFilter)) .* skeleton;

vertexPixelFinder = nextPixelFinder .* vertex;

vertexPathStarts = vertexPixelFinder(vertexIdx);

% Not all vertex neighbors are on unique paths.  Any two adjacent vertex
% neighbors on a side and at a corner must be on the same path.  Since side
% neighbors have precedence over corner neighbors, remove corner neighbors
% adjacent to side neighbors.  Thus each neighbor is the start of a unique path
% from the vertex.
vertexPathStarts = removeAdjacentCornerNeighbors(vertexPathStarts);

% Clear the indicators for the vertices, this allows a fast way to determine
% when a vertex has been reached
nextPixelFinder(branchPoints | endPoints) = 0;

% Find all paths starting from each vertex
edgeStack = Stack();
[vertexR vertexC] = ind2sub(size(vertex), vertexIdx);
fprintf('[findEdges] Main loop; %d vertices...\n', numVertices);
numTimings = 0;
totalTime = 0;
minTime = Inf;
maxTime = -Inf;
waitbarHandle = waitbar(0, sprintf('Begin searching for paths from %d vertices', numVertices));
for i = 1:numVertices
    pathStarts = vertexPathStarts(i);
%    fprintf('[test2.test2] processing paths from vertex %d  pathStarts=%d\n', i, pathStarts);
    if pathStarts ~= 0
        vr = vertexR(i);
        vc = vertexC(i);
        bitPos = 0;
        while pathStarts ~= 0
            bitPos = bitPos + 1;
            indicator = bitget(pathStarts, 1);
            pathStarts = bitsrl(pathStarts, 1);
            if indicator == 1
                % Find next location from vertex from bit position.  If
                % bitPos is 1, then the first bit encodes 1. If bitPos is 
                % 2, then the second bit encodes 2.  If bitPos is 3, then 
                % the third bit encodes 4.
                [dr dc] = offset(bitPos);
                tic;
                [edge targetVrtx vrtxPrev]= follow(nextPixelFinder, vr, vc, vr+dr, vc+dc, nextPixelFilter, vertexNumber);
                time = toc;
                
%                 if i == 98 | targetVrtx == 98
%                     fprintf('[findEdges] Found path from vertex %d to vertex %d\n', i, targetVrtx);
%                     fprintf('[findEdges] vertex %d: r=%d c=%d  vertex%d: r=%d c=%d \n', i, vertexR(i), vertexC(i),...
%                         targetVrtx, vertexR(targetVrtx), vertexC(targetVrtx));
%                     for p = 1:numel(edge.pathIdxList)
%                         [r c] = ind2sub(size(nextPixelFinder), edge.pathIdxList(p));
%                         fprintf('path: r=%d c=%d\n', r, c);
%                     end
%                     fprintf('-----\n');
%                 end
                numTimings = numTimings + 1;
                totalTime = totalTime+ time;
                minTime = min(minTime, time);
                maxTime = max(maxTime, time);
                % To prevent double processing of edges, update the destination
                % vertex of the edge removing the indicator corresponding to
                % the edge.
                if targetVrtx == i
                    % Vertex i is currently being processed so update
                    % pathStarts
                    pathStarts = pathStarts - vrtxPrev;
                else
                    vertexPathStarts(targetVrtx) = vertexPathStarts(targetVrtx) - vrtxPrev;
                end
                edgeStack.push(edge);
            end
        end
    end
    if ishandle(waitbarHandle)
        waitbar(i/numVertices, waitbarHandle, sprintf('Searched for paths from %d of %d vertices', i, numVertices));
    end
end
if ishandle(waitbarHandle)
    close(waitbarHandle);
end
% fprintf('numTimings=%f\n', numTimings);
% fprintf('totalTime=%f\n', totalTime);
% fprintf('meanTime=%f\n', (totalTime / numTimings));
% fprintf('minTime=%f\n', minTime);
% fprintf('maxTime=%f\n', maxTime);

%M = zeros(size(skeleton));
%while ~edgeStack.empty()
%    edge = edgeStack.pop();
%    M(edge.pathIdxList) = 1;
%end

%comp1 = (M == 1) &  (skeleton ~= 1);
%comp2 = (M ~= 1) & (skeleton == 1);
%diff1 = sum(comp1(:));
%diff2 = sum(comp2(:));
%if diff1 + diff2 ~= 0
%    error('[test2] %d skeleton pixels were not found and %d pixels were created', diff2, diff1);
%end



end

%
% Since L-shaped paths are allowed:
%
% 0 B A
% 0 C 0
% D 0 0 
%
% If location C is reached from location B, then there is ambiguity about the
% next location because both A and D are present in the next pixel indicator
% after B is removed.  The solution is that whenever a location is reached
% from a previous location that shares a side, then the diagonal neighbors that
% flank the previous location are removed from the next pixel indicator.
%
function nextPixelIndicator = removePrevNeighbors(nextPixelIndicator, prev);
if prev > 8
    switch prev
    case 16
        nextPixelIndicator = bitset(nextPixelIndicator, 1, 0);   % clear 1
        nextPixelIndicator = bitset(nextPixelIndicator, 2, 0);   % clear 2
    case 32
        nextPixelIndicator = bitset(nextPixelIndicator, 2, 0);   % clear 2
        nextPixelIndicator = bitset(nextPixelIndicator, 3, 0);   % clear 4
    case 64
        nextPixelIndicator = bitset(nextPixelIndicator, 3, 0);   % clear 4
        nextPixelIndicator = bitset(nextPixelIndicator, 4, 0);   % clear 8
    case 128
        nextPixelIndicator = bitset(nextPixelIndicator, 4, 0);   % clear 8
        nextPixelIndicator = bitset(nextPixelIndicator, 1, 0);   % clear 1
    otherwise
        error('[test2.renovePrevNeighbors] Unexpectes prev value: %d', prev);
    end
end
end

% Remove corner neighbors adjacent to side neighbors.
function vertexPathStarts = removeAdjacentCornerNeighbors(vertexPathStarts)
for i = 1:numel(vertexPathStarts)
    pathStarts = vertexPathStarts(i);
    if bitget(pathStarts, 5) == 1                   % 16
        pathStarts = bitset(pathStarts, 1, 0);      % remove 1
        pathStarts = bitset(pathStarts, 2, 0);      % remove 2
    end
    if bitget(pathStarts, 6) == 1                   % 32
        pathStarts = bitset(pathStarts, 2, 0);      % remove 2
        pathStarts = bitset(pathStarts, 3, 0);      % remove 4
    end
    if bitget(pathStarts, 7) == 1                   % 64
        pathStarts = bitset(pathStarts, 3, 0);      % remove 4
        pathStarts = bitset(pathStarts, 4, 0);      % remove 8
    end
    if bitget(pathStarts, 8) == 1                   % 128
        pathStarts = bitset(pathStarts, 4, 0);      % remove 8
        pathStarts = bitset(pathStarts, 1, 0);      % remove 1
    end
    vertexPathStarts(i) = pathStarts;
end
end


function [dr dc] = offset(pos)
switch pos
    case 1        % 1
        dr = -1;
        dc = -1;
    case 2        % 2
        dr = -1;
        dc = 1;
    case 3        % 4
        dr = 1;
        dc = 1;
    case 4        % 8
        dr = 1;
        dc = -1;
    case 5        % 16
        dr = -1;
        dc = 0;
    case 6        % 32
        dr = 0;
        dc = 1;
    case 7        % 64
        dr = 1;
        dc = 0;
    case 8        % 128
        dr = 0;
        dc = -1;
    otherwise
        error('[test2.offset] Unexpected pos value: %d', pos);
end
end


function [edge vertexNum vertexPrev] = follow(nextPixelFinder, vr, vc, r, c, nextPixelFilter, vertexNumber)
sz = size(nextPixelFinder);
pixelIdxArrStack = Stack();
root2 = sqrt(2);
bufferSize = 40;
buffer = zeros(bufferSize, 1);
bufferIndex = 0;
buffer(1) = sub2ind(sz, vr, vc);
buffer(2) = sub2ind(sz, r, c);
bufferIndex = 2;
numPixels = 2;

% Compute direction indicator to previous pixel (vr, vc) from current pixel
% (r, c)
ri = (vr - r) + 2;
ci = (vc - c) + 2;
prev = nextPixelFilter(ri, ci);

if prev > 8
    dist = 1;
else
    dist = root2;
end

% track =  vr == 749 && c == 64;
% if track
%     fprintf('[findEdges.follow] r=%d c=%d i=%d\n', vr, vc, sub2ind(size(nextPixelFinder), vr, vc));
%     fprintf('[findEdges.follow] r=%d c=%d i=%d\n', r, c, sub2ind(size(nextPixelFinder), r, c));
% end
nextPixelIndicator = nextPixelFinder(r, c);
% If the previous location shares a side with (r,c), then remove corner
% locations that share a side with the previous location
nextPixelIndicator = removePrevNeighbors(nextPixelIndicator, prev);
nextPixelIndicator = nextPixelIndicator - prev;

while nextPixelIndicator > 0
%    fprintf('[test2.follow] Looking for next pixel from r=%d c=%d nextPixelIndicator = %d\n', r, c, nextPixelIndicator)
    [r c prev] = nextPixel(r, c, nextPixelIndicator);
    if prev > 8
        dist = dist + 1;
    else
        dist = dist + root2;
    end
    numPixels = numPixels + 1;
    idx2 = sub2ind(size(nextPixelFinder), r, c);
%     if track
%         fprintf('[findEdges.follow] r=%d c=%d i=%d\n', r, c, idx2);
%     end
    if bufferIndex > bufferSize
        pixelIdxArrStack.push(buffer);
        buffer = zeros(bufferSize, 1);
        bufferIndex = 1;
        buffer(1) = idx2;
    else
        bufferIndex = bufferIndex + 1;
        buffer(bufferIndex) = idx2;
    end
    nextPixelIndicator = nextPixelFinder(r, c);
    nextPixelIndicator = removePrevNeighbors(nextPixelIndicator, prev);
    nextPixelIndicator = nextPixelIndicator - prev;
end

% if track
%     for i = 1:bufferIndex
%         fprintf('[findEdges.follow] buffer: %d\n', buffer(i));
%     end
% end

% Push final buffer onto stack
pixelIdxArrStack.push(buffer(1:bufferIndex));

pixelIdxList = zeros(numPixels, 1);
% Stack has buffers in reverse order, so fill pixelIdxList from back
ind = numPixels;
while ~pixelIdxArrStack.empty()
    pixelIdxArr = pixelIdxArrStack.pop();
    for i = numel(pixelIdxArr):-1:1
        pixelIdxList(ind) = pixelIdxArr(i);
        ind = ind - 1;
    end
end
if (ind ~= 0)
    error('[test2.follow] Allocate %d words for pixelIdxList, but %d remain', numPixels, ind);
end
% if track
%     for i = 1:numel(pixelIdxList)
%         fprintf('[findEdges.follow] Pixel: %d\n', pixelIdxList(i))
%     end
% end
secondVertexNumber = vertexNumber(r, c);
edge = EdgeInfo(dist, pixelIdxList, [vertexNumber(vr, vc), secondVertexNumber]);
vertexNum = secondVertexNumber;
vertexPrev = prev;
% if track
%     for i = 1:numel(edge.pathIdxList)
%         fprintf('[findEdges.follow] edge path: %d\n', edge.pathIdxList(i))
%     end
% end
end

function [r c prev] = nextPixel(r, c, nextPixelIndicator)
if nextPixelIndicator > 8
    % Shift high order bits: 16 -> 1  32 -> 2  64 -> 4 128 -> 8
    sideIndicator = bitsrl(nextPixelIndicator, 4);
    switch sideIndicator
        case 1           % 16
            r = r - 1;
            c = c;
            prev = 64;
        case 2           % 32
            r = r;
            c = c + 1;
            prev = 128;
        case 4           % 64
            r = r + 1;
            c = c;
            prev = 16;
        case 8           % 128
            r = r;
            c = c - 1;
            prev = 32;
        otherwise
            % More than one side neighbor
            error('[test2.nextPixel] Unexpected (side) next pixel indicator: %d', nextPixelIndicator);
    end
else
    switch nextPixelIndicator
        case 1
            r = r - 1;
            c = c - 1;
            prev = 4;
        case 2
            r = r - 1;
            c = c + 1;
            prev = 8;
        case 4
            r = r + 1;
            c = c + 1;
            prev = 1;
        case 8
            r = r + 1;
            c = c - 1;
            prev = 2;
        otherwise
            % More than one corner neighbor
            error('[test2.nextPixel] Unexpected (corner) next pixel indicator: %d', nextPixelIndicator);
    end
end
end
