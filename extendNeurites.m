
% conncet neurites inside halo to cell body
% 
% find point closest to average fringe point
% find neurites touching cell body that do not reach extended cell body border
% 
% extendedCellBodyFringe = imdilate(extendedCellBodyMask, true(3)) & ~extendedCellBodyMask
% neuritesTouchingCellBody imreconstruct(imdilate(cellBodyMask, true(3)). neuriteMask)
% neuritesAtFringe = imreconstruct(extendedCellBodyFringe, neuriteMask)
% neuritesInsideHalo


function extensions = extendNeurites(nip, neuriteMask, cellBodyMask, extendedCellBodyMask, dilationSide)


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



% fringeExtent maps neurite fringe to area of its extent
fringeExtent = zeros(numFringeLabels, 1);
for i = 1:numFringeLabels
    
    fringeMask = fringeLabels == i;
    
  
    
    extent = imreconstruct(fringeMask, neuriteMask);
    extentArea = sum(double(extent(:)));
    
    % Find fringe midpoint (r1, c1);
    [fringeR fringeC] = find(fringeMask);
    [fringeCentroidR fringeCentroidC] = centroid(fringeR, fringeC);
    [~, idx] = closest(fringeCentroidR, fringeCentroidC, fringeR, fringeC);
    r1 = fringeR(idx);
    c1 = fringeC(idx);
    
    % Find the extended cell body mask adjacent to the neurite fringe
    ecbmFringe = labeledECBMFringe(fringeMask);
%     ecbmLabel = ecbmFringe(1);
    k = find(ecbmFringe);
    if isempty(k)
        % Neurite is not on fringe so ignore it
        ecbmLabel = 0;
    else
        ecbmLabel = ecbmFringe(k(1));
    end
    
%    if i == 22
%%         b(cellBodyInsideNeuriteBorders) = 1;
%        b(fringeMask) = 1;
%        figure, imshow(cat(3, r, g, b));
%        sum(double(fringeMask(:)))
%        ecbmFringe
%        figure, imshow(fringeMask)
%    end
    

    
    % Find the cell body point inside the extended cell body that is
    % closest to the fringe midpoint
    cellBodyBordersInECBM = cellBodyInsideNeuriteBorders & (labeledECBM == ecbmLabel);
    if any(cellBodyBordersInECBM(:))
        
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
    end
end

impliedNeurites = impliedNeurites & ~neuriteMask;

extensions = impliedNeurites;
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


