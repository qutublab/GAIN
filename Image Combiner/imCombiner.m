%Combine individual cell bodies images and nuclei images into paired images
function imCombiner
[files,path]=uigetfile('*.*','Image File', 'MultiSelect','on');%import image files

for i = 1:numel(files) 
 im{i} = imread(files{i});%read image files
end

for k = 1:2:numel(files)-1
newName = strcat('stackedImage_', num2str((k+1)/2), '.tif'); %stacked file name
imwrite(im{k}, newName) %first image - cell body 
imwrite(im{k+1}, newName, 'WriteMode','append')%second image - nuclei
end

 end