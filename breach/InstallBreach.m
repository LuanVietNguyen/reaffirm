function InstallBreach(silent)
%INSTALLBREACH compiles C/C++ mex functions used by Breach. Needs only to
% be called once after an update of Breach

if (~exist('silent','var'))
   silent =1;  
end

MEX = 'mex ';
FLAGS = ' '; 
if silent
   FLAGS = [FLAGS ' -silent '];
end

InitBreach
cdr = pwd;
dr = which('InstallBreach');

% setup directories of interest

breach_dir = dr(1:end-16);
breach_src_dir = [breach_dir filesep 'Core' filesep 'src']; 
stl_src_dir  = [breach_dir filesep '@STL_Formula' filesep 'private' filesep 'src'];

% compile STL mex functions
fprintf('\nCompiling legacy STL monitoring functions...\n')
cd(stl_src_dir);

legacy_functions = { ' lemire_engine.c', ... 
                     ' lemire_nd_engine.c', ...
                     ' lemire_nd_maxengine.c', ... 
                     ' lemire_nd_minengine.c', ... 
                     ' until_inf.c', ...   
                     ' lim_inf.c', ...          
                     ' lim_inf_inv.c', ...         
                     ' lim_inf_indx.c', ...
                    };

for ilf = 1:numel(legacy_functions)
  cmd = [MEX FLAGS '-outdir ..' legacy_functions{ilf}];
  eval(cmd);
end
 
legacy_functions_time_robustness= {                     
                     ' ltr.c',...
                     ' rtr.c',...
    };
    
for ilf = 1:numel(legacy_functions_time_robustness)
  cmd = [MEX FLAGS '-outdir ../../../Core/m_src ' legacy_functions_time_robustness{ilf}];
  eval(cmd)
end

if (0)
  fprintf([MEX FLAGS '-outdir .. lemire_engine.c\n']);
  mex -outdir .. lemire_engine.c
  fprintf([MEX FLAGS '-outdir .. lemire_nd_engine.c\n']);
  mex -outdir .. lemire_nd_engine.c
  fprintf([MEX FLAGS '-outdir .. lemire_nd_maxengine.c\n']);
  mex -outdir .. lemire_nd_maxengine.c
  fprintf([MEX FLAGS '-outdir .. lemire_nd_minengine.c\n']);
  mex -outdir .. lemire_nd_minengine.c
  fprintf([MEX FLAGS '-outdir .. until_inf.c\n']);
  mex -outdir .. until_inf.c
  fprintf([MEX FLAGS '-outdir .. lim_inf.c\n']);
  mex -outdir .. lim_inf.c
  fprintf([MEX FLAGS '-outdir .. lim_inf_inv.c\n']);
  mex -outdir .. lim_inf_inv.c
  fprintf([MEX FLAGS '-outdir .. lim_inf_indx.c\n']);
  mex -outdir .. lim_inf_indx.c
  fprintf([MEX FLAGS '-outdir ../../../Core/m_src ltr.c\n']);
  mex -outdir ../../../Core/m_src/ ltr.c
  fprintf([MEX FLAGS '-outdir ../../../Core/m_src rtr.c\n']);
  mex -outdir ../../../Core/m_src/ rtr.c
end


cd robusthom;
fprintf('Compiling offline STL monitoring functions...\n')
CompileRobusthom;
    
% compiles cvodes common stuff
sundials_dir = [breach_dir filesep 'Ext' filesep 'Toolboxes' filesep 'sundials'];
sundials_inc_dir = [sundials_dir filesep 'include'];
sundials_src_dir = [sundials_dir filesep 'src' filesep 'sundials'];
sundials_cvodes_src_dir = [sundials_dir filesep 'src' filesep 'cvodes'];
sundials_nvm_src_dir = [sundials_dir filesep 'sundialsTB' filesep 'nvector' filesep 'src'];
cvodesTB_src_dir =  [breach_dir filesep 'Core' filesep 'cvodesTB++' filesep 'src'];

sundials_inc_flags = [' -I' qwrap(breach_src_dir) ...
                      ' -I' qwrap(sundials_inc_dir) ...
                      ' -I' qwrap(sundials_cvodes_src_dir) ...
                      ' -I' qwrap(cvodesTB_src_dir) ...
                      ' -I' qwrap(sundials_nvm_src_dir) ...
                    ];

sundials_src_files = [ 
           qwrap([sundials_nvm_src_dir filesep 'nvm_serial.c']) ...
           qwrap([sundials_nvm_src_dir filesep 'nvm_ops.c']) ...
           qwrap([sundials_cvodes_src_dir filesep 'cvodes_band.c']) ...
           qwrap([sundials_cvodes_src_dir filesep 'cvodes_bandpre.c']) ...
           qwrap([sundials_cvodes_src_dir filesep 'cvodes_bbdpre.c']) ...
           qwrap([sundials_cvodes_src_dir filesep 'cvodes_dense.c']) ...
           qwrap([sundials_cvodes_src_dir filesep 'cvodes_diag.c']) ...
           qwrap([sundials_cvodes_src_dir filesep 'cvodea.c']) ...
           qwrap([sundials_cvodes_src_dir filesep 'cvodes.c']) ...
           qwrap([sundials_cvodes_src_dir filesep 'cvodes_io.c']) ...
           qwrap([sundials_cvodes_src_dir filesep 'cvodea_io.c']) ...
           qwrap([sundials_cvodes_src_dir filesep 'cvodes_spils.c']) ...
           qwrap([sundials_cvodes_src_dir filesep 'cvodes_spbcgs.c']) ...
           qwrap([sundials_cvodes_src_dir filesep 'cvodes_spgmr.c']) ...
           qwrap([sundials_cvodes_src_dir filesep 'cvodes_sptfqmr.c']) ...
           qwrap([sundials_src_dir filesep 'sundials_band.c']) ...
           qwrap([sundials_src_dir filesep 'sundials_dense.c']) ...
           qwrap([sundials_src_dir filesep 'sundials_iterative.c']) ...
           qwrap([sundials_src_dir filesep 'sundials_nvector.c']) ...
           qwrap([sundials_src_dir filesep 'sundials_smalldense.c']) ...
           qwrap([sundials_src_dir filesep 'sundials_spbcgs.c']) ...
           qwrap([sundials_src_dir filesep 'sundials_spgmr.c']) ...
           qwrap([sundials_src_dir filesep 'sundials_sptfqmr.c']) ...
           qwrap([sundials_src_dir filesep 'sundials_math.c']) ...
           qwrap([sundials_dir filesep  'src' filesep 'nvec_ser' filesep 'nvector_serial.c' ])... 
           ];

out_dir = qwrap([breach_src_dir  filesep 'cv_obj']);

% Compose and execute compilation command for CVodes common files.
compile_cvodes = [MEX FLAGS '-c -outdir ' out_dir ' ' sundials_inc_flags ' ' sundials_src_files ];
%fprintf(regexprep(compile_cvodes,'\','\\\\'));
fprintf('Compiling some more legacy functions...\n');
eval(compile_cvodes);

% Compile blitz library
blitz_dir = [breach_dir filesep 'Ext' filesep 'Toolboxes' filesep 'blitz'];
cd(blitz_dir);
CompileBlitzLib;

% Compile mydiff
if (0) % TODO move this into a dedicated script
    cd([breach_dir filesep 'Toolboxes' filesep 'mydiff']);
    fprintf([MEX FLAGS '-lginac mydiff_mex.cpp\n']);
    try
        mex -lginac mydiff_mex.cpp
    catch %#ok<CTCH>
        warning('InstallBreach:noMydiffCompilation',...
            ['An error occurs when compiling mydiff. Maybe GiNaC not available.\n'...
            'Some functionnalities will not be available.']);
        fprintf('\n'); 
    end
end

fprintf('Compiling online monitoring functions...\n')
compile_stl_mex

addpath(breach_dir);
savepath;

% cd back and clean variable
cd(cdr);

fprintf('\n');
disp('-------------------------------------------------------------------');
disp('- Install successful.                                            --')
disp('-------------------------------------------------------------------');


end
    
function qst = qwrap(st)
% necessary for dealing with £¨% spaces in dirnames...

qst = ['''' st ''' '];

end
