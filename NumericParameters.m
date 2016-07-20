classdef NumericParameters < handle
    properties
        % As properties are added and removed, update the static
        % parameterType method that associates each property with its type.
        SegmentBrightNuclei = []
        SegmentDimNuclei = []
        SeparateWeaklyConnectedNuclei  = []      % Disk size for post-threshold imopen
        DetermineNucleiClusters = []      % Ratio for determining nucleus clusters
        SingleNucleusSize = []
        MinAcceptableNucleusSize  = []
        CellBodiesandNeurites = []
        RemoveNeurites = []   % Disk size for imopen to RemoveNeurites
        SegmentNeurites = []
        ImproveSegmentationQuality= []
        ConnectNeuriteSections = []       % Size of square structuring element for imclose
 
        
        
        
        
    end
    
    methods (Static)
        % Returns a NumericSubtype value indicating the type of numeric
        % values that can be assigned to a property
        function typ = parameterType(paramName)
            persistent typesMap;
            if isempty(typesMap)
                % Initialize typesMap
                typesMap = NumericParameters.createTypesMap(...
                    'SegmentBrightNuclei', NumericSubtype.POSITIVE,...
                    'SegmentDimNuclei', NumericSubtype.POSITIVE,...
                    'SeparateWeaklyConnectedNuclei', NumericSubtype.POSITIVE_INTEGER,...
                    'DetermineNucleiClusters', NumericSubtype.POSITIVE_LE1,...
                    'SingleNucleusSize', NumericSubtype.POSITIVE,...
                    'MinAcceptableNucleusSize', NumericSubtype.POSITIVE,...
                    'CellBodiesandNeurites', NumericSubtype.POSITIVE,...
                    'SegmentNeurites', NumericSubtype.POSITIVE,...
                    'ImproveSegmentationQuality', NumericSubtype.POSITIVE,...
                    'RemoveNeurites', NumericSubtype.POSITIVE_INTEGER,...
                    'ConnectNeuriteSections', NumericSubtype.POSITIVE_INTEGER...
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
            np.SegmentBrightNuclei = 1;
            np.SegmentDimNuclei = 1;
            np.SeparateWeaklyConnectedNuclei  = 3;
            np.DetermineNucleiClusters = 0.95;
            np.SingleNucleusSize = 1;
            np.MinAcceptableNucleusSize  = 2;
            np.CellBodiesandNeurites = 1;
            np.SegmentNeurites = 1;
            np.ImproveSegmentationQuality= 1.5;
            np.RemoveNeurites = 5;
            np.ConnectNeuriteSections = 3;
        end

        % Optimized parameters 
        function initialize2(np)
            np.CellBodiesandNeurites = 0.996921;
            np.RemoveNeurites = 4.896013;
            np.SegmentNeurites = 0.969891;
            np.ImproveSegmentationQuality= 1.5;   % Parameter added after optimzation was done
            np.ConnectNeuriteSections = 3.020864;
            np.SegmentBrightNuclei = 1.013925 ;
            np.SegmentDimNuclei = 1.036532;
            np.SeparateWeaklyConnectedNuclei  = 2.961556;
            np.DetermineNucleiClusters = 0.964889;
            np.SingleNucleusSize = 1.055883;
            np.MinAcceptableNucleusSize  = 2.003794;
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
            str = sprintf('NumericParameters[SeparateWeaklyConnectedNuclei =%d', p.SeparateWeaklyConnectedNuclei );
            str = sprintf('%s,RemoveNeurites=%d', str, p.RemoveNeurites);
            str = sprintf('%s,DetermineNucleiClusters=%f', str, p.DetermineNucleiClusters);
            str = sprintf('%s,ConnectNeuriteSections=%d', str, p.ConnectNeuriteSections);
            str = sprintf('%s,CellBodiesandNeurites=%f', str, p.CellBodiesandNeurites);
            str = sprintf('%s,SegmentNeurites=%f', str, p.SegmentNeurites);
            str = sprintf('%s,ImproveSegmentationQuality=%f', str, p.ImproveSegmentationQuality);
            str = sprintf('%s,SegmentBrightNuclei=%f', str, p.SegmentBrightNuclei);
            str = sprintf('%s,SegmentDimNuclei=%f', str, p.SegmentDimNuclei);
            str = sprintf('%s,MinAcceptableNucleusSize =%f', str, p.MinAcceptableNucleusSize );
            str = sprintf('%s,SingleNucleusSize=%f]', str, p.SingleNucleusSize);
        end
        
    end
    
    
end
