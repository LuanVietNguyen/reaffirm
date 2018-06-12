classdef BreachProblem < BreachStatus
    % BreachProblem A class for generic optimization problem involving STL specifications
    %
    % A BreachProblem is essentially created from a BreachSystem and a
    % property. E.g.,
    %
    %   problem = BreachProblem(BrSys, phi);
    %
    % In that case BrSys parameter ranges determines the variables and
    % search domains. BrSys parameter vectors are used as initial values
    % for the problem. Alternatively, parameters to optimize and ranges can
    % be specified explictly using the syntax:
    %
    %   problem = BreachProblem(BrSys, phi, params, ranges);
    %
    % where params is a cell array of parameters and ranges a corresponding
    % array of ranges.
    %
    % When a problem is created, the objective function is constructed from
    % the robust satisfaction of the property phi. A solver can then be
    % selected to solve it via the solve method.
    %
    % BreachProblem Properties (inputs)
    %   BrSet          -  BreachSet used as (initial) domain for optimization
    %   BrSys          -  BreachSystem used by the solver to compute new
    %                     traces or new satifaction values
    %   robust_fn      -  the robust satisfaction function, returns an array
    %                     of values if BrSys has more than one parameter vector/trace
    %   objective_fn   -  default: minimum of robust_fn.
    %   solver         -  default: 'basic', use list_solvers to get a list of available solvers
    %   solver_options -  option structure for the solver. See each solver
    %                     help to know available options (E.g., for matlab solvers, this is
    %                     often set using the optimset command).
    %   max_time       -  maximum wall-time budget allocated to optimization
    %   log_traces     -  (default=true) logs all traces computed during optimization
    %                     (can be memory intensive)
    %   T_spec         -  time 
    % 
    % BreachProblem Properties (outputs)
    %   BrSet_Logged    -  BreachSet with parameter vectors used during optimization.
    %
    %   BrSet_Best      -  BreachSet with the best parameter vector found during optimization.
    %   res             -  a result structure, specific to each solver
    %   X_log, obj_log  -  all values tried by the solver and corresponding objective function values.
    %   x_best,obj_best -  best value found
    %
    %
    % BreachProblem Methods
    %   list_solvers    - returns a list of strings of available solvers
    %   setup_solver    - setup the solver given as argument with default options
    %                     and returns these options.
    %   solve           - calls the solver 
    %   GetBrSet_Logged - returns a BrSet_Logged
    %   GetBrSet_Best   - returns a BrSet_Best
    %
    % See also FalsificationProblem, ParamSynthProblem, ReqMiningProblem
    
    %% Properties 
    properties
        objective
        x0
        solver= 'global_nelder_mead'   % default solver name
        solver_options    % solver options
        Spec
        T_Spec=0
        constraints_fn    % constraints function
        robust_fn   % base robustness function - typically the robust satisfaction of some property by some trace
    end
    
    % properties related to the function to minimize
    properties
        BrSet
        BrSys
        BrSet_Best
        BrSet_Logged
        params
        lb
        ub
        Aineq
        bineq
        Aeq
        beq
        res
        X_log
        obj_log
        x_best
        obj_best   = inf
        log_traces = true
    end
    
    % misc options
    properties
        display = 'on'
        freq_update = 10 
        use_parallel = false % true default?
        max_time = 60
        time_start = tic
        time_spent = 0
        nb_obj_eval = 0
        max_obj_eval = inf
    end
    %% Static Methods
    methods (Static)
        function solvers = list_solvers()
        % list_solvers display the list of (supposedly) available solvers.      
        % TODO check dependency on locally installed toolboxes 
        solvers = ...
                {'init', ...
                'basic',...
                'global_nelder_mead (default)',...
                'binsearch',...
                'fminsearch',...
                'cmaes'...
                };
            
            solvers_others = ...
                {'fmincon', ...
                'simulannealbnd', ...
                'optimtool',...
                'ga',...
                };
            
            for i_solv = 1:numel(solvers)
                disp(solvers{i_solv});
            end
            
            for i_solv = 1:numel(solvers_others)
                if exist(solvers_others{i_solv})
                    disp(solvers_others{i_solv});
                    solvers= [solvers solvers_others{i_solv}];
                end
            end
            
        end
    end
    
    %% Methods
    methods
             
        %% Constructor
        function this = BreachProblem(BrSet, phi, params, ranges)
            
            this.Spec = phi;
            this.BrSet = BrSet.copy();
            this.BrSet.Sys.Verbose=0;
            
            this.use_parallel = BrSet.use_parallel;
        
            % Parameter ranges
            if ~exist('params','var')
                params = BrSet.GetBoundedDomains();
            else
                if ischar(params)
                    params = {params};
                end
                
            end
            this.params= params;
            
            if ~exist('ranges', 'var')
                ranges = BrSet.GetParamRanges(params);
                lb__ = ranges(:,1);
                ub__ = ranges(:,2);

                % if range is singular, assumes unconstrained - probably a
                % bad idea
                issame  = find(ub__-lb__==0);
                lb__(issame) = -inf;
                ub__(issame) = inf;
            else
                lb__ = ranges(:,1);
                ub__ = ranges(:,2);
                this.BrSet.SetParam(params, 0.5*(ranges(:,2)-ranges(:,1)), true); % adds parameters they don't exist 
                this.BrSet.SetDomain(params, 'double', ranges);
            end
                       
            this.lb = lb__;
            this.ub = ub__;
            
            % Initial value
            this.Reset_x0();
            
            % robustness
            [this.robust_fn, this.BrSys] = BrSet.GetRobustSatFn(phi, this.params, this.T_Spec);
            this.BrSys.Sys.Verbose=0;
             
            % objective function
            this.objective = @(x) (objective_wrapper(this,x));
            
            % setup default solver
            this.setup_solver();
            
            % reset display
            rfprintf_reset();
            
            % Setup use parallel
            if this.use_parallel
                  this.SetupParallel();
            end
            
        end
        
        function Reset_x0(this)
            phi_params = get_params(this.Spec);
            
            x0__ = zeros(numel(this.params), size(this.BrSet.P.pts,2));
            for ip = 1:numel(this.params)
                x0__ip =  this.BrSet.GetParam(this.params{ip});
                if ~isempty(x0__ip)
                    x0__(ip,:) = x0__ip;
                elseif isfield(phi_params,this.params{ip})
                    x0__(ip,:) = phi_params.(this.params{ip});
                else
                    error('BreachProblem:unknown_param', ['Parameter ' this.params{ip} ' is neither a system parameter nor a property parameter.']);
                end
            end
            this.BrSet.SetParam(this.params, x0__,'spec');
            
            this.x0 = unique(x0__', 'rows')';
            
        end
        
        function ResetObjective(this, BrSet)
            if nargin == 1
                BrSet = this.BrSet;
            end
            
            this.Reset_x0;
            
            % Reset display
            rfprintf_reset();
            
            % robustness
            [this.robust_fn, this.BrSys] = BrSet.GetRobustSatFn(this.Spec, this.params, this.T_Spec);
            
            this.BrSet_Best = [];
            this.BrSet_Logged = [];
            this.res = [];
            this.X_log = [];
            this.obj_log= [];
            this.obj_best =inf;
            this.time_spent = 0;
            this.nb_obj_eval = 0;
        end
        
        %% Options for various solvers
        function solver_opt = setup_solver(this, solver_name)
            if ~exist('solver_name','var')
                solver_name = this.solver;
            end
            
            solver_opt = eval(['this.setup_' solver_name ]);
        end
        
        function solver_opt = setup_init(this)
            solver_opt = struct();
            this.solver= 'init';
            this.solver_options = solver_opt;
        end
        
        function solver_opt = setup_optimtool(this)
            solver_opt = optimset('Display', 'iter');
            this.display = 'off';
            solver_opt.lb = this.lb;
            solver_opt.ub = this.ub;
            this.solver = 'optimtool';
            this.solver_options = solver_opt;
        end
        
        function solver_opt = setup_fmincon(this)
            disp('Setting options for fmincon solver');
            solver_opt = optimset('Display', 'iter');
            this.display = 'off';
            solver_opt.lb = this.lb;
            solver_opt.ub = this.ub;
            this.solver = 'fmincon';
            this.solver_options = solver_opt;
        end
        
        function solver_opt = setup_fminsearch(this)
            disp('Setting options for fminsearch solver');
            solver_opt = optimset('Display', 'iter');
            this.display = 'off';
            solver_opt.lb = this.lb;
            solver_opt.ub = this.ub;
            this.solver = 'fminsearch';
            this.solver_options = solver_opt;
        end
        
        function solver_opt = setup_simulannealbnd(this)
            disp('Setting options for simulannealbnd solver');
            this.display = 'off';
            solver_opt = optimset('Display', 'iter');
            solver_opt.lb = this.lb;
            solver_opt.ub = this.ub;
            this.solver = 'simulannealbnd';
            this.solver_options = solver_opt;
        end
        
        function solver_opt = setup_cmaes(this)
            disp('Setting options for cmaes solver - use help cmaes for details');
            solver_opt = cmaes();
            solver_opt.Seed = 0;
            solver_opt.LBounds = this.lb;
            solver_opt.UBounds = this.ub;
            this.display = 'off';
            this.solver = 'cmaes';
            this.solver_options = solver_opt;
        end
        
        %% solve functions for various solvers
        function res = solve(this)
            
            % reset display
            rfprintf_reset();
            
            % reset time
            this.time_start = tic;
            this.time_spent = 0;
            
            % create problem structure
            problem = this.get_problem();
                        
            switch this.solver
                case 'init'
                    res = FevalInit(this);
                    
                case 'basic'
                    res = this.solve_basic();
                    
                case 'global_nelder_mead'
                    res = this.solve_global_nelder_mead();
                    
                case 'cmaes'
                    % adds a few more initial conditions
                    nb_more = 10*numel(this.params)- size(this.x0, 2);
                    if nb_more>inf
                        Px0 = CreateParamSet(this.BrSet.P, this.params,  [this.lb this.ub]);
                        Px0 = QuasiRefine(Px0, nb_more);
                        this.x0 = [this.x0' GetParam(Px0,this.params)]';
                    end
                    
                    [x, fval, counteval, stopflag, out, bestever] = cmaes(this.objective, this.x0', [], this.solver_options);
                    res = struct('x',x, 'fval',fval, 'counteval', counteval,  'stopflag', stopflag, 'out', out, 'bestever', bestever);
                    this.res=res;
                    
                case 'ga'
                    res = solve_ga(this, problem);
                    this.res = res;
                    
                case {'fmincon', 'fminsearch', 'simulannealbnd'}
                    [x,fval,exitflag,output] = feval(this.solver, problem);
                    res =struct('x',x,'fval',fval, 'exitflag', exitflag, 'output', output);
                    this.res=res;
                    
                case 'optimtool'
                    problem.solver = 'fmincon';
                    optimtool(problem);
                    res = [];
                    return;

                case 'binsearch'
                    res = solve_binsearch(this);
                    this.res = res;

                otherwise
                    res = feval(this.solver, problem);
                    this.res = res;
            end
            this.DispResultMsg(); 
        end
        
        %% Utility functions for solvers
        
        % function res = FevalInit(this,X0)
        % defined in external file
        
        function X0 = init_basic_X0(this)
            % returns initial vectors
            BrQ = this.BrSet.copy();
            BrQ.ResetParamSet();
            BrQ.SetParamRanges(this.params, [this.lb this.ub])
            BrC = BrQ.copy();
            nb_samples = this.solver_options.nb_new_trials;
            step = this.solver_options.start_at_trial;
            
            BrC.P = CreateParamSet(BrC.Sys,this.params,[this.lb this.ub]);
            BrC.CornerSample();
            XC = BrC.GetParam(this.params);
            nb_corners= size(XC, 2);
            qstep = step-nb_corners;
            if qstep>=0
                % skips corners
                BrQ.QuasiRandomSample(nb_samples, step);
                X0 = BrQ.GetParam(this.params);
            else
                qnb_samples = nb_samples+qstep;
                if qnb_samples>0  % needs to finish corners plus some
                    BrQ.QuasiRandomSample(qnb_samples);
                    XQ = BrQ.GetParam(this.params);
                    X0 = [XC(:,step+1:end) XQ];
                else % more corners than samples anyway
                    X0 = XC(:,step+1:end);
                end
                
            end
            
        end
        
        function problem = get_problem(this)
            problem =struct('objective', this.objective, ...
                'fitnessfcn', this.objective, ... % for ga
                'x0', this.x0, ...
                'nvars', size(this.x0, 1),... % for ga
                'solver', this.solver,...
                'Aineq', this.Aineq,...
                'bineq', this.bineq,...
                'Aeq', this.Aeq,...
                'beq', this.beq,...
                'lb', this.lb,...
                'ub', this.ub,...
                'nonlinq', [],...
                'intcon',[],...
                'rngstate',[],...
                'options', this.solver_options);
            
            % Checks whether some variables are integer
            for ip = 1:numel(this.params)
                dom = this.BrSys.GetDomain(this.params{ip});
                if strcmp(dom.type, 'int')
                    problem.intcon = [problem.intcon ip];
                end
            end
            
        end
        
        %% Parallel 
        function SetupParallel(this)
            this.BrSys.SetupParallel();
            this.BrSys.Sys.Parallel=0;  % not intuitive, uh?
            this.use_parallel =1;
            this.log_traces = 0;
            this.objective= @(x) objective_fn(this,x);
        end
        
        %% Objective wrapper        
        function obj = objective_fn(this,x)
            % default objective_fn is simply robust satisfaction of the least
            obj = min(this.robust_fn(x));
        end
        
        function fval= objective_wrapper(this,x)
            % objective_wrapper calls the objective function and wraps some bookkeeping
            
            if this.stopping()==true
                fval = this.obj_best;
            else
                % calling actual objective function
                fval = this.objective_fn(x);
                
                % logging and updating best
                this.LogX(x, fval);
 
                % update status
                if rem(this.nb_obj_eval,this.freq_update)==1
                    this.display_status();
                end
                
            end
            
        end
        
        function b = stopping(this)
            b =  (this.time_spent > this.max_time) ||...
                    (this.nb_obj_eval> this.max_obj_eval) ;
        end
              
        %% Misc methods
        function LogX(this, x, fval)
            % LogX logs values tried by the optimizer

            this.X_log = [this.X_log x];
            this.obj_log = [this.obj_log fval];
            
            if (this.log_traces)
                if isempty(this.BrSet_Logged)
                    this.BrSet_Logged = this.BrSys.copy();
                else
                    this.BrSet_Logged.Concat(this.BrSys);
                end
            end
            
            [ fmin , imin] = min(fval);
            x_min =x(:, imin);
            if fmin < this.obj_best
                this.x_best = x_min;
                this.obj_best = fmin;
                this.BrSet_Best = this.BrSys.copy(); % could be more efficient - also suspicious when several x... 
            end
            
            % Timing and num_eval       
            this.nb_obj_eval= numel(this.obj_log);
            this.time_spent = toc(this.time_start);
            
        end
        
        function DispResultMsg(this)
            this.display_status();
            % DispResultMsg message displayed at the end of optimization
            if this.time_spent> this.max_time
                fprintf('\n Stopped after max_time was reached.\n');
            end
            
            if this.nb_obj_eval> this.max_obj_eval
                fprintf('\n Stopped after max_obj_eval was reached (maximum number of objective function evaluation.\n' );
            end
            
            fprintf('\n ---- Best value %g found with\n', this.obj_best);
            param_values = this.x_best;
            for ip = 1:numel(this.params)
                fprintf( '        %s = %g\n', this.params{ip},param_values(ip))
            end
            fprintf('\n');
            
        end
        
        function BrOut = GetBrSet_Logged(this)
            % GetBrSet_Logged gets BreachSet object containing parameters and traces computed during optimization
            if this.log_traces
                BrOut = this.BrSet_Logged;
            elseif ~isempty(this.BrSys.log_folder)
                BrOut = LoadLogFolder(this.BrSys.log_folder);
            else
                BrOut = this.BrSys.copy();
                BrOut.ResetSimulations();
                BrOut.SetParam(this.params, this.X_log);
            end
            BrOut.Sys.Verbose=1;
            BrOut.AddSpec(this.Spec);
        end
        
        function BrBest = GetBrSet_Best(this)
            BrBest = this.BrSet_Best;
            if isempty(BrBest)
                BrBest = this.BrSys.copy();
                BrBest.SetParam(this.params, this.x_best, 'spec');
                if ~isempty(this.BrSys.log_folder)
                   BrBest.Sim(); 
                end
            end
            BrBest.Sys.Verbose=1;
        end
        
        function SetupLogFolder(this, fname)
            if nargin<2
                this.BrSys.SetupLogFolder();
            else
                this.BrSys.SetupLogFolder(fname);
            end
            this.log_traces= false;
        end
        
        function display_status_header(this)
            fprintf(  '#calls (max:%5d)           time spent (max: %g)           best                         obj\n',...
                        this.max_obj_eval, this.max_time);           
        end
        
        function display_status(this,fval)
            
            if ~strcmp(this.display,'off')              
                if nargin==1
                    fval = this.obj_log(end); % bof bof
                end
                
                if this.nb_obj_eval==1
                    this.display_status_header();
                    rfprintf_reset();
                end
                
                st__= sprintf('    %5d                   %7.1f                            %+5.5e             %+5.5e\n', ...
                    this.nb_obj_eval, this.time_spent, this.obj_best, fval);
                switch this.display
                    case 'on'
                        fprintf(st__);
                    case 'light'
                        rfprintf(st__);
                end
            end
        end

        function [cmp, cmpSet, cmpSys, cmpBest, cmpLogged] = compare(this, other)
            % FIXME broken as per changes in BreachStatus
            cmp = BreachStatus();
            cmpSet = BreachStatus();
            cmpSys = BreachStatus();
            cmpBest = BreachStatus();
            cmpLogged= BreachStatus();
            
            if ~isequal(this,other)
                cmp.addstatus(-1, 'Something is different.')
                cmpSet = this.BrSet.compare(other.BrSet);
                if (cmpSet.status~=0)
                    cmp.addStatus(-1, 'Fields BrSet are different.');
                end
                cmpSys = this.BrSys.compare(other.BrSys);
                if (cmpSys.status~=0)
                    cmp.addStatus(-1, 'Fields BrSys are different.');
                end
                cmpBest   = this.BrSet_Best.compare(other.BrSet_Best);
                if (cmpBest.status~=0)
                    cmp.addStatus(-1, 'Fields BrSet_Best are different.');
                end
                cmpLogged = this.BrSet_Logged.compare(other.BrSet_Logged);
                if (cmpLogged.status~=0)
                    cmp.addStatus(-1, 'Fields BrSet_Logged are different.');
                end
            end
        end
        
        function new = copy(this)
            % copy operator for BreachSet, works with R2010b or newer.
            objByteArray = getByteStreamFromArray(this);
            new = getArrayFromByteStream(objByteArray);
        end
                
    end
end
