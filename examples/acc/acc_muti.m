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
% partial model
modelName = 'partial_acc_model';
% uncertain parameter lists
% newGuards.params = {'ngps', 'nenc'};
% newGuards.values = {[1 20], [1 10]};
newGuards.params = {'ngps'};
newGuards.values = {[0 20]};
newGuards.template = {'abs(ngps-nenc)'};
numIn = length(newGuards.params);
% guard tolerance
%tol = 0.5;
tol = 1;
option_plot = 0;
option_resilient_to_nominal = 1;
option_check_mono = 1;
mono = zeros(1, numIn); % store mononicity check results
tStart = tic;
flag = 0; % if no counterexample found for the first testing loop, return a testing cadidate as a resilient model
count = 1;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% ACC case study
% initialize parameters and state variables for simulation
% using the Simulink/StateFlow model
% states values
vl = 26;
d0 = 100;
v0 = 25;
ed0 = 1;
ev0 = 1;
% sensor's parameters
nrad = 0;
%nenc = 0.05;



while flag < 1 
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % initial setup for each casestudy
    bdclose all;
    % create breach interface object with a simulink model
    falsify_obj = BreachSimulinkSystem(modelName);
    
    % print parameters and signals
    falsify_obj.PrintParams();
    falsify_obj.PrintSignals();
    
    % setting input profiles 
    % generate gps and enc attacks as a step input
    ngps_gen = step_signal_gen({'ngps'});
    nenc_gen = constant_signal_gen({'nenc'});
    input_gen = BreachSignalGen({ngps_gen, nenc_gen});
    falsify_obj.SetInputGen(input_gen);
    falsify_obj.SetParam({'ngps_step_base_value','ngps_step_time'}, [0.05 5]);
    falsify_obj.SetParamRanges({'nenc_u0'}, [0 0.05]);
    %falsify_obj.SetParam({'nenc_step_base_value','nenc_step_time'}, [0.05 5]);
    %falsify_obj.SetParam({'nenc_step_base_value','nenc_step_time'}, [0 1]);
    

    input_step_amp = cell(1, numIn); 
    for i = 1:numIn
        input_step_amp{1,i} = strcat(newGuards.params{i},'_step_amp');
    end
    
    % specify the ranges of initial values of state variables
    falsify_obj.SetParamRanges({'d0', 'v0', 'ed0', 'ev0'},[50 100; 10 30; 0 1; 0 1]);

    % set simulation time
    Tsim = 1000; Ts = 0.02; time = 0:Ts:Tsim; t = time';
    falsify_obj.SetTime(t(end));
    
    % specify a safety property
    % dsafe == 5 + v[t], %dref = 10 + 2*(v[t] - ev[t])
    safe_distance = STL_Formula('safe_distance', 'alw d[t] >= 5 + v[t]');
    
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Falsification and resilient model synthesis
    nLoop = 1;
    pos = 1;
    robustness = -1;
    best_value = zeros(1, numIn); % Store counter example values
    
    % run a falsication loop and retrieve a counterexample if exists 
    while robustness < 0 && nLoop < 10
        [falsify_obj, robustness, best_value, mono, newGuards.values, nLoop, flag, option_check_mono] = falsification(falsify_obj,input_step_amp, newGuards.values, safe_distance ...
                                                                   , best_value, tol, mono, nLoop, flag, option_check_mono, option_plot);
    end
    % if the current model has a counterexample, continue generating a new
    % resilient model. Otherwise, exist the loop
    if flag == 0 
        [resilient_model, modelName, pos] = resilient_model_construction(modelName, mono, newGuards, best_value, tol, count, pos, nLoop, option_resilient_to_nominal);
    end
    count = count + 1;   
end

tElapsed=toc(tStart);
fprintf('Total execution time: time %f\n',tElapsed);
open_system([modelName,'.mdl'])


