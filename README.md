# REAFFIRM: Model-Based Repair of Hybrid Systems for Improving Resiliency

**Tool Overview**: 
* REAFFIRM takes the following inputs: 1) an original hybrid system modeled as a Simulink/Stateflow diagram, 2) a given resiliency pattern specified as a model transformation script, and 3) a safety requirement expressed as a Signal Temporal Logic formula, and then outputs a repaired model which satisfies the requirement. 

* REAFFIRM contains two main modules, a model transformation, and a model synthesizer.

* Resiliency patterns are specified as HATL (Hybrid Automata Transformation Language) scripts. 

**Installation Requirements**: 
* The HATL language is designed using ANTLR v4 and the interpreter is written in Python. The model transformation of REAFFIRM dynamically interprets HATL scripts in Python and translates them into Stateflow model transformations via the Matlab Engine. A user needs to make the following setup and installations.  
  - Add ANTLR (.\reaffirm\Javalib\antlr-4.7.1-complete.jar) to the CLASSPATH
  - Install python runtime targets e.g., pip install antlr4-python3-runtime 
  - Install the Matlab Engine for Python following the instruction at https://www.mathworks.com/help/matlab/matlab_external/install-the-matlab-engine-for-python.html   
  
* The model synthesizer of REAFFIRM built on top of the falsification tool Breach. To install Breach, run the script .\reaffirm\breach\installBreach.m in Matlab. More infomation about Breach can be found at https://github.com/decyphir/breach

**Tool Usages**: 
* Run the script .\reaffirm\Init_reaffirm.m to add required classes and functions subfolders to the Matlab path
* To perform the model repair for the ACC example: cd to .\reaffirm\examples\acc folder and run acc_execution.m
* To perform the model repair for the SMIB example: cd to .\reaffirm\examples\smartpower folder and run smib_execution.m
