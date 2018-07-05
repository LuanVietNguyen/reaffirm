function [transition] = addTransition(chart, src, dest, label, srcO, dstO )
    % adds a new transition with a label and a source/destination clock angle
    transition = Stateflow.Transition(chart);
    transition.Source = src;
    transition.Destination = dest;
    transition.LabelString = label;
    transition.SourceOClock = srcO;
    transition.DestinationOClock = dstO;
end