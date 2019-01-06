function out = isHighGuard(guard, lowvars)
    out = true;
    if ~isempty(guard)
        elements = strsplit(guard,{'!','||','<','>','>=','<=','==','&&',' ','+','-','*','/','(',')'});
        if ~isempty(intersect(elements,lowvars))
            out = false;
        end
    end
end