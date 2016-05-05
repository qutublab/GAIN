classdef Path < handle
    properties
        distance
        edgeStack
        fromVertex
        toVertex
        edgeInPath
        fromBody
        toBody
    end
    
    methods
        function p = Path(distance, edgeStack, fromVertex, toVertex, numTotalEdges)
            if nargin == 0
                return;
            end
            p.distance = distance;
            p.edgeStack = edgeStack;
            p.fromVertex = fromVertex;
            p.toVertex = toVertex;
            if nargin == 5
                p.numEdgeObjects(numTotalEdges);
            end
            numEdges = p.numEdgeObjects();
            if isempty(numEdges)
                error('[Path] Unknown number of total edges');
            end
            p.edgeInPath = false(numEdges, 1);
            edges = edgeStack.toCellArray();
            for i = 1:numel(edges)
                p.edgeInPath(edges{i}.idNum) = true;
            end
            p.fromBody = 0;
            p.toBody = 0;
        end
        
        function n = numEdgeObjects(p, num)
           persistent numEdges;
           if nargin == 2
               numEdges = num;
           end
           n = numEdges;
        end
        
        % Returns the path as a convenience to the caller
        function p = addEdge(p, edge, toVertex)
            p.distance = p.distance + edge.distance;
            p.edgeStack.push(edge);
            p.toVertex = toVertex;
            if p.edgeInPath(edge.idNum)
                error('[Path.addEdge] Edge is already in path');
            else
                p.edgeInPath(edge.idNum) = true;
            end
        end
        
        function p2 = copy(p)
           p2 = Path();
           p2.distance = p.distance;
           p2.edgeStack = p.edgeStack.copy();
           p2.fromVertex = p.fromVertex;
           p2.toVertex = p.toVertex;
           p2.edgeInPath = p.edgeInPath;
           p2.fromBody = p.fromBody;
           p2.toBody = p.toBody;
        end
        
    end
end
