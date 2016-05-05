classdef Stack < handle
    properties (Access = private)
        contents
        numElements
    end
    
    methods
        function s = Stack(varargin)
            s.contents = [];
            s.numElements = 0;
            for i = 1:nargin
                s.push(varargin{i});
            end
        end
        
        function sz = size(s)
            sz = s.numElements;
        end
        
        function b = empty(s)
            b = isempty(s.contents);
        end
        
        function push(s, value)
            n = Node(value);
            n.next = s.contents;
            s.contents = n;
            s.numElements = s.numElements + 1;
        end
        
        function value = pop(s)
            if s.empty()
                error('Cannot pop an empty stack');
            end
            value = s.contents.value;
            s.contents = s.contents.next;
            s.numElements = s.numElements - 1;
        end
        
        function value = top(s)
            if s.empty()
                error('Empty stack has no top');
            end
            value = s.contents.value;
        end
        
        function value = second(s)
            if s.numElements < 2
                error('Stack has less than 2 items');
            end
            value = s.contents.next.value;
        end
        
        function value = peek(s, n)
            if s.numElements >= n
                c = s.contents;
                for i = 1:n-1
                    c = c.next;
                end
                value = c.value;
            else
               error('[Stack.peek] Stack has %d elements but the %d-th element was requested', s.size(), n); 
            end
        end
        
        function ca = toCellArray(s)
            ca = cell(s.size(), 1);
            idx = 1;
            p = s.contents;
            for i = 1:s.size()
                ca{i} = p.value;
                p = p.next;
            end
        end

        function mutateEach(s, mutator)
            p = s.contents;
            while ~isempty(p)
                mutator(p.value);
                p = p.next;
            end
        end
        
        function s2 = copy(s)
            s2 = Stack();
            s2.numElements = s.size();
            s2.contents = [];
            p = s.contents;
            if ~isempty(p);
                n = Node(p.value);
                n.next = [];
                s2.contents = n;
                last = n;
                p = p.next;
                while ~isempty(p)
                    n = Node(p.value);
                    n.next = [];
                    last.next = n;
                    last = n;
                    p = p.next;
                end
            end
        end
        
    end
    
end
