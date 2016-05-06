function s = trimDecimal(s)
    if isnumeric(s)
        s = sprintf('%f', s);
    end
    k = strfind(s, '.');
    if numel(k) ~= 1
        return;
    end
    i = numel(s);
    while s(i) == '0'
        i = i - 1;
    end
    if i == k
        % Number had only zeros following the decimal point, so trim decimal
        % point too 
        s = s(1:(i-1));
    else
        s = s(1:i);
    end
end
