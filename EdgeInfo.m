classdef EdgeInfo < handle
    properties
        idNum
        distance
        pathIdxList
        vertices
        used
        useCount = 0;
    end
    
    methods
        function ei = EdgeInfo(distance, pathIdxList, vertices)
            ei.idNum = ei.nextId();
            ei.pathIdxList = [];
            if nargin > 0
                ei.distance = distance;
% ei.pathIdxList = sort(pathIdxList);
                ei.pathIdxList = pathIdxList;
                ei.vertices = vertices;
                ei.used = false;
            end
        end
        
        function id = nextId(e, doNotIncrement)
            persistent count;
            if isempty(count)
                count = 0;
            end
            if nargin == 1
                count = count + 1;
            end
            id = count;
        end
        
        function n = numObjects(e)
           n = e.nextId('doNotIncrement');
        end
        
%         function b = eq(e1, e2)
%             b = (e1.distance == e2.distance) && (e1.pathIdxList == e2.pathIdxList);
%         end
%         
%         function b = ne(e1, e2)
%             b = ~eq(e1, e2);
%         end
        
        function b = samePath(e1, e2)
            b = false;
            if numel(e1.pathIdxList) ~= numel(e2.pathIdxList) return; end
            c = (e1.pathIdxList ~= e2.pathIdxList);
            if ~any(c(:))
                b = true;
            else
                c = (e1.pathIdxList ~= (e2.pathIdxList(end:-1:1)));
                if ~any(c(:))
                    b = true;
                end
            end
        end

        
    end
end
