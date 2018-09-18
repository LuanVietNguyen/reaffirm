function states = getStates(chart)
    states = chart.find('-isa','Stateflow.State');
end
