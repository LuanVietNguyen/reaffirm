bdclose all; clc; clear;
load_system('freedm_vs2');
root = sfroot;
diagram = root.find('-isa','Simulink.BlockDiagram');
model = diagram.find('-isa', 'Stateflow.Chart');
addInput(model,"switch");
% Get battery control components
batController1 = getComponent(model, "Bat1");
addEmptyState(batController1,"Init1");
delAllTransitions(batController1);
t1 = addTransition(batController1, "Init1", "To_bat1", "((d1 - (r1+p1) <= 0 && B1 < Bmax) || (d1 - (r1+p1)> 0 && B1 > 0)) && switch >= 0");
t1.addResetLabel("b1 = -(d1 - (r1+p1)); bm1 = bm1 + m");
addTransition(batController1, "To_bat1", "Init1", "switch < 0");
t2 = addTransition(batController1, "Init1", "To_grid1", "((d1 - (r1+p1) <= 0 && B1 < Bmax) || (d1 - (r1+p1)> 0 && B1 > 0)) && switch < 0");
t2.addResetLabel("b1 = 0; gr = gr - (d1 - (r1+p1)); grm = grm + m");
addTransition(batController1, "To_grid1", "Init1", "switch >= 0");
addDefaultTransition(batController1, "Init1");

batController2 = getComponent(model, "Bat2");
addEmptyState(batController2,"Init2");
delAllTransitions(batController2);
t3 = addTransition(batController2, "Init2", "To_bat2", "((d2 - (r2+p2) <= 0 && B2 < Bmax) || (d2 - (r2+p2)> 0 && B2 > 0)) && switch >= 0");
t3.addResetLabel("b2 = -(d2 - (r2+p2)); bm2 = bm2 - m");
addTransition(batController2, "To_bat2", "Init2", "switch < 0");
t3 = addTransition(batController2, "Init2", "To_grid2", "((d2 - (r2+p2) <= 0 && B2 < Bmax) || (d2 - (r2+p2)> 0 && B2 > 0)) && switch < 0");
t3.addResetLabel("b2 = 0; gr = gr - (d2 - (r2+p2)); grm = grm - m");
addTransition(batController2, "To_grid2", "Init2", "switch >= 0");
addDefaultTransition(batController2, "Init2");

%add_block('simulink/Sources/Random Number','freedm_vs2/switch', 'Position',[140,80,180,120]);
add_block('simulink/Sources/Random Number','freedm_vs2/switch', 'Position',[-200 20 -160 60]);
add_line('freedm_vs2','switch/1', 'Freedm-chart/2');
%set_param('freedm_vs2/switch','position',[50,200,180,120]);
% h1 = get_param('freedm_vs2/switch','PortHandles');
% h2 = get_param('freedm_vs2/Freedm-chart','PortHandles');
% add_line('freedm_vs2',h1.Outport(1),h2.Inport(2));
save_system('freedm_vs2', 'freedm_vs2_res')