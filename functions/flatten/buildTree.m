function t = buildTree(chart)
%BUILDTREE Given a hierarchical SLSF chart, return a tree according to
%Hylink's strategy

% Compute the leaves from a list of all the states. Construct a node for
% each leaf, then for each parent of each leaf, construct nodes and add the
% leaves as children. repeat until we hit the root, which corresponds to
% there being no more states left to encapsulate into nodes.

% careful, this will loop infinitely if there is a cycle in the hierarchy
% graph, i.e. two nodes are each others' parents

t = buildTreeHelper(chart);

    function n = buildTreeHelper(state)

        n = Node(state.Name,decomp(state));
        children = find(chart,'-isa','Stateflow.State');

        for i=1:length(children)
            c = children(i);
            if strcmp(get(state,'Name'),get(c.getParent,'Name'))
                n = n.addChild(buildTreeHelper(c));
            end
        end
    end

    function d = decomp(s)
        if get(s,'Decomposition') == "PARALLEL_AND"
            d = decomp.AND;
        elseif get(s,'Decomposition') == "EXCLUSIVE_OR"
            d = decomp.OR;
        else
            error("something bad happened")
        end
    end
end
