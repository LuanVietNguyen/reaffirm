classdef copyModel < handle %< matlab.mixin.Copyable
   properties
      states
      trans
   end
   methods
      function copyModel = copyModel(obj, origin)
          if origin == "chart"
            copyModel.states = obj.find('-isa','Stateflow.State');
            copyModel.trans = obj.find('-isa','Stateflow.Transition');
          elseif origin == "copyModel"
              copyModel.states = obj.states;
              copyModel.trans = obj.trans;
          else
              error('invalid option')
          end          
      end
      
      function result = find(obj, propname)
          if propname == "trans"
              result = obj.trans;
          elseif propname == "states"
              result = obj.states;
          else
              error("oops no property with that name")
          end
      end
   end
   
end