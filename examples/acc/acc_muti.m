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




%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Model Transformation
bdclose all; clc; clear all; close all;
patternFile = 'pattern1';
modelName = 'acc_model_new';
resModelName = [modelName,'_resilient'];
tStartT = tic;

runHATL(patternFile,modelName)

tTransform=toc(tStartT);
tStartE = tic;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% INPUT PATTERN
% initialize parameters and state variables for simulation
% using the Simulink/StateFlow model
% states values

vl = 20; d0 = 50; v0 = 25; ed0 = d0; ev0 = v0;
% sensor's parameters
nrad = 0;
theta = 0;
% initial setup for each casestudy
bdclose all;
% create breach interface object with a simulink model
%falsify_obj = BreachSimulinkSystem('acc_model_new_resilient');
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
%falsify_obj.SetParamRanges({'nenc_u0', ngps_input_variation}, [0 0.05; -100 -30]);
falsify_obj.SetParamRanges({'nenc_u0', ngps_input_variation}, [0 0.05; -50 50]);
% specify the ranges of initial values of state variables
falsify_obj.SetParamRanges({'d0', 'v0', 'ed0', 'ev0'},[90 100; 25 30; 90 100; 25 30]);
%falsify_obj.SetParamRanges({'d0', 'v0', 'ed0', 'ev0','theta'},[90 100; 25 30; 90 100; 25 30; 100 150]);

%falsify_obj.PrintParams();
%falsify_obj.PrintSignals();

% specify a safety property
% dsafe == 5 + ev[t], %dref = 10 + 2*ev[t]
safe_distance = STL_Formula('safe_distance', 'alw(d[t] >= 5 + v[t])');
%falsify_obj.PlotRobustMap(safe_distance, 'theta', [100 200])


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Falsification and resilient model synthesis

param.names = {'theta'};
param.values = {[0 50]};
%param.values = {[0.1 0.9]};
numParams = length(param.names);
% guard tolerance
%tol = 0.02;
tol = 1;
option_plot = 0;
option_check_mono = 0;
mono = zeros(1, numParams); % store mononicity check results
guess_mono = -ones(1,numParams); % if mononicity check returns uncetain results, set mono based on guessing
robustness  = -1;
%theta_lb = 0;%theta_ub = 60;
nLoop = 1;
maxLoop = 15;
termination = false;
best_value = zeros(1, numParams); % Store counter example values
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
