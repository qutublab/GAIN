% Why is this class even necessary?
%
% 

classdef IntermediateParameters < NumericParameters
    methods
%         function status = update(np, x)
%         end
        function status = readFromFile(np, fileName);
            status = '';
            % readFile returns either: a) an array of OneParameter objects or
            % b) a non-empty string containing an error message
            opaOrStatus = OneParameter.readFile(fileName);
            if ischar(opaOrStatus)
                status = opaOrStatus;
                return;
            end
            % Since argument np can be of subclass Parameters, prevent the
            % invocation of the Parameters.update method
            class(np)
            status = update@NumericParameters(np, opaOrStatus);
        end
    end
    
end