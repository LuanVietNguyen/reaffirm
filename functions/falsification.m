function [obj, robustness, best_value, mono, inputValues, nLoop, flag, option_check_mono] = falsification(obj, inputName,inputValues, spec, best_value, tol, mono, nLoop, flag, option_check_mono, option_plot)
    numIn = length(inputName);
    % Create falsification object
    for i = 1:numIn
        obj.SetParamRanges({inputName(i)},inputValues{i})
    end
    falsify_pb = FalsificationProblem(obj, spec);
    % chose optimization solver, see falsify_pb.list_solvers()
    falsify_pb.setup_solver('cmaes');
    falsify_pb.max_time = 30;
    % retrieve violated parameter value
    falsify_pb.solve();
    robustness = falsify_pb.obj_best();
    for i = 1:numIn
        idx = strcmp(falsify_pb.params, inputName{1,i}); 
        best_value(i) = falsify_pb.x_best(idx);
    end
    if option_check_mono == 1 %% 
        for i = 1:numIn
            % mono(i) = obj.ChecksMonotony(spec, inputName(i), inputValues{i});
            mono_obj = obj.copy();
            figure
            mono_obj.PlotRobustMap(spec, {inputName(i)}, inputValues{i})
            robustness_array = extractfield(mono_obj.P.props_values,'val');
            mono(i) = monotony(robustness_array);
        end
        option_check_mono = 0;
    end
    for i = 1:numIn
        if mono(i) > 0 
            inputValues{i}(1) = ceil(best_value(i) + tol);
            best_value(i) = inputValues{i}(1);
        else
            inputValues{i}(2) = floor(best_value(i) - tol);
            best_value(i) = inputValues{i}(2);
        end
    end
    % plot falsified traces
    if option_plot == 1
        if robustness < 0
            obj_result = falsify_pb.GetBrSet_False();
        else
            obj_result = falsify_pb.GetBrSet_Best();
        end
        figure
        obj_result.PlotRobustSat(safe_distance);
        % figure
        % obj_result.PlotSignals({'ngps','d','v','ev', 'ed'}, [], {'LineWidth', 1.3});
    end 
    if robustness > 0 && nLoop == 1
        flag = 1;
    end
    nLoop = nLoop + 1;
end