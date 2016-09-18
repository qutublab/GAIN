%Version - 9.18.2016

function [edit_box, text_box]=createEditBox(h,i,oneParameter,pEdit,pText,editBoxCallbackHandle)
%figure(h);
h;
if oneParameter.active
    enbl='on';
else
    enbl='off';
end
if i < 2
    edit_box=uicontrol('Style','edit',...%editbox showing the image file dir
    'Units', 'normalized',...
    'position', pEdit,...
    'string', oneParameter.value,...
    'HorizontalAlignment', 'right',...
    'Enable',enbl);
    
    
else
    edit_box=uicontrol('Style','edit',...%edit boxes and text boxes for parameters
    'Units', 'normalized',...
    'position', pEdit,...
    'string', oneParameter.value,...
    'Enable',enbl,...
    'callback', {editBoxCallbackHandle, oneParameter.name, oneParameter.subtype, i});
   %Parameter name translator
    switch(oneParameter.name)
        case 'dapiThreshFactor1' %name used by image processor
            nameStr = 'Bright Nuclei Selectivity';%name shown on GUI
        case 'dapiThreshFactor2'
            nameStr = 'Dim Nuclei Selectivity';
        case 'nucleusOpenDiskRadius'
            nameStr = 'Nuclei  Separation Control';
        case 'areaToConvexHullRatio' 
            nameStr = 'Nucleus Cluster Sensitivity';
        case 'medianNucleusAdjustmentFactor' 
            nameStr = 'Single Nucleus Size Control';
        case 'median2MinimumNucleusAreaRatio' 
            nameStr = 'Minimum Acceptable Nucleus Size Control';
        case 'tujThreshFactor1' 
            nameStr = 'Cell Body Selectivity';
        case 'neuriteRemovalDiskRadius'
            nameStr = 'Cell Body/Neurite Discrimination';
        case 'tujThreshFactor2' 
            nameStr = 'Neurite Selectivity';
        case 'tujThreshFactor3'  
            nameStr = 'Secondary Neurite Selectivity';
        case 'tujClosingDiskRadius'
            nameStr = 'Neurite Bridge Length';
        case 'branchResolutionDistance'
            nameStr = 'Branch Resolution Distance';
        
    end

text_box=uicontrol('Style','text',...
    'Units', 'normalized',...
    'position', pText,...
    'TooltipString', oneParameter.description,... %parameter explanation; shows up when mouse hover on the text box
    'string',nameStr,...%temp - 9.18 original: oneParameter.name
    'HorizontalAlignment','left');
oneParameter.description
end  
end