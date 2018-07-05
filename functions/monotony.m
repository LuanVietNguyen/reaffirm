% montotony check for robustness values
function mono = monotony(array)
    if issorted(array, 'monotonic')
       if issorted(array, 'ascend')
           mono = 1;
       else
           mono = -1;
       end
    else
        mono = 0;
    end
end