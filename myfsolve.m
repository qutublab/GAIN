function myfsolve()

fprintf('[myfsolve] Make sure that segmentationError output is appropriate!\n\n');

c = int16(clock());

p = Parameters();
p.initialize();
x0 = p.toVector();

year = sprintf('%d', c(1));
month = pad2(c(2));
day = pad2(c(3));
hour = pad2(c(4));
minute = pad2(c(5));
dateStr = sprintf('%s%s%s%s%s', year, month, day, hour, minute);

filename = sprintf('minNImP4-fsolve-%s.txt', dateStr);
fid = fopen(filename, 'w');
fprintf(fid, '%s-%s-%s %s:%s\n\n', year, month, day, hour, minute);
fprintf(fid, 'Initial Parameters: %s\n\n', p.toString());
os = optimset('Display', 'iter', 'MaxIter', 1000, 'MaxFunEvals', 10000, 'Algorithm', 'levenberg-marquardt');

fprintf(fid, 'optimset:\n');
fieldNames = fieldnames(os);
for i = 1:numel(fieldNames)
    fn = fieldNames{i};
    val = os.(fn);
    if ~isempty(val)
        if ischar(val)
            fprintf(fid, '%s: %s\n', fn, val);
        else
            if isnumeric(val)
                fprintf(fid, '%s: %f\n', fn, val);
            else
                fprintf(fid, '%s: ???\n', fn);
            end
        end
    end
end
fprintf(fid, '\n');

[x, fval, exitflag, output] = fsolve(@segmentationError, x0, os);
fprintf(fid, 'x = [%f', x(1));
for i = 2:numel(x)
    fprintf(fid, ', %f', x(i)); 
end
fprintf(fid, ']\n');
fprintf(fid, 'fval = %f\n', fval);
fprintf(fid, 'exitflag = %d\n', exitflag);


fieldNames = fieldnames(output);
for i = 1:numel(fieldNames)
    fn = fieldNames{i};
    val = output.(fn);
    if ~isempty(val)
        if ischar(val)
            fprintf(fid, 'output.%s: %s\n', fn, val);
        else
            if isnumeric(val)
                fprintf(fid, 'output.%s: %g\n', fn, val);
            else
                fprintf(fid, 'output.%s: ???\n', fn);
            end
        end
    end
end
fclose(fid);
fprintf('Wrote file %s\n', filename);
end


function s = pad2(intgr)
    if intgr < 10
        s = sprintf('0%d', intgr);
    else
        s = sprintf('%d', intgr);
    end
end
