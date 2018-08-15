function  [] = add_trans_label(tran, relation, label)
    if ~isempty(tran.LabelString)
        oldGuard = char(extractBetween(tran.LabelString,'[',']'));
        oldUpdate = char(extractBetween(tran.LabelString,'{','}'));
        newGuard = [oldGuard,relation,label,10,oldUpdate];
        tran.LabelString = newGuard;
    else
        tran.LabelString = ['[', label, ']'];
    end
end