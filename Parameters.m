classdef Parameters < NumericParameters
    properties
        fileName = ''
    end
    
    methods
 
        function oneParamArr = generateOneParameterArr(p)
            propNames = ['fileName'; properties(NumericParameters)];
            numParams = numel(propNames);
            % Allocate oneParamArr
            oneParamArr(numParams) = OneParameter();
            % Place non-numeric fileName in oneParamArr
            oneParamArr(1) = OneParameter('fileName', p.fileName, false);
            % Extra element in front of paramVec is unused value for
            % fileName
            paramVec = [0, p.toVector()];
            % Add numeric values to oneParamArr
            for i = 2:numParams
                typ = NumericParameters.parameterType(propNames{i});
                if typ.isIntegerType()
                    valueStr = sprintf('%d', paramVec(i));
                else
                    valueStr = sprintf('%f', paramVec(i));
                end
                oneParamArr(i) = OneParameter(propNames{i}, valueStr, false);
            end
        end
        
        function status = update(p, oneParamArr)
            status = '';
            % Force oneParamArr to be a column vector to facilitate removal
            % of fileName parameter.
            oneParamArr = oneParamArr(:);
            % Find fileName parameter
            fileNameIndex = find(strcmp('fileName', {oneParamArr.name}));
            if numel(fileNameIndex) ~= 1
                error('[Parameters.update] fileName parameter found %d times', numel(fileNameIndex));
            end
            fileName = oneParamArr(fileNameIndex).value;
            % Remove file name parameter
            oneParamArr = [oneParamArr(1:(fileNameIndex-1)); oneParamArr((fileNameIndex+1):end)];
            status = updateNumeric(p, oneParamArr);
            % Do not update filename of p unless update of numeric parameters
            % was successful
            if isempty(status)
                p.fileName = fileName;
            end
        end
        
        function str = toString(p)
            propNames = properties(Parameters);
            propNm = propNames{1};
            str = sprintf('Parameters[%s=%s', propNm, p.(propNm));
            for i = 2:numel(propNames)
                propNm = propNames{i};
                typ = NumericParameters.parameterType(propNm);
                if typ.isIntegerType()
                    str = sprintf('%s,%s=%d', str, propNm, p.(propNm));
                else
                    str = sprintf('%s,%s=%f', str, propNm, p.(propNm));
                end
            end
            str = sprintf('%s]', str);
        end
    end
    
    
end
