% Resilient Model Construction using Breach Falsification Tool
% Input: a partial SLSF folder and uncertain parameter values
% Output: a resilient SLSF model
% Requirement: Breach installation
% https://github.com/decyphir/breach
% -------------------------------------------------------------------------
% author: Luan Nguyen
% -------------------------------------------------------------------------


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Missile guidance case study: gyroscopes spoofing attack
bdclose all; clc; clear all; close all;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% MODEL TRANSFORMATION 
resModelName = model_transformation('pattern3_gyro', 'aero_guidance_modified','Gyronoise');
tStartE=tic;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% INPUT PATTERN
% initialize parameters and state variables for simulation
% using the Simulink/StateFlow model
% states values
theta = 0;
% create breach interface object with a simulink model
falsify_obj = BreachSimulinkSystem(resModelName);

% print parameters and signals
falsify_obj.PrintParams();
falsify_obj.PrintSignals();

% set simulation time
Tsim = 4; Ts = 0.01; 
time = 0:Ts:Tsim; t = time';
falsify_obj.SetTime(t(end));

% setting input profiles 
% generate gps attacks as a step/pulse/constant input   
signals = {'ngyro1', 'ngyro2'};
signal_types = {'const', 'const'};
falsify_obj = input_gen(falsify_obj, signals, signal_types); 

falsify_obj.SetParamRanges({'ngyro1_u0', 'ngyro2_u0'}, [0 0.05; 0 1]);
safe_prop = STL_Formula('fuze_distance', 'ev(range[t] <= 10)');
% mono_obj = falsify_obj.copy();
% mono_obj.PlotRobustMap(fuze_distance, {'theta'}, [0.4 0.5]);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% MODEL SYNTHESIS USING FALSIFICATION
param.names = {'theta'};
% param.values = {[0.05 1]}; % for pattern 1 and 2
% tol = 0.02; % specify guard tolerance for pattern 1 and 2
%param.values = {[0.1 0.9]}; % for pattern 3
param.values = {[0.01 0.1]}; % for pattern 3
tol = 0.02; % specify guard tolerance for pattern 3
maxLoop = 15; % maximum number of falsification loop
option_plot = 0; % plot the falsified or almost-violated traces
option_check_mono = 0; % perform mononicity check
guess_mono = -ones(1,length(param.names)); % if no mononicity check or the check returns uncetain results, set monotonic values based on guessing

% call model synthesis
model_synthesis
tElapsed=toc(tStartE);
fprintf('Total synthesize time: time %f\n',tElapsed);

% update the parameter to a constant with a synthesized value
% export the final model
complete_model_gen

