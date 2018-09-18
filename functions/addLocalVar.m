function  var = addLocalVar(chart, name)
    %  create local variables in SLSF model
    var = addVariable(chart, name, 'Local');
end