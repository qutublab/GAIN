function temp(nip)

T = nip.getCellImage();
B = nip.getOpenedCellBodyMask();
N1 = nip.getFirstNeuriteMask();
N2 = nip.getSecondNeuriteMask();
N3 = nip.getThirdNeuriteMask();

figure, imshow(T);

brdrB = B & ~imerode(B, true(3));
brdrN1 = N1 & ~imerode(N1, true(3));
brdrN2 = N2 & ~imerode(N2, true(3));
brdrN3 = N3 & ~imerode(N3, true(3));

r = T; g = T; b = T;

r(brdrB) = 1;
g(brdrB) = 0;
b(brdrB) = 0;

r(brdrN1) = 0;
g(brdrN1) = 1;
b(brdrN1) = 0;

r(brdrN2) = 0;
g(brdrN2) = 0;
b(brdrN2) = 1;

r(brdrN3) = 1;
g(brdrN3) = 0;
b(brdrN3) = 0;

rgb = cat(3, r, g, b);
figure, imshow(rgb);
return;



L = imread('ExampleResults/paramopt-tuj11-longPathSkel.tif');
S = imread('ExampleResults/paramopt-tuj11-shortPathSkel.tif');
C = imread('ExampleResults/paramopt-tuj11-connected.tif');

C2 = C & ~(B | L | S);

rgb = double(cat(3, B | C2, L | C2, S | C2));


figure, imshow(rgb);

%
%T = mat2gray(imread('ExampleResults/paramopt-tuj11-tuj.tif'));
%
%
%disk = strel('disk', 5, 0);
%
%thresh1 = graythresh(T);
%C1 = im2bw(T, thresh1);
%B1 = imopen(C1, disk);
%N1 = C1 & ~B1;
%
%thresh2 = graythresh(T(~C1));
%C2 = im2bw(T, thresh2) | C1;
%B2 = imopen(C2, disk);
%N2 = (C2 & ~B2) | N1;
%
%G = imgradient(T);
%threshG = graythresh(G);
%E0 = im2bw(G, threshG);
%E1 = E0 & ~B2;
%EObj = imclose(E1, strel('disk', 3, 0));
%
%EdgeCellBody = imopen(EObj | B1, disk);
%
%NE = EObj & ~EdgeCellBody;
%
%
%threshG2 = graythresh(G(~(
%
%
%figure, imshow(T);
%rgb = double(cat(3, NE, N2, NE));
%figure, imshow(rgb);
%


end
