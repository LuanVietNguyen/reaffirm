classdef sinusoid_signal_gen < signal_gen
    % sinusoid_signal_gen   A class derived from signal_gen to generate periodic sinusoid signals.
    %
    % sinusoid_signal_gen Methods
    %   pulse_signal_gen -  constructor, takes signal names, and an optional p0.
    %                       Each signal 'x' gets a 'x_sin_amp' and 'x_sin_offset' parameter, with default
    %                       to 1, 0, and 0, respectively.
    %
    %  See also signal_gen.
    methods
    % The constructor must name the signals and the parameters needed to construct them.
        function this = sinusoid_signal_gen(signals, p0)
            this.signals = signals;
            this.params = {};
            this.p0 = zeros(2*numel(signals), 1);
            
           for i_s = 1:numel(this.signals)
               this.params = { this.params{:} [this.signals{i_s} '_sin_amp'] ...
                              [this.signals{i_s} '_sin_offset']};
               this.p0(2*(i_s-1)+1:2*i_s,1) = [1 0];
           end     
           
           if nargin == 2
               this.p0 = p0;
           end

           this.params_domain = repmat(BreachDomain(), 1, numel(this.params));
           this.signals_domain = repmat(BreachDomain(), 1, numel(this.signals));
        end
        % The class must implement a method with the signature below
        function [X, time] = computeSignals(this, p, time)
            if numel(p) ~= numel(this.signals)
                error('Wrong number of parameters for computing sinusoid signal.' )
            end
            if size(p,1) ==1
                p = p';
            end
            X = zeros(numel(this.signalls),numel(time));
            
            for i_s = 0:numel(this.signals)-1 
                pi_s = p(2*i_s+1:2*i_s+2);
                amplitude = pi_s(1);
                offset = pi_s(2);
                X(i_s+1,:) = amplitude*cos(time)+ offset;          
            end

        end
    end
end
