classdef ImageHandle < handle
    properties
        image
    end
    methods
        function ih = ImageHandle(image)
            ih.image = image;
        end
    end
    
end