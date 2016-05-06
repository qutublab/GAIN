function nucleusImageFile=get_image(hObject,callbackdata)
n=NeuronImageProcessor;
[FileName, PathName]=uigetfile('*.*','Select the Neuron Image File');
nucleusImageFile=strcat(PathName,FileName);
n.readNucleusFile(nucleusImageFile);
if isempty(n.readNucleusFile(nucleusImageFile))
    disp(nucleusImageFile);
else
    errordlg('The File selected is not an Image File','File Error');
end
figure
imshow(nucleusImageFile)
end