function [edit_box nextActionTextbox,instructionTextbox, h,Handles]=createControlPanel(oneParameterArr, buttonLabel,forwardCallbackHandle,backCallbackHandle, saveCallbackHandle, quitCallbackHandle, batchCallbackHandle, parameterCallbackHandle)
h=figure;
leftMargin=10;
bottomMargin=10;
pushButtonWidth=130;
pushButtonHeight=30;
horizontalSpace=20;
fileNameBox = 330;
editBoxHeight=20;
editBoxWidth=60;
verticalSpace=20;  %spacing between edit boxes
textBoxHeight=20;  %spacing between text boxes
textBoxWidth=250;
totalwidth = leftMargin + editBoxWidth + horizontalSpace + textBoxWidth;
savepushButtonHandle=uicontrol('Style','pushbutton',...
    'units', 'pixels',...
    'string','Save Current Parameters',...
    'position',[leftMargin bottomMargin pushButtonWidth pushButtonHeight],...
    'callback',saveCallbackHandle);
batchpushButtonHandle=uicontrol('Style','pushbutton',...
    'units', 'pixels',...
    'string','Exit to Batch Processing',...
    'position',[leftMargin+pushButtonWidth+horizontalSpace bottomMargin pushButtonWidth pushButtonHeight],...
    'callback',batchCallbackHandle);
bottom=bottomMargin+pushButtonHeight+verticalSpace;
backpushButtonHandle=uicontrol('Style','pushbutton',...
    'units', 'pixels',... 
    'string', char(223), 'FontName', 'Wingdings', 'FontSize', 24, ...
    'position',[leftMargin bottom pushButtonWidth pushButtonHeight],...
    'callback',backCallbackHandle);
% pushButtonHandle=uicontrol('Style','pushbutton',...
%     'units', 'pixels',...
%     'string',buttonLabel,...
%     'position',[leftMargin+pushButtonWidth+horizontalSpace bottom pushButtonWidth pushButtonHeight],...
%     'callback',forwardCallbackHandle);
pushButtonHandle=uicontrol('Style','pushbutton',...
    'units', 'pixels',...
    'string', char(224), 'FontName', 'Wingdings', 'FontSize', 24, ...
    'position',[leftMargin+pushButtonWidth+horizontalSpace bottom pushButtonWidth pushButtonHeight],...
    'callback',forwardCallbackHandle);
bottom=bottom+textBoxHeight+30;

nextActionTextbox=uicontrol('Style','text',...
    'units', 'pixels',...
    'string',buttonLabel,...
    'position',[leftMargin+pushButtonWidth+horizontalSpace bottom pushButtonWidth textBoxHeight*2]);
bottomInstruction=bottom+textBoxHeight+pushButtonHeight+verticalSpace*2+(editBoxHeight+verticalSpace)*7;
instructionTextbox=uicontrol('Style','text',... %instruction for each parameter
    'units', 'pixels',...
    'string',buttonLabel,...
    'position',[leftMargin+editBoxWidth+horizontalSpace+1/2*textBoxWidth bottomInstruction textBoxWidth*1/2 textBoxHeight*2+verticalSpace]);
backButtonName=uicontrol('Style','text',...
    'units', 'pixels',...
    'string','Back',...
    'position',[leftMargin bottom pushButtonWidth textBoxHeight]);

bottom=bottom+pushButtonHeight+verticalSpace;

for i=numel(oneParameterArr):-1:4
    edit_box(i)=createEditBox(h,i,oneParameterArr(i),[leftMargin bottom editBoxWidth editBoxHeight],[leftMargin+editBoxWidth+horizontalSpace bottom textBoxWidth textBoxHeight]);
    bottom=bottom+(editBoxHeight+verticalSpace);
end
for i=3:-1:2
    edit_box(i)=createEditBox(h,i,oneParameterArr(i),[leftMargin bottom editBoxWidth editBoxHeight],[leftMargin+editBoxWidth+horizontalSpace bottom textBoxWidth*1/2 textBoxHeight]);
    bottom=bottom+(editBoxHeight+verticalSpace);
end
for i= 1:-1:1
    edit_box(i)=createEditBox(h,i,oneParameterArr(i),[leftMargin bottom fileNameBox editBoxHeight],[leftMargin+fileNameBox+horizontalSpace bottom textBoxWidth textBoxHeight]);
    bottom=bottom+(editBoxHeight+verticalSpace);
end


quitButtonHandle=uicontrol('Style','pushbutton',...
    'units', 'pixels',...
    'string','Quit',...
    'position',[leftMargin+pushButtonWidth+horizontalSpace bottom pushButtonWidth pushButtonHeight],...
    'callback',quitCallbackHandle);

parameterButtonHandle=uicontrol('Style','pushbutton',...
    'units', 'pixels',...
    'string','Open Parameters File',...
    'position',[leftMargin bottom pushButtonWidth pushButtonHeight],...
    'callback',parameterCallbackHandle);

 
set(h, 'Position', [100, 100, totalwidth, bottom+pushButtonHeight+verticalSpace]);
Handles = {savepushButtonHandle,parameterButtonHandle,quitButtonHandle,backpushButtonHandle,pushButtonHandle,batchpushButtonHandle};    
end