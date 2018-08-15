% Resilient Model Construction using Breach Falsification Tool
% Input: a partial SLSF folder and uncertain parameter values
% Output: a resilient SLSF model
% Requirement: Breach installation
% https://github.com/decyphir/breach
% -------------------------------------------------------------------------
% author: Luan Nguyen
% -------------------------------------------------------------------------

bdclose all;
close all;
clc;
clear;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% ACC case study
% modelName = 'partial_acc_model';
modelName = 'acc_model_new';
% resilient patterns: guard template, flow dynamics modification
guardPattern = struct('params', {{'ngps'}}, 'values', {{[-50 10]}}, 'template', {{'abs(ngps-nenc)'}});
flowPattern = 'nenc';

% clock pattern
clock.on = 1;
clock.name = 'clock';
clock.guard_template = 'clock > 5';
clock.update_template = 'clock = 0';


% initialize parameters and state variables for simulation
% using the Simulink/StateFlow model
% states values
vl = 30; d0 = 50; v0 = 25; ed0 = d0; ev0 = v0;
% sensor's parameters
nrad = 0;


% guard tolerance
tol = 1;
option_plot = 0;
option_resilient_to_nominal = 1;
option_check_mono = 1;
num_input_changes = 1;
mono = zeros(1, num_input_changes); % store mononicity check results
flag = 0; % if no counterexample found for the first testing loop, return a testing cadidate as a resilient model
count = 1;
tStart = tic;
while flag < 1 
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % initial setup for each casestudy
    bdclose all;
    % create breach interface object with a simulink model
    falsify_obj = BreachSimulinkSystem(modelName);
    
    % print parameters and signals
    % falsify_obj.PrintParams();
    % falsify_obj.PrintSignals();
    
    % set simulation time
    Tsim = 50; Ts = 0.01; 
    time = 0:Ts:Tsim; t = time';
    falsify_obj.SetTime(t(end));
    
    
    % setting input profiles 
    nenc_gen = constant_signal_gen({'nenc'});
    
    % generate gps attacks as a step/pulse/constant input   
    ngps_input_type = 'step'; 
    switch ngps_input_type
        case 'const'
            % set as constant signal
            ngps_gen = constant_signal_gen({'ngps'});
            input_gen = BreachSignalGen({ngps_gen, nenc_gen});
            falsify_obj.SetInputGen(input_gen);
            input_variations = {'ngps_u0'}; 
        case 'ramp'
            % set as a ramp signal
            ngps_gen= ramp_signal_gen({'ngps'});
            input_gen = BreachSignalGen({ngps_gen, nenc_gen});
            falsify_obj.SetInputGen(input_gen);
            input_variations = {'ngps_ramp_amp'};
        case 'impulse'
            ngps_gen = impulse_signal_gen({'ngps'});
            input_gen = BreachSignalGen({ngps_gen, nenc_gen});
            falsify_obj.SetInputGen(input_gen);
            falsify_obj.SetParam({'ngps_base_value', 'ngps_impulse_time', 'ngps_impulse_period'}, [0.05 20 10]);
            input_variations = {'ngps_impulse_amp'}; 
        case 'pulse_train'
            ngps_gen = pulse_signal_gen({'ngps'});
            input_gen = BreachSignalGen({ngps_gen, nenc_gen});
            falsify_obj.SetInputGen(input_gen);
            falsify_obj.SetParam({'ngps_base_value', 'ngps_pulse_period'}, [0.05 10]);
            input_variations = {'ngps_pulse_amp'}; 
        case 'step'
            ngps_gen = step_signal_gen({'ngps'});
            input_gen = BreachSignalGen({ngps_gen, nenc_gen});
            falsify_obj.SetInputGen(input_gen);
            falsify_obj.SetParam({'ngps_step_base_value','ngps_step_time'}, [0.05 5]);
            input_variations = {'ngps_step_amp'}; 
        case 'sinusoid'
            % set as sinusoid signal
            ngps_gen = sinusoid_signal_gen({'ngps'});
            input_gen = BreachSignalGen({ngps_gen, nenc_gen});
            falsify_obj.SetInputGen(input_gen);
            falsify_obj.SetParam({'ngps_sin_amp', 'ngps_sin_freq'}, [1 1/(2*pi)]);
            input_variations = {'ngps_sin_offset'}; 
        case 'random'
            % set as a random signal
            ngps_gen = random_signal_gen({'ngps'});
            input_gen = BreachSignalGen({ngps_gen, nenc_gen});
            falsify_obj.SetInputGen(input_gen);
            falsify_obj.SetParam({'ngps_max'}, guardPattern.values{1}(2));
            input_variations = {'ngps_min'}; 
        otherwise
            'Error';
    end 

    falsify_obj.SetParamRanges({'nenc_u0'}, [0 0.05]);
    % specify the ranges of initial values of state variables
    falsify_obj.SetParamRanges({'d0', 'v0', 'ed0', 'ev0'},[90 100; 25 30; 90 100; 25 30]);

    
    % specify a safety property
    % dsafe == 5 + ev[t], %dref = 10 + 2*ev[t]
    safe_distance = STL_Formula('safe_distance', 'alw(d[t] >= 5 + v[t])');
    
%     ACC_Map = falsify_obj.copy();
%     ACC_Map.PlotRobustMap(safe_distance, {'ngps_pulse_amp', 'ngps_pulse_period'}, [-50 50; 5 10]);
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Falsification and resilient model synthesis
    nLoop = 1;
    pos = 1;
    robustness = -1;
    best_value = zeros(1, num_input_changes); % Store counter example values
    % run a falsication loop and retrieve a counterexample if exists 
    while robustness < 0 && nLoop < 10
        [falsify_obj, robustness, best_value, mono, guardPattern.values, nLoop, flag, option_check_mono] = falsification(falsify_obj,input_variations, guardPattern.values, safe_distance ...
                                                                   , best_value, tol, mono, nLoop, flag, option_check_mono, option_plot);
    end
    % if the current model has a counterexample, continue generating a new
    % resilient model. Otherwise, exist the loop
    if flag == 0 
        [resilient_model, modelName, pos] = resilient_model_construction(modelName, mono, guardPattern, flowPattern, best_value, tol, count, pos, nLoop, option_resilient_to_nominal, clock);
    end
    count = count + 1;   
end

tElapsed=toc(tStart);
fprintf('Total execution time: time %f\n',tElapsed);
open_system([modelName,'.mdl'])


