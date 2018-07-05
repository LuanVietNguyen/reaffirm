function [chart] = resilient_to_nomial_guards(model, destStatesName, n, guard)
    bdclose all;
    load_system([model,'.mdl']);
    rt = sfroot;
    m = rt.find('-isa','Simulink.BlockDiagram');
    chart = m.find('-isa', 'Stateflow.Chart');
    states = chart.find('-isa','Stateflow.State');
    numOfStates = length(states);
    numOfDestStates = length(destStatesName);  
    srcTrans = cell(numOfDestStates,1);
    destTrans = cell(numOfDestStates,1);
    
    for i = 1: numOfStates
        for k = 1:numOfDestStates
            if strcmp(states(i).Name,destStatesName(k))
                destTrans{k} = states(i);
            end
            if  count(states(i).Name,destStatesName(k)) == 1 && count(states(i).Name,'Resilient') == n 
                srcTrans{k} = states(i);
                srcTrans{k}.Name
            end
        end
    end
    add_new_guards(chart, srcTrans , destTrans, numOfDestStates, guard)  
end