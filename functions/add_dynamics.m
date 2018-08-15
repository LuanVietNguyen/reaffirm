function  [] = add_dynamics(state, flow)
    if ~isempty(state.Label)
        newLabel = [state.Label,10,flow];
        state.Label = newLabel;
    else
        state.Label = ['du:',10,flow];
    end
end