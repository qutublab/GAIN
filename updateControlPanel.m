%update the parameter values when the user opens a parameter file

function [editBoxes_new] = updateControlPanel(editBoxes, oneParameterArr, h)
% leftMargin=10;
% bottomMargin=10;
% pushButtonWidth=130;
% pushButtonHeight=30;
% horizontalSpace=20;
% fileNameBox = 330;
% editBoxHeight=20;
% editBoxWidth=60;
% verticalSpace=20;  %spacing between edit boxes
% textBoxHeight=20;  %spacing between text boxes
% textBoxWidth=250;
% totalwidth = leftMargin + editBoxWidth + horizontalSpace + textBoxWidth;
%
% bottom=bottomMargin+pushButtonHeight+verticalSpace;
% bottom=bottom+textBoxHeight+15;
% bottom=bottom+pushButtonHeight+verticalSpace;

for i=numel(oneParameterArr):-1:2
    %     editBoxes_new(i)=createEditBox(h,i,oneParameterArr(i),[leftMargin bottom editBoxWidth editBoxHeight],[leftMargin+editBoxWidth+horizontalSpace bottom textBoxWidth textBoxHeight]);
    %     bottom=bottom+(editBoxHeight+verticalSpace);
    set(editBoxes(i), 'string', oneParameterArr(i).value)
end
editBoxes_new = editBoxes;

end

