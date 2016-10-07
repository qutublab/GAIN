function temp3()

tstart = tic;
pause(2)
temp4();
et = toc(tstart);
fprintf('[temp3] time: %f\n', et);
end


function temp4()
tstart = tic;
pause(5);
et = toc(tstart);
fprintf('[temp4] time: %f\n', et);
end
