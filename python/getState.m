function states = getState(chart)
    states = chart.find('-isa','Stateflow.State');
end