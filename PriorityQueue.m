classdef PriorityQueue < handle
    properties
        first
        last
        numElements
    end
    
    methods
        function pq = PriorityQueue()
            pq.first = [];
            pq.last = [];
            pq.numElements = 0;
        end
        
        function sz = size(pq)
            sz = pq.numElements;
        end
        
        function priority = headPriority(pq)
            if isempty(pq.first)
                error('[PriorityQueue.headPriority] Queue is empty');
            end
            priority = pq.first.priority;
        end
        
   
        
        function [value priority] = dequeue(pq)
            if isempty(pq.first)
                error('[PriorityQueue.dequeue] Queue is empty');
            end
            value = pq.first.value;
            priority = pq.first.priority;
            if pq.first == pq.last
                pq.first = [];
                pq.last = [];
            else
                pq.first = pq.first.next;
                pq.first.prev = [];
            end
            pq.numElements = pq.numElements - 1;
        end
        
        function enqueue(pq, value, priority)
            newPriorityNode = PriorityNode(value, priority);
            if isempty(pq.last)
                newPriorityNode.next = [];
                newPriorityNode.prev = [];
                pq.first = newPriorityNode;
                pq.last = newPriorityNode;
            else
                n = pq.last;
                while ~isempty(n) && priority > n.priority
                   n = n.prev; 
                end
                if isempty(n)
                   pq.first.prev = newPriorityNode;
                   newPriorityNode.next = pq.first;
                   pq.first = newPriorityNode;
                else
                    newPriorityNode.next = n.next;
                    newPriorityNode.prev = n;
                    n.next.prev = newPriorityNode;
                    n.next = newPriorityNode;
                end
            end
            pq.numElements = pq.numElements + 1;
        end
    end
end