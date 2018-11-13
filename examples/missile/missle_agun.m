% Resilient Model Construction using Breach Falsification Tool
% Input: a partial SLSF folder and uncertain parameter values
% Output: a resilient SLSF model
% Requirement: Breach installation
% https://github.com/decyphir/breach
% -------------------------------------------------------------------------
% author: Luan Nguyen
% -------------------------------------------------------------------------


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Missile guidance case study: angular noise injection attack
bdclose all; clc; clear all; close all;

% create breach interface object with a simulink model
falsify_obj = BreachSimulinkSystem('aero_guidance_modified');
% print parameters and signals
falsify_obj.PrintParams();
falsify_obj.PrintSignals();
% 
fuze_distance = STL_Formula('fuze_distance', 'ev(range[t] <= 10)');
% Perform sensitivity analysis using Morris method
BrSensi = falsify_obj.copy();
%params = {'agun','tors','wgyro', 'Ks', 'K_r', 'Beamwidth', 'wn_hom'};
%params = {'agun','tors','wgyro', 'Ks', 'Beamwidth', 'wn_hom'};
%ranges = [0 0.1; 0.05 0.2; 90*2*pi 110*2*pi; 19*2*pi 21*2*pi; 9.9*d2r 10.1*d2r; 6.95 7.05];
params = {'agun','tors','wgyro', 'Ks', 'wn_hom'};
ranges = [0 0.1; 0.05 0.25; 90*2*pi 110*2*pi; 19*2*pi 21*2*pi; 6.95 7.05];
BrSensi.SensiSpec(fuze_distance, params, ranges);
falsify_obj.SetParamRanges({'agun'}, [0 0.1]);

tStartE = tic;
% Create the max sat problem to find a new value for tors
AFC_MaxSat = falsify_obj.copy();
max_sat_problem = MaxSatProblem(AFC_MaxSat, fuze_distance,{'tors'},[0.05 0.25]);
max_sat_problem.setup_solver('cmaes');
max_sat_problem.max_time = 30;
max_sat_problem.solve();

tElapsed=toc(tStartE);
fprintf('Total synthesize time: time %f\n',tElapsed);


