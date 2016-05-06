% The beginning of a comment is indicated by a percent character - even if
% it occurs within a string
function s = stripComment(s)
k = strfind(s, '%');
if ~isempty(k)
    commentStart = k(1);
    if commentStart == 1
        s = '';
    else
        s = s(1:(commentStart - 1));
    end
end
end