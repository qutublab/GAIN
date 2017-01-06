

function computeLongPaths(neuronBodyDataArr, G, junctionSpan, showWaitBar)

totalNeuriteLength = 0;
numClusters = numel(neuronBodyDataArr);
if showWaitBar
    h = waitbar(0, sprintf('Processing cell cluster %d of %d', 0, numClusters));
end
timing = zeros(numel(neuronBodyDataArr), 1);
fprintf('[computeLongPaths] %d cell body clusters\n', numel(neuronBodyDataArr));
%for d = 7    %1:numel(neuronBodyDataArr)  byron
%for d = 12     %1:numel(neuronBodyDataArr)
for d = 1:numel(neuronBodyDataArr)
    tstart = tic;
    if showWaitBar & ishandle(h)
        waitbar(d / numClusters, h, sprintf('Processing cell cluster %d of %d', d, numClusters));
    end  % if

    longPaths = Stack();
    shortPaths = Stack();
%    fprintf('Looking for paths from cluster %d of %d\n', d, numel(neuronBodyDataArr));
    nbd = neuronBodyDataArr(d);
%     if nbd.nucleiNumber > 0
%         numCells = nbd.numberOfNeurons;
        numCells = max(1, nbd.numberOfNuclei);
        avgArea = nbd.bodyArea / numCells;
        avgDiameter = sqrt((4 * avgArea) / pi);
        minNeuriteLength = 3 * avgDiameter;
%        fprintf('[computeLongPaths] Computing walks for neuron body: %d\n', d);
%         tic;
%        pathStack = G.allStraightWalksFromTujBody(d, junctionSpan);
        pathStack = G.allWalksFromCellBody(d, junctionSpan);
%         et = toc;
%         fprintf('[computeLongPaths] time: %f\n', et);
        numPaths = pathStack.size();
        longNeuriteCount= 0;
        longest = 0;
        shortNeuriteCount = 0;
        if numPaths ~= 0
            % Reset paths variable for reuse.
            clear paths;
            for n = numPaths:-1:1
                paths(n) = pathStack.pop();
            end  % if
            [~, idx] = sort([paths.distance], 'descend');
            paths = paths(idx);
            for p = 1:numPaths   %1:min(numCells, numPaths)
%                 fprintf('[computeLongPaths] Neuron body: %d  path: %d\n', d, p);
%                 tic;
                path = paths(p);
                totalNeuriteLength = totalNeuriteLength + path.distance;
                longest = max(longest, path.distance);
                if path.distance >= minNeuriteLength
                    longNeuriteCount = longNeuriteCount + 1;
                    longPaths.push(path);
                else
                    shortNeuriteCount = shortNeuriteCount + 1;
                    shortPaths.push(path);
                end  % if
%                 et = toc;
%                 fprintf('[computeLongPaths] time: %f\n', et);
            end % for
        end  % if
        nbd.minNeuriteLength = minNeuriteLength;
        nbd.longNeuriteCount = longNeuriteCount;
        nbd.longestNeuriteLength = longest;
        nbd.shortNeuriteCount = shortNeuriteCount;
        nbd.longPaths = longPaths.toCellArray();
        nbd.shortPaths = shortPaths.toCellArray();
%     end
timing(d) = toc(tstart);
%fprintf('[computeLongPaths] End of loop body d=%d\n', d)
end
if showWaitBar & ishandle(h)
    close(h);
end

numTimings = numel(timing);
fprintf('[computeLongPaths] minimum time=%f (of %d)\n', min(timing), numTimings);
[mx mxIndex] = max(timing);
fprintf('[computeLongPaths] maximum time=%f for %dth element (of %d)\n', max(timing), mxIndex, numTimings);
fprintf('[computeLongPaths] mean time=%f (of %d)\n', mean(timing), numTimings);
fprintf('[computeLongPaths] median time=%f (of %d)\n', median(timing), numTimings);




%fprintf('Total Neurite Length: %f pixel widths\n', totalNeuriteLength);


% Check for missing paths due to marking edges as used
% for d1 = 1:numel(neuronBodyDataArr)
%     nbd = neuronBodyDataArr(d1);
%     for lp = 1:numel(nbd.longPaths);
%         pth = nbd.longPaths{lp};
%         sourceBodyNumbers = ng.vertexattujbody{pth.fromVertex};
%         if numel(sourceBodyNumbers) ~= 1
% 	  error('[computeLongPaths] Vertex %d touches %d cell bodies', pth.fromVertex, numel(sourceBodyNumbers));
%         k = find(adjacentBodyNumbers == nbd.bodyNumber);
%         if ~any(k)
%             error('[computeLongPaths] path does not start from body number');
%         end
%         targetBodyNumbers = ng.vertexattujbody{pth.toVertex};
%         % Skip edges that do not terminate at a cell body
%         if isempty(targetBodyNumbers) continue; end
%         if numel(targetBodyNumbers) ~= 1
%             error('[computeLongPaths] Vertex %d touches %d cell bodies', pth.toVertex, numel(targetBodyNumbers));
%         end
%         targetBodyNumber = sum(targetBodyNumbers);
%         nbd2 = neuronBodyDataArr(targetBodyNumber);
%         foundPath = false;
%         for i = 1:numel(nbd2.longPaths)
%             if pth == nbd2.longPaths{i};
%     end
% 

end
