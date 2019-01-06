function [compo] = getComponent(model,name)
    compo = model.find('-isa', 'Stateflow.State','-and','Name',name);
end