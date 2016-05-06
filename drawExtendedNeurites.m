function rgb = displayExtendedNeurites(nip, extendedNeurites)

cellBodyMask = nip.getOpenedCellBodyMask();
cellBodyBorder = border(cellBodyMask);
extendedCellBodyBorder = border(nip.getExtendedCellBodyMask());

neuriteMask = nip.getSecondNeuriteMask();
connectedNeuriteMask = imreconstruct(imdilate(cellBodyMask, true(3)), neuriteMask);
unconnectedNeuriteMask = neuriteMask & ~connectedNeuriteMask;

neuriteBorder = border(neuriteMask);
connectedNeuriteBorder = border(connectedNeuriteMask);
unconnectedNeuriteBorder = border(unconnectedNeuriteMask);

extendedNeuritesBorder = border(extendedNeurites);


I = nip.getCellImage();
r = I;
g = I;
b = I;

cellBodyBorder2 = cellBodyBorder | extendedCellBodyBorder;
r(cellBodyBorder2) = 1;
g(cellBodyBorder2) = 0;
b(cellBodyBorder2) = 0;


r(neuriteBorder) = 0;
g(neuriteBorder) = 1;
b(neuriteBorder) = 0;

r(extendedNeuritesBorder) = 0;
g(extendedNeuritesBorder) = 0;
b(extendedNeuritesBorder) = 1;

rgb = cat(3, r, g, b);

end

function B = border(M)
B = M & ~imerode(M, true(3));
end
