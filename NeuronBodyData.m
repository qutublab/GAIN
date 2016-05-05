classdef NeuronBodyData < handle
    properties
        bodyNumber
        nucleiNumber
        bodyArea
%         numberOfNeurons
        numberOfNuclei
        centroidRow
        centroidColumn
        radius
        hasDapi
        mask
        totalNucleiArea = 0
        countedNucleiArea = 0
        minNeuriteLength
        longNeuriteCount
        longestNeuriteLength
        shortNeuriteCount
        longPaths
        shortPaths
    end
    
    methods
        function nbd = NeuronBodyData(bodyNumber, nucleiNumber, bodyArea,...
                numberOfNuclei, centroidRow, centroidColumn, radius, mask, ...
                totalNucleiArea)
            if nargin == 0
                return;
            end
            nbd.bodyNumber = bodyNumber;
            nbd.nucleiNumber = nucleiNumber;
            nbd.bodyArea = bodyArea;
            nbd.numberOfNuclei = numberOfNuclei;
            nbd.centroidRow = centroidRow;
            nbd.centroidColumn = centroidColumn;
            nbd.radius = radius;
            nbd.mask = mask;
            if nargin >= 9
                nbd.totalNucleiArea = totalNucleiArea;
            end
        end

        function n = copy(nbd)
            n = NeuronBodyData(nbd.bodyNumber, nbd.nucleiNumber, nbd.bodyArea, nbd.numberOfNuclei, nbd.centroidRow, nbd.centroidColumn, nbd.radius, nbd.mask, nbd.totalNucleiArea);
            n.countedNucleiArea = nbd.countedNucleiArea;
            n.minNeuriteLength = nbd.minNeuriteLength;
            n.longNeuriteCount = nbd.longNeuriteCount;
            n.longestNeuriteLength = nbd.longestNeuriteLength;
            n.shortNeuriteCount = nbd.shortNeuriteCount;
            n.longPaths = cell(numel(nbd.longPaths), 1);
            for i = 1:numel(nbd.longPaths)
                n.longPaths{i} = nbd.longPaths{i}.copy();
            end
            n.shortPaths = cell(numel(nbd.shortPaths), 1);
            for i = 1:numel(nbd.shortPaths)
                n.shortPaths{i} = nbd.shortPaths{i}.copy();
            end
        end
    end
end
