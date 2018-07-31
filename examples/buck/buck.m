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
newGuards.values = {[0 10]};
numIn = length(newGuards.params);
% guard tolerance
tol = 1;
option_plot = 0;
option_check_mono = 1;
option_resilient_to_nominal = 1;
mono = zeros(1, numIn); % store mononicity check results
tStart = tic;
flag = 0; % if no counterexample found for the first testing loop, return a testing cadidate as a resilient model
count = 1;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Hysteresis controller for a buck converter case study
% initialize parameters and state variables for simulation
% using the Simulink/StateFlow model

% define parameters
buck_parameters;



while flag < 1 
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % initial setup for each casestudy
    bdclose all;
    % create breach interface object with a simulink model
    original_obj = BreachSimulinkSystem(modelName);
    falsify_obj = original_obj.copy(); % Creates a copy of the interface object

    % print parameters and signals
    falsify_obj.PrintParams();
    falsify_obj.PrintSignals();

    % setting input profiles
    % Vs as a constant signal
    Vs_gen = constant_signal_gen({'Vs'});
    % generate a noise attack as a step input
    Vn_gen = step_signal_gen({'Vn'});
    input_gen = BreachSignalGen({Vs_gen,Vn_gen});
    falsify_obj.SetInputGen(input_gen);
    falsify_obj.SetParam({'Vn_step_base_value','Vn_step_time'}, [0 0.005]);
    falsify_obj.SetParam({'Vs_u0'},24);

    input_step_amp = cell(1, numIn); 
    for i = 1:numIn
        input_step_amp{1,i} = strcat(newGuards.params{i},'_step_amp');
    end


    % set simulation time
    Tsim = 0.1; Ts = 0.002; time = 0:Ts:Tsim; t = time';
    falsify_obj.SetTime(t(end));

    % specified a safety property
    %upper_bound = STL_Formula('upper_bound', 'v[t] > 12 - 5');
    upper_bound = STL_Formula('upper_bound', 'v[t] < Vref + Vtol_safe');
    lower_bound = STL_Formula('lower_bound', 'v[t] > Vref - Vtol_safe');
    safe_voltage = STL_Formula('safe_voltage', 'ev_[0, 0.02](alw(upper_bound and lower_bound))');
    %safe_voltage2 = STL_Formula('safe_voltage2', 'alw(v[t] > 15 => (ev_[0,0.01](alw(v[t] < Vref + Vtol_safe))))');
    falsify_obj.SetParam('Vref', Vref, 'spec');
    falsify_obj.SetParam('Vtol_safe', Vtol_safe, 'spec');

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Falsification and resilient model synthesis
    nLoop = 1;
    pos = 1;
    robustness = -1;
    best_value = zeros(1, numIn); % Store counter example values

    % run a falsication loop and retrieve a counterexample if exists 
    while robustness < 0 && nLoop < 10
        [falsify_obj, robustness, best_value, mono, newGuards.values, nLoop, flag, option_check_mono] = falsification(falsify_obj,input_step_amp, newGuards.values, safe_voltage ...
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

% 
% figure
% Buck_result.PlotSignals({'Vs','Vn','v'}, [], {'LineWidth', 2});
% % Some figure cosmetics
% subplot(3,1,1); set(gca, 'XLim', [0 Tsim], 'FontSize',14, 'LineWidth', 2);
% subplot(3,1,2); set(gca, 'XLim', [0 Tsim], 'FontSize',14, 'LineWidth', 2);
% subplot(3,1,3); set(gca, 'XLim', [0 Tsim],'YLim', [11 13], 'FontSize',14, 'LineWidth', 2);
% plot([0 Tsim], 1*[Vref + Vtol_safe Vref + Vtol_safe],'r');
% plot([0 Tsim], 1*[Vref - Vtol_safe Vref - Vtol_safe],'r')




