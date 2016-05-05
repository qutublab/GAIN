classdef NumericParameters < handle
    properties
        % As properties are added and removed, update the static
        % parameterType method that associates each property with its type.
        dapiThreshFactor1 = []
        dapiThreshFactor2 = []
        nucleusOpenDiskRadius = []      % Disk size for post-threshold imopen
        areaToConvexHullRatio = []      % Ratio for determining nucleus clusters
        medianNucleusAdjustmentFactor = []
        median2MinimumNucleusAreaRatio = []
        tujThreshFactor1 = []
        neuriteRemovalDiskRadius = []   % Disk size for imopen to remove neurites
        tujThreshFactor2 = []
        tujClosingSquareSide = []       % Size of square structuring element for imclose
 
        
        
        
        
    end
    
    methods (Static)
        % Returns a NumericSubtype value indicating the type of numeric
        % values that can be assigned to a property
        function typ = parameterType(paramName)
            persistent typesMap;
            if isempty(typesMap)
                % Initialize typesMap
                typesMap = NumericParameters.createTypesMap(...
                    'dapiThreshFactor1', NumericSubtype.POSITIVE,...
                    'dapiThreshFactor2', NumericSubtype.POSITIVE,...
                    'nucleusOpenDiskRadius', NumericSubtype.POSITIVE_INTEGER,...
                    'areaToConvexHullRatio', NumericSubtype.POSITIVE_LE1,...
                    'medianNucleusAdjustmentFactor', NumericSubtype.POSITIVE,...
                    'median2MinimumNucleusAreaRatio', NumericSubtype.POSITIVE,...
                    'tujThreshFactor1', NumericSubtype.POSITIVE,...
                    'tujThreshFactor2', NumericSubtype.POSITIVE,...
                    'neuriteRemovalDiskRadius', NumericSubtype.POSITIVE_INTEGER,...
                    'tujClosingSquareSide', NumericSubtype.POSITIVE_INTEGER...
                    );
            end
            typ = typesMap(paramName);
        end
        
       function map = createTypesMap(varargin)
           propNames = sort(properties(NumericParameters));
           if mod(nargin, 2) ~= 0
               error('[NumericParameters.createTypesMap] Unexpected number of arguments: %d', nargin);
           end
           map = containers.Map;
           for i = 1:2:nargin
               propNm = varargin{i};
               foundIndex = strBinarySearch(propNm, propNames);
               if foundIndex == 0
                   error('[NumericParameters.createTypesMap] Unexpected property name: %s', propNm);
               end
               if isKey(map, propNm)
                   error('[NumericParameters.createTypesMap] Property name argument: %s occurs more than once', propNm);
               end
               subtype = varargin{i+1};
               if ~strcmp(class(subtype), 'NumericSubtype')
                   error('[NumericParameters.createTypesMap] Argument %d is not a NumericSubtype object', i+1);
               end
               map(propNm) = subtype;
           end
       end
       
       function status = updateStatus(status, lineNum, msg)
           if ~isempty(status)
               status = sprintf('%s\n', status);
           end
           if ~isempty(lineNum)
               status = sprintf('%sLine %d: ', status, lineNum);
           end
           status = sprintf('%s%s', status, msg);
       end
    end
    
    methods
        
        function np = NumericParameters()
        end

        % Parameters set during program development
        function initialize(np)
            np.dapiThreshFactor1 = 1;
            np.dapiThreshFactor2 = 1;
            np.nucleusOpenDiskRadius = 3;
            np.areaToConvexHullRatio = 0.95;
            np.medianNucleusAdjustmentFactor = 1;
            np.median2MinimumNucleusAreaRatio = 2;
            np.tujThreshFactor1 = 1;
            np.tujThreshFactor2 = 1;
            np.neuriteRemovalDiskRadius = 5;
            np.tujClosingSquareSide = 3;
        end

        % Optimized parameters 
        function initialize2(np)
            np.tujThreshFactor1 = 0.996921;
            np.neuriteRemovalDiskRadius = 4.896013;
            np.tujThreshFactor2 = 0.969891;
            np.tujClosingSquareSide = 3.020864;
            np.dapiThreshFactor1 = 1.013925 ;
            np.dapiThreshFactor2 = 1.036532;
            np.nucleusOpenDiskRadius = 2.961556;
            np.areaToConvexHullRatio = 0.964889;
            np.medianNucleusAdjustmentFactor = 1.055883;
            np.median2MinimumNucleusAreaRatio = 2.003794;
            np.rectify();
        end
        


        function v = toVector(np)
            propNames = properties(NumericParameters);
            numProps = numel(propNames);
            v = zeros(1, numProps);
            for i = 1:numProps
                propNm = propNames{i};
                num=np.(propNm);
                if isempty(num)
                    error('[NumericParameters.toVector] Property %s is empty', propNames{i});
                end
                v(i) = num;
            end
        end

        function np = fromVector(a, v)
            np = NumericParameters();
            np.assignFromVector(v);
        end
        
        function assignFromVector(p, v)
            if ~isnumeric(v)
                error('[NumericProperties.assignFromVector] vector argument is not numeric');
            end
            propNames = properties(NumericParameters);
            numProps = numel(propNames);
            if numProps ~= numel(v)
                error('[NumericProperties.assignFromVector] vector argument length: %d; expected length: %d', numel(v), numProps);
            end
            for i = 1:numProps
                propNm = propNames{i};
                p.(propNm) = v(i);
%                 set(p, propNames{i}, v(i));
            end
        end
        

        function rectify(np)
            propNames = properties(NumericParameters);
            for i = 1:numel(propNames)
                propNm = propNames{i};
                typ = NumericParameters.parameterType(propNm);
                np.(propNm) = typ.rectify(np.(propNm));
            end
        end
        
        function status = validate(p)
            status = '';
            propNames = properties(NumericParameters);
            for i = 1:numel(propNames)
                propNm = propNames{i};
                typ = NumericParameters.parameterType(propNm);
                typStatus = typ.check(p.(propNm));
                if ~isempty(typStatus)
                    if isempty(status)
                        status = sprintf('Unexpected %s: %s', propNm, typStatus);
                    else
                        status = sprintf('%s\nUnexpected %s: %s', status, propNm, typStatus);
                    end
                end
            end
        end

      
        % Argument np is updated only if parameter values in oneParamArr
        % are valid
        function status = updateNumeric(np, oneParamArr)
            status = '';
            propNames = sort(properties(NumericParameters));
            temp = NumericParameters();
            for i = 1:numel(oneParamArr)
                op = oneParamArr(i);
                findIndex = strBinarySearch(op.name, propNames);
                if findIndex == 0
                    % op.name is not a property
                    status = NumericParameters.updateStatus(status, op.lineNum, sprintf('Unknown parameter name: %s', op.name));
                else
                    num = str2num(op.value);
                    typ = NumericParameters.parameterType(op.name);
                    typStatus = typ.check(num);
                    if ~isempty(typStatus)
                        % op.val is not a correct number
                        status = NumericParameters.updateStatus(status, op.lineNum, sprintf('Unexpected %s value. %s', op.name, typStatus));
                    else
                        propNm = op.name;
                        value = temp.(propNm);
                        if ~isempty(value)
                            % Parameter occurs twice
                            status = NumericParameters.updateStatus(status, op.lineNum, sprintf('Parameter %s already defined', op.name));
                        else
                            temp.(propNm) = num;
                        end
                    end
                end
            end
            for i = 1:numel(propNames)
                propNm = propNames{i};
                value = temp.(propNm);
                if isempty(value)
                    status = NumericParameters.updateStatus(status, [], sprintf('Parameter %s is not defined', propNm));
                end
            end
            if isempty(status)
                np.assignFromVector(temp.toVector());
            end
        end
        
        function status = writeToFile(p, fileName)
            status = '';
            [fid errmsg] = fopen(fileName, 'w');
            if (fid == -1)
                status = sprintf('Unable to open %s  Reason: $s', fileName, errmsg);
                return;
            end
            propNames = properties(NumericParameters);
            v = p.toVector();
            for i = 1:numel(propNames)
               typ = NumericParameters.parameterType(propNames{i});
               if typ.isIntegerType()
                   fprintf(fid, '%s %d\n', propNames{i}, v(i));
               else
                   fprintf(fid, '%s %f\n', propNames{i}, v(i));
               end
            end
            fclose(fid);
        end
        
        function status = readFromFile(np, fileName);
            status = '';
            % OneParameter.readFile returns either: a) an array of 
            % OneParameter objects or b) a non-empty string containing an
            % error message
            opaOrStatus = OneParameter.readFile(fileName);
            if ischar(opaOrStatus)
                status = opaOrStatus;
                return;
            end
            status = updateNumeric(np, opaOrStatus);
        end
        
        function str = toString(p)
            str = sprintf('NumericParameters[nucleusOpenDiskRadius=%d', p.nucleusOpenDiskRadius);
            str = sprintf('%s,neuriteRemovalDiskRadius=%d', str, p.neuriteRemovalDiskRadius);
            str = sprintf('%s,areaToConvexHullRatio=%f', str, p.areaToConvexHullRatio);
            str = sprintf('%s,tujClosingSquareSide=%d', str, p.tujClosingSquareSide);
            str = sprintf('%s,tujThreshFactor1=%f', str, p.tujThreshFactor1);
            str = sprintf('%s,tujThreshFactor2=%f', str, p.tujThreshFactor2);
            str = sprintf('%s,dapiThreshFactor1=%f', str, p.dapiThreshFactor1);
            str = sprintf('%s,dapiThreshFactor2=%f', str, p.dapiThreshFactor2);
            str = sprintf('%s,median2MinimumNucleusAreaRatio=%f', str, p.median2MinimumNucleusAreaRatio);
            str = sprintf('%s,medianNucleusAdjustmentFactor=%f]', str, p.medianNucleusAdjustmentFactor);
        end
        
    end
    
    
end
