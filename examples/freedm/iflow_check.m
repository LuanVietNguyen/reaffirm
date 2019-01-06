clc; clear all; bdclose all;
lowvars = {'gr', 't'};
insecure_trans = NonDeducibility('freedm_vs2',lowvars);


































% load_system('freedm_vs2');
% root = sfroot;
% diagram = root.find('-isa','Simulink.BlockDiagram');
% model = diagram.find('-isa', 'Stateflow.Chart');
% %orState = model.find('-isa','Stateflow.State','-and','Type','OR');
% states = model.find('-isa','Stateflow.State','-and','Decomposition','EXCLUSIVE_OR','-and','TYPE', 'AND');
% k = 1;
% lowvars = {'gr', 't'};
% for i = 1: length(states)
%     trans = getTransitions(states(i));
%     for j = 1 : length(trans)
%         if notDefaultTransition(trans(j))
%             trans(j).LabelString
%             isSecureTran(trans(j), lowvars)
%             if ~isSecureTran(trans(j), lowvars)
%                insecure_trans{k} = trans(j);
%                k = k + 1;
%             end
%         end
%     end
% end
% 
% if k > 1
%     for i = 1: k-1
%         fprintf('Insecure transition: %s\n',insecure_trans{i}.LabelString);
%     end   
% else
%    fprintf('No insecure transition found\n'); 
% end
% 
% function out = isSecureTran(t, lowvars)
%     out = true;
%     if ~isempty(t.LabelString)
%         guard = char(extractBetween(t.LabelString,'[',']'));
%         update = char(extractBetween(t.LabelString,'{','}'));
%         if isLowUpdate(update, lowvars) && isHighGuard(guard, lowvars)
%             out = false;
%         end
%     end
% end
% 
% function out = isHighGuard(guard, lowvars)
%     out = true;
%     if ~isempty(guard)
%         elements = strsplit(guard,{'!','||','<','>','>=','<=','==','&&',' ','+','-','*','/','(',')'});
%         if ~isempty(intersect(elements,lowvars))
%             out = false;
%         end
%     end
% end
% 
% function out = isLowUpdate(update, lowvars)
%     out = false;
%     if ~isempty(update)      
%         elements = strsplit(update,{';', ','});
%         if ~isempty(elements)
%             for i = 1:length(elements)
%                 asig = strsplit(elements{i},{' ','+','-','*','/','(',')'});
%                 for j = 1:length(asig) - 1
%                     if ~isempty(intersect(asig(j),lowvars)) && strcmp(asig(j+1),'=')
%                         out = true;
%                         break
%                     end
%                 end
%             end
%         end
%     end
% end