function [resilient_model] = model_synthesis(partial_model, newGuards)
    
    % Reference: http://blogs.mathworks.com/seth/2010/01/21/building-models-with-matlab-code/
    % Reference: http://www.mathworks.com/help/stateflow/api/quick-start-for-the-stateflow-api.html
    load_system([partial_model,'.mdl']);
    rt = sfroot;
    resilient_model = rt.find('-isa','Simulink.BlockDiagram');
    chart = resilient_model.find('-isa', 'Stateflow.Chart');
    
    % add new states in resilient model
    [states, copyStates, copyStateNames, numOfStates] = copy_states(chart);
    
    % copy trasitions of nominal model to resilient model
    copy_transitions(chart, copyStates, copyStateNames);
    
    % add new transitions based on counterexample
    add_new_guards(chart, states, copyStates, numOfStates, newGuards);
    
    % fix dynamic by ignoring unsafe parameters 
    fix_dynamics(copyStates, numOfStates, newGuards)

    %save model file
    slsf_model_path = [partial_model,'_resilient.mdl'];
    sfsave(resilient_model.Name, slsf_model_path);
end

function  [state, copyStates, copyStateNames, numOfStates] = copy_states(chart)
    state = chart.find('-isa','Stateflow.State');
    numOfStates = length(state);
    copyStates = cell(numOfStates,1);
    copyStateNames = strings(numOfStates,1);
    
    % add new states into resilient model
    for i = 1: numOfStates
        copyStates{i} = Stateflow.State(chart);
        copyStates{i}.Position =  [state(i).Position(1) state(i).Position(2) + 300 state(i).Position(3) state(i).Position(4)];
        copyStates{i}.Label = state(i).Label;
        copyStateNames(i) = [state(i).Name, '_Resilient'];
        copyStates{i}.Name = copyStateNames(i);
    end
end


function  [] = copy_transitions(chart, copyStates, copyStateNames)
    trans = chart.find('-isa','Stateflow.Transition');
    numOfTrans = length(trans);
    copyTrans = cell(numOfTrans-1,1);
    % store source and destination states
    srcTrans = cell(numOfTrans-1,1);
    destTrans = cell(numOfTrans-1,1);
    % ignore initial transition
    for i = 2: numOfTrans
        for j = 1: length(copyStateNames)
            if [trans(i).Source.Name,'_Resilient'] == copyStateNames(j)
                srcTrans{i-1} = copyStates{j};
            end
            if [trans(i).Destination.Name,'_Resilient'] == copyStateNames(j)
                destTrans{i-1}  = copyStates{j};
            end
        end  
        copyTrans{i-1} = addTransition(chart, srcTrans{i-1}, destTrans{i-1}, trans(i).LabelString, trans(i).SourceOClock, trans(i).DestinationOClock);
        posTL = trans(i).LabelPosition;
        posTL(2) = posTL(2) + 300;
        copyTrans{i-1}.LabelPosition = posTL;
    end
end

function  [] = add_new_guards(chart, states, copyStates, numOfStates, newGuards)
    newTrans = cell(numOfStates,1);
    for  i = 1: numOfStates
        newTrans{i} = addTransition(chart, states(i), copyStates{i}, newGuards.label, 6, 0);
    end
end

function  [] = fix_dynamics(copyStates, numOfStates, newGuards)
    % replace variables in destination states by zeros
    for  i = 1: numOfStates
        oldLabel = copyStates{i}.Label;
        newLabel = oldLabel;
        for j = 1 : length(newGuards.params)
            newLabel = strrep(newLabel,newGuards.params{j},'0');
        end
        copyStates{i}.Label = newLabel;
    end
end


function [transition] = addTransition(chart, src, dest, label, srcO, dstO )
    % adds a new transition with a label and a source/destination clock angle
    transition = Stateflow.Transition(chart);
    transition.Source = src;
    transition.Destination = dest;
    transition.LabelString = label;
    transition.SourceOClock = srcO;
    transition.DestinationOClock = dstO;
end
