classdef Tree < handle
properties
node
value
expanded = false;
childArr = Tree.empty
end

methods
function t = Tree(node, varargin)
    if nargin == 0
        return;
    end
    t.node = node;
    for i = numel(varargin):-1:1
        if isa(varargin{i}, 'Tree')
            t.childArr(i) = varargin{i};
        else
            error('[Tree] %dth argument is not a tree', (i+1));
        end
    end
end

function n = numChildren(t)
    n = numel(t.childArr);
end

function n = getNode(t)
    n = t.node;
end

function v = getValue(t)
    v = t.value;
end

function setValue(t, v)
    t.value = v;
end

function expanded = isExpanded(t)
    expanded = t.expanded;
end

function setExpanded(t, expanded)
    t.expanded = expanded;
end

function c = getChild(t, i)
    c = [];
    if i >= 0 && i <= t.numChildren()
        c = t.childArr(i);
    else
        error('[Tree.getChild] Tree does not have %d children', i)
    end
end

function setChild(t, i, c)
    if i <= 0
        error('[Tree.setChild] Unexpected index: %d', i);
    end
    if isa(c, 'Tree')
        t.childArr(i) = c;
    else
        error('[Tree.setChild] Child argument is not a Tree object');
    end
end

function lf = isLeaf(t)
    lf = isempty(t.childArr);
end

function d = depth(t)
    if isempty(t.childArr)
        d = 1;
    else
        d = 1 + max(arrayfun(@depth, t.childArr));
    end
end

function count = numLeaves(t)
    if isempty(t.childArr)
        count = 1;
    else 
        count = sum(arrayfun(@numLeaves, t.childArr));
    end
end


% Sequence of nodes leading to each leaf
function pathCA = getLeafPaths(t)
    pathCA = cell(t.numLeaves(), 1);
    pathCAIndex = 1;
    % Allocate array to hold sequence of node values representing a path
    path(t.depth()) = t.node;
    depthFirstTraversal(t, 1);

    function depthFirstTraversal(tr, currDepth)
        path(currDepth) = tr.node;
        if isempty(tr.childArr)
            % A leaf has been reached, store path in pathCA
            pathCA{pathCAIndex} = path(1:currDepth);
            pathCAIndex = pathCAIndex + 1;
        else
            for i = 1:tr.numChildren()
                depthFirstTraversal(tr.getChild(i), currDepth+1);
            end
        end

    end

end


end  % methods


end  % classdef
