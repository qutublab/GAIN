
% Taken from http://www.mathworks.com/matlabcentral/answers/39374-compare-two-strings-based-on-ascii-dictionary-order

% Assumes string arguments do not trailing spaces!

% Returns 0 if a and b are the same string. Returns a negative number if a
% precedes b. Returns a positive number if b precedes a.
function cmp = cstrcmp( a, b )

    % Force the strings to equal length
    x = char({a;b});

    % Subtract one from the other
    d = x(1,:) - x(2,:);

    % Remove zero entries
    d(~d) = [];
    if isempty(d)
        cmp = 0;
    else
        cmp = d(1);
    end

    
    
end
