function trans = delTransitions(chart)
    trans = chart.find('-isa','Stateflow.Transition');
	numOfTrans = length(trans);
	for i = 1 : numOfTrans
		trans(i).delete;
	end
end