function InitBreach(br_dir)
% InitBreach This script initializes Breach, in particular adding paths to Breach directories

% checks if global configuration variable is defined
global BreachGlobOpt
if isfield(BreachGlobOpt, 'breach_dir')
    if ~exist('br_dir', 'var') || isequal(BreachGlobOpt.breach_dir, br_dir)
        return; % OK InitBreach has been run before
    end
end

if ~exist('br_dir', 'var')
    br_dir = which('InstallBreach');
    br_dir = fileparts(br_dir);
end

% remove old path, if any
if isfield(BreachGlobOpt, 'breach_dir')
    if isfield(BreachGlobOpt, 'list_path')  % we listed paths from previous version
        rmpath(BreachGlobOpt.list_path{:});
    else % in case we're dealing with an older version of Breach (dangerous, let's warn)
        warning('Breach:RemoveOldPath','Older version of Breach detected. Attempting to clean old path by removing every path with ''breach'' in it.');
        old_dr = BreachGlobOpt.breach_dir;
        toks = regexp(old_dr, ['(' old_dr '[\w' filesep '\+_-]*):'],'tokens');
        for ii = 1:numel(toks)
            rmpath(toks{ii}{1});
        end
    end
end

disp(['Initializing Breach from folder ' br_dir '...']);

id = 'MATLAB:dispatcher:nameConflict';
warning('off',id);

cdr = pwd;
cd(br_dir);

list_path = { ...
    br_dir, ...
    [br_dir filesep 'Core'], ...
    [br_dir filesep 'Core' filesep 'm_src'], ...
    [br_dir filesep 'Core' filesep 'Algos'], ...
    [br_dir filesep 'Core' filesep 'SignalGen'], ...
    [br_dir filesep 'Params'], ...
    [br_dir filesep 'Params' filesep 'm_src'], ...
    [br_dir filesep 'Params' filesep 'm_src' filesep 'sobolqr'], ...
    [br_dir filesep 'Params' filesep 'm_src' filesep 'niederreiter2'], ...
    [br_dir filesep 'Plots'], ...
    [br_dir filesep 'Plots' filesep 'm_src'], ...
    [br_dir filesep 'Online' filesep 'm_src'], ...
    [br_dir filesep 'Online' filesep 'bin'], ...
    [br_dir filesep 'Online' filesep 'simulink_stlib'], ...
    [br_dir filesep 'Examples'], ...
    [br_dir filesep 'Ext' filesep 'Models'], ...
    [br_dir filesep 'Ext' filesep 'Specs'], ...
    [br_dir filesep 'Ext' filesep 'Classes'], ...
    [br_dir filesep 'Ext' filesep 'Specs' filesep 'STLib'], ...
    [br_dir filesep 'Ext' filesep 'ModelsData'], ...
    [br_dir filesep 'Ext' filesep 'Toolboxes'], ...
    [br_dir filesep 'Ext' filesep 'Toolboxes' filesep 'optimize'], ...
    [br_dir filesep 'Ext' filesep 'Toolboxes' filesep 'DataHash'], ...
    [br_dir filesep 'Ext' filesep 'Toolboxes' filesep 'simulink_custom'], ...
    [br_dir filesep 'Ext' filesep 'Toolboxes' filesep 'sundials' filesep 'sundialsTB' ], ...
    [br_dir filesep 'Ext' filesep 'Toolboxes' filesep 'sundials' filesep 'sundialsTB' filesep 'cvodes'], ...
    };

addpath(list_path{:});

%% Init BreachGlobOpt options and fourre-tout global variable
if exist('BreachGlobOpt.mat')
    load BreachGlobOpt;
    
    % Convert BreachGlobOpt into global
    BreachGlobOptTmp = BreachGlobOpt;
    clear BreachGlobOpt;
    global BreachGlobOpt;
    BreachGlobOpt = BreachGlobOptTmp;
    clear BreachGlobOptTmp;
    BreachGlobOpt.RobustSemantics = 0 ; % 0 by default, -1 is for left time robustness, +1 for right, inf for sum ?
    
else
    
    BreachGlobOpt.breach_dir = br_dir;
    
    if ~isfield(BreachGlobOpt,'RobustSemantics')
        BreachGlobOpt.RobustSemantics = 0;
    end
    
end
cd(cdr);


%% Init STL_Formula database

if isfield(BreachGlobOpt, 'STLDB')
    if ~strcmp(class(BreachGlobOpt.STLDB), 'containers.Map')
        BreachGlobOpt.STLDB = containers.Map();
    end
else
    BreachGlobOpt.STLDB = containers.Map();
end

%% Store path_list for when we want to remove it
BreachGlobOpt.list_path = list_path;

warning('on',id);

end