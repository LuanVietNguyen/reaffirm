% a function which calls HATL to transform an orignal model "modelName"
% using a pattern "patternFile"
% return the name of a repaired model
function [resModelName] = model_transformation(patternFile, modelName, varargin)
    resModelName = [modelName,'_resilient'];
    tStartT = tic;
    if nargin == 2
        runHATL(patternFile,modelName);
    else
        runHATL(patternFile,modelName,varargin);
    end
    tTransform=toc(tStartT);
    fprintf('Total transformation time %f\n',tTransform);
end