classdef PredictionSet
    properties
        predictionsMap
        unmatchedPredictions
    end


    methods
        function ps = PredictionSet(predictionsMap, unmatchedPredictions)
            if nargin == 0
                return;
            end
            ps.predictionsMap = predictionsMap;
            ps.unmatchedPredictions = unmatchedPredictions;
        end
    end


end
