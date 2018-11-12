% update the parameter to a constant with synthesize value
synthesized_values = best_value - mono*tol;
bdclose all;
load_system(resModelName);
root = sfroot;
for i = 1: length(synthesized_values)
    tmp_SFData = root.find('-isa','Stateflow.Data','Name',param.names{i});
    tmp_SFData.Scope = 'constant';
    tmp_SFData.Props.InitialValue = num2str(synthesized_values(i));
end
save_system(resModelName)