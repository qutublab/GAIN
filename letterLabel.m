function lbl = letterLabel(n)
letter = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
lbl = '';
while n > 0
    n = n - 1;
    r = rem(n, 26);
    lbl = strcat(char('A' + r), lbl);
    n = floor(n / 26);
end
end