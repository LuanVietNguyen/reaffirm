function  [] = addResetLabel(tran, update)
    if ~isempty(tran.LabelString)
        oldUpdate = char(extractBetween(tran.LabelString,'{','}'));
        oldGuard = char(extractBetween(tran.LabelString,'[',']'));
        if ~isempty(oldGuard)
            newGuard  = sprintf('[%s]\n{%s%s;}',oldGuard,oldUpdate, update);
        else
            newGuard  = sprintf('{%s%s;}',oldUpdate, update);
        end
        tran.LabelString =  sprintf('%s',newGuard);
    else
        tran.LabelString = ['{%s;}',update];
    end
end