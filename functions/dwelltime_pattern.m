function dwelltime_pattern(chart, clock)
    % add dwelltime
    states = chart.find('-isa','Stateflow.State');
    numOfStates = length(states);

    add_clock(chart, clock.name)
    for i = 1: numOfStates
        add_clock_flow(states(i), clock.name)
    end

    trans = chart.find('-isa','Stateflow.Transition');
    numOfTrans = length(trans);

    for i = 1: numOfTrans
        if ~isempty(trans(i).Source)
            add_trans_label(trans(i), ' && ', clock.guard_template)
        end
        add_variable_update(trans(i), clock.update_template)
    end
end

function  [] = add_clock(chart, clockName)
    add_variables(chart, clockName, 'Local', 'CONTINUOUS');
end


function  [] = add_clock_flow(state, clockName)
    add_dynamics(state, [clockName,'_dot = 1;'])
end



