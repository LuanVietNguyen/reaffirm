% input: monotonicity values, uncertain parameters and their values
% output: return candidate guards
function guard = guard_inferrence(mono, newGuards, robustness)
    guard = '';
    vars = newGuards.params;
    if isempty(newGuards.template)
        guard = [vars{1}, inequality_check(mono(1)), num2str(robustness(1))];
        if length(mono) > 1
            for i = 2 : length(mono)
                if mono(i) < 1
                    str = [' & ', vars{i}, inequality_check(mono(i)), num2str(robustness(i))];
                else
                    str = [' || ', vars{i}, inequality_check(mono(i)), num2str(robustness(i))];
                end
                guard = strcat(guard, str);
            end
        end
        guard = ['[', guard,']'];
    else
        if contains(newGuards.template, 'abs')
            if robustness(1) < 0
                guard =[char(newGuards.template), inequality_check((-1)*mono(1)), num2str(abs(robustness(1)))];
            end
        end
    end
end

function sign = inequality_check(value)
    if value < 1
        sign = ' > ';
    else
        sign = ' < ';
    end
end
