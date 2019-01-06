% check a non-deducibility information flow 
% input : an SLSF model, a list of low-domain variables
% output: insecure transitions
function out = NonDeducibility(system,lowvars)
    load_system(system);
    root = sfroot;
    diagram = root.find('-isa','Simulink.BlockDiagram');
    model = diagram.find('-isa', 'Stateflow.Chart');
    %orState = model.find('-isa','Stateflow.State','-and','Type','OR');
    states = model.find('-isa','Stateflow.State','-and','Decomposition','EXCLUSIVE_OR','-and','TYPE', 'AND');
    k = 1;
    for i = 1: length(states)
        trans = getTransitions(states(i));
        for j = 1 : length(trans)
            if notDefaultTransition(trans(j))
                %trans(j).LabelString
                %isSecureTran(trans(j), lowvars)
                if ~isSecureTran(trans(j), lowvars)
                   insecure_trans{k} = trans(j);
                   k = k + 1;
                end
            end
        end
    end

    if k > 1
        for i = 1: k-1
            fprintf('Insecure transition: %s\n',insecure_trans{i}.LabelString);
        end  
        out = insecure_trans;
    else
       fprintf('No insecure transition found\n'); 
       out = '';
    end
  
end