function copyState = getCopyState(chart,state)
    copyState = state;
    copyStateName = strcat(state.Name,'_copy');
    states = getStates(chart);
    for i = 1: length(states)
        if strcmp(states(i).Name, copyStateName)
           copyState = states(i);
        end
    end
end