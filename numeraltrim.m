% Trim leading and trailing (after the decimal point) zeros

function s = numeraltrim(s)
s = strtrim(s);
sz = numel(s);

% Find last leading zero
i = 1;
while s(i) == '0' && i <= sz
    i = i + 1;
end

% If the string is all zeros or the leading zeros do not precede a non-zero
% digit, then leave one leading zero; otherwise ignore all of them
if i > sz || isempty(strfind('123456789', s(i)))
    first = max(1, i-1);
else
    first = i;
end

decimalIndex = strfind(s, '.');

if isempty(decimalIndex)
    last = sz;
else
    decimalIndex = decimalIndex(end);

    % Find first trailing zero starting from the right
    i = sz;
    while s(i) == '0' && i >= 1
        i = i - 1;
    end

    % if the trailing zeros are after a decimal point, then remove them
    % leaving one trailing zero if they immediateky follow a decimal point 
    if i == decimalIndex 
        last = min(sz, i + 1);
    else
        last = i;
    end
end

s = s(first:last);

end
