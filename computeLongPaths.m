

function computeLongPaths(neuronBodyDataArr, G)

totalNeuriteLength = 0;
for d = 1:numel(neuronBodyDataArr)
    longPaths = Stack();
    shortPaths = Stack();
    fprintf('Looking for paths from cluster %d of %d\n', d, numel(neuronBodyDataArr));
    nbd = neuronBodyDataArr(d);
%     if nbd.nucleiNumber > 0
%         numCells = nbd.numberOfNeurons;
        numCells = max(1, nbd.numberOfNuclei);
        avgArea = nbd.bodyArea / numCells;
        avgDiameter = sqrt((4 * avgArea) / pi);
%fprintf('Parameterize minNeuriteLength multiplier !!!\n');
        minNeuriteLength = 3 * avgDiameter;
fprintf('Parameterize junctionSpan !!!\n');
        junctionSpan = 9;
        fprintf('[computeLongPaths] Computing walks for neuron body: %d\n', d);
%         tic;
        pathStack = G.allStraightWalksFromTujBody(d, junctionSpan);
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
            end
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
                end
%                 et = toc;
%                 fprintf('[computeLongPaths] time: %f\n', et);
            end
        end
        nbd.minNeuriteLength = minNeuriteLength;
        nbd.longNeuriteCount = longNeuriteCount;
        nbd.longestNeuriteLength = longest;
        nbd.shortNeuriteCount = shortNeuriteCount;
        nbd.longPaths = longPaths.toCellArray();
        nbd.shortPaths = shortPaths.toCellArray();
%     end
end


fprintf('Total Neurite Length: %f pixel widths\n', totalNeuriteLength);


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
