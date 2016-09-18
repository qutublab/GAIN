%update the parameter values when the user opens a parameter file

function [editBoxes_new, hSliders_new] = updateControlPanel(editBoxes, oneParameterArr, h, hSliders)

for i=numel(oneParameterArr):-1:2
    %     editBoxes_new(i)=createEditBox(h,i,oneParameterArr(i),[leftMargin bottom editBoxWidth editBoxHeight],[leftMargin+editBoxWidth+horizontalSpace bottom textBoxWidth textBoxHeight]);
    %     bottom=bottom+(editBoxHeight+verticalSpace);
    set(editBoxes(i), 'string', oneParameterArr(i).value) %update editbox values
    textValue(i-1) = str2num(oneParameterArr(i).value);
    set(hSliders(i-1),'Value', textValue(i-1)) %update slider positions
end

editBoxes_new = editBoxes;
hSliders_new = hSliders;

end

