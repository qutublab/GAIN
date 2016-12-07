
%version 11/1/16

%create data table on a figure window in the interaction mode on GUI
function [dHeader,dataCell] = createDataTable(nip)
%input fHandle is the figure handle

% t = uitable(fHandle);

nbdArr = nip.getCellBodyData();

dHeader = {'Cell Body Label','Cell Body Area','Nucleus Count','Total Nucleus Area',...
    'Minimum Neurite Length','Number of Long Neurites','Neurite Lengths'};

n = numel(nbdArr);
ndbCell = cell(n,1); %each row of the cell contains a mtrix, whcih gives all info about a cell cluster
rowLength = zeros(n,1); %length of each row; initialize
for i = 1:n
   nbd = nbdArr(i);
   nbdCell{i} = [nbd.bodyNumber, nbd.bodyArea, nbd.numberOfNuclei,...
       nbd.totalNucleiArea, nbd.minNeuriteLength,...
       nbd.longNeuriteCount];   
   numLongPaths = numel(nbd.longPaths);
   numShortPaths = numel(nbd.shortPaths);
   numPaths = numLongPaths + numShortPaths;
   neuriteLengths = zeros(numPaths, 1);
   for p = 1:numLongPaths
       neuriteLengths(p) = nbd.longPaths{p}.distance;
   end
   for p = 1:numShortPaths
       neuriteLengths(p + numLongPaths) = nbd.shortPaths{p}.distance;
   end
   neuriteLengths = sort(neuriteLengths, 'descend'); 
   for p = 1:numPaths
      nbdCell{i} = [nbdCell{i}  neuriteLengths(p)];%append neurite lengths to a row
   end
   
   rowLength(i) = length(nbdCell{i});
end
rowLengthMax = max(rowLength);


%make each row vector have same length; use NaN to fill empty spaces
dataMatrix = zeros(n,rowLengthMax); %initialize content matrix
for i = 1:n
 diff = rowLengthMax - rowLength(i);
    if diff > 0       
        nbdCell{i} = [nbdCell{i} nan(1, diff)];
    end
    dataMatrix(i,:) = nbdCell{i}; %merge all rows into one big matrix
end

%Make header and dataCell to have the same length. Fill the tail with NaN
% headerLength = length(dHeader);
% headerDiff = rowLengthMax - headerLength;
% if headerDiff > 0
%     dHeaderFilled = [dHeader num2cell(nan(1, headerDiff))];
% elseif headerDiff < 0
%     fillMat = nan(n,abs(headerDiff));
%     dataMatrix = [dataMatrix,fillMat];
% end


dataCell = num2cell(dataMatrix);%convert data matrix to cell array

%temp
for i = 1:n
dataCell{i,1} =  letterLabel(dataCell{i,1}); %convert number label to letter label e.g. 1=>A
end
nanPosition = cellfun(@(V) any(isnan(V(:))), dataCell);
dataCell(nanPosition) = {' '};%replace all NaN with a blank space
%/temp


% dContent = [dHeaderFilled;dataCell];%full content cell array
% nanPosition = cellfun(@(V) any(isnan(V(:))), dContent);
% dContent(nanPosition) = {' '};%replace all NaN with a blank space


% set(t, 'Data', dataCell, 'Units', 'normalized','Position' , [0,0,1,1], 'RowName', ({}), 'ColumnName',dHeader);


end