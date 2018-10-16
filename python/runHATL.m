function runHATL(hatlScript,modelFile,varargin)
%RUNHATL run the HATL interpreter given a script and model file
%   Run HATL on a model transformation script. Also input the
%   modelfile of the SLSF model desired to be transformed. If the
%   model file contains multiple models, please specify the name of
%   a single model to be transformed

[~, output] = system("python -V");

if ~contains(output,"Python 3.6")
    error("Invalid python version, must run Python 3.6 or greater")
end

if matlab.engine.isEngineShared
   error("Do not share the engine when running HATL from inside MATLAB")
end

args = hatlScript + " " + modelFile;
if nargin == 3
    args = args + " --name " + varargin{1};
elseif nargin ~= 2
    error("Improper arguments to HATL interpreter")
end

hatlPath = ".." + filesep + ".." + filesep + "python" + filesep;
%hatlPath = "python" + filesep;
hatlInterpreter = hatlPath + "hatl.py";

err = system("python" + " " + hatlInterpreter + " " + args + "--fromMATLAB");
if err
    error("HATL failed")
end

end
