
% add classes and functions subfolders to path

addpath(genpath('functions'));
addpath(genpath('breach'))
addpath(genpath('examples'))
addpath(genpath('python'))
setenv('REAFFIRM_ROOT',pwd)
% initialize breach
InitBreach;

% execute the ACC example
% acc;