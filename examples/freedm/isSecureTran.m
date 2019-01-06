function out = isSecureTran(t, lowvars)
    out = true;
    if ~isempty(t.LabelString)
        guard = char(extractBetween(t.LabelString,'[',']'));
        update = char(extractBetween(t.LabelString,'{','}'));
        if isLowUpdate(update, lowvars) && isHighGuard(guard, lowvars)
            out = false;
        end
    end
end