% montotony check for robustness values
function sign = monotony(array)
    sign = '';
    if length(array) > 1
        if issorted(array, 'monotonic')
           if max(array) == min(array)
               sign = '=';
           else
               if min(diff(array)) >= 0
                   sign ='<';
               else
                   sign = '>';
               end
           end
        end
    end
end