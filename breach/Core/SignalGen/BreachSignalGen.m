classdef BreachSignalGen < BreachSystem
 % BreachSignalGen A class to generate signals of different types. 
 %   This class is derivated from BreachSystem, and thus inherits from all properties and methods.  
 %   It aggregates several instances of a simpler signal_gen class. The
 %   main use-case of this class is to as input generators for a
 %   BreachOpenSystem. It can also be used to interface an external
 %   simulator. 
 % 
 % BreachSignalGen Properties
 %   signalGenerators - cell array of signalgen object.
 %   dt_default=1e-3  - default fixed time step for signal generation.
 % 
 % BreachSignalGen Methods
 %       BreachSignalGen - constructor, takes a cell array of signal_gen
 %                         objects as only argument
 %
 %  
 % See also BreachOpenSystem, signal_gen
 
    properties
        signalGenerators
        dt_default=1e-3 % in case no time step is provided
    end
    
    methods
        %% Constructor
        function this = BreachSignalGen(signalGenerators)
    
            if nargin==0
               return; 
            end
            
            if ~iscell(signalGenerators)
               signalGenerators = {signalGenerators}; 
            end
            
            this.Domains = [];
            % we need to declare parameters, signals, p0, and simfn           
            this.InitSignalGen(signalGenerators);
            
        end
        
        function InitSignalGen(this, signalGenerators)
            this.signalGenerators = signalGenerators;
            signals ={}; 
            params = {};
            p0=[];

            ParamDomains = []; 
            SignalDomains = []; 
            for isg = 1:numel(signalGenerators)
                sg=  signalGenerators{isg};
                signals = {signals{:}, signalGenerators{isg}.signals{:}};
                params = {params{:}, signalGenerators{isg}.params{:}}; 
                
                % domains 
                num_sig = numel(sg.signals);
                if isempty(sg.signals_domain)
                    SignalDomains = [SignalDomains repmat(BreachDomain(),1, num_sig)];
                else
                    SignalDomains = [SignalDomains sg.signals_domain];
                end
                
                num_par = numel(sg.params);
                if isempty(sg.params_domain)
                    ParamDomains = [ParamDomains repmat(BreachDomain(),1, num_par)];
                else
                    ParamDomains = [ParamDomains sg.params_domain];
                end
                
                % default values
                p0sg = signalGenerators{isg}.p0;
                if size(p0sg,2) >1
                    p0sg = p0sg';
                end
                p0 = [p0; p0sg ];
            end
            this.Domains = [SignalDomains ParamDomains];
            
            p0 = [zeros(numel(signals),1) ; p0 ];
            this.Sys = CreateExternSystem('BreachSignalGen', signals, params, p0, @(Sys, tspan, p)breachSimWrapper(this, Sys, tspan, p));
            this.Sys.tspan =0:.01:10;
            this.P = CreateParamSet(this.Sys);
            this.P.epsi(:,:)=0 ;
            
            if isaSys(this.Sys) % Note: we ignore initial conditions for now in ParamRanges
                                % OK for Simulink, less so for ODEs...
                this.SignalRanges = [];
            end
            
            
        end
        
        function [tspan, X] = breachSimWrapper(this, Sys, tspan, p)
            
            if numel(tspan)==1
               tspan = 0:this.dt_default:tspan; 
            elseif numel(tspan)==2
               tspan = tspan(1):this.dt_default:tspan(2); 
            end
            
            p = p(this.Sys.DimX+1:end);
            cur_ip =1;
            cur_is =1;
            for isg = 1:numel(this.signalGenerators)
               np = numel(this.signalGenerators{isg}.params);
               p_isg = p(cur_ip:cur_ip+np-1);  % 
               ns = numel(this.signalGenerators{isg}.signals);
               X(cur_is:cur_is+ns-1, :) = this.signalGenerators{isg}.computeSignals(p_isg, tspan); 
               cur_ip = cur_ip+ np;
               cur_is = cur_is+ ns;
            end
                
        end
        
        function sg = GetSignalGenFromSignalName(this, sig_name)
        % GetSignalGenFromSignalName(this, sig_name) only works for one
        % dimensional signal generators so far
            for  is = 1:numel(this.Sys.DimX) 
                if strcmp(this.signalGenerators{is}.signals{1}, sig_name)  
                   sg = this.signalGenerators{is};
                   return;
                end
            end  
            error('signal not found.');
        end
    end
end
