% Returns 0 if targetStr is not in strCellArr; otherwise returns an index
% of an element of strCellArr containing targetStr.
function mid = strBinarySearch(targetStr, strCellArr)
lo = 1;
hi = numel(strCellArr);
mid = round((lo + hi) / 2);
s = strCellArr{mid};
cmp = mystrcmp(targetStr, s);
while cmp ~= 0
    if cmp < 0
        % targetStr is before midpoint
        hi = mid - 1;
    else
        % targetStr is after midpoint
        lo = mid + 1;
    end
    if lo > hi
        break;
    end
    mid = round((lo + hi) / 2);
    s = strCellArr{mid};
    cmp = mystrcmp(targetStr, s);
end
if cmp ~= 0
    mid = 0;
end
end