classdef impulse_signal_gen < signal_gen
    % step_signal_gen   A class derived from signal_gen to generate simple impulse signals.
    %  
    % impulse_signal_gen Methods
    %   impulse_signal_gen -  constructor, takes signal names, and an optional p0.
    %                       Each signal 'x' gets a 'x_base_value',
    %                       'x_impulse_time', 'x_impulse_period'
    %                       and 'x_step_amp' parameter, with default value
    %                       to 0, 1, 1,and 1 respectively. 
    %                         
    %  See also signal_gen.  
 
    
    methods 
        
        function this = impulse_signal_gen(signals)
           this.signals = signals; 
           this.params = {};
           for i_s = 1:numel(this.signals)
               this.params = { this.params{:} [this.signals{i_s} '_base_value'] ...
                              [this.signals{i_s} '_impulse_time']... 
                              [this.signals{i_s} '_impulse_period']... 
                              [this.signals{i_s} '_impulse_amp']};
               this.p0(4*(i_s-1)+1:4*i_s,1) = [0 1 1 1];

           end     
           
           if nargin == 2
               this.p0 = p0;
           end

           this.params_domain = repmat(BreachDomain(), 1, numel(this.params));
           this.signals_domain = repmat(BreachDomain(), 1, numel(this.signals));
 
           
        end
        
                
        function params = getParamNames(this) % get parameterization names, e.g., signal1_u0, signal2_u0, etc                                             
            params = this.params;
        end
            
        function X = computeSignals(this,p, time) % compute the signals
            if numel(p) ~= 4*numel(this.signals)
                error('Wrong number of parameters for computing constant signal.' )
            end
            if size(p,1) ==1
                p = p';
            end
            
            X = repmat(p(1:4:end), 1, numel(time));
            
            for i_s = 0:numel(this.signals)-1 
                pi_s = p(4*i_s+1:4*i_s+4);
                i_after = find(time>pi_s(2) & time<pi_s(2)+ pi_s(3));
                X(i_s+1,i_after) = X(i_s+1,i_after)+pi_s(4);              
            end
           
        end
        
        function type = getType(this)
            type = 'impulse';
        end
    end
            
end


