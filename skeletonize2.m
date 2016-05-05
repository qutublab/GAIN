
% This is an amended version of newcreategraph7. Changed so that after ring
% removal, neurites are extended to tuj bodies.

function S = skeletonize2(neuriteMask, cellBodyMask)  %, cellNumberGrid, numCellBodies)


% Skeletonize mask
S = bwmorph(neuriteMask, 'skel', Inf) & ~cellBodyMask;


% Remove pocket pixels from skeletonization
S2 = double(S);
% Once was not enough, so do it twice
for i = 1:2
    h = [1 1 0; 1 1 -1; 1 1 0];
    for r = 1:4
        Sf = imfilter(S2, h);
        S2 = S2 - (Sf == 6);
        h = rot90(h);
    end
end
% Reskeltonize
S = bwmorph(S2 == 1, 'skel', Inf);





% Remove unrecognized branch points
S2 = double(S);
h = [1 1 -1; 1 1 -1; 1 -1 -1];
for r = 1:4
    Sf = imfilter(S2, h);
    S2 = S2 - (Sf == 5);
    h = rot90(h);
end
h = [-1 1 1; -1 1 1; -1 -1 1];
for r = 1:4
    Sf = imfilter(S2, h);
    S2 = S2 - (Sf == 5);
    h = rot90(h);
end
% Reskeltonize
S = bwmorph(S2 == 1, 'skel', Inf);
mask = S;
% Sometimes branchpoints outside of S are found take conjunction with S
branchPoints = bwmorph(S, 'branchpoints') & S;

% De-recognize unnecessary branch points
h = [-1 -1 -1; -1 10 -1; -1 10 10];
h2 = [1 1 1; -1 10 -1; 0 0 0];
for i = 1:4
    unnecessaryBranch = (imfilter(double(branchPoints), h) == 30) & (imfilter(double(mask), h2) == 11);
    branchPoints = branchPoints & ~unnecessaryBranch;
    h = rot90(h);
    h2 = rot90(h2);
end
h = [-1 -1 -1; -1 10 -1; 10 10 -1];
h2 = [1 1 1; -1 10 -1; 0 0 0];
for i = 1:4
    unnecessaryBranch = (imfilter(double(branchPoints), h) == 30) & (imfilter(double(mask), h2) == 11);
    branchPoints = branchPoints & ~unnecessaryBranch;
    h = rot90(h);
    h2 = rot90(h2);
end

displayProblemPoints(S, branchPoints);
return;



% Remove pocket points
% perhaps a generalization of the above
S2 = double(S);
h = [0 1 0; 1 1 -1; 0 1 0];
for r = 1:4
    Sf = imfilter(S2, h);
    S2 = S2 - (Sf == 4);
    h = rot90(h);
end
% Reskeltonize
S = bwmorph(S2 == 1, 'skel', Inf);
%figure, imshow(S((749-3):(749+3), (435-3):(435+3)), 'InitialMagnification', 'fit'), title('r=749 c=435');


mask = S;


% The mask argument is a neurite skeleton, and the cellBodyMask argument is
% a mask of cell bodies.  In order to find where the neurite skeleton ends
% at a cell body, dilate the cell body mask.



mh = MaskHandle(double(mask));


mask = bwmorph(mask, 'skel', Inf);
skeleton = mask;
endPoints = bwmorph(mask, 'endpoints') & mask;
branchPoints = bwmorph(mask, 'branchpoints') & mask;




common = endPoints & branchPoints;
assert(~any(common(:)), 'Overlapping end points and branch points');
epIdx = find(endPoints);
bpIdx = find(branchPoints);
% vIdx maps vertex numbers to linear indices to locate vertices
vIdx = [epIdx; bpIdx];

%red = imdilate(skeleton, true);
%green = red;
%blue = red;
%v = false(size(red));
%v(vIdx) = true;
%v = imdilate(v, true(3));
%red(v) = false;
%green(v) = true;
%blue(v) = false;
%figure, imshow(double(cat(3,red,green,blue))), title('Final Skeleton');

bp = branchPoints & mask;
lim = 14;
contact = imfilter(double(bp), [1 1 1; 1 10 1; 1 1 1]) >= lim;
[R, C] = find(contact);
fprintf('%d branch points with %d or more branch point neighbors\n', numel(R), lim-10);

if size(R, 1) > 0
    
    for b = 1:size(R, 1)
        r = R(b);
        c = C(b);
        
        rgb = makeRGB(mask, branchPoints, endPoints);
        
    end
    result = input('*****');
    error('***');
end


sz = size(mask);


%legs = skeleton & ~branchpoints
%legs = imdilate(legs, true(3));
r = skeleton;
g = skeleton;
b = skeleton;
r(branchPoints) = false;
g(branchPoints) = true;
b(branchPoints) = false;
%figure, imshow(double(cat(3, r,g,b))), title('Branch Points');

%result = input('***');
%error('***');

fprintf('[newcreategraph7] Starting findEdges\n');
[edgeStack vertexLocations] = findEdges(skeleton, branchPoints, endPoints);
fprintf('[newcreategraph7] edgeStack1 contains %d edges\n', edgeStack.size);

fprintf('[newcreategraph7] Calling NeuriteGraph constructor\n');
tic;
G = NeuriteGraph(edgeStack.toCellArray(), vertexLocations, cellNumberGrid, size(mask), ringVertices, skeleton);
toc;

end


function rgb = makeRGB(skel)
branchPoints = bwmorph(skel, 'branchpoints');
endPoints = bwmorph(skel, 'endpoints');

red = zeros(size(skel));
green = zeros(size(skel));
blue = zeros(size(skel));

% Yellow neurites
red(skel) = 1;
green(skel) = 1;
blue(skel) = 0;

% Blue branch points
red(branchPoints) = 0;
green(branchPoints) = 0;
blue(branchPoints) = 1;

% Cyan end points
red(endPoints) = 0;
green(endPoints) = 1;
blue(endPoints) = 1;


rgb = double(cat(3, red, green, blue));
end

function displayProblemPoints(S, branchPoints)
S = double(S);
mx = max(S(:));
if (mx ~= 1)
    error('[skeletonize.printBranchInfo] maximum is %f\n', mx);
end
neighborCount = imfilter(S, [1 1 1; 1 0 1; 1 1 1]);
branchNeighborCount = neighborCount .* double(branchPoints);
neighbor4 = branchNeighborCount == 4;
neighbor5Plus = branchNeighborCount >= 5;

[R C] = find(neighbor5Plus);
fprintf('%d occupied points with 5 or more neighbors\n', numel(R));

numRows = size(S, 1);
numCols = size(S, 2);
r = S;
g = S;
b = S;
r(branchPoints) = 0;
g(branchPoints) = 0;
rgb = cat(3, r, g, b);
for i = 1:numel(R)
   rLo = max(1, R(i)-2);
   rHi = min(numRows, R(i)+2);
   cLo = max (1, C(i)-2);
   cHi = min(numCols, C(i)+2);
   rgbSmall = rgb(rLo:rHi, cLo:cHi,:);
   figure, imshow(rgbSmall, 'InitialMagnification', 'fit')
   title(sprintf('r=%d c=%d', R(i), C(i)));
end

% neighbor5Plus = occupiedNeighborCount >= 5;
% fprintf('%d occupied points with 5 or more neighbors\n', numel(find(neighbor5Plus)));

end