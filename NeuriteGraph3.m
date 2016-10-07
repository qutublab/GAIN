% Remove code tagged with "byron"

classdef NeuriteGraph < handle
    properties
        % distancetable - a Matlab map whose keys are strings of the
        % form: 'r:c' where r and c are desired row and column indices
        % and whose values are Box objects containing cell arrays of
        % EdgeInfo objects.
        % Note that there may be multiple edges between a pair of vertices.
        distancetable
        
        % vertexlocations - an nX2 table of row and column coordinates in
        % the neurite skeleton mask for each vertex
        vertexlocations
        
        % vertexattujbody - an nx1 cell array of tuj body id numbers
        % indicating which tuj bodies a vertex is in contact with in the
        % original image. A value of [] means that the vertex is not
        % touching a tuj body.
        vertexattujbody
        
        numvertices
        cellBodyNumberGrid
        imageSize
        skeleton
        anEdge
        edgeCountByVertex
    end
    
    methods
        function ng = NeuriteGraph(edgeData, vertexlocations, tujBodyNumberGrid, imageSize, skeleton)
            fprintf('[NeuriteGraph]\n');
            if nargin == 0
                return;
            end
            ng.anEdge = edgeData{1};
            ng.cellBodyNumberGrid = tujBodyNumberGrid;
            ng.distancetable = containers.Map();
            ng.vertexlocations = vertexlocations;
            fprintf('size(ng.vertexlocations, 1)=%d\n', size(ng.vertexlocations, 1));
            ng.numvertices = size(vertexlocations, 1);
            ng.edgeCountByVertex = zeros(ng.numvertices, 1);
            ng.imageSize = imageSize;
            ng.skeleton = skeleton;
            %            edgeCount = sparse(zeros(ng.numvertices));
            edgeCount = containers.Map('0', 0);
            % Determine number of edges between each pair of vertices
            fprintf('[NeuriteGraph] Begin edge counting ...\n');
            for i = 1:numel(edgeData)
                e = edgeData{i};
                v1 = e.vertices(1);
                v2 = e.vertices(2);
                key = ng.createKey(v1, v2);
                if edgeCount.isKey(key)
                    edgeCount(key) = edgeCount(key) + 1;
                else
                    edgeCount(key) = 1;
                end
            end
            % Preallocate edge arrays and assign edge values
            fprintf('[NeuriteGraph] Begin map building ...\n');
            for i = 1:numel(edgeData)
                e = edgeData{i};
                v1 = e.vertices(1);
                v2 = e.vertices(2);
                ei = e;
                pathIdxList = ei.pathIdxList;
                r1 = ng.vertexlocations(v1, 1);
                c1 = ng.vertexlocations(v1, 2);
                r2 = ng.vertexlocations(v2, 1);
                c2 = ng.vertexlocations(v2, 2);
                idx1 = sub2ind(ng.imageSize, r1, c1);
                idx2 = sub2ind(ng.imageSize, r2, c2);
                key = ng.createKey(v1, v2);
                ind = edgeCount(key);
                edgesBox = ng.getEdgesBox(v1, v2, 'CreateWhenAbsent');
                edgesBox.v(ind) = ei;
                edgeCount(key) = ind - 1;
                ng.edgeCountByVertex(v1) = ng.edgeCountByVertex(v1) + 1;
                ng.edgeCountByVertex(v2) = ng.edgeCountByVertex(v2) + 1;
            end
            fprintf('[NeuriteGraph] End map building\n');
            
            numTujBodies = max(tujBodyNumberGrid(:));
            ng.vertexattujbody = cell(ng.numvertices, 1);
%             ringVertexCount = 0;
            for i = 1:ng.numvertices
                r = vertexlocations(i, 1);
                c = vertexlocations(i, 2);
                % Search neighbors of (r, c) to find adjacent tuj bodies
                delta = [-1 -1; -1 0; -1 1; 0 -1; 0 1; 1 -1; 1 0; 1 1];
                newR = delta(:, 1) + r;
                newC = delta(:, 2) + c;
                goodR = (newR >= 1) & (newR <= size(tujBodyNumberGrid, 1));
                goodC = (newC >= 1) & (newC <= size(tujBodyNumberGrid, 2));
                goodRC = goodR & goodC;
                usableR = newR(goodRC);
                usableC = newC(goodRC);
                touchesBody = false(numTujBodies, 1);
%                 ringBody = ringVertices(r, c);
%                 if ringBody ~= 0
%                     touchesBody(ringBody) = true;
%                     ringVertexCount = ringVertexCount + 1;
%                 end
                for j = 1:numel(usableR)
                    r2 = usableR(j);
                    c2 = usableC(j);
                    tujBodyNumber = tujBodyNumberGrid(r2, c2);
                    if tujBodyNumber ~= 0 & ~touchesBody(tujBodyNumber)
                        touchesBody(tujBodyNumber) = true;
                    end
                end
                count = sum(double(touchesBody));
                adjacentBodyNumbers = zeros(count);
                index = 1;
                for j = 1:numTujBodies
                    if touchesBody(j)
                        adjacentBodyNumbers(index) = j;
                        index = index + 1;
                    end
                end
                ng.vertexattujbody{i} = adjacentBodyNumbers;
            end
%             fprintf('ringVertexCount=%d\n', ringVertexCount);
        end
        
        
        function removeSpurs(ng, length)
fprintf('[NeuriteGraph.removeSpurs] First loop...\n');
tic;
            % Do not remove any edges until all candidates have been examined because
            % the removal of an edge can make another edge become a spur.
            
            % An edge between v1 and v2 is removed if all of the following hold
            % 1. v1 and v2 do not touch cell bodies
            % 2. v1 is an endpoint (and hence may have 0 or 1 edges)
            % 3. v1 has only a single edge incident upon it.
            % 4. The edge between v1 and v2 is short
            
            spurStack = Stack();
            % Detect endpoint vertices
            % bwmorph can find endpoints not on the skeleton
            endPointMask = bwmorph(ng.skeleton, 'endpoints') & ng.skeleton;
            for v = 1:ng.numvertices
%                fprintf('[NeuriteGraph.removeSpurs] Processing vertex %d of %d\n', v, ng.numvertices);
                if ~isempty(ng.vertexattujbody{v}) continue; end
                % Now assume v is not at a cell body
                vr = ng.vertexlocations(v, 1);
                vc = ng.vertexlocations(v, 2);
                % Vertices removed after the graph has been created have vr
                % and vc set to 0
                if vr == 0 || vc == 0 continue; end
                if ~endPointMask(vr, vc) continue; end
                % Now assume v is an endpoint
                edgeStack = ng.getEdges(v);
                if edgeStack.size() ~= 1 continue; end
                edge = edgeStack.pop();
                if edge.distance > length continue; end
                % Now assume the edge is short
                if edge.vertices(1) == v
                    v2 = edge.vertices(2);
                elseif edge.vertices(2) == v
                    v2 = edge.vertices(1);
                else
                    error('[NeuriteGraph.removeSpurs] Expected edge to touch vertex %d', v);
                end
                if ~isempty(ng.vertexattujbody{v2}) continue; end
                % Now assume that the vertex connected to v is not touching a cell
                spurStack.push(edge);
                % Remove vertex v from graph as much as is practically possible
                ng.vertexlocations(v, 1) = 0;
                ng.vertexlocations(v, 2) = 0;
                ng.vertexattujbody{v} = [];

            end
toc;
fprintf('[NeuriteGraph.removeSpurs] Second loop...\n');
tic;
            
            while ~spurStack.empty()
                edge = spurStack.pop();
                v1 = edge.vertices(1);
                v2 = edge.vertices(2);
                ng.clearEdges(v1, v2);
            end
toc;
        end
        
        function removeSpurs2(ng, length)
fprintf('[NeuriteGraph.removeSpurs2] First loop...\n');
tic;
            % Do not remove any edges until all candidates have been examined because
            % the removal of an edge can make another edge become a spur.
            
            % An edge between v1 and v2 is removed if all of the following hold
            % 1. v1 has only a single edge incident upon it.
            % 2. v1 and v2 do not touch cell bodies
            % 3. The edge between v1 and v2 is short
            
            spurStack = Stack();
            % Detect endpoint vertices
            % bwmorph can find endpoints not on the skeleton
            for v = 1:ng.numvertices
%                fprintf('[NeuriteGraph.removeSpurs2] Processing vertex %d of %d\n', v, ng.numvertices);
                if ng.edgeCountByVertex(v) ~= 1 continue; end
                % Now assume that v has a single edge
                if ~isempty(ng.vertexattujbody{v}) continue; end
                % Now assume v is not at a cell body
                edgesBox = ng.getFirstNonemptyEdgesBox(v);
                if numel(edgesBox.v) ~= 1
                    error('[NeuriteGraph.removeSpurs2] Attempting to clear edges box with %d edges', numel(edgesBox.v));
                end
                if edgesBox.v(1).distance > length continue; end
                edge = edgesBox.v(1);
                % Now assume the edge is short
                if edge.vertices(1) == v
                    v2 = edge.vertices(2);
                elseif edge.vertices(2) == v
                    v2 = edge.vertices(1);
                else
                    error('[NeuriteGraph.removeSpurs2] Expected edge to touch vertex %d', v);
                end
                if ~isempty(ng.vertexattujbody{v2}) continue; end
                % Now assume that the vertex connected to v is not touching a
                % cell body
                spurStack.push([v, v2]);
%                spurStack.push({edgesBox, v});
            end
toc;
fprintf('[NeuriteGraph.removeSpurs2] Second loop...\n');
tic;
            
            while ~spurStack.empty()
                vv2 = spurStack.pop();
                v = vv2(1);
                v2 = vv2(2);
                ng.clearEdges(v, v2);

%                ebv = spurStack.pop();
%                edgesBox = ebv{1};
%                v = ebv{2};
%                edgesBox.v = EdgeInfo.empty(0);
                % Remove vertex v from graph as much as is practically possible
                ng.vertexlocations(v, 1) = 0;
                ng.vertexlocations(v, 2) = 0;
                ng.vertexattujbody{v} = [];
                ng.edgeCountByVertex(v) = 0;
            end
toc;
        end
        
        % Returns the first edge found or []
	function edgesBox = getFirstNonemptyEdgesBox(ng, v)
            for v2 = 1:ng.numvertices
                edgesBox = ng.getEdgesBox(v, v2);
                if ~isempty(edgesBox) && numel(edgesBox.v > 0)
                    return;
                end
            end
            error('[NeuriteGraph.getFirstNonemptyEdgesBox] Unable to find nonempty edges box for vertes %d', v);
        end


        function testNormalAngle(ng)
            ng = NeuriteGraph();
            ng.imageSize = [6 6];
            ng.numvertices = 2;
            ng.vertexlocations = [4 5]; %[4 2]; %[3 5]; %[4 4];
            ng.cellBodyNumberGrid = ...
                [0 0 2 2 2 0; ...
                0 0 2 2 2 0; ...
                0 0 2 2 0 0; ...
                0 0 0 0 0 0; ...
                0 1 0 0 0 0;
                0 0 0 0 0 0];
            ng.normalAngle(1, 2)
        end
        
        function [r c] = linearSearch(ng, n, r, c, dr, dc)
            while r > 0 && r <= ng.imageSize(1) && c > 0 && c <= ng.imageSize(2) && ng.cellBodyNumberGrid(r, c) ~= n
                r = r + dr;
                c = c + dc;
            end
            if ~(r > 0 && r <= ng.imageSize(1) && c > 0 && c <= ng.imageSize(2))
                r = [];
                c = [];
                
            end
        end
        
        function mag = vectorMagnitude(ng, v)
            mag = sqrt(sum(v .* v));
            assert(numel(mag) == 1, '[NeuriteGraph.vectorMagnitude] wrong size')
        end
        
        function uv = makeUnitVector(ng, v)
            uv = v / ng.vectorMagnitude(v);
        end
        
        function [unitNormal distToV] = unitNormalVector(ng, v, cellBodyNumber)
            numRows = ng.imageSize(1);
            numCols = ng.imageSize(2);
            vr = ng.vertexlocations(v, 1);
            vc = ng.vertexlocations(v, 2);
            
            % Find cell body pixels that touch vertex which is not part of cell
            sharedSide = zeros(0, 2);
            sharedCorner = zeros(0, 2);
            for r = (vr-1):(vr+1)
                for c = (vc-1):(vc+1)
                    if r > 0 && r <= numRows && c > 0 && c <= numCols
                        if cellBodyNumber == ng.cellBodyNumberGrid(r, c);
                            if r == vr || c == vc
                                sharedSide(end+1, :) = [r, c];
                            else
                                sharedCorner(end+1, :) = [r, c];
                            end
                        end
                    end
                end
            end
            % Pick one cell pixel with a preference for locations that share an
            % edge as opposed to a corner
            if size(sharedSide, 1) > 0   % For now, just use the first location
                cellR = sharedSide(1, 1);
                cellC = sharedSide(1, 2);
                distToV = 1;
            else
                if size(sharedCorner, 1) > 0   % For now, just use the first location
                    cellR = sharedCorner(1, 1);
                    cellC = sharedCorner(1, 2);
                    distToV = sqrt(2);
                else
                    error('[NeuriteGraph.unitNormalVector] Unable to find a neighboring pixel for vr=%d vc=%d', vr, vc);
                end
            end
            % Find locations for computing tangent vector
            dr = cellR - vr;
            dc = cellC - vc;
            if dr == 0
                [r1 c1] = ng.linearSearch(cellBodyNumber, vr - 1, vc, 0, dc);
                [r2 c2] = ng.linearSearch(cellBodyNumber, vr + 1, vc, 0, dc);
            elseif dc == 0
                [r1 c1] = ng.linearSearch(cellBodyNumber, vr, vc - 1, dr, 0);
                [r2 c2] = ng.linearSearch(cellBodyNumber, vr, vc + 1, dr, 0);
            else
                % Check for flanking cells on the complementary diagonal
                % before attempting linear search
                vc2 = vc + (2 * dc);
                if vc2 >= 1 && vc2 <= numCols && ng.cellBodyNumberGrid(vr, vc2) == cellBodyNumber
                    r1 = vr;
                    c1 = vc2;
                else
                    [r1 c1] = ng.linearSearch(cellBodyNumber, cellR, cellC + dc, dr, dc);
                end
                vr2 = vr + (2 * dr);
                if vr2 >= 1 && vr2 <= numRows && ng.cellBodyNumberGrid(vr2, vc) == cellBodyNumber
                    r2 = vr2;
                    c2 = vc;
                else
                    [r2 c2] = ng.linearSearch(cellBodyNumber, cellR + dr, cellC, dr, dc);
                end
            end
            % If r1, c1, r2, and c2 are well-defined, then a normal vector
            % to the tangent vector (r1-r2, c1-c2) is any vector that
            % yields a zero dot product with the tangent.
            if (~isempty(r1)) && (~isempty(c1)) && (~isempty(r2)) && (~isempty(c2))
                normalVector1 = [-(c1-c2), (r1-r2)];
            elseif (isempty(r1) || isempty(c1)) && (isempty(r2) || isempty(c2))
                % If both points are not well defined, then the normal
                % vector runs from the nearest cell pixel to the vertex
                normalVector1 = [-dr, -dc];
            elseif isempty(r1) || isempty(c1)
                % If only one point is well-defined then let that point and
                % the nearest cell pixel determine the tangent from which
                % the normal is computed.
                normalVector1 = [-(cellC-c2), cellR-r2];
            else
                normalVector1 = [-(cellC-c1), cellR-r1];
            end
            % A second normal vector points 180 degrees away from the first
            normalVector2 = -1 * normalVector1;
            
            % The desired normal vector is the vector that from the point
            % (cellR, cellC) comes closest to (vr, vc).
            sum1 = normalVector1 + [cellR, cellC];
            sum2 = normalVector2 + [cellR, cellC];
            delta1 = sum1 - [vr, vc];
            delta2 = sum2 - [vr, vc];
            dist1sqrd = sum(delta1 .* delta1);
            dist2sqrd = sum(delta2 .* delta2);
            assert(numel(dist1sqrd) == 1 && numel(dist2sqrd) == 1, '[NeuriteGraph.normalvector] Improperly computed vector distance')
            if dist1sqrd < dist2sqrd
                unitNormal = ng.makeUnitVector(normalVector1);
            else
                unitNormal = ng.makeUnitVector(normalVector2);
            end
        end
        
        
        function [first delta last] = getPathDirection(ng, pathIdxList, r, c)
%             fprintf('[NeuriteGraph.getPathDirection] r=%d c=%d\n', r, c);
            idx = sub2ind(ng.imageSize, r, c);
            if idx == pathIdxList(1)
                first = 1;
                delta = 1;
                last = numel(pathIdxList);
            elseif idx == pathIdxList(end)
                first = numel(pathIdxList);
                delta = -1;
                last = 1;
            else
                for i = 1:numel(pathIdxList)
                    [r2 c2] = ind2sub(ng.imageSize, pathIdxList(i));
                    fprintf('path: r=%d c=%d\n', r2, c2);
                end
                [rFirst cFirst] = ind2sub(ng.imageSize, pathIdxList(1));
                [rLast cLast] = ind2sub(ng.imageSize, pathIdxList(end));
                error('[NeuriteGraph.getPathDirection] r=%d c=%d but rFirst=%d cFirst=%d rLast=%d cLast=%d', r, c, rFirst, cFirst, rLast, cLast);
            end
        end
        
        function [r c remainingDist towardsVertex] = followEdgeFromVertex(ng, edge, v, dist)
            r = ng.vertexlocations(v, 1);
            c = ng.vertexlocations(v, 2);
            pathIdxList = edge.pathIdxList;
            root2 = sqrt(2);
            [first delta last] = ng.getPathDirection(pathIdxList, r, c);
            [targetR targetC] = ind2sub(ng.imageSize, pathIdxList(last));
            vrc1 = ng.vertexlocations(edge.vertices(1), :);
            if vrc1(1) == targetR && vrc1(2) == targetC
                towardsVertex = edge.vertices(1);
            else
                vrc2 = ng.vertexlocations(edge.vertices(2), :);
                if vrc2(1) == targetR && vrc2(2) == targetC
                    towardsVertex = edge.vertices(2);
                else
                    error('[NeuriteGraph.followEdgeFromVertex] Unable to determine target vertex at r=%d c=%d', targetR, targetC);
                end
            end
            [R, C] = ind2sub(ng.imageSize, pathIdxList);
            remainingDist = dist;
            for i = (first+delta):delta:last
                if remainingDist <= 0
                    break;
                end
                nextR = R(i);
                nextC = C(i);
                rcDelta = abs(nextR - r) + abs(nextC - c);
                if rcDelta == 2
                    remainingDist = remainingDist - root2;
                elseif rcDelta == 1
                    remainingDist = remainingDist - 1;
                else
                    error('[NeuriteGraph.followEdgeFromVertex] Unexpected rcDelta: %f', rcDelta);
                end
                r = nextR;
                c = nextC;
            end
%             path = Path(edge.distance, Stack(edge), v, towardsVertex);
        end
        
        
        % Finds the direction to the vertex v from a point along the path
        % in edgeStack a distance span away
        function unitVec = unitVectorToVertexFromPath(ng, v, path, span)
            edgeStack = path.edgeStack;
            vr = ng.vertexlocations(v, 1);
            vc = ng.vertexlocations(v, 2);
            vr0 = vr;
            vc0 = vc;
            %fprintf('[unitVectorToVertexFromPath] vertex %d  r=%d c=%d\n', v, vr, vc);
            remainingDist = span;
            edgeNum = 1;
            while remainingDist > 0 && edgeNum <= edgeStack.size
                edge = edgeStack.peek(edgeNum);
                [vr vc remainingDist v] = ng.followEdgeFromVertex(edge, v, remainingDist);
                edgeNum = edgeNum + 1;
            end
            vec = [vr0 - vr, vc0 - vc];
            unitVec = ng.makeUnitVector(vec);
        end
        
        
        % Returns the best results of extending the current path by a
        % single vertex.  This method used to: Return the entire sequence
        % of edges necessary to go a distance of span from vertex v.
% :03:
        function [bestPaths bestCosine] = findBestStartsFromVertex(ng, v, currPath, r0, c0, span, unitTarget)  
%fprintf('[NeuriteGraph.findBestStartsFromVertex] v=%d\n', v)   % byron
            bestPaths = Stack();
            % Find unused edges from v
            unusedEdgeStack = ng.unusedEdges(v, currPath.edgeInPath);
if v == 822 || v == 837
  fprintf('[NeuriteGraph.findBestStartsFromVertex] Unused edges from vertex %d: %d\n', v, unusedEdgeStack.size())    % byron
end
            bestUnusedEdges = Stack();
            bestCosine = -Inf;
            while ~unusedEdgeStack.empty()
                edge = unusedEdgeStack.pop()
                [r c remainingSpan towardsVertex] = ng.followEdgeFromVertex(edge, v, span);
                newCurrPath = currPath.copy().addEdge(edge, towardsVertex);
                if remainingSpan <= 0
                    u = ng.makeUnitVector([r - r0, c - c0]);
                    cosine = sum(u .* unitTarget);
                    pathStack = Stack(newCurrPath);
fprintf('[NeuriteGraph.findBestStartsFromVertex] angle point: r=%d c=%d\n', r, c);
                else
                    % Keep going only when a cell body is NOT reached
                    if isempty(ng.vertexattujbody{towardsVertex})
		    fprintf('[NeuriteGraph.findBestStartsFromVertex] Continuing from vertex %d\n', towardsVertex)
%                         [pathStack cosine] = ng.findBestStartsFromVertex(towardsVertex, newCurrPath, r0, c0, remainingSpan, unitTarget);
                        [~, cosine] = ng.findBestStartsFromVertex(towardsVertex, newCurrPath, r0, c0, remainingSpan, unitTarget);
                        pathStack = Stack(newCurrPath);
                    else
fprintf('[NeuriteGraph.findBestStartsFromVertex] Reached cell body\n')
                        u = ng.makeUnitVector([r - r0, c - c0]);
                        cosine = sum(u .* unitTarget);
                        pathStack = Stack(newCurrPath);
                    end
                end
                if cosine > bestCosine
                    bestCosine = cosine;
                    bestPaths = pathStack;
                elseif cosine == bestCosine
                    while ~pathStack.empty()
                        path = pathStack.pop();
                        bestPaths.push(path);
                    end
                end
            end
%             fprintf('[NeuriteGraph.findBestStartsFromVertex] Found %d starts from vertex %d\n', bestPaths.size(), v);
        end
        % -.797 -.605
% :02:
        function bestPaths = findBestPaths(ng, v, currPath, span, unitTarget)
            r = ng.vertexlocations(v, 1);
            c = ng.vertexlocations(v, 2);
if v == 822
fprintf('\n\n[NeuriteGraph.findBestPaths] Begin vertex %d  r=%d c=%d unitTarget=(%d,%d)\n', v, r, c, unitTarget(1), unitTarget(2)); % byron
end
            [bestStarts bestCosine] = ng.findBestStartsFromVertex(v, currPath, r, c, span, unitTarget);
            bestPaths = Stack();
            while ~bestStarts.empty()
                path = bestStarts.pop();
                v2 = path.toVertex;
%                 fprintf('[NeuriteGraph.findBestPaths] Using path from vertex %d (%d) to vertex %d\n', v, path.fromVertex, v2);
                newUnitTarget = ng.unitVectorToVertexFromPath(v2, path, span);
                bestPathsFromStart = ng.findBestPaths(v2, path, span, newUnitTarget);
                while ~bestPathsFromStart.empty()
                    p = bestPathsFromStart.pop();
                    bestPaths.push(p);
                end
            end
            % If no best path found, return original path
            if bestPaths.empty()
                bestPaths.push(currPath);
            end
%             fprintf('[NeuriteGraph.findBestPaths] Found %d paths at vertex %d\n', bestPaths.size(), v);
        end

        function log(ng, s)
            fid = fopen('log.txt', 'a');
            fprintf('%s\n', s);
            fprintf(fid, '%s\n',s)
            fclose(fid)
        end
        

% :01:
        % Returns longest straight paths from a cell body
        function pathStack = allStraightWalksFromTujBody(ng, nbi, span)
            pathStack = Stack();
            fprintf('[NeuriteGraph.allStraightWalksFromTujBody] Begin checking edges from cluster %d\n', nbi);
            tic;
% 1247 1275 1283 1286 1295 1319 1323 1358 1376
            for v = 1247     % 1:ng.numvertices byron
                if ~isempty(find(ng.vertexattujbody{v} == nbi))
                    [unitTarget distToV] = ng.unitNormalVector(v, nbi);
                    pth = Path(distToV, Stack(), v, v);
                    pth.fromBody = ng.vertexattujbody{v};
                    fprintf('[NeuriteGraph.allStraightWalksFromTujBody] findBestPaths v=%d\n', v);
                    tic;
                    bestPaths = ng.findBestPaths(v, pth, span, unitTarget);
                    et = toc;
                    fprintf('[NeuriteGraph.allStraightWalksFromTujBody] time: %f\n', et);
%                     fprintf('[NeuriteGraph.allStraightWalksFromTujBody] Found %d paths at vertex %d of cluster %d\n', bestPaths.size(), v, nbi);
                    % Keep longest path from each vertex
                    maxLength = -1;
                    longestPath = [];
                    while ~bestPaths.empty()
                        p = bestPaths.pop();
                        if p.distance > maxLength
                            maxLength = p.distance;
                            longestPath = p;
                        end
                    end
                    if ~isempty(longestPath)
                        lastVertex = longestPath.toVertex;
                        if longestPath.distance >= 2 && ~isempty(ng.vertexattujbody{lastVertex})
                            longestPath.toBody = ng.vertexattujbody{lastVertex};
                        end
                        pathStack.push(longestPath);
                        edgeCA = longestPath.edgeStack.toCellArray();
                        for i = 1:numel(edgeCA)
                            edgeCA{i}.used = true;
                        end
                    end
                end
            end
            % Mark edges as unused
            pathCellArr = pathStack.toCellArray();
            for i = 1:numel(pathCellArr)
                pth = pathCellArr{i};
%                 fprintf('[NeuriteGraph.allStraightWalksFromTujBody] class:%s\n', class(pth));
                edgeCellArr = pth.edgeStack.toCellArray();
                for j = 1:numel(edgeCellArr)
                    edgeCellArr{j}.used = false;
                end
            end
%             fprintf('[NeuriteGraph.allStraightWalksFromTujBody] Found %d paths for cluster %d\n', pathStack.size(), nbi);
        end
        
        function edgeStack = unusedEdges(ng, v, used)
            edgeStack = Stack();
            for v2 = 1:ng.numvertices
                edgesBox = ng.getEdgesBox(v, v2);
                if ~isempty(edgesBox)
                    edges = edgesBox.v;
                    for i = 1:numel(edges)
                        e = edges(i);
                        if (~e.used) && (~used(e.idNum))
                            edgeStack.push(e);
%if v == 926   % byron
%  fprintf('[NeuriteGraph.unusedEdges] Unused edge between 926 and %d\n', v2)
%end
%else
%if v == 926
%  fprintf('[NeuriteGraph.unusedEdges] Used edge between 926 and %d  e.used=%d used(e.idNum=%d\n', v2, e.used, used(e.idNum))
%end

                        end
                    end
                end
            end
        end
        
        
        
        function key = createKey(ng, v1, v2)
            if v1 <= v2
                key = sprintf('%d:%d', v1, v2);
            else
                key = sprintf('%d:%d', v2, v1);
            end
        end
        
        
        function clearEdges(ng, v1, v2)
            key = ng.createKey(v1, v2);
            if ng.distancetable.isKey(key)
                edgesBox = ng.distancetable(key);
                numEdges = numel(edgesBox.v);
                ng.edgeCountByVertex(v1) = ng.edgeCountByVertex(v1) - numEdges;
                ng.edgeCountByVertex(v2) = ng.edgeCountByVertex(v2) - numEdges;
                ng.distancetable.remove(key);
            end
        end
        
        function eb = getEdgesBox(ng, v1, v2, flag1)
            key = ng.createKey(v1, v2);
            if ng.distancetable.isKey(key)
                eb = ng.distancetable(key);
            else
                if nargin > 3 && strcmpi(flag1, 'CreateWhenAbsent')
                    eb = Box(EdgeInfo.empty(0));
                    ng.distancetable(key) = eb;
                else
                    eb = [];
                end
            end
        end
        
        function I = createImage(ng)
            numVertices = ng.numvertices;
            E = false(ng.imageSize);
            edgeBoxArr = ng.distancetable.values();
            for i = 1:numel(edgeBoxArr)
                for j = 1:numel(edgeBoxArr{i}.v)
                    E(edgeBoxArr{i}.v(j).pathIdxList) = true;
                end
            end
            V = false(ng.imageSize);
            C = false(ng.imageSize);
            for i = 1:numVertices
                r = ng.vertexlocations(i, 1);
                c = ng.vertexlocations(i, 2);
                if r ~= 0 && c ~= 0
                    V(r, c) = true;
                    E(r, c) = false;
                    if ~isempty(ng.vertexattujbody{i})
                        C(r, c) = true;
                    end
                end
            end
            I = double(cat(3, V, E, C));
        end
        
        
        function validate(ng)
            fprintf('Verifying that edge path index lists include vertices...\n');
            for v1 = 1:ng.numvertices
                v1Idx = sub2ind(ng.imageSize, ng.vertexlocations(v1, 1), ng.vertexlocations(v1, 2));
                for v2 = 1:ng.numvertices
                    v2Idx = sub2ind(ng.imageSize, ng.vertexlocations(v2, 1), ng.vertexlocations(v2, 2));
                    edgesBox = ng.getEdgesBox(v1, v2);
                    if ~isempty(edgesBox)
                        edges = edgesBox.v;
                        fprintf('Examining %d edge(s) between vertex %d and vertex %d\n', numel(edges), v1, v2);
                        for i = 1:numel(edges)
                            e = edges(i);
                            idx1 = e.pathIdxList(1);
                            idx2 = e.pathIdxList(end);
                            assert((idx1 == v1Idx && idx2 == v2Idx) || (idx1 == v2Idx && idx2 == v1Idx), sprintf('Edge path between vertex %d and vertex %d is incorrectly terminated', v1, v2));
                        end
                    end
                end
            end
        end
        
        
        function validate2(ng)
            % Verify that edges are not duplicated
            for v1 = 1:ng.numvertices
                fprintf('[validate2] Checking edges from vertex %d of %d\n', v1, ng.numvertices);
                for v2 = 1:ng.numvertices
                    eb = ng.getEdgesBox(v1, v2);
                    if isempty(eb) continue; end
                    edges = eb.v;
                    for eIdx1 = 1:numel(edges)
                        e1 = edges(eIdx1);
                        for eIdx2 = (eIdx1+1):numel(edges)
                            e2 = edges(eIdx2);
                            if e1.samePath(e2)
                                error('[validate2] Duplicate edge between vertices %d and %d', v1, v2);
                            end
                        end
                    end
                end
            end
        end
        
        function recordEdgeCount(ng)
            
            % Create a path to let the Path class know how many edges
            % there are
            Path(0, Stack(), 0, 0, ng.anEdge.numObjects);
        end


    end
end
