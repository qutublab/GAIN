classdef NumericParameters < handle
    properties
        % As properties are added and removed, update the static
        % parameterType method that associates each property with its type.
        BrightNucleiSelectivity = []
        DimNucleiSelectivity = []
        NucleiSeparationControl  = []      % Disk size for post-threshold imopen
        NucleusClusterSensitivity = []      % Ratio for determining nucleus clusters
        SingleNucleusSizeControl = []
        MinimumAcceptableNucleusSizeControl = []
        CellBodySelectivity = []
        CellBodyNeuriteDiscrimination = []   % Disk size for imopen to CellBodyNeuriteDiscrimination
        NeuriteSelectivity = []
        SecondaryNeuriteSelectivity= []
        NeuriteBridgeLength = []       % Size of square structuring element for imclose
 
        
        
        
        
    end
    
    methods (Static)
        % Returns a NumericSubtype value indicating the type of numeric
        % values that can be assigned to a property
        function typ = parameterType(paramName)
            persistent typesMap;
            if isempty(typesMap)
                % Initialize typesMap
                typesMap = NumericParameters.createTypesMap(...
                    'BrightNucleiSelectivity', NumericSubtype.POSITIVE,...
                    'DimNucleiSelectivity', NumericSubtype.POSITIVE,...
                    'NucleiSeparationControl', NumericSubtype.POSITIVE_INTEGER,...
                    'NucleusClusterSensitivity', NumericSubtype.POSITIVE_LE1,...
                    'SingleNucleusSizeControl', NumericSubtype.POSITIVE,...
                    'MinimumAcceptableNucleusSizeControl', NumericSubtype.POSITIVE,...
                    'CellBodySelectivity', NumericSubtype.POSITIVE,...
                    'NeuriteSelectivity', NumericSubtype.POSITIVE,...
                    'SecondaryNeuriteSelectivity', NumericSubtype.POSITIVE,...
                    'CellBodyNeuriteDiscrimination', NumericSubtype.POSITIVE_INTEGER,...
                    'NeuriteBridgeLength', NumericSubtype.POSITIVE_INTEGER...
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
            np.BrightNucleiSelectivity = 1;
            np.DimNucleiSelectivity = 1;
            np.NucleiSeparationControl  = 3;
            np.NucleusClusterSensitivity = 0.95;
            np.SingleNucleusSizeControl = 1;
            np.MinimumAcceptableNucleusSizeControl   = 2;
            np.CellBodySelectivity = 1;
            np.NeuriteSelectivity = 1;
            np.SecondaryNeuriteSelectivity= 1.5;
            np.CellBodyNeuriteDiscrimination = 5;
            np.NeuriteBridgeLength = 3;
        end

        % Optimized parameters 
        function initialize2(np)
            np.CellBodySelectivity = 0.996921;
            np.CellBodyNeuriteDiscrimination = 4.896013;
            np.NeuriteSelectivity = 0.969891;
            np.SecondaryNeuriteSelectivity= 1.5;   % Parameter added after optimzation was done
            np.NeuriteBridgeLength = 3.020864;
            np.BrightNucleiSelectivity = 1.013925 ;
            np.DimNucleiSelectivity = 1.036532;
            np.NucleiSeparationControl  = 2.961556;
            np.NucleusClusterSensitivity = 0.964889;
            np.SingleNucleusSizeControl = 1.055883;
            np.MinimumAcceptableNucleusSizeControl   = 2.003794;
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
            str = sprintf('NumericParameters[NucleiSeparationControl =%d', p.NucleiSeparationControl );
            str = sprintf('%s,CellBodyNeuriteDiscrimination=%d', str, p.CellBodyNeuriteDiscrimination);
            str = sprintf('%s,NucleusClusterSensitivity=%f', str, p.NucleusClusterSensitivity);
            str = sprintf('%s,NeuriteBridgeLength=%d', str, p.NeuriteBridgeLength);
            str = sprintf('%s,CellBodySelectivity=%f', str, p.CellBodySelectivity);
            str = sprintf('%s,NeuriteSelectivity=%f', str, p.NeuriteSelectivity);
            str = sprintf('%s,SecondaryNeuriteSelectivity=%f', str, p.SecondaryNeuriteSelectivity);
            str = sprintf('%s,BrightNucleiSelectivity=%f', str, p.BrightNucleiSelectivity);
            str = sprintf('%s,DimNucleiSelectivity=%f', str, p.DimNucleiSelectivity);
            str = sprintf('%s,MinimumAcceptableNucleusSizeControl  =%f', str, p.MinimumAcceptableNucleusSizeControl  );
            str = sprintf('%s,SingleNucleusSizeControl=%f]', str, p.SingleNucleusSizeControl);
        end
        
    end
    
    
end
