function [transition] = addTransition(chart, src, dest, label, srcO, dstO )
    % adds a new transition with a label and a source/destination clock angle
    if nargin > 3
        transition = Stateflow.Transition(chart);
        transition.Source = src;
        transition.Destination = dest;
        transition.LabelString = label;
    end
    if nargin > 4
        transition.SourceOClock = srcO;
        transition.DestinationOClock = dstO;
    else
        transition.SourceOClock = 6;
        transition.DestinationOClock = 0;
    end
end