function [resilient_model, originalStateNames] = model_synthesis(partial_model, newGuards, pos)
    
    % Reference: http://blogs.mathworks.com/seth/2010/01/21/building-models-with-matlab-code/
    % Reference: http://www.mathworks.com/help/stateflow/api/quick-start-for-the-stateflow-api.html
    load_system([partial_model,'.mdl']);
    rt = sfroot;
    resilient_model = rt.find('-isa','Simulink.BlockDiagram');
    chart = resilient_model.find('-isa', 'Stateflow.Chart');
   
    % add new states in resilient model
    [states, stateNames, copyStates, copyStateNames, numOfStates] = copy_states(chart, pos);
    if pos == 1
        originalStateNames = stateNames;
    end
    % copy trasitions of nominal model to resilient model
    copy_transitions(chart, copyStates, copyStateNames, pos);
    
    % add new transitions based on counterexample
    add_new_guards(chart, states, copyStates, numOfStates, newGuards);
    
    % fix dynamic by ignoring unsafe parameters 
    fix_dynamics(copyStates, numOfStates, newGuards);
    %save model file
    slsf_model_path = [partial_model,'_resilient.mdl'];
    sfsave(resilient_model.Name, slsf_model_path);
end

function  [oldStates, stateNames, copyStates, copyStateNames, numOfStates] = copy_states(chart, pos)
    state = chart.find('-isa','Stateflow.State');
    numOfStates = length(state);
    stateNames = strings(numOfStates,1);
    
    oldStates = cell(numOfStates,1);
    copyStates = cell(numOfStates,1);
    copyStateNames = strings(numOfStates,1);
    
    
    % add new states into resilient model
    for i = 1: numOfStates
        stateNames(i) = state(i).Name;
        oldStates{i} = state(i);
        copyStates{i} = Stateflow.State(chart);
        copyStates{i}.Position =  [state(i).Position(1) state(i).Position(2) + 300*pos state(i).Position(3) state(i).Position(4)];
        copyStates{i}.Label = state(i).Label;
        copyStateNames(i) = strcat(stateNames(i),'_Resilient');
        copyStates{i}.Name = copyStateNames(i);
    end
end


function  [] = copy_transitions(chart, copyStates, copyStateNames, pos)
    trans = chart.find('-isa','Stateflow.Transition');
    numOfTrans = length(trans);
    copyTrans = cell(numOfTrans-1,1);
    % store source and destination states
    srcTrans = cell(numOfTrans-1,1);
    destTrans = cell(numOfTrans-1,1);
    % ignore initial transition
    k = 0;
    for i = 1: numOfTrans
        if isempty(trans(i).Source)
            k = i - 1;
        else
            k = k + 1;
            for j = 1: length(copyStateNames)
                if [trans(i).Source.Name,'_Resilient'] == copyStateNames(j)
                    srcTrans{k} = copyStates{j};
                end
                if [trans(i).Destination.Name,'_Resilient'] == copyStateNames(j)
                    destTrans{k}  = copyStates{j};
                end
            end  
            copyTrans{k} = addTransition(chart, srcTrans{k}, destTrans{k}, trans(i).LabelString, trans(i).SourceOClock, trans(i).DestinationOClock);
            posTL = trans(i).LabelPosition;
            posTL(2) = posTL(2) + 300*pos;
            copyTrans{k}.LabelPosition = posTL;
        end
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



