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

       function v2 = opposingVertex(e, v)
           if v == e.vertices(1)
               v2 = e.vertices(2);
           else
               if v == e.vertices(2)
                   v2 = e.vertices(1);
               else
                   error('[EdgeInfo.opposingVertex] vertex %d is not in edge %d', v, e.idNum);
               end
           end
       end

       function [first delta last] = pathDirection(e, idx)
           if idx == e.pathIdxList(1)
               first = 1;
               delta = 1;
               last = numel(e.pathIdxList);
           else
               if idx == e.pathIdxList(end)
                   first = numel(e.pathIdxList);
                   delta = -1;
                   last = 1;
               else
                   error('[EdgeInfo.pathDirection] Index %d not at end of edge (%d or %d) ', idx, e.pathIdxList(1), e.pathIdxList(end));
               end
           end
        end

        function idx = endPointNeighbor(e, v)
            if numel(e.pathIdxList) < 2
                error('[EdgeInfo.endPointNeighbor] End point has no neighbor');
            end
            if v == e.vertices(1)
                idx = e.pathIdxList(2);
            else
                if v == e.vertices(2)
                    idx = e.pathIdxList(end-1);
                else
                    error('[EdgeInfo.endPointNeighbor] Vertex is not an end point');
                end
            end
        end
        
    end
end
