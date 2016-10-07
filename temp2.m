function temp2()

dir = 'ExampleResults2';
dir = [dir, '/'];

T = mat2gray(imread([dir, 'paramopt-tuj11-tuj.tif']));
figure, imshow(T);

N3 = imread([dir, 'paramopt-tuj11-thirdneuritemask.tif']);
B = imread([dir, 'paramopt-tuj11-cellbody.tif']);

N3Conn = imreconstruct(imdilate(B, true(3)), N3);

C1 = imclose(N3, true(3));
C2 = imclose(C1, strel('disk', 3, 0));

C3 = imclose(N3, strel('disk', 3, 0));

R2 = imreconstruct(imdilate(B, true(3)), C2);
R3 = imreconstruct(imdilate(B, true(3)), C3);

R23 = imdilate(R2 & ~R3, true(5));
R32 = imdilate(R3 & ~R2, true(5));

r = T; 
r(R23 | R32) = 0;
g = r;
b = r;
r(R23) = 1;
g(R32) = 1;
figure, imshow(cat(3, r, g, b));

r = T;
r(R2 | R3) = 0;
g = r;
b = r;
r(R2) = 1;
g(R3) = 1;
figure, imshow(cat(3, r, g, b));

%figure, imshow(double(cat(3, R2, R3, R2)));
%figure, imshow(imdilate(C, true(1)));

end
