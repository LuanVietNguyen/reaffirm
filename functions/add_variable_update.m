function  [] = add_variable_update(tran, update)
    if ~isempty(tran.LabelString)
        oldUpdate = char(extractBetween(tran.LabelString,'{','}'));
        oldGuard = char(extractBetween(tran.LabelString,'[',']'));
        if ~isempty(oldGuard)
            newGuard = ['[',oldGuard,']',10,'{', oldUpdate, update,';}'];
        else
            newGuard = ['{', oldUpdate, update,';}'];
        end
        tran.LabelString = newGuard;
    else
        tran.LabelString = ['{', update, ';}'];
    end
end