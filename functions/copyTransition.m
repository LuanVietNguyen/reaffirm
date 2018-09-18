function [chart] = copyTransition(chart,t, src, dst)
    chart = addTransition(chart, src, dst, t.LabelString, t.SourceOClock, t.DestinationOClock);
end