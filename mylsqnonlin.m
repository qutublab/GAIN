function mylsqnonlin()

fprintf('[myflsqnonlin] Make sure that segmentationError output is appropriate!\n\n');

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

filename = sprintf('minNImP4-lsqnonlin-%s.txt', dateStr);
fid = fopen(filename, 'w');
fprintf(fid, '%s-%s-%s %s:%s\n\n', year, month, day, hour, minute);
fprintf(fid, 'Initial Parameters: %s\n\n', p.toString());
os = optimset('Display', 'iter-detailed', 'MaxIter', 1000, 'MaxFunEvals', 10000, 'Algorithm', 'levenberg-marquardt');

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
                fprintf(fid, '%s: %g\n', fn, val);
            else
                fprintf(fid, '%s: ???\n', fn);
            end
        end
    end
end
fprintf(fid, '\n');


% Set lower and upper parameter bounds
lb = zeros(size(x0));
ub = Inf(size(x0));
propNames = properties(NumericParameters);
for i = 1:numel(propNames)
    propNm = propNames{i};
    typ = NumericParameters.parameterType(propNm);
    if typ == NumericSubtype.POSITIVE_LE1
        ub(i) = 1;
    end
end

fprintf(fid, 'lower bounds: ');
for i = 1:numel(lb)
    fprintf(fid, '%f ', lb(i));
end
fprintf(fid, '\n');

fprintf(fid, 'upper bounds: ');
for i = 1:numel(ub)
    fprintf(fid, '%f ', ub(i));
end
fprintf(fid, '\n');


[x, resnorm, residual, exitflag, output] = lsqnonlin(@segmentationError, p.toVector, lb, ub, os)
fprintf(fid, 'x = [%f', x(1));
for i = 2:numel(x)
    fprintf(fid, ', %f', x(i)); 
end
fprintf(fid, ']\n');

fprintf(fid, 'resnorm = %f\n', resnorm);
fprintf(fid, 'sumSquares = %f\n', sum(residual .* residual));
fprintf(fid, 'exitflag = %d\n', exitflag);
fprintf(fid, 'output.firstorderopt = %f\n', output.firstorderopt);
fprintf(fid, 'output.iterations = %d\n', output.iterations);
fprintf(fid, 'output.funcCount = %d\n', output.funcCount);
fprintf(fid, 'output.cgiterations = %d\n', output.cgiterations);
%fprintf(fid, 'output.stepsize = %f\n', output.stepsize);
fprintf(fid, 'output.algorithm = %s\n', output.algorithm);
fprintf(fid, 'output.message = %s\n', output.message);
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
