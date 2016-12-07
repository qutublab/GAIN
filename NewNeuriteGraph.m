classdef NewNeuriteGraph < handle
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
        maxEdgesPerVertexPair
        edgeLocator % Maps vertex numbers and edge number to index for edgeTable
        edgeTable   % One dimensional cell array of edges
        maxSpurLength
        % Long edges are too long to  be spurs
        longEdgeCountByVertex
        % Short edge neighbor vertex tracked for spur removal.  Only the last
        % one encountered is remembered because a vertex at the end of a spur
        % has only one neighbor
        shortEdgeNeighborVertex
    end
    
    methods
        function ng = NewNeuriteGraph(edgeData, vertexlocations, tujBodyNumberGrid, imageSize, skeleton, maxSpurLength, maxEdgesPerVertexPair)
            if nargin == 0
                return;
            end
            ng.maxSpurLength = maxSpurLength;
            ng.anEdge = edgeData{1};
            ng.cellBodyNumberGrid = tujBodyNumberGrid;

            ng.vertexlocations = vertexlocations;
%            fprintf('size(ng.vertexlocations, 1)=%d\n', size(ng.vertexlocations, 1));
            ng.numvertices = size(vertexlocations, 1);

            ng.maxEdgesPerVertexPair = maxEdgesPerVertexPair;
            ng.edgeLocator = sparse(ng.numvertices * ng.numvertices, maxEdgesPerVertexPair);
            ng.edgeTable = edgeData;



            ng.edgeCountByVertex = zeros(ng.numvertices, 1);
            ng.longEdgeCountByVertex = zeros(ng.numvertices, 1);
            ng.shortEdgeNeighborVertex = zeros(ng.numvertices, 1);
            ng.imageSize = imageSize;
            ng.skeleton = skeleton;

            % Preallocate edge arrays and assign edge values
%            fprintf('[NeuriteGraph] Begin map building ...\n');
            for i = 1:numel(edgeData)
                e = edgeData{i};
                v1 = min(e.vertices);
                v2 = max(e.vertices);
                idx1 = ((v1 - 1) * ng.numvertices) + v2;
                edgeLocations = ng.edgeLocator(idx1, 1:maxEdgesPerVertexPair);
                idx2 = find(edgeLocations == 0, 1);
                ng.edgeLocator(idx1, idx2) = i;
                ng.edgeCountByVertex(v1) = ng.edgeCountByVertex(v1) + 1;
                ng.edgeCountByVertex(v2) = ng.edgeCountByVertex(v2) + 1;
                if e.distance > maxSpurLength
                    ng.longEdgeCountByVertex(v1) = ng.longEdgeCountByVertex(v1) + 1;
                    ng.longEdgeCountByVertex(v2) = ng.longEdgeCountByVertex(v2) + 1;
                else
                    % Needed for spur removal. Remember a short edge neighbor
                    ng.shortEdgeNeighborVertex(v1) = v2;
                    ng.shortEdgeNeighborVertex(v2) = v1;
                end
            end
%            fprintf('[NeuriteGraph] End map building\n');
%fprintf('[NewNeuriteGraph] Vertex 2419 has %d edges\n', ng.edgeCountByVertex(2419));
            
            numTujBodies = max(tujBodyNumberGrid(:));
            ng.vertexattujbody = cell(ng.numvertices, 1);
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
        
        
        function removeSpurs4(ng)
%fprintf('[NeuriteGraph.removeSpurs4] Begin...\n');
%tic;
            % An edge between v1 and v2 is removed if all of the following
            % hold:
            % 1. v1 has only a single, short edge incident upon it.
            % 2. v1 and v2 do not touch cell bodies
            % 3. v2 has at least two other edges which are long
%tic;
            spurStack = Stack();

            % Identify vertices that do not touch cell bodies
            nonCellVertices = cellfun(@isempty, ng.vertexattujbody);

            % Identify vertices with one, short edge and not touching a cell
            % body
            loneVertices = find(ng.edgeCountByVertex == 1 ...
                & ng.longEdgeCountByVertex == 0 & nonCellVertices);

            % Identify neighbors of lonveVertices
            loneVertexNeighbors = ng.shortEdgeNeighborVertex(loneVertices);

            % An acceptable potential neighbor, v2, does not touch a cell body 
            % and has at least two long edges.
            acceptablePotentialNeighborVertices = nonCellVertices ...
                & ng.longEdgeCountByVertex >= 2;

            acceptableActualNeighbors = acceptablePotentialNeighborVertices(loneVertexNeighbors);

            spurVertices1 = loneVertices(acceptableActualNeighbors);
            spurVertices2 = loneVertexNeighbors(acceptableActualNeighbors);

%toc;
%tic;
            arrayfun(@(v1, v2)ng.clearEdges(v1, v2), spurVertices1, spurVertices2);
%toc;
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
        
        % Traverses edge e from end point vertex v until either distance dist
        % has been traveled or the end of the edge is reached.  Returns the row
        % and column of the pixel reached, the remaining distance to be
        % traveled, and the edge end point vertex towards which the traversal
        % was done.
        function [r c remainingDist towardsVertex] = followEdgeFromVertexOld(ng, edge, v, dist)
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
        
        % Traverses edge e from end point vertex v until either distance dist
        % has been traveled or the end of the edge is reached.  Returns the row
        % and column of the pixel reached, the remaining distance to be
        % traveled, and the edge end point vertex towards which the traversal
        % was done.
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
            if edge.distance <= dist
                r = targetR;
                c = targetC;
                remainingDist = dist - edge.distance;
return;
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
        




% New version using indices instead of subscripts
%        function [r c remainingDist towardsVertex] = followEdgeFromVertex(ng, edge, v, dist)
%            if v == edge.vertices(1)
%                first = 1;
%                delta = 1;
%                last = numel(edge.pathIdxList);
%                towardsVertex = edge.vertices(2);
%            else
%                if v == edge.vertices(2)
%                    first = numel(edge.pathIdxList);
%                    delta = -1;
%                    last = 1;
%                    towardsVertex = edge.vertices(1);
%                else
%                    error('[NeuriteGraph.followEdgeFromVertex] Edge does not contain vertex %d as an end point', v);
%                end
%            end
%            if edge.distance <= dist
%                [r c] = ind2sub(ng.imageSize, edge.pathIdxList(last));
%                remainingDist = dist - edge.distance;
%                return;
%            end
%            root2 = sqrt(2);
%            remainingDist = dist;
%            k = edge.pathIdxList(first);
%            for i = (first+delta):delta:last
%                if remainingDist <= 0
%                    break;
%                end
%                k2 = edge.pathIdxList(i);
%		if isSideAdjacent(k, k2, ng.imageSize)
%                    remainingDist = remainingDist - 1;
%                else
%                    remainingDist = remainingDist - root2;
%                end
%                k = k2;
%            end
%            [r c] = ind2sub(ng.imageSize, k);
%        end



        
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
            bestPaths = Stack();
            % Find unused edges from v
            unusedEdgeCA = ng.unusedEdges(v, currPath.edgeInPath);
            bestUnusedEdges = Stack();
            bestCosine = -Inf;
%            while ~unusedEdgeStack.empty()
	    for i = 1:numel(unusedEdgeCA)
                edge = unusedEdgeCA{i};
                [r c remainingSpan towardsVertex] = ng.followEdgeFromVertex(edge, v, span);
                newCurrPath = currPath.copy().addEdge(edge, towardsVertex);
                if remainingSpan <= 0
                    u = ng.makeUnitVector([r - r0, c - c0]);
                    cosine = sum(u .* unitTarget);
                    pathStack = Stack(newCurrPath);
                else
                    % Keep going only when a cell body is NOT reached
                    if isempty(ng.vertexattujbody{towardsVertex})
%                         [pathStack cosine] = ng.findBestStartsFromVertex(towardsVertex, newCurrPath, r0, c0, remainingSpan, unitTarget);
                        [pstk, cosine] = ng.findBestStartsFromVertex(towardsVertex, newCurrPath, r0, c0, remainingSpan, unitTarget);
                        % if there was no other unused edge, then pstk is
                        % empty. In such cases measure cosine from endpoint of
                        % current edge.
                        if pstk.empty
                            u = ng.makeUnitVector([r - r0, c - c0]);
                            cosine = sum(u.* unitTarget);
                        end
                        pathStack = Stack(newCurrPath);
                    else
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
%            fprintf('[NeuriteGraph.allStraightWalksFromTujBody] Begin checking edges from cluster %d\n', nbi);
% 1247 1275 1283 1286 1295 1319 1323 1358 1376
            for v = 1:ng.numvertices
                if ~isempty(find(ng.vertexattujbody{v} == nbi))
                    [unitTarget distToV] = ng.unitNormalVector(v, nbi);
                    pth = Path(distToV, Stack(), v, v);
                    pth.fromBody = ng.vertexattujbody{v};
%                    tic;
                    bestPaths = ng.findBestPaths(v, pth, span, unitTarget);
%                    et = toc;
%                    fprintf('[NeuriteGraph.allStraightWalksFromTujBody] time: %f\n', et);
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
        
%        function edgeStack = unusedEdges(ng, v, used)
%            edgeStack = Stack();
%            for v2 = 1:ng.numvertices
%                edgesBox = ng.getEdgesBox(v, v2);
%                if ~isempty(edgesBox)
%                    edges = edgesBox.v;
%                    for i = 1:numel(edges)
%                        e = edges(i);
%                        if (~e.used) && (~used(e.idNum))
%                            edgeStack.push(e);
%                        end
%                    end
%                end
%            end
%        end

        function edgeCA = unusedEdges(ng, v, used)
            edgeCA = cell(ng.edgeCountByVertex(v), 1);
            edgeIdx = 0;
            % Vertices less than or equal to v
            for v0 = 1:v
                idx1 = ((v0 - 1) * ng.numvertices) + v;
                locations = ng.edgeLocator(idx1, 1:ng.maxEdgesPerVertexPair);
                % Remove zeros
                locations = locations(locations ~= 0);
                numLocations = numel(locations);
                edges = ng.edgeTable(locations);
                edgeCA((edgeIdx+1):(edgeIdx + numLocations)) = edges;
                edgeIdx = edgeIdx + numLocations;
            end
            % Vertices greater than v
            preIdx1 = (v - 1) * ng.numvertices;
            for v2 = (v+1):ng.numvertices
                idx1 = preIdx1 + v2;
                locations = ng.edgeLocator(idx1, 1:ng.maxEdgesPerVertexPair);
                % Remove zeros
                locations = locations(locations ~= 0);
                numLocations = numel(locations);
                edges = ng.edgeTable(locations);
                edgeCA((edgeIdx+1):(edgeIdx + numLocations)) = edges;
                edgeIdx = edgeIdx + numLocations;
            end
	    assert(edgeIdx == ng.edgeCountByVertex(v), '[NewNeuriteGraph.unusedEdges] Mismatched edge count by vertex v=%d, edgeIdx=%d, ng.edgeCountByVertex(%d)=%d', v, edgeIdx, v, ng.edgeCountByVertex(v))

            unused = cellfun(@(edge)(~edge.used) && (~used(edge.idNum)), edgeCA);
            edgeCA = edgeCA(unused);
        end
        
        
        
        function key = createKey(ng, v1, v2)
            if v1 <= v2
                key = sprintf('%d:%d', v1, v2);
            else
                key = sprintf('%d:%d', v2, v1);
            end
        end
        
        
        % Remove all edges between v1 and v2
        function clearEdges(ng, v1, v2)
            minV = min(v1, v2);
            maxV = max(v1, v2);
            idx1 = ((minV - 1) * ng.numvertices) + maxV;
            for idx2 = 1:ng.maxEdgesPerVertexPair
                edgeLocation = ng.edgeLocator(idx1, idx2);
                if edgeLocation == 0
                    continue;
                end
                edge = ng.edgeTable{edgeLocation};
                if ~isempty(edge)
                    ng.edgeTable{edgeLocation} = [];
                    ng.edgeLocator(idx1, idx2) = 0;
                    ng.edgeCountByVertex(v1) = ng.edgeCountByVertex(v1) - 1;
                    ng.edgeCountByVertex(v2) = ng.edgeCountByVertex(v2) - 1;
                    if edge.distance > ng.maxSpurLength
                        ng.longEdgeCountByVertex(v1) = ng.longEdgeCountByVertex(v1) - 1;
                        ng.longEdgeCountByVertex(v2) = ng.longEdgeCountByVertex(v2) - 1;
                    else
                        if ng.shortEdgeNeighborVertex(v1) == v2
                            ng.shortEdgeNeighborVertex(v1) == 0;
                        end
                        if ng.shortEdgeNeighborVertex(v2) == v1
                            ng.shortEdgeNeighborVertex(v2) == 0;
                        end
                    end
                end
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
        
%        function edgeCA = getEdges(ng, v1, v2)
%            minV = min(v1, v2);
%            maxV = max(v1, v2);
%            idx1 = ((minV - 1) * ng.numvertices) + maxV;
%            edgeLocation = ng.edgeLocator(idx1, 1:ng.maxEdgesPerVertexPair);
%            % Remove zeros
%            edgeLocation = edgeLocation(edgeLocation ~= 0);
%            if isempty(edgeLocation)
%                edgeCA = {};
%            edgeCA = cell(numel(edgeLocation), 1);
%            edgeIdx = 0;
%            for loc = edgeLocation
%                edgeIdx = edgeIdx + 1;
%                edge = ng.edgeTable{loc};
%                assert(min(edge.vertices) == minV && max(edge.vertices) == maxV, '[NewNeuriteGraph.getEdges] Incorrect edge found')
%                edgeCA{edgeIdx} = edge;
%            end
%        end




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

    function v2 = vertexNeighbor(v1, e)
        v2 = [];
        if e.vertices(1) == v1
            v2 = e.vertices(2);
        else
            if e.vertices(2) == v1
                v2 = e.vertices(1);
            else
                error('[NeuriteGraph.vertexNeighbor] Unable to find vertex %d in edge %d', v1, e.idNum);
            end
        end
    end

    end
end
