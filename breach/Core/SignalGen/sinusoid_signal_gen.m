classdef sinusoid_signal_gen < signal_gen
    % sinusoid_signal_gen   A class derived from signal_gen to generate periodic sinusoid signals.
    %
    % sinusoid_signal_gen Methods
    %   pulse_signal_gen -  constructor, takes signal names, and an optional p0.
    %                       Each signal 'x' gets a 'x_sin_amp' and 'x_sin_offset' parameter, with default
    %                       to 1, and 0, respectively.
    %
    %  See also signal_gen.
    methods
    % The constructor must name the signals and the parameters needed to construct them.
        function this = sinusoid_signal_gen(signals, p0)
            this.signals = signals;
            this.params = {};
            this.p0 = zeros(3*numel(signals), 1);
            
           for i_s = 1:numel(this.signals)
               this.params = { this.params{:} [this.signals{i_s} '_sin_amp'] ...
                              [this.signals{i_s} '_sin_freq'] ...
                              [this.signals{i_s} '_sin_offset']};
               this.p0(3*(i_s-1)+1:3*i_s,1) = [1 1 0];
           end     
           
           if nargin == 2
               this.p0 = p0;
           end

           this.params_domain = repmat(BreachDomain(), 1, numel(this.params));
           this.signals_domain = repmat(BreachDomain(), 1, numel(this.signals));
        end
        % The class must implement a method with the signature below
        function [X, time] = computeSignals(this, p, time)
            if numel(p) ~= 3*numel(this.signals)
                error('Wrong number of parameters for computing sinusoid signal.' )
            end
            if size(p,1) ==1
                p = p';
            end
            X = zeros(numel(this.signals),numel(time));
            
            for i_s = 0:numel(this.signals)-1 
                pi_s = p(3*i_s+1:3*i_s+3);
                amplitude = pi_s(1);
                frequency = pi_s(2);
                offset = pi_s(3);
                X(i_s+1,:) = amplitude*cos(2*pi*frequency*time)+ offset;          
            end

        end
        function type = getType(this)
            type = 'sinusoid';
        end
    end
end
