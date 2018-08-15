function [resilient_model, modelName, pos] = resilient_model_construction(modelName, mono, newGuards, flowPattern, best_value, tol, count, pos, nLoop, option_resilient_to_nominal, clock)
    % construct a final resilient model
    newGuards.label = guard_inferrence(mono, newGuards, best_value);
    bdclose all;
    if pos == 1
        [resilient_model, originalStateNames] = model_synthesis(modelName, newGuards,flowPattern, pos);
    else
        [resilient_model] = model_synthesis(modelName, newGuards,flowPattern, pos);
    end
    modelName = resilient_model.Name;
    pos = pos*(pos + 1);
    % add guard from resilient to normial modes based on robustness values 
    if nLoop > 1 && option_resilient_to_nominal
        backGuards.params = newGuards.params;
        backGuards.template = newGuards.template;
        backGuards.label = guard_inferrence((-1)*mono, newGuards, best_value + tol);
        [chart] = resilient_to_nomial_guards(modelName, originalStateNames, count, backGuards);
        if clock.on > 0
            dwelltime_pattern(chart, clock)
        end
        sfsave(modelName);
    end
end