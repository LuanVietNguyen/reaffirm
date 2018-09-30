function    python2matlab(pythonPath, resilient_pattern, original_model, resilient_script)
    %py.tomatlab.main()
    systemCommand = ['python ', [pythonPath,'tomatlab.py  '], resilient_pattern, ' ',original_model, ' ', resilient_script];
    system(systemCommand);
end

