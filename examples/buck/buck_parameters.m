% initial values of state variables
Vn = 0;
i0 = 0;
v0 = 0;
%v0 = 0.646;

%Define Buck paramerts
T = 1/50000;
Vs = 24;
Vref = 12;
Vtol = Vref/120;% Tolerance level for hysteresis band of controller
Vtol_safe = Vref/30; % Safe tolerance level
C = 2.2e-3;
L = 2.65e-3;
R = 10;% load resistance
rs = 200e-3;% switching loss
rL = 520e-3;%  inductor loss
Tmax = T*1000;% 
    
% Define transition matrices

Ac_nom = [-1*(rs+rL)/L, -(1/L); (1/C), -(1/(R*C))];% switch closed
Bc_nom = [(1/L); 0];

Ao_nom = [-rL/L, -(1/L); (1/C), -(1/(R*C))];% switch open
Bo_nom = [0; 0];
        
Ad_nom = [0, 0; 0, -(1/(R*C))];%For DCM
Bd_nom = [0; 0];%For DCM
        
%D = Vref / Vs;% duty cycle; multiply with cr incase of open loop

sys(1).Ac = Ac_nom;
sys(1).Bc = Bc_nom;
sys(1).Ao = Ao_nom;
sys(1).Bo = Bo_nom;
sys(1).Ad = Ad_nom;%For DCM
sys(1).Bd = Bd_nom;%For DCM
    
% set parameters used in stateflow simulation
a00c = sys(1).Ac(1,1);
a01c = sys(1).Ac(1,2);
a10c = sys(1).Ac(2,1);
a11c = sys(1).Ac(2,2);
    
b0c = sys(1).Bc(1);
b1c = sys(1).Bc(2);
    
a00o = sys(1).Ao(1,1);
a01o = sys(1).Ao(1,2);
a10o = sys(1).Ao(2,1);
a11o = sys(1).Ao(2,2);
    
b0o = sys(1).Bo(1);
b1o = sys(1).Bo(2);
    
%DCM
    
a00d = sys(1).Ad(1,1);
a01d = sys(1).Ad(1,2);
a10d = sys(1).Ad(2,1);
a11d = sys(1).Ad(2,2);
    
b0d = sys(1).Bd(1);
b1d = sys(1).Bd(2);
