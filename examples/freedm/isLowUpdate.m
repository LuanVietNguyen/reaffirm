function out = isLowUpdate(update, lowvars)
    out = false;
    if ~isempty(update)      
        elements = strsplit(update,{';', ','});
        if ~isempty(elements)
            for i = 1:length(elements)
                asig = strsplit(elements{i},{' ','+','-','*','/','(',')'});
                for j = 1:length(asig) - 1
                    if ~isempty(intersect(asig(j),lowvars)) && strcmp(asig(j+1),'=')
                        out = true;
                        break
                    end
                end
            end
        end
    end
end