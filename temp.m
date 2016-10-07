function temp()

T = mat2gray(imread('ExampleResults/paramopt-tuj11-tuj.tif'));


disk = strel('disk', 5, 0);

thresh1 = graythresh(T);
C1 = im2bw(T, thresh1);
B1 = imopen(C1, disk);
N1 = C1 & ~B1;

thresh2 = graythresh(T(~C1));
C2 = im2bw(T, thresh2) | C1;
B2 = imopen(C2, disk);
N2 = (C2 & ~B2) | N1;

G = imgradient(T);
threshG = graythresh(G);
E0 = im2bw(G, threshG);
E1 = E0 & ~B2;
EObj = imclose(E1, strel('disk', 3, 0));

EdgeCellBody = imopen(EObj | B1, disk);

NE = EObj & ~EdgeCellBody;


threshG2 = graythresh(G(~(


figure, imshow(T);
rgb = double(cat(3, NE, N2, NE));
figure, imshow(rgb);
end
