function  newVar = addVariable(chart, name, scope, update)
    %  create local, output, and input variables in SLSF model
    newVar = Stateflow.Data(chart);      
    newVar.Name = name;
    newVar.Scope = scope;
    if nargin > 3
        newVar.Update = update;
    else
        newVar.Update = 'CONTINUOUS';
    end
end