% Resilient Model Construction using Breach Falsification Tool
% Input: a partial SLSF folder and uncertain parameter values
% Output: a resilient SLSF model
% Requirement: Breach installation
% https://github.com/decyphir/breach
% -------------------------------------------------------------------------
% author: Luan Nguyen
% -------------------------------------------------------------------------


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SMIB case study
bdclose all; clc; clear all; close all;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% MODEL TRANSFORMATION 
resModelName = model_transformation('pattern_time', 'smib_attack_v2', 'SMIB');
tStartE=tic;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% INPUT PATTERN
% initialize parameters and state variables for simulation
% using the Simulink/StateFlow model
% states values
omega0 = 0; delta0 = 1.1198; theta = 0;
% initial setup for each casestudy
bdclose all;
% create breach interface object with a simulink model
falsify_obj = BreachSimulinkSystem(resModelName);
% print parameters and signals
falsify_obj.PrintParams();
falsify_obj.PrintSignals();

% set simulation time
Tsim = 10; Ts = 0.01; 
time = 0:Ts:Tsim; t = time';
falsify_obj.SetTime(t(end));
falsify_obj.SetParamRanges({'omega0', 'delta0'},[0 1; 0 1.1198;]);

% specify a safety property
safe_distance = STL_Formula('safe_region', 'alw((omega[t] >= -2) and (omega[t] <= 3) and (delta[t] >= 0) and (delta[t] <= 3.5))');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% MODEL SYNTHESIS USING FALSIFICATION
param.names = {'theta'};
param.values = {[0 0.3]};
%length(param.names) = length(param.names);
tol = 0.02; %specify guard tolerance
maxLoop = 10; % maximum number of falsification loop
option_plot = 0;
option_check_mono = 0;
guess_mono = ones(1,length(param.names));

% call model synthesis
model_synthesis
tElapsed=toc(tStartE);
fprintf('Total synthesize time: time %f\n',tElapsed);





















