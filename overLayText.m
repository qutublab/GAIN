

function rgb = overLayText(rgb, text, location, charHeight, color)
% size is a resizing factor
% color = rgb values
%location = [row, col]

location = round(location);

row = location(1);
col = location(2);

n = length(text);
for k = 1:n
    c = text(k);

    if c>='0' && c<='9'
        index = c+1-'0';
    elseif c>='A' && c<='Z'
        index = c+11-'A';
    elseif c>='a' && c<='z' %convert lower case letters to upper case
        index = c+11-'a';
    else
        error('[overLayText] Unexpected text character: %s', c)
    end
    
    character = imread('templates.tif',index);
    [orgHeight, orgWidth] = size(character);
    scale = charHeight/orgHeight;
    character = imresize(character,scale);
    [height, width] = size(character);
    
    cr  = character*color(1);
    cg  = character*color(2);
    cb  = character*color(3);
    
%     if row-height+1 < 1 
%        cr = cr((end-row+1):end, :);
%        cg = cg((end-row+1):end, :);
%        cb = cb((end-row+1):end, :);
%        height = row;
%     end
%     rgbWidth = size(rgb,2);
%     if col+width-1 > rgbWidth 
%         fprintf('here\n')
%        cr = cr(:, 1:(rgbWidth-col+1));
%        cg = cg(:, 1:(rgbWidth-col+1));
%        cb = cb(:, 1:(rgbWidth-col+1));
%        width = rgbWidth-col+1;
%     end
%     rgb((row-height+1):row, col:(col+width-1), 1) = cr;
%     rgb((row-height+1):row, col:(col+width-1), 2) = cg;
%     rgb((row-height+1):row, col:(col+width-1), 3) = cb;

if row-height+1 < 1
    character = character((end-row+1):end, :);
    height = row;
end
rgbHeight = size(rgb,1);
rgbWidth = size(rgb,2);
if col+width-1 > rgbWidth
    %fprintf('here\n')
    character = character(:, 1:(rgbWidth-col+1));
    width = rgbWidth-col+1;
end
[orgRow,orgCol] = ind2sub(size(character), find(character==1));
% orgInd = find(character==1);%linear indices of the freground pixels in the character maask
    rgbArea = rgbHeight*rgbWidth;
    rRow = orgRow+row-height;
    rCol = orgCol+col-1;
    
    rInd = sub2ind([rgbHeight, rgbWidth], rRow,rCol);%linear indices of charactrer pixels on 1st layer(red)
    gInd = rInd + rgbArea;
    bInd = gInd + rgbArea;
    rgb(rInd) = 1*color(1);
    rgb(gInd) = 1*color(2);
    rgb(bInd) = 1*color(3);
    
    
    col = col + width + max(round(4*scale),1);
    
end


end
