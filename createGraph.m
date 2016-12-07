
% This is an amended version of newcreategraph7. Changed so that after ring
% removal, neurites are extended to tuj bodies.

%function G = createGraph(mask, endPoints, branchPoints, cellNumberGrid, maxSpurLength)
function G = createGraph(mask, branchPoints, endPoints, cellNumberGrid, maxSpurLength)

skeleton = mask;

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
if numel(R) > 0
    fprintf('%d branch points with %d or more branch point neighbors\n', numel(R), lim-10);
end

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
% r = skeleton;
% g = skeleton;
% b = skeleton;
% r(branchPoints) = false;
% g(branchPoints) = true;
% b(branchPoints) = false;
%figure, imshow(double(cat(3, r,g,b))), title('Branch Points');

%result = input('***');
%error('***');

%fprintf('[createGraph] Starting findEdges\n');
tstartFindEdges = tic;
%[edgeStack vertexLocations] = findEdges2(skeleton, branchPoints, endPoints);
[edges vertexLocations maxEdgesPerVertexPair]= findEdges2(skeleton, branchPoints, endPoints);
%fprintf('[createGraph] findEdges2 elapsed time: %f\n', toc(tstartFindEdges));


%fprintf('[createGraph] edgeStack1 contains %d edges\n', edgeStack.size);
%fprintf('[createGraph] edgeStack1 contains %d edges\n', numel(edges));

%fprintf('[createGraph] Calling NeuriteGraph constructor\n');
%tic;
%G = NeuriteGraph(edgeStack.toCellArray(), vertexLocations, cellNumberGrid, size(mask), skeleton, maxSpurLength);
%G = NeuriteGraph(edges, vertexLocations, cellNumberGrid, size(mask), skeleton, maxSpurLength);
G = NewNeuriteGraph(edges, vertexLocations, cellNumberGrid, size(mask), skeleton, maxSpurLength, maxEdgesPerVertexPair);
%toc;
%fprintf('[createGraph] Finished\n');

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
fprintf('%d branch points with 5 or more neighbors\n', numel(R));

numRows = size(S, 1);
numCols = size(S, 2);
r = S;
g = S;
b = S;
r(branchPoints) = 0;
g(branchPoints) = 0;
rgb = cat(3, r, g, b);
delta = 3;
for i = 1:numel(R)
   rLo = max(1, R(i)-delta);
   rHi = min(numRows, R(i)+delta);
   cLo = max (1, C(i)-delta);
   cHi = min(numCols, C(i)+delta);
   rgbSmall = rgb(rLo:rHi, cLo:cHi,:);
   figure, imshow(rgbSmall, 'InitialMagnification', 'fit')
   title(sprintf('r=%d c=%d', R(i), C(i)));
end

% neighbor5Plus = occupiedNeighborCount >= 5;
% fprintf('%d occupied points with 5 or more neighbors\n', numel(find(neighbor5Plus)));

end
