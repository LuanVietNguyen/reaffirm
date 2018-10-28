% this script run the model synthesis using the falsifier of Breach
mono = zeros(1, length(param.names)); % store mononicity check results
robustness  = -1;
nLoop = 1;
termination = false;
best_value = zeros(1, length(param.names)); % Store counter example values
while robustness < 0 && nLoop < maxLoop && termination == false

    [falsify_obj, robustness, best_value, param.values, mono, nLoop, termination] = falsification(falsify_obj, param.names, param.values, safe_distance ...
                                                                   , best_value, tol, mono, guess_mono, nLoop,termination, option_check_mono, option_plot);
end

if nLoop > maxLoop - 1
   disp('Maximum iteration reached, please try another pattern or increase maxLoop\n')
end