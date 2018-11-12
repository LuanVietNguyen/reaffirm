function obj = input_gen(obj, signals, types)  
    % generate input attacks as a step/pulse/constant/random/pulse_train
    % look at each signal generator script to see the specific parameters
    % needs to be specified
    
    num_sigs = length(signals);
    for i = 1 : num_sigs
        sigs_gen{i} = strcat(signals{i},'_gen');
        switch types{i}
            case 'const'
                % set as constant signal
                sigs_gen{i} = constant_signal_gen(signals{i});
                % default input_variations = {'ngps_u0'}; 
            case 'ramp'
                % set as a ramp signal
                sigs_gen{i} = ramp_signal_gen(signals{i});
                % input_variations = {'ngps_ramp_amp'};
            case 'impulse'
                sigs_gen{i} = impulse_signal_gen({'ngps'});
                % falsify_obj.SetParam({'ngps_base_value', 'ngps_impulse_time', 'ngps_impulse_period'}, [0.05 20 10]);
                % input_variations = {'ngps_impulse_amp'}; 
            case 'pulse_train'
                sigs_gen{i} = pulse_signal_gen({'ngps'});
                % falsify_obj.SetParam({'ngps_base_value', 'ngps_pulse_period'}, [0.05 10]);
                % input_variations = {'ngps_pulse_amp'}; 
            case 'step'
                sigs_gen{i} = step_signal_gen({'ngps'});
                % falsify_obj.SetParam({'ngps_step_base_value','ngps_step_time'}, [0.05 5]);
                % input_variations = {'ngps_step_amp'}; 
            case 'sinusoid'
                % set as constant signal
                sigs_gen{i} = sinusoid_signal_gen({'ngps'});
                % falsify_obj.SetParam({'_sin_amp'}, [0.05 5]);
                % input_variations = {'ngps_sin_offset'}; 
            case 'random'
                % set as constant signal
                sigs_gen{i} = random_signal_gen({'ngps'});
                % falsify_obj.SetParam({'ngps_max'}, 10);
                % input_variations = {'ngps_min'}; 
            otherwise
                'Error';
        end 
    end
    inputs_gen = BreachSignalGen(sigs_gen);
    obj.SetInputGen(inputs_gen);
end