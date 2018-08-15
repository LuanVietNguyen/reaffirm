function  [] = add_variables(chart, name, scope, update)
    %  create local, output, and input variables in SLSF model
    newVar = Stateflow.Data(chart);      
    newVar.Name = name;
    newVar.Scope = scope;
    newVar.Update = update;
end