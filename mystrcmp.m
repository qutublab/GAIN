% Returns 0 if s1 and s2 are identical. Returns -1 if s1 precedes s2.
% Returns 1 if s2 precedes s1.
function cmp = mystrcmp(s1, s2)
len1 = numel(s1);
len2 = numel(s2);
cmp = 0;
for i = 1:min(len1, len2)
    cmp = sign(s1(i) - s2(i));
    if cmp ~= 0
        return;
    end
end
% s1 is a prefix of s2 or vice versa
cmp = sign(len1 - len2);
end