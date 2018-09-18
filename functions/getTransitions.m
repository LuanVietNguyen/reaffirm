function trans = getTransitions(chart)
    if isa(chart,'copyModel')
        trans = chart.trans;
    else  
        trans = chart.find('-isa','Stateflow.Transition');
    end
end