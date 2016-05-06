classdef OneParameter < handle

    properties
        name
        value
        active
        lineNum = []
        description
    end
    
    methods
        function op = OneParameter(name, value, active, lineNum)
            if nargin == 0;
                return;
            end
            op.name = name;
            op.value = value;
            op.active = active;
            if nargin >= 4
                op.lineNum = lineNum;
            end
        end

        function str = toString(op)
            str = 'OneParameter[';
            str = sprintf('%sname=%s', str, op.name);
            str = sprintf('%s,value=%f', str, op.value);
            str = sprintf('%s,active=%f', str, op.active);
            str = sprintf('%s,active=%f', str, op.lineNum);
            str = sprintf('%s]', str);
        end
        
    end
    
    methods (Static)
        function opa = readFile(fileName);
            status = '';
            [fid errmsg] = fopen(fileName, 'r');
            if (fid == -1)
                status = sprintf('Unable to open %s  Reason: %s', fileName, errmsg);
                opa = status;
                return;
            end
            ln = fgetl(fid);
            lineNum = 1;
            paramStack = Stack();
            while ischar(ln)
                ln = stripComment(ln);
                ln = strtrim(ln);
                C = strsplit(ln);
                if ~(numel(C) == 0 || isempty(C{1}))
                    if numel(C) ~= 2
                        status = sprintf('%s\nExpected 2 items, but found %d items on line %d of file %s', status, numel(C), lineNum, fileName);
                    else
                        op = OneParameter(C{1}, C{2}, true, lineNum);
                        paramStack.push(op);
                    end
                end
                ln = fgetl(fid);
                lineNum = lineNum + 1;
            end
            fclose(fid);
            if ~isempty(status)
                opa = status;
                return;
            end
            numParams = paramStack.size();
            for i = numParams:-1:1
               opa(i) = paramStack.pop(); 
            end
        end
    end
    
end
