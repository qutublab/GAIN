classdef Node < handle
    properties
        value
        next
    end
    methods
        function n = Node(value)
            n.value = value;
        end
    end
    
end
    