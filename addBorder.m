function rgb = addBorder(I, M, color)
border = M & ~imerode(M, true(5));
if size(I, 3) == 1
    r = I;
    g = I;
    b = I;
else
    r = I(:, :, 1);
    g = I(:, :, 2);
    b = I(:, :, 3);
end
r(border) = color(1);
g(border) = color(2);
b(border) = color(3);
rgb = cat(3, r, g, b);
end