function  [state] = addEmptyState(model, name)
    sA = Stateflow.State(model);
    sA.Name = name;
	sA.Position = [sA.Position(1)+100 sA.Position(2)+100 sA.Position(3) sA.Position(4)]
end