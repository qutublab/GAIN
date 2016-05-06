classdef PriorityNode < Node
    properties
        priority
        prev
    end
    
    methods
        function pn = PriorityNode(value, priority)
            pn@Node(value);
            pn.priority = priority;
        end
    end
end