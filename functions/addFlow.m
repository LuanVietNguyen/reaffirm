function  [] = addFlow(mode, flow)
    if ~isempty(mode.Label)
        newLabel = sprintf('%s\n%s;',mode.Label,flow);
        mode.Label = newLabel;
    else
        mode.Label = sprintf('du:\n%s',flow);
    end
end