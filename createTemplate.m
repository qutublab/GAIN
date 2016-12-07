
function createTemplate
%create the name of the output file name
outputfile = 'templates.tif';

%check if the file already exists
if exist(outputfile) == 2
    delete(outputfile) 
end
%load all the character templates
characters = dir('*bmp');
n = length(characters);

for k = 1:n

I = imread(characters(k).name);
I = imcomplement(I);
I = I == 255;

%row = x coord. ; colummn = y coord.
[row,column] = find(I == 1);
toplim = min(row); %top limit
bottomlim = max(row);
leftlim = min(column);
rightlim = max(column);

Ic = I(toplim:bottomlim, leftlim:rightlim);%cropped image
imwrite(Ic, outputfile, 'tif', 'WriteMode','append')
% figure
% imshow(Ic)

% figure
% imshow(I)
end


end