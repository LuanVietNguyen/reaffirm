% Resilient Model Construction using Breach Falsification Tool
% Input: a partial SLSF folder and uncertain parameter values
% Output: a resilient SLSF model
% Requirement: Breach installation
% https://github.com/decyphir/breach
% -------------------------------------------------------------------------
% author: Luan Nguyen
% -------------------------------------------------------------------------


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% ACC case study
bdclose all; clc; clear all; close all;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% MODEL TRANSFORMATION 
resModelName = model_transformation('pattern3', 'acc_model_new');
tStartE=tic;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% INPUT PATTERN
% initialize parameters and state variables for simulation
% using the Simulink/StateFlow model
% initial values of state variables and parameters
vl = 20; d0 = 50; v0 = 25; ed0 = d0; ev0 = v0; nrad = 0; theta = 0;
% initial setup for each casestudy
bdclose all;
% create breach interface object with a simulink model
falsify_obj = BreachSimulinkSystem(resModelName);
% print parameters and signals
falsify_obj.PrintParams();
falsify_obj.PrintSignals();

% set simulation time
Tsim = 50; Ts = 0.01;
time = 0:Ts:Tsim; t = time';
falsify_obj.SetTime(t(end));

% setting input profiles
nenc_gen = constant_signal_gen({'nenc'});
% generate gps attacks as a step/pulse/constant input
ngps_input_type = 'const';
switch ngps_input_type
    case 'const'
        % set as constant signal
        ngps_gen = constant_signal_gen({'ngps'});
        input_gen = BreachSignalGen({ngps_gen, nenc_gen});
        falsify_obj.SetInputGen(input_gen);
        ngps_input_variation = 'ngps_u0';
    case 'ramp'
        % set as a ramp signal
        ngps_gen= ramp_signal_gen({'ngps'});
        input_gen = BreachSignalGen({ngps_gen, nenc_gen});
        falsify_obj.SetInputGen(input_gen);
        ngps_input_variation = 'ngps_ramp_amp';
    case 'impulse'
        ngps_gen = impulse_signal_gen({'ngps'});
        input_gen = BreachSignalGen({ngps_gen, nenc_gen});
        falsify_obj.SetInputGen(input_gen);
        falsify_obj.SetParam({'ngps_base_value', 'ngps_impulse_time', 'ngps_impulse_period'}, [0.05 20 10]);
        ngps_input_variation = 'ngps_impulse_amp';
    case 'pulse_train'
        ngps_gen = pulse_signal_gen({'ngps'});
        input_gen = BreachSignalGen({ngps_gen, nenc_gen});
        falsify_obj.SetInputGen(input_gen);
        falsify_obj.SetParam({'ngps_base_value', 'ngps_pulse_period'}, [0.05 10]);
        ngps_input_variation = 'ngps_pulse_amp';
    case 'step'
        ngps_gen = step_signal_gen({'ngps'});
        input_gen = BreachSignalGen({ngps_gen, nenc_gen});
        falsify_obj.SetInputGen(input_gen);
        falsify_obj.SetParam({'ngps_step_base_value','ngps_step_time'}, [0.05 1]);
        ngps_input_variation = 'ngps_step_amp';
    case 'sinusoid'
        % set as sinusoid signal
        ngps_gen = sinusoid_signal_gen({'ngps'});
        input_gen = BreachSignalGen({ngps_gen, nenc_gen});
        falsify_obj.SetInputGen(input_gen);
        falsify_obj.SetParam({'ngps_sin_amp', 'ngps_sin_freq'}, [1 1/(2*pi)]);
        ngps_input_variation = 'ngps_sin_offset';
    case 'random'
        % set as a random signal
        ngps_gen = random_signal_gen({'ngps'});
        input_gen = BreachSignalGen({ngps_gen, nenc_gen});
        falsify_obj.SetInputGen(input_gen);
        falsify_obj.SetParam({'ngps_max'}, guardPattern.values{1}(2));
        ngps_input_variation = 'ngps_min';
    otherwise
        'Error';
end

% specify the amplitude range of an attack signal
falsify_obj.SetParamRanges({'nenc_u0', ngps_input_variation}, [0 0.05; -50 50]);
% specify the ranges of initial values of state variables
falsify_obj.SetParamRanges({'d0', 'v0', 'ed0', 'ev0'},[90 100; 25 30; 90 100; 25 30]);
% specify a safety property: d > safe == 5 + v[t]
safe_distance = STL_Formula('safe_distance', 'alw(d[t] >= 5 + v[t])');



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% MODEL SYNTHESIS USING FALSIFICATION
param.names = {'theta'};
%param.values = {[0 50]}; % for pattern 1 and 2
%tol = 1; % specify guard tolerance for pattern 1 and 2
param.values = {[0.1 0.9]}; % for pattern 3
tol = 0.02; % specify guard tolerance for pattern 3
maxLoop = 15; % maximum number of falsification loop
option_plot = 0; % plot the falsified or almost-violated traces
option_check_mono = 0; % perform mononicity check
guess_mono = -ones(1,length(param.names)); % if no mononicity check or the check returns uncetain results, set monotonic values based on guessing

% call model synthesis
model_synthesis
tElapsed=toc(tStartE);
fprintf('Total synthesize time: time %f\n',tElapsed);