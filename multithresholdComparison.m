% Comparsion of double thresholding to multithresholding

function multithresholdComparison()
dirName ='ImagesNoScaleBars';
fileName = {'Combined11.tif', 'Combined12.tif', 'Combined13.tif', ...
    'Combined14170.tif', 'Combined14172.tif', 'Combined14174.tif', ...
    'Combined14176.tif', 'Combined6697.tif', 'Combined6700.tif', ...
    'Combined6706.tif'};

outputFileName = 'multiThreshComparison.csv';

fid = fopen(outputFileName, 'w');

nip = NeuronImageProcessor();
p = Parameters();
p.initialize();
fprintf(fid, 'File,NucThresh1,NucThresh2,CellThresh1,CellThresh2,NucMultiThresh1,NucMultiThresh2,CellMultiThresh1,CellMultiThresh2\n');
for i = 1:numel(fileName)
    p.fileName = [dirName, '/', fileName{i}];
    nip.processForOptimization(p);
    
    C = nip.getCellImage();
    N = nip.getNucleusImage();
    
    nucleusThresh1 = nip.getNucleusThresh1();
    nucleusThresh2 = nip.getNucleusThresh2();
    cellThresh1 = nip.getCellThresh1();
    cellThresh2 = nip.getCellThresh2();
   
    nucleusMultithresh = multithresh(N, 2);
    cellMultithresh = multithresh(C, 2);
    nucleusMultithresh1 = max(nucleusMultithresh);
    nucleusMultithresh2 = min(nucleusMultithresh);
    cellMultithresh1 = max(cellMultithresh);
    cellMultithresh2 = min(cellMultithresh);
    
    fprintf(fid, '%s,%f,%f,%f,%f,%f,%f,%f,%f\n', ...
        fileName{i}, nucleusThresh1, nucleusThresh2, cellThresh1, cellThresh2, ...
        nucleusMultithresh1, nucleusMultithresh2, cellMultithresh1, ...
        cellMultithresh2); 
    
    
    
    if i == 1
        firstRow = 620;  %520;
        lastRow = 940;   %1040;
        firstCol = 100;    %1;
        lastCol = 544;  %694;
%         
%         cm1 = im2bw(C, cellThresh1);
%         cm2 = im2bw(C, cellThresh2);
%         cm1Border = border(cm1);
%         cm2Border = border(cm2);
%         borders = cm1Border | cm2Border;
%         r = C;
%         g = C;
%         b = C;
%         r(borders) = 0;
%         g(borders) = 0;
%         b(borders) = 0;
%         r(cm1Border) = 1;
%         g(cm2Border) = 1;
%         rgb = cat(3, r, g, b);
%         figure, imshow(rgb(firstRow:lastRow, firstCol:lastCol, :));
        
        
        nucleusMultithreshMask1 = im2bw(N, nucleusMultithresh1);
        nucleusMultithreshMask2 = im2bw(N, nucleusMultithresh2);
        
        % Do not use nucleusMultithreshMask2 objects that contain
        % nucleusMultitheshMask1 objects
        
%         contain = imreconstruct(nucleusMultithreshMask1, nucleusMultithreshMask2);
%         nucleusMultithreshMask2 = nucleusMultithreshMask2 & ~contain;
        
        
        cellMultithreshMask1 = im2bw(C, cellMultithresh1);
        cellMultithreshMask2 = im2bw(C, cellMultithresh2);
        
        nmm1Border = border(nucleusMultithreshMask1);
        nmm2Border = border(nucleusMultithreshMask2);
        cmm1Border = border(cellMultithreshMask1);
        cmm2Border = border(cellMultithreshMask2) & ~cmm1Border;
        
        allNucleusBorders = nmm1Border | nmm2Border;
        allCellBorders = cmm1Border | cmm2Border;
        
        rN = N;
        gN = N;
        bN = N;
        rN(allNucleusBorders) = 0;
        gN(allNucleusBorders) = 0;
        bN(allNucleusBorders) = 0;
        gN(nmm2Border) = 1;
        bN(nmm1Border | nmm2Border) = 1;
        
        rC = C;
        gC = C;
        bC = C;
        rC(allCellBorders) = 0;
        gC(allCellBorders) = 0;
        bC(allCellBorders) = 0;
        rC(cmm1Border) = 1;
        gC(cmm2Border) = 1;
        %     bN(cm1Border | cm2Border) = 1;
        
        
        rgbC = cat(3, rC, gC, bC);
        

        
        imwrite(rgbC(firstRow:lastRow, firstCol:lastCol, :), 'sampleMultithresh.tif', 'tif', 'Compression', 'none');
        fprintf('Wrote file sampleMultithresh.tif\n');
        
        
        rgbN = cat(3, rN, gN, bN);
%         figure, imshow(rgbN);
%         figure, imshow(rgbC), title(sprintf('%s  red=multithresh green=doublethresh', fileName{i}));
    end
    
    
end
fclose(fid);
fprintf('Wrote file %s\n', outputFileName);
end


function B = border(M)
B = M & ~imerode(M, true(3));
end
