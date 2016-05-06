classdef NucleusData < handle
    properties 
        labelNum
        area
        areaToConvexHullRatio
        centroid
        cluster
        small
        numNuclei
    end
    methods
        function nd = NucleusData(labelNum, area, areaToConvexHullRatio, cluster, centroid)
            if nargin == 0
                return;
            end
            nd.labelNum = labelNum;
            nd.area = area;
            nd.areaToConvexHullRatio = areaToConvexHullRatio;
            nd.cluster = cluster;
            nd.centroid = centroid;
        end

        function ln = getLabelNum(nd)
            ln = nd.labelNum;
        end

        function a = getArea(nd)
            a = nd.area;
        end

        function a2chr = getAreaToConvexHullRatio(nd)
            a2chr = nd.areaToConvexHullRatio;
        end

        function sml = isSmall(nd)
            sml = nd.small;
        end

        function clstr = isCluster(nd)
            clstr = nd.cluster;
        end

        function str = toString(nd)
            str = 'NucleusData[';
            str = sprintf('%slabelNum=%d', str, nd.labelNum);
            str = sprintf('%s,area=%d', str, nd.area);
            str = sprintf('%s,areaToConvexHullRatio=%f', str, nd.areaToConvexHullRatio);
            str = sprintf('%s,cluster=%d', str, nd.cluster);
            str = sprintf('%s,small=%d', str, nd.small);
            str = sprintf('%s,numNuclei=%d', str, nd.numNuclei);
            str = sprintf('%s]', str);
        end

        function nd2 = copy(nd)
%            nd2 = NucleusData(nd.labelNum, nd.area, nd.areaToConvexHullRatio, nd.cluster, nd.small, nd.numNuclei);
            nd2 = NucleusData();
%             p = fieldnames(struct(nd));
            p = properties(nd);
            for i = 1:numel(p)
                nd2.(p{i}) = nd.(p{i});
            end
        end

    end
    
end
    
