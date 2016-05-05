classdef MaskHandle < handle
    properties
        mask
    end
    methods
        function mh = MaskHandle(mask)
            mh.mask = mask;
        end
    end
    
end