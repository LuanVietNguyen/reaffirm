function [chart] = getChartByName(diagram,name)
    chart = diagram.find('-isa', 'Stateflow.Chart','-and','Name',name);
end