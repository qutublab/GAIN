classdef Box < handle
    properties
        v
    end
    
    methods
        function b = Box(v)
        if nargin == 0
            return;
        end
        b.v = v;
        end
    end

end
