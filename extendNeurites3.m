

% Rethreshold area defined by extended cell bodies without the cell bodies
% themselves

function extensions = extendNeurites3(nip, neuriteMask, cellBodyMask, extendedCellBodyMask, dilationSide)
tstart0 = tic;
% brdr = (cellBodyMask & ~imerode(cellBodyMask, true(3))) | (extendedCellBodyMask & ~imerode(extendedCellBodyMask, true(3)));
% r = nip.getCellImage();
% r(brdr | neuriteMask) = 0;
% g = r; b = r;
% r(brdr) = 1;
% g(neuriteMask) = 1;
% figure, imshow(cat(3, r, g, b))

% figure, imshow(double(cat(3, cellBodyMask, neuriteMask, extendedCellBodyMask & ~cellBodyMask)));
% title('red: cell body,  green: neurite,  blue: extended cell body');

cellBodyHalo = extendedCellBodyMask & ~cellBodyMask;

% Connect all neurites inside the halo to the cell body


% Locate neurites wholly contained in the extended cell body mask and
% touching the cell body
outsideNeurites = neuriteMask & ~extendedCellBodyMask;
insideNeurites = neuriteMask & ~imreconstruct(outsideNeurites, neuriteMask);
insideConnectedNeurites = imreconstruct(imdilate(cellBodyMask, true(3)), insideNeurites);
cellBodyInsideNeurites = cellBodyMask | insideConnectedNeurites;
cellBodyInsideNeuriteBorders = cellBodyInsideNeurites & ~imerode(cellBodyInsideNeurites, true(3));


%% Find neurites that at least abut the extended cell body mask but do not
%% touch the cell body mask
%
%outerNeurites = neuriteMask & imdilate(extendedCellBodyMask, true(3));
%neuritesTouchingCellBody = imreconstruct(imdilate(cellBodyMask, true(3)), outerNeurites);
%outerNeurites = outerneurites & ~neuritesTouchingCellBody;

% Label pixels just outside of extended cell body mask
[labeledECBM numLabels] = bwlabel(extendedCellBodyMask);
labeledECBMFringe = zeros(size(labeledECBM));
for i = 1:numLabels
    M = (labeledECBM == i);
    fringe = imdilate(M, true(3)) & ~M;
    labeledECBMFringe(fringe) = i;
end

% Find neurites that end at the extended cell body mask

% Find neurites inside extended cell body reachable from fringe/border of
% extended cell bodyMask
insideNeurites = neuriteMask & imdilate(extendedCellBodyMask, true(3));
marker = imdilate(extendedCellBodyMask, true(3)) & ~imerode(extendedCellBodyMask, true(3));
% Source neurites are inside neurites that start at fringe/border
sourceNeurites = imreconstruct(marker, insideNeurites);
% Source neurites do not already touch cell body
cellBodyNeurites = imreconstruct(imdilate(cellBodyMask, true(3)), insideNeurites);
sourceNeurites = sourceNeurites & ~cellBodyNeurites;

% figure, imshow(double(cat(3, extendedCellBodyMask, neuriteMask&~sourceNeurites, sourceNeurites)));
% title('red: extended cell body,  green: neurites,  blue: source neurites');


% Use just the border pixels
sourceNeurites = sourceNeurites & ~imerode(sourceNeurites, true(3));

% b(sourceNeurites) = 1;
% figure, imshow(cat(3, r, g, b));

% Identify neurite sections at the edge and inside the extended cell body mask
neuritesAtECB = neuriteMask & imdilate(extendedCellBodyMask, true(3));
% Determine which sections actually enter the extended cell body mask
neuritesInsideMask = imreconstruct(extendedCellBodyMask, neuritesAtECB);
connectedNeurites = imreconstruct(imdilate(cellBodyMask, true(3)), neuriteMask);
% Keep the neurite fringe sections that do not enter into the extended cell
% body mask
neuriteFringe = neuritesAtECB & ~neuritesInsideMask;
%neuriteFringe = neuritesAtECB & ~connectedNeurites;

% figure, imshow(double(cat(3,neuritesInsideMask, connectedNeurites, neuriteMask)));
% title('red: neuritesInsideMask  g: connectedNeurites  b: neuriteMask');


% r = extendedCellBodyMask;
% g = neuriteMask;
% b = neuriteFringe;
% rgb = double(cat(3, r, g, b));
% figure, imshow(rgb), title('blue: neuriteFringe');


% [fringeLabels numFringeLabels] = bwlabel(neuriteFringe);
[fringeLabels numFringeLabels] = bwlabel(sourceNeurites);
impliedNeurites = false(size(neuriteMask));

et0 = toc(tstart0);

et1a = 0;
et1b = 0;
et1c = 0;
et1d = 0;
et1e = 0;
et1f = 0;
et1g = 0;
et1h = 0;
et1i = 0;
et1j = 0;
et1k = 0;
et2 = 0;
% fringeExtent maps neurite fringe to area of its extent
fringeExtent = zeros(numFringeLabels, 1);
for i = 1:numFringeLabels
tstart1 = tic; 
    fringeMask = fringeLabels == i;
et1a = et1a + toc(tstart1);
    
    extent = imreconstruct(fringeMask, neuriteMask);
et1b = et1b + toc(tstart1);
    extentArea = sum(double(extent(:)));
et1c = et1c + toc(tstart1);
    
    % Find fringe midpoint (r1, c1);
    [fringeR fringeC] = find(fringeMask);
et1d = et1d + toc(tstart1);
    [fringeCentroidR fringeCentroidC] = centroid(fringeR, fringeC);
et1e = et1e + toc(tstart1);

    [~, idx] = closest(fringeCentroidR, fringeCentroidC, fringeR, fringeC);
et1f = et1f + toc(tstart1);

    r1 = fringeR(idx);
et1g = et1g + toc(tstart1);

    c1 = fringeC(idx);
et1h = et1h + toc(tstart1);
    
    % Find the extended cell body mask adjacent to the neurite fringe
    ecbmFringe = labeledECBMFringe(fringeMask);
et1i = et1i + toc(tstart1);

%     ecbmLabel = ecbmFringe(1);
    k = find(ecbmFringe);
et1j = et1j + toc(tstart1);

    if isempty(k)
        % Neurite is not on fringe so ignore it
        ecbmLabel = 0;
    else
        ecbmLabel = ecbmFringe(k(1));
    end
et1k = et1k + toc(tstart1);

    
    % Find the cell body point inside the extended cell body that is
    % closest to the fringe midpoint
    cellBodyBordersInECBM = cellBodyInsideNeuriteBorders & (labeledECBM == ecbmLabel);
    if any(cellBodyBordersInECBM(:))
tstart2 = tic;        
        [I2 J2] = find(cellBodyBordersInECBM); % Border pixels of cell body
        [~, idx] = closest(r1, c1, I2, J2);
        r2 = I2(idx);
        c2 = J2(idx);
        
        % Draw a line between (and exclusive of) the points including
        % (r1, c1) and (r2, c2); hence the end points touch neither the
        % neurite nor the cell body.
        [R C] = graphLine(r1, c1, r2, c2);
        Idx = sub2ind(size(cellBodyMask), R, C);
        oneImpliedNeurite = false(size(cellBodyMask));
        oneImpliedNeurite(Idx) = true;
        % It is possible for the point in the fringe (r1, c1) to have
        % another fringe pixel between it and the cell body halo.  Remove
        % such pixels from the neurite.
        oneImpliedNeurite = oneImpliedNeurite & ~fringeMask;
        
        % Keep only those implied neurites that: a) have centerlines wholly
        % within the cell body halo and b) have (dilated) areas less than
        % the areas of the neurites that the connect to.
        % areas of the neurites that they connect to; and b) are wholly
        % contained in the cell body halo
        outsideHalo = oneImpliedNeurite & ~cellBodyHalo;
        if ~any(outsideHalo(:))
            % Thicken the implied neurite and restrict it to the space
            % between the cell body and the extended cell body.
            oneImpliedNeurite = imdilate(oneImpliedNeurite, true(dilationSide)) & cellBodyHalo; 
            % Use the implied neurite if the neurite to which it connects
            % is significantky large
            oneImpliedNeuriteArea = sum(double(oneImpliedNeurite(:)));
            if oneImpliedNeuriteArea < (2 * extentArea) 
                impliedNeurites = impliedNeurites | oneImpliedNeurite;
            end
        end
et2 = et2 + toc(tstart2);
    end
end

impliedNeurites = impliedNeurites & ~neuriteMask;

extensions = impliedNeurites;
fprintf('[extendNeurites] et0=%f\n', et0);
fprintf('[extendNeurites] et1a=%f\n', et1a);
fprintf('[extendNeurites] et1b=%f\n', et1b);
fprintf('[extendNeurites] et1c=%f\n', et1c);
fprintf('[extendNeurites] et1d=%f\n', et1d);
fprintf('[extendNeurites] et1e=%f\n', et1e);
fprintf('[extendNeurites] et1f=%f\n', et1f);
fprintf('[extendNeurites] et1g=%f\n', et1g);
fprintf('[extendNeurites] et1h=%f\n', et1h);
fprintf('[extendNeurites] et1i=%f\n', et1i);
fprintf('[extendNeurites] et1j=%f\n', et1j);
fprintf('[extendNeurites] et1k=%f\n', et1k);
fprintf('[extendNeurites] et2=%f\n', et2);
end


% Returns the pair of points from (I1,J1) and (I2,J2) that have the
% shortest distance between them.
function [r1 c1 r2 c2] = findClosest(I1, J1, I2, J2)
[d2Arr idx2Arr] = arrayfun(@(i1, j1)closest(i1, j1, I2, J2), I1, J1);
[~, idx1] = min(d2Arr);
r1 = I1(idx1);
c1 = J1(idx1);
idx2 = idx2Arr(idx1);
r2 = I2(idx2);
c2 = J2(idx2);
end



% Returns minimum squared distance between point (i1,j1) and a point in
% (I2,J2). The index of the point in (I2,J2) is also returned.
function [d2 idx] = closest(i1, j1, I2, J2)
d2Arr = arrayfun(@(i2, j2)(i1-i2)^2 + (j1-j2)^2, I2, J2);
[d2 idx] = min(d2Arr);
end

function [r c] = centroid(R, C)
r = sum(R(:)) / numel(R);
c = sum(C(:)) / numel(R);
end



% Graph line between (but not including) points (r1,c1) and (r2,c2);
function [R C] = graphLine(r1, c1, r2, c2)
% Walk along row or column, whichever has the greater range
if abs(r1 - r2) >= abs(c1 - c2)
    sgn = sign(r2 - r1);
    R = (r1+sgn):sgn:(r2-sgn);
    % Use point-slope formula: y = mx + b;
    m = (c2 - c1) / (r2 - r1);
    b = c1 - (m * r1);
    C = round((R * m) + b);
else
    sgn = sign(c2 - c1);
    C = (c1+sgn):sgn:(c2-sgn);
    % x = my + b;
    m = (r2 - r1) / (c2 - c1);
    b = r1 - (m * c1);
    R = round((C * m) + b);
end
end


