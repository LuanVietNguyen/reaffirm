% Resilient Model Construction using Breach Falsification Tool
% Input: a partial SLSF folder and uncertain parameter values
% Output: a resilient SLSF model
% Requirement: Breach installation
% https://github.com/decyphir/breach
% -------------------------------------------------------------------------
% author: Luan Nguyen
% -------------------------------------------------------------------------

bdclose all;
clc;
clear;
% partial model
modelName = 'partial_acc_model';
% uncertain parameter lists
newGuards.params = {'ngps', 'nenc'};
newGuards.values = {[1 20], [1 10]};
numIn = length(newGuards.params);
% guard tolerance
tol = 0.5;

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
%nenc = 0.05;

option_plot = 1;


tStart=tic;

flag = 0; % if 
count = 1;

while flag < 1 
    
    % create breach interface object with a simulink model
    bdclose all;
    BrACC = BreachSimulinkSystem(modelName);
    
    % print parameters and signals
    BrACC.PrintParams();
    BrACC.PrintSignals();
    
    % create a copy of the interface object
    ACC_falsify = BrACC.copy(); 

    % setting input profiles
    
    % generate gps and enc attacks as a step input
    ngps_gen = step_signal_gen({'ngps'});
    nenc_gen = step_signal_gen({'nenc'});
    input_gen = BreachSignalGen({ngps_gen, nenc_gen});
    ACC_falsify.SetInputGen(input_gen);
    ACC_falsify.SetParam({'ngps_step_base_value','ngps_step_time'}, [0.05 5]);
    ACC_falsify.SetParam({'nenc_step_base_value','nenc_step_time'}, [0.05 5]);
    input_step_amp = cell(1, numIn); 
    best_value = zeros(1, numIn); 
    mono = zeros(1, numIn);
    for i = 1:numIn
        input_step_amp{1,i} = strcat(newGuards.params{i},'_step_amp');
    end
    % specify the ranges of initial values of state variables
    ACC_falsify.SetParamRanges({'d0', 'v0', 'ed0', 'ev0'},[50 100; 10 30; 0 1; 0 1]);
    
    % ACC_falsify.SetParam({'ngps_step_base_value'}, 0.05);
    % ACC_falsify.SetParamRanges({'ngps_step_time','ngps_step_amp'},[5 20; 1 50]);

    % set simulation time
    Tsim = 50; Ts = 0.02; time = 0:Ts:Tsim; t = time';
    ACC_falsify.SetTime(t(end));

    % specify a safety property
    % dsafe == 5 + v[t], %dref = 10 + 2*(v[t] - ev[t])
    safe_distance = STL_Formula('safe_distance', 'alw d[t] >= 5 + v[t]');
    
    nLoop = 1;
    pos = 1;
    robustness = -1;
    
    while robustness < 0 && nLoop < 10
        % Create falsification object
        for i = 1:numIn
            ACC_falsify.SetParamRanges({input_step_amp(i)},newGuards.values{i})
        end
        falsify_pb = FalsificationProblem(ACC_falsify, safe_distance);
        % chose optimization solver, see falsify_pb.list_solvers()
        falsify_pb.setup_solver('cmaes');
        falsify_pb.max_time = 20;
        % retrieve violated parameter value
        res = falsify_pb.solve();
        robustness = falsify_pb.obj_best();
        for i = 1:numIn
            idx = find(strcmp(falsify_pb.params, input_step_amp{1,i})); 
            best_value(i) = falsify_pb.x_best(idx);
        end
        if nLoop == 1
            for i = 1:numIn
                mono(i) = ACC_falsify.ChecksMonotony(safe_distance,input_step_amp(i), newGuards.values{i});
            end
        end
        for i = 1:numIn
            if mono(i) > 0 
                newGuards.values{i}(1) = ceil(best_value(i) + tol);
                best_value(i) = newGuards.values{i}(1);
            else
                newGuards.values{i}(2) = floor(best_value(i) - tol);
                best_value(i) = newGuards.values{i}(2);
            end
        end
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
        if robustness > 0 && nLoop == 1
            flag = 1;
        end
        nLoop = nLoop + 1;
    end
    % if the current model has a counterexample, continue generating a new
    % resilient model. Otherwise, exist the loop
    if flag == 0 
        newGuards.label = guard_inferrence(mono, newGuards.params, best_value - tol); 
        bdclose all;
        if pos == 1
            [resilient_model, originalStateNames] = model_synthesis(modelName, newGuards, pos);
        else
            [resilient_model] = model_synthesis(modelName, newGuards, pos);
        end
        modelName = resilient_model.Name;
        pos = pos*(pos + 1);
        if nLoop > 1
            backGuards.params = newGuards.params;
            backGuards.label = guard_inferrence((-1)*mono, newGuards.params, best_value - tol);
            resilient_to_nomial_guards(modelName, originalStateNames, count, backGuards);
            sfsave(modelName);
        end
    end
    count = count + 1;   
end
tElapsed=toc(tStart);
fprintf('Total execution time: time %f\n',tElapsed);
open_system([modelName,'.mdl'])


