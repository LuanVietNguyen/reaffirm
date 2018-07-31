function  [] = add_new_guards(chart, oldStates, copyStates, numOfStates, newGuards)
    newTrans = cell(numOfStates,1);
    for  i = 1: numOfStates
        newTrans{i} = addTransition(chart, oldStates{i}, copyStates{i}, char(newGuards.label), 6, 0);
    end
end