% Returns 1 when pixels share a side and returns 0 when they share a corner
% Assumes pixels are adjacent.  Arguments p1 and p2 are linear indices of two
% pixels, and argument sz is the size of the image
function s = isSideAdjacent(p1, p2, sz)
numRows = sz(1);
diff = abs(p1 - p2);
if diff == 1 || diff == numRows
    s = true;
else
    if diff == (numRows - 1) || diff == (numRows + 1)
        s = false;
    else
        [R C] = ind2sub(sz, [p1, p2]);
        error('[isSideAdjacent] %d (r=%d,c=%d) and %d (r=%d,c=%d) are not adjacent (numRows=%d)', p1, R(1), C(1), p2, R(2), C(2), numRows)
    end
end
end

