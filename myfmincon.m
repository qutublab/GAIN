function myfmincon()

fprintf('[myfmincon] Make sure that segmentationError output is appropriate!\n\n');

c = int16(clock());

p = Parameters();
p.initialize();
x0 = p.toVector();

% Create matrix A and column vector b to describe constraints.  Each parameter
% is constrained to be less than or equal to twice its initial value.  The 
% areaToConvexHullRatio parameter is further constrained to be less than or
% equal to 1.

p2 = Parameters();
p2.assignFromVector(2 * x0);
% Rectify method forces areaToConvexHullRatio to be less than or equal to 1.
p2.rectify();
b = p2.toVector();
% Make b a column vector
b = b(:);
A = eye(numel(b));

% Add constraints that each parameter is not negative, i.e. the negation of
% each parameter is less than or equal to 0.
b2 = zeros(size(b));
A2 = -A;

b = [b; b2];
A = [A; A2];

% In order to specify algorithm using optimset, must also provide Aeq, beq, lb,
% ub, and nonlcon arguments
Aeq = zeros(1, numel(x0));
beq = 0;
lb = zeros(size(x0));
ub = b(1:numel(x0));
nonlcon = @mycon;


year = sprintf('%d', c(1));
month = pad2(c(2));
day = pad2(c(3));
hour = pad2(c(4));
minute = pad2(c(5));
dateStr = sprintf('%s%s%s%s%s', year, month, day, hour, minute);

filename = sprintf('minNImP4-fmincon-%s.txt', dateStr);
fid = fopen(filename, 'w');
fprintf(fid, '%s-%s-%s %s:%s\n\n', year, month, day, hour, minute);
fprintf(fid, 'Initial Parameters: %s\n\n', p.toString());

fprintf(fid, 'Parameter Constraints\n');
for i = 1:numel(b)
    fprintf(fid, '%s ', trimDecimal(b(i)));
end
fprintf(fid, '\n\n');




os = optimset('Display', 'iter', 'MaxIter', 1000, 'MaxFunEvals', 10000, 'Algorithm', 'active-set');
%os = optimset();

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

[x, fval, exitflag, output] = fmincon(@segmentationError, x0, A, b, Aeq, beq, lb, ub, nonlcon, os);
fprintf(fid, 'x = [%f', x(1));
for i = 2:numel(x)
    fprintf(fid, ', %f', x(i)); 
end
fprintf(fid, ']\n');
fprintf(fid, 'fval = %f\n', fval);
fprintf(fid, 'exitflag = %d\n', exitflag);
fprintf(fid, 'output.iterations = %d\n', output.iterations);
fprintf(fid, 'output.funcCount = %d\n', output.funcCount);
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

function [c ceq] = mycon(x)
    c = [];
    ceq = [];
end
