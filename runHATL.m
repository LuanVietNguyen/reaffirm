function runHATL(hatlScript,modelFile,varargin)
%UNTITLED2 Summary of this function goes here
%   Detailed explanation goes here

if ~matlab.engine.isEngineShared
    matlab.engine.shareEngine
end

args = hatlScript + " " + modelFile;
if nargin == 3
    args = args + " --name " + varargin{1};
elseif nargin ~= 2
    error("Improper arguments to HATL interpreter")
end

%hatlPath = ".." + filesep + ".." + filesep + "python" + filesep;
hatlPath = "python" + filesep;
hatlProg = hatlPath + "hatl.py";

system("python" + " " + hatlProg + " " + args)

end
