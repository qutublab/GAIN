function [edit_box, nextActionTextbox,instructionTextbox, hControlPanel,Handles,hSlider,wControlPanel,hgtControlPanel]=createControlPanel(oneParameterArr, buttonLabel,forwardCallbackHandle,backCallbackHandle, saveCallbackHandle, quitCallbackHandle, batchCallbackHandle, parameterCallbackHandle, sliderCallbackHandle,editBoxCallbackHandle)
hControlPanel=figure;
screensize = get( groot, 'Screensize' );%get the user's screen resolution
wScreen = screensize(3); %screen width
hScreen = screensize(4);%screen height

wControlPanel_rel = 0.29;%control panel width relative to the screen (0.27 - 7/6)
hgtControlPanel_rel = 0.82;%control panel height relative to the screen

% wControlPanel = wControlPanel_rel * wScreen;%control panel width in pixels
% hgtControlPanel = hgtControlPanel_rel * hScreen;%control panel height in pixels

%On any PC or Mac, the relative position of the control panel on the screen
%is fixed, since its position is normalized; the relative position of each 
%object on control panel is also fixed, since normalized positions are 
%calibrated on Quentin's laptop
wControlPanel = 396.14; %calibration based on Quentin's laptop ( = wControlPanel_rel * wScreen)
hgtControlPanel = 629.76;%calibration 

%fix the relative position of each object on control panel
format long 
leftMargin=20/wControlPanel;
bottomMargin=10/hgtControlPanel;
pushButtonWidth=160/wControlPanel;
pushButtonHeight=30/hgtControlPanel;
horizontalSpace=20/wControlPanel;
fileNameBoxWidth = 340/wControlPanel; %originally 330 (6/27/16)
editBoxHeight=20/hgtControlPanel;
editBoxWidth=80/wControlPanel;
verticalSpace=19/hgtControlPanel;  %spacing between edit boxes (originally 20) (6/27/16)   %20 to 19 (7/6)
textBoxHeight=20/hgtControlPanel;  
textBoxWidth=240/wControlPanel; % 250
instructionBoxWidth=10/wControlPanel; %instruciton for parameters (90 to 10 - 7/6 to remove the instruction)
buttonGap = 10/hgtControlPanel; %the vertical gap between buttons
sliderGap = 17/hgtControlPanel; %vertical gap below the corresponding edit box
sliderHeight = 15/hgtControlPanel; 


totalwidth = leftMargin*2 + editBoxWidth + horizontalSpace + textBoxWidth + ...
             instructionBoxWidth;% replaced with wControlPanel
         
savepushButtonHandle=uicontrol('Style','pushbutton',...
    'units', 'normalized',...
    'string','Save Current Parameters',...
    'position',[leftMargin bottomMargin pushButtonWidth pushButtonHeight],...
    'callback',saveCallbackHandle);
batchpushButtonHandle=uicontrol('Style','pushbutton',...
    'units', 'normalized',...
    'string','Exit to Batch Processing',...
    'position',[leftMargin+pushButtonWidth+horizontalSpace bottomMargin pushButtonWidth pushButtonHeight],...
    'callback',batchCallbackHandle);
bottom=bottomMargin+pushButtonHeight+buttonGap;
backpushButtonHandle=uicontrol('Style','pushbutton',...
    'units', 'normalized',... 
    'string', char(8592), 'FontSize', 24, ...%8592 - Unicode Dec(HTML)
    'position',[leftMargin bottom pushButtonWidth pushButtonHeight],...
    'callback',backCallbackHandle);
pushButtonHandle=uicontrol('Style','pushbutton',...
    'units', 'normalized',...
    'string', char(8594), 'FontSize', 24, ...%8594 - Unicode Dec(HTML)
    'position',[leftMargin+pushButtonWidth+horizontalSpace bottom pushButtonWidth pushButtonHeight],...
    'callback',forwardCallbackHandle);
bottom=bottom+textBoxHeight+verticalSpace;
% backpushButtonHandle=uicontrol('Style','pushbutton',...
%     'units', 'pixels',... 
%     'string', char(223), 'FontName', 'Wingdings', 'FontSize', 24, ...%223
%     'position',[leftMargin bottom pushButtonWidth pushButtonHeight],...
%     'callback',backCallbackHandle);

% pushButtonHandle=uicontrol('Style','pushbutton',...
%     'units', 'pixels',...
%     'string', char(224), 'FontName', 'Wingdings', 'FontSize', 24, ...%224
%     'position',[leftMargin+pushButtonWidth+horizontalSpace bottom pushButtonWidth pushButtonHeight],...
%     'callback',forwardCallbackHandle);
% bottom=bottom+textBoxHeight+30;

nextActionTextbox=uicontrol('Style','text',...
    'units', 'normalized',...
    'string',sprintf('\n%s',buttonLabel'),...
    'FontWeight', 'bold', ...
    'position',[leftMargin+pushButtonWidth+horizontalSpace bottom pushButtonWidth textBoxHeight*1.5]);


% %Test - 7/5
% nextActionTextbox=axes('Position', [leftMargin+pushButtonWidth+horizontalSpace bottom pushButtonWidth textBoxHeight*1.5],...
%          'Visible',  'on',...
%          'Parent',   hControlPanel);
% text(0,0.5,buttonLabel,'Units','Normalized')


%Instruction text box on the control panel - hide it temporarily (7/6)
bottomInstruction=bottom+textBoxHeight+pushButtonHeight+verticalSpace+(editBoxHeight+verticalSpace)*7;
instructionTextbox=uicontrol('Style','text',... %instruction for each parameter
    'units', 'normalized',...
    'FontSize', 10,...%11.5 - 7/6
    'BackgroundColor', [0.94,0.94,0.94],...
    'HorizontalAlignment','left',...
    'position',[leftMargin+fileNameBoxWidth+horizontalSpace/2 bottomInstruction instructionBoxWidth (textBoxHeight*2+verticalSpace)*2]);
%'string','Open an image file by clicking the right arrow',...%temporary string. Should be changed to parameter descriptions 

backButtonTextbox=uicontrol('Style','text',...
    'units', 'normalized',...
    'string',sprintf('\n%s','Back'),... %Bring the button label down, since there is no vertical alignment in Matlab
    'FontWeight', 'bold', ...
    'position',[leftMargin bottom pushButtonWidth textBoxHeight*1.5]);

bottom=bottom+pushButtonHeight+verticalSpace;
%create edit boxes and sliders
for i=numel(oneParameterArr):-1:4
    edit_box(i)=createEditBox(hControlPanel,i,oneParameterArr(i),[leftMargin bottom editBoxWidth editBoxHeight],[leftMargin+editBoxWidth+horizontalSpace bottom textBoxWidth textBoxHeight],editBoxCallbackHandle);
    hSlider(i-1) = createSlider(hControlPanel,edit_box(i),[leftMargin bottom-sliderGap  editBoxWidth+horizontalSpace+textBoxWidth sliderHeight], sliderCallbackHandle);  
    bottom=bottom+(editBoxHeight+verticalSpace);
end
for i=3:-1:2
    edit_box(i)=createEditBox(hControlPanel,i,oneParameterArr(i),[leftMargin bottom editBoxWidth editBoxHeight],[leftMargin+editBoxWidth+horizontalSpace bottom textBoxWidth*1/2 textBoxHeight], editBoxCallbackHandle);
    hSlider(i-1) = createSlider(hControlPanel,edit_box(i),[leftMargin bottom-sliderGap  editBoxWidth+horizontalSpace+textBoxWidth sliderHeight], sliderCallbackHandle);
    bottom=bottom+(editBoxHeight+verticalSpace);
end
bottom = bottom - verticalSpace/2;
for i= 1:-1:1
    edit_box(i)=createEditBox(hControlPanel,i,oneParameterArr(i),[leftMargin bottom fileNameBoxWidth editBoxHeight],[leftMargin+fileNameBoxWidth+horizontalSpace bottom textBoxWidth textBoxHeight]);
    bottom=bottom+(editBoxHeight+buttonGap);
end

% %create a slider for the first parameter
% for k=(numel(oneParameterArr))-1:-1:1 % one fewer than edit boxes
% hSlider(k) = createSlider(h,edit_box,[leftMargin bottom editBoxWidth editBoxHeight])    
% end
% hSlider = uicontrol('Style', 'slider',...
%      'position', [leftMargin, bottomInstruction+verticalSpace+2, editBoxWidth+horizontalSpace+textBoxWidth, 15],...
%      'Min',0,'Max',10,'Value',1,...
%      'callback',sliderCallbackHandle);

quitButtonHandle=uicontrol('Style','pushbutton',...
    'units', 'normalized',...
    'string','Quit',...
    'position',[leftMargin+pushButtonWidth+horizontalSpace bottom pushButtonWidth pushButtonHeight],...
    'callback',quitCallbackHandle);

parameterButtonHandle=uicontrol('Style','pushbutton',...
    'units', 'normalized',...
    'string','Open Parameters File',...
    'position',[leftMargin bottom pushButtonWidth pushButtonHeight],...
    'callback',parameterCallbackHandle);




% set(hControlPanel, 'Position', [30, 40, totalwidth, bottom+pushButtonHeight+buttonGap])
set(hControlPanel, 'units', 'normalized', 'Position', [0.01 0.06 wControlPanel_rel hgtControlPanel_rel]);%Auto resize the window to fit the user's screen
Handles = {savepushButtonHandle,parameterButtonHandle,quitButtonHandle,backpushButtonHandle,pushButtonHandle,batchpushButtonHandle};    
end