python2matlab('toy', 'test_model', 'toy_resilient');
eval('toy_resilient');
save_system('test_model','toy_resilient_model.mdl') 

function    python2matlab(resilient_pattern, original_model, resilient_script)
    systemCommand = ['python tomatlab.py ', resilient_pattern, ' ',original_model, ' ', resilient_script];
    system(systemCommand);
end


