classdef Node
    %NODE A simple n-ary tree implementation for flattening Stateflow charts

    properties
        name %name of the state this node represents
        children = {} %can only be nodes
        kind % either AND or OR
    end

    methods
        function obj = Node(n, d)
            obj.name = n;
            obj.kind = d;
        end

        function o = addChild(obj,n)
           o = obj;
           l = obj.children
           l{end+1} = n
           o.children = l;
        end
    end

end
