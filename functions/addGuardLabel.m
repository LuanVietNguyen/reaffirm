function  [] = addGuardLabel(tran, relation, label)
    if ~isempty(tran.LabelString)
        oldGuard = char(extractBetween(tran.LabelString,'[',']'));
        oldUpdate = char(extractBetween(tran.LabelString,'{','}'));
        newGuard  = sprintf('[%s %s %s]\n%s',oldGuard,relation,label,oldUpdate);
        tran.LabelString = newGuard;
    else
        tran.LabelString = sprintf('[%s]',label);
        %tran.LabelString = ['[', label, ']'];
    end
end