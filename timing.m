function nip = timing()
fileNameCA = strcat('/home/bl6/NeuronImages/GUI/NeuronGUI4b/ImagesNoScaleBars/', ...
    {'paramopt-tuj11.tif', 'paramopt-tuj12.tif', 'paramopt-tuj13.tif', ...
    'paramopt-tuj14190.tif', 'paramopt-tuj14192.tif', ...
    'paramopt-tuj14194.tif', 'paramopt-tuj14198.tif'});
fileName = fileNameCA{1};
%fileName = '/home/bl6/GitHub/CalibrationModel/combined1.tif';
p = Parameters();

% paramFileName = '/home/bl6/GitHub/GAIN-master/tuj11params.txt';
% status = p.readFromFile(paramFileName);
% if ~isempty(status)
%     error('[processImage] Unable to read parameters in file %s', paramFileName)
% end

p.initialize2();
p.fileName = fileName;
%p.tujThreshFactor1 = 0.75;
%p.tujThreshFactor2 = 1.2;
%p.tujThreshFactor3 = 1.5;
%p.branchResolutionDistance = 10;
p.branchResolutionDistance = 15;


p.tujThreshFactor1 = 1;
p.tujThreshFactor2 = 1.2;
p.tujThreshFactor3 = 1.6;
p.branchResolutionDistance = 15;




nip = NeuronImageProcessor();
%nip.showWaitBar(true);
nip.showWaitBar(false);
nip.showTiming(true);

elapsedTime = zeros(numel(fileNameCA), 1);
for i = 1:numel(fileNameCA)
    filename = fileNameCA{i};
    fprintf('(%d/%d) Begin processing %s ...\n', i, numel(fileNameCA), filename);
    p.fileName = filename;
    tstart = tic;
    nip.resetState();
    nip.processImage(p);
    et = toc(tstart);
    elapsedTime(i) = et;
end
fprintf('Mean time: %f\n', mean(elapsedTime));
fprintf('Median time: %f\n', median(elapsedTime));
fprintf('Min time: %f\n', min(elapsedTime));
fprintf('Max time: %f\n', max(elapsedTime));
for i = 1:numel(elapsedTime)
    fprintf('elapsedTime(%d)=%f\n', i, elapsedTime(i));
end
