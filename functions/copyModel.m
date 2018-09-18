classdef copyModel %< matlab.mixin.Copyable
   properties
      states
      trans
   end
   methods
      function copyModel = copyModel(chart)
        copyModel.states = chart.find('-isa','Stateflow.State');
        copyModel.trans = chart.find('-isa','Stateflow.Transition');
      end
   end
   
end