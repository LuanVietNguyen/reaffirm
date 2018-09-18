function  [state] = addState(chart, state)
    sA = Stateflow.State(chart);
    sA.Label = state.Label;
    sA.Name = strcat(state.Name,'_copy');
    sA.Position = [state.Position(1) state.Position(2) + 300 state.Position(3) state.Position(4)];
    state = sA;
end    