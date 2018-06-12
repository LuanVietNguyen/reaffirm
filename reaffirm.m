% Resilient Model Construction using Breach Falsification Tool
% Input: a partial SLSF folder and uncertain parameter values
% Output: a resilient SLSF model
% Requirement: Breach installation
% https://github.com/decyphir/breach
% ------------------------------------------------------------------------------
% author: Luan Nguyen
% ------------------------------------------------------------------------------

bdclose all;
clc;
clear;
% partial model
modelName = 'partial_acc_model';
% uncertain parameter lists
newGuards.params = {'ngps'};
newGuards.values = {[2 50]};


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% ACC case study
% initialize parameters and state variables for simulation
% using the Simulink/StateFlow model
vl = 26;
d0 = 100;
v0 = 25;
ed0 = 1;
ev0 = 1;

% sensor's parameters
nrad = 0;
nenc = 0.05;

% initialize breach
addpath(genpath('breach'))
InitBreach;
option_plot = 1;

robustness = -10000000;
nLoop = 0;

while robustness < 0 && nLoop < 2
    % create breach interface object with a simulink model
    BrACC = BreachSimulinkSystem(modelName);

    BrACC.PrintParams();
    BrACC.PrintSignals();
    ACC_falsify = BrACC.copy(); % create a copy of the interface object

    % setting input profiles
    
    % generate as constant signal
    % ngps_gen = constant_signal_gen({'ngps'});
    % ACC_falsify.SetParamRanges({'ngps_u0'},[0 50]);
    
    % generate a gps attack as a step input
    ngps_gen = step_signal_gen({'ngps'});
    input_gen = BreachSignalGen({ngps_gen});
    ACC_falsify.SetInputGen(input_gen);
    ACC_falsify.SetParam({'ngps_step_base_value','ngps_step_time'}, [0.05 5]);
    ACC_falsify.SetParamRanges({'ngps_step_amp'},newGuards.values{1});
    %
    % ACC_falsify.SetParam({'ngps_step_base_value'}, 0.05);
    % ACC_falsify.SetParamRanges({'ngps_step_time','ngps_step_amp'},[5 20; 1 50]);

    % set simulation time
    Tsim = 50;
    Ts = 0.02;
    time = 0:Ts:Tsim;
    t = time';
    ACC_falsify.SetTime(t(end));

    % specified a safety property
    % dsafe == 5 + v[t], %dref = 10 + 2*(v[t] - ev[t])
    safe_distance = STL_Formula('safe_distance', 'alw d[t] >= 5 + v[t]');


    falsify_pb = FalsificationProblem(ACC_falsify, safe_distance);
    % chose optimization solver, see falsify_pb.list_solvers()
    falsify_pb.setup_solver('cmaes');
    % retrieve violated parameter value
    res = falsify_pb.solve();
    robustness = falsify_pb.obj_best();
    % plot falsified traces
    if option_plot == 1
        if robustness < 0
            ACC_result = falsify_pb.GetBrSet_False();
        else
            ACC_result = falsify_pb.GetBrSet_Best();
        end
        figure
        ACC_result.PlotRobustSat(safe_distance);
        % figure
        % ACC_result.PlotSignals({'ngps','d','v','ev', 'ed'}, [], {'LineWidth', 1.3});
    end
    if robustness < 0
        % perform monotonicity check and generate a cadidate guard
        ACC_falsify.PlotRobustMap(safe_distance, {'ngps_step_amp'}, newGuards.values{1})
        robustness_array = extractfield(ACC_falsify.P.props_values,'val');
        sign = monotony(robustness_array);
        newGuards.label = [newGuards.params{1}, sign, num2str(floor(falsify_pb.x_best))] ;
        % call model synthesis to generate a resilient model
        bdclose all;
        % generate resilient model and continue a testing loop
        [resilient_model] = model_synthesis(modelName, newGuards);
        modelName = resilient_model.Name;
    end 
    nLoop = nLoop + 1;
end



