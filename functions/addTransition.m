function [transition] = addTransition(chart, src, dest, label, srcO, dstO )
    % adds a new transition with a label and a source/destination clock angle
	% src and dest can be a state or the name of a state
	if isstring(src) || ischart(src)
		srcState = getComponent(chart, src);
	else 
		srcState = src;
	end
	if isstring(dest) || ischart(dest)
		destState = getComponent(chart, dest);
	else 
		destState = dest;	
	end
    if nargin > 3
        transition = Stateflow.Transition(chart);
        transition.Source = srcState;
        transition.Destination = destState;
        if ~contains(label, '[')
            transition.LabelString = strcat('[',label,']');
        else
            transition.LabelString = label;
        end
    end
    if nargin > 4
        transition.SourceOClock = srcO;
        transition.DestinationOClock = dstO;
    else
        transition.SourceOClock = 6;
        transition.DestinationOClock = 0;
    end
end