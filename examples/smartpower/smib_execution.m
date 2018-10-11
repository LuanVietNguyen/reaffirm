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




%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Model Transformation
bdclose all; clc; clear all; close all;
modelName = 'smib_attack_v2';
patternName = 'pattern_time';
resModelName = [modelName,'_resilient'];
tStartT = tic;

runHATL(patternName,modelName,"SMIB")

tTransform=toc(tStartT);
tStartE = tic;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% INPUT PATTERN
% initialize parameters and state variables for simulation
% using the Simulink/StateFlow model
% states values

omega0 = 0; delta0 = 1.1198; 
theta = 0;
% initial setup for each casestudy
bdclose all;
% create breach interface object with a simulink model
%falsify_obj = BreachSimulinkSystem('smib');
falsify_obj = BreachSimulinkSystem(resModelName);

% print parameters and signals
falsify_obj.PrintParams();
falsify_obj.PrintSignals();

% set simulation time
Tsim = 10; Ts = 0.01; 
time = 0:Ts:Tsim; t = time';
falsify_obj.SetTime(t(end));
falsify_obj.SetParamRanges({'omega0', 'delta0'},[0 1; 0 1.1198;]);

%falsify_obj.SetParamRanges({'theta_u0'}, [0 0.2]);
% specify the ranges of initial values of state variables
% falsify_obj.SetParamRanges({'d0', 'v0', 'ed0', 'ev0'},[90 100; 25 30; 90 100; 25 30]);
%falsify_obj.SetParamRanges({'d0', 'v0', 'ed0', 'ev0','theta'},[90 100; 25 30; 90 100; 25 30; 100 150]);

falsify_obj.PrintParams();
falsify_obj.PrintSignals();

% specify a safety property
% dsafe == 5 + ev[t], %dref = 10 + 2*ev[t]
safe_distance = STL_Formula('safe_region', 'alw((omega[t] >= -2) and (omega[t] <= 3) and (delta[t] >= 0) and (delta[t] <= 3.5))');
%safe_distance = STL_Formula('safe_region', 'alw(omega[t] <= 2.5 && delta[t] <= 2.5)');
%falsify_obj.PlotRobustMap(safe_distance, 'theta', [100 200])


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Falsification and resilient model synthesis

param.names = {'theta'};
param.values = {[0 0.3]};
%param.values = {[0.15 1]};
%param.values = {[0.1 1]};
numParams = length(param.names);
% guard tolerance
tol = 0.02;
%tol = 0.005;
option_plot = 0;
option_check_mono = 0;
mono = zeros(1, numParams); % store mononicity check results
guess_mono = ones(1,numParams); % if mononicity check returns uncetain results, set mono based on guessing 
robustness  = -1;
%theta_lb = 0;%theta_ub = 60;
nLoop = 1;
maxLoop = 10;
termination = false;
best_value = zeros(1, numParams); % Store counter example values
falsify_obj.PrintParams();
while robustness < 0 && nLoop < maxLoop && termination == false
    
    [falsify_obj, robustness, best_value, param.values, mono, nLoop, termination] = falsification(falsify_obj, param.names, param.values, safe_distance ...
                                                                   , best_value, tol, mono, guess_mono, nLoop,termination, option_check_mono, option_plot);
    
%     falsify_obj.SetParamRanges('theta',[theta_lb theta_ub]);
%     falsify_pb = FalsificationProblem(falsify_obj, safe_distance);
%     % chose optimization solver, see falsify_pb.list_solvers()
%     falsify_pb.setup_solver('cmaes');
%     falsify_pb.max_time = 30;
%     % retrieve violated parameter value
%     falsify_pb.solve();
%     robustness = falsify_pb.obj_best();
% %    falsify_obj.PlotRobustMap(safe_distance, 'theta', [theta_lb theta_ub])
%     % find theta
%     idx = strcmp(falsify_pb.params, 'theta'); 
%     theta_ub = falsify_pb.x_best(idx)- tol;
%     %theta_ub = (falsify_pb.x_best(idx)+theta_lb)/2;
end

if nLoop > maxLoop - 1
   disp('Maximum iteration reached, please try another pattern or increase maxLoop\n')
end

% %Model synthesis
%falsify_obj.Sim();
% synth_pb = ParamSynthProblem(falsify_obj, safe_distance , {'theta'}, [60 120]);
% falsify_obj.PrintParams();
% synth_pb.setup_solver('fmincon')
% synth_pb.solver_options.monotony = -1;
% %synth_pb.setup_solver('cmaes');
% %synth_pb.max_time = 30;
% synth_pb.solve();
%theta_best = synth_pb.x_best;

tElapsed=toc(tStartE);
fprintf('Total transformation time %f\n',tTransform);
fprintf('Total synthesize time: time %f\n',tElapsed);
%open_system([modelName,'.mdl'])

%save model file
% slsf_model_path = [partial_model,'_resilient.mdl'];
% sfsave(resilient_model.Name, slsf_model_path);





















