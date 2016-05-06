function repairEndPoints(skel, endPoints)
exploreDist = 5;
[R C] = find(endPoints);
numEndPoints = numel(R);
table = cell(numEndPoints);
imgHandle = uint16(double(skel));
% In order to mark pixels as being visited without having to reset the
% visited pixels, use an increasing value held in variable thr.  For the
% first walk, set visited pixels to the value 2 -- only locations holding
% values greater than 0 and less than 2 can be visited  After the walk is
% complete, do not reset pixel values, instead visit only those pixels with
% values greater than 0 and less than 3 where visited locations
% are then set to 3.
thr = 1;
explored = cell(numEndPoints, 1);
for i = 1:numel(R)
    ri = R(i);
    ci = C(i);
    if isempty(explored(i))
        explored(i) = explore(ri, ci, imgHandle, exploreDist, thr);
    end
    thr = thr + 1;
    for j = (i+1):numel(R)
        rj = R(j);
        cj = C(j);
        dist = sqrt((ri - rj)^2 + (ci - cj)^2);
        qj = 

    end
end


end

function q = explore(startR, startC, imgHandle, distance, thr)
sqrt2 = sqrt(2);
numRows = size(imgHandle.image, 1);
numCols = size(imgHandle.image, 2);
q = PriorityQueue();
% Use the distance yet to be traveled as each pixel's priority
q.enqueue([startR, startC], distance);
while q.size() > 0 && q.firstPriority > 0
    [location dist] = q.dequeue();
    r = location(1);
    c = location(2);
    neighborR = [r-1, r-1, r-1, r, r, r+1, r+1];
    neighborC = [c-1, c, c+1, c-1, c+1, c-1, c, c+1];
    inBounds = neighborR >= 1 & neighborR <= numRows & neighborC >= 1 & neighborC <= numCols;
    neighborR = neighborR(inBounds);
    neighborC = neighborC(inBounds);
    for i = 1:numel(neighborR)
        ri = neighborR(i);
        ci = neighborC(i);
        n = imageHandle.image(ri, ci);
        if n ~= 0 && n > thr
            % Mark the location as visited by setting it to a value below
            % thr.
            imageHandle.image(ri, ci) = thr - 1;
            if (r == ri || c == ci)
                dist2 = dist - 1;
            else
                dist2 = dist - sqrt;
            end
            q.enqueue([ri, ci], dist2);
        end
    end
    
end
end
