% input: monotonicity values, uncertain parameters and their values
% output: return candidate guards
function guard = guard_inferrence(mono, vars, robustness)
    guard = [vars{1}, inequality_check(mono(1)), num2str(robustness(1))];
    if length(mono) > 1
        for i = 2 : length(mono)
            str = ['||', vars{i}, inequality_check(mono(i)), num2str(robustness(i))];
            guard = strcat(guard, str);
        end
    end
end

function sign = inequality_check(value)
    if value < 0
        sign = '>';
    else
        sign = '<';
    end
end