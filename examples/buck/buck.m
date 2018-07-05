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
modelName = 'buck_hysteresis';
% uncertain parameter lists
newGuards.params = {'Vn'};
newGuards.values = {[0 8]};
% guard tolerance
tol = 1;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Hysteresis controller for a buck converter case study
% initialize parameters and state variables for simulation
% using the Simulink/StateFlow model

% define parameters
buck_parameters;

%%%%%%%%%%%% Testing
robustness = -1;
option_plot = 1;
nLoop = 1;
tStart=tic;
pos = 1;
while robustness < 0 && nLoop < 4
    % create breach interface object with a simulink model
    BrBuck = BreachSimulinkSystem(modelName);
    
    % print parameters and signals
    BrBuck.PrintParams();
    BrBuck.PrintSignals();
    
    % create a copy of the interface object
    Buck_falsify = BrBuck.copy(); 

    % setting input profiles
    
    % generate a gps attack as a step input
    % Vs as a constant signal
    Vs_gen = constant_signal_gen({'Vs'});
    % generate a noise attack as a step input
    Vn_gen = step_signal_gen({'Vn'});
    input_gen = BreachSignalGen({Vs_gen,Vn_gen});
    Buck_falsify.SetInputGen(input_gen);
    Buck_falsify.SetParam({'Vn_step_base_value','Vn_step_time'}, [0 0.005]);
    Buck_falsify.SetParam({'Vs_u0'},24);
    Buck_falsify.SetParamRanges({'Vn_step_amp'},newGuards.values{1});
    

    % set simulation time
    Tsim = 0.1;
    Ts = 0.002;
    time = 0:Ts:Tsim;
    t = time';
    Buck_falsify.SetTime(t(end));

    % specified a safety property
    %upper_bound = STL_Formula('upper_bound', 'v[t] > 12 - 5');
    upper_bound = STL_Formula('upper_bound', 'v[t] < Vref + Vtol_safe');
    lower_bound = STL_Formula('lower_bound', 'v[t] > Vref - Vtol_safe');
    safe_voltage = STL_Formula('safe_voltage', 'ev_[0, 0.02](alw(upper_bound and lower_bound))');
    %safe_voltage2 = STL_Formula('safe_voltage2', 'alw(v[t] > 15 => (ev_[0,0.01](alw(v[t] < Vref + Vtol_safe))))');
    Buck_falsify.SetParam('Vref', Vref, 'spec');
    Buck_falsify.SetParam('Vtol_safe', Vtol_safe, 'spec');
    
    % Create falsification object
    falsify_pb = FalsificationProblem(Buck_falsify, safe_voltage );
    % chose optimization solver, see falsify_pb.list_solvers()
    falsify_pb.setup_solver('cmaes');
    falsify_pb.max_time = 180;
    % retrieve violated parameter value
    res = falsify_pb.solve();
    robustness = falsify_pb.obj_best();
    
    % plot falsified traces
    if option_plot == 1
        if robustness < 0
            Buck_result = falsify_pb.GetBrSet_False();
        else
            Buck_result = falsify_pb.GetBrSet_Best();
        end
        figure
        Buck_result.PlotRobustSat(safe_voltage)
%         figure
%         Buck_result.PlotSignals({'Vs','Vn','v'}, [], {'LineWidth', 2});
%         % Some figure cosmetics
%         subplot(3,1,1); set(gca, 'XLim', [0 Tsim], 'FontSize',14, 'LineWidth', 2);
%         subplot(3,1,2); set(gca, 'XLim', [0 Tsim], 'FontSize',14, 'LineWidth', 2);
%         subplot(3,1,3); set(gca, 'XLim', [0 Tsim],'YLim', [11 13], 'FontSize',14, 'LineWidth', 2);
%         plot([0 Tsim], 1*[Vref + Vtol_safe Vref + Vtol_safe],'r');
%         plot([0 Tsim], 1*[Vref - Vtol_safe Vref - Vtol_safe],'r')
    end
    
    if robustness < 0
        % perform monotonicity check and generate a cadidate guard, just
        % check one time
        if nLoop == 1
            %figure
            Buck_falsify.PlotRobustMap(safe_voltage, {'Vn_step_amp'}, newGuards.values{1})
            robustness_array = extractfield(Buck_falsify.P.props_values,'val');
            mono = monotony(robustness_array);
            %mono = Buck_falsify.ChecksMonotony(safe_voltage,'Vn_step_amp', newGuards.values{1});
        end
        % get unsafe values of parameters we consider
        idx = find(strcmp(falsify_pb.params, 'Vn_step_amp')); 
        % retrieve a candidate guard
        newGuards.label = guard_inferrence(mono, newGuards.params, floor(falsify_pb.x_best(idx))- tol);
        
        % call model synthesis to generate a resilient model and continue a testing loop
        bdclose all;
        if pos == 1
            [resilient_model, originalStateNames] = model_synthesis(modelName, newGuards, pos);
        else
            [resilient_model] = model_synthesis(modelName, newGuards, pos);
        end
        modelName = resilient_model.Name;
    elseif nLoop > 1
        backGuards.params = newGuards.params;
        backGuards.label = guard_inferrence((-1)*mono, newGuards.params, floor(falsify_pb.x_best(idx))- tol);
        resilient_to_nomial_guards(modelName, originalStateNames, nLoop, backGuards);
    end
    nLoop = nLoop + 1;
    pos = pos*(pos + 1);
end
tElapsed=toc(tStart);
fprintf('Total execution time: time %f\n',tElapsed);
open_system([modelName,'.mdl'])





