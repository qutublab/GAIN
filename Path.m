classdef Path < handle
    properties
        distance
        edgeStack
        fromVertex
        toVertex
        fromBody
        toBody
    end
    
    methods
        function p = Path(distance, edgeStack, fromVertex, toVertex, fromBody, toBody)
            if nargin == 0
                return;
            end
            p.distance = distance;
            p.edgeStack = edgeStack;
            p.fromVertex = fromVertex;
            p.toVertex = toVertex;
            p.fromBody = fromBody;
            p.toBody = toBody;
        end

        function p2 = copy(p)
            p2 = Path(p.distance, p.edgeStack.copy(), p.fromVertex, p.toVertex, p.fromBody, p.toBody);
        end
        
    end
end
