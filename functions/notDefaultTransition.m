function out = notDefaultTransition(t)
    out = false;
    if ~isempty(t.Source)
        out = true;
    end
end