function [transition] = addDefaultTransition(model, name)
	sA = getComponent(model, name);
    dt = Stateflow.Transition(sA);
	dt.Destination = sA;
	dt.DestinationOClock = 0;
	xsource = sA.Position(1)+sA.Position(3)/2;
	ysource = sA.Position(2)-30;
	dt.SourceEndPoint = [xsource ysource];
	dt.MidPoint = [xsource ysource+15];
end