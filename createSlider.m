%Version 9/10/16
function handleSlider=createSlider(h,edit_box,pSlider,sliderCallbackHandle,oneParameter)
h;
if strcmp(edit_box.Enable, 'on')
    enbl='on';
else
    enbl='off';
end
textValue = str2num(get(edit_box,'String'));%get the default parameter value
handleSlider = uicontrol('Style', 'slider',...
    'Units', 'normalized',...
    'position',pSlider,...
    'Enable',enbl,...
    'callback',sliderCallbackHandle);
%'position', [leftMargin, bottomInstruction+verticalSpace+2, editBoxWidth+horizontalSpace+textBoxWidth, 15],...

if oneParameter.subtype == NumericSubtype.POSITIVE
    set(handleSlider, 'Min',realmin('single'), 'Max',20, 'Value',textValue) % 'SliderStep', [0.01,0.10] by default
elseif oneParameter.subtype == NumericSubtype.POSITIVE_INTEGER
   set(handleSlider, 'Min',realmin('single'), 'Max',20, 'SliderStep',[0.05 0.05],'Value',textValue)%step = 1
elseif oneParameter.subtype == NumericSubtype.POSITIVE_LE1
    set(handleSlider, 'Min',realmin('single'), 'Max',1 ,'Value',textValue)% 'SliderStep', [0.01,0.10] by default
elseif oneParameter.subtype == NumericSubtype.NONNEGATIVE_INTEGER
    set(handleSlider, 'Min', 0 , 'Max',20, 'SliderStep',[0.05,0.05], 'Value',textValue)
else 
    error('This parameter subtype is unkown.')
end

% oneParameter.subtype == NumericSubtype.POSITIVE

end