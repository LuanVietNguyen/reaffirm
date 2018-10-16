import sys
from antlr4 import *
from antlr4.InputStream import InputStream
import pdb
import os
import argparse
from enum import Enum

sys.path.append("/Users/gautam/research/CASE/reaffirm/python")
#os.chdir("python")

from ReaffirmLexer import ReaffirmLexer
from ReaffirmParser import ReaffirmParser
from ReaffirmVisitor import ReaffirmVisitor

from matlab import engine
from matlab.engine import MatlabExecutionError
import io

scriptFile = None

def doCleanup():
    print("TODO: cleanup MATLAB engine / Stateflow edits properly")

def errorClose(ctx, msg):
    print("At line " + repr(ctx.start.line) + ", column " +
          repr(ctx.start.column) + " in " + scriptFile + ":", file=sys.stderr)
    print("\t" + msg, file=sys.stderr)
    doCleanup()
    exit()

def issingle(ctx, arg):
    single = None
    if hasattr(arg,'size'): #arg is a matlab object
        single = arg.size == (1,1)
    else:
        single = len(arg) == 1
    if not single:
        errorClose(ctx, "error: Argument in expression '" +
                        ctx.getText() + "' must be a single value")

def istype(ctx, arg, ty):
    if not isinstance(arg,ty):
        errorClose(ctx, "error: In '" + ctx.getText() +
                   "', argument is a '" + type(arg).__name__ +
                   "', must be a '" + ty.__name__ + "'")

def ismode(ctx, arg): istype(ctx, arg, Mode)
def istrans(ctx, arg): istype(ctx, arg, Transition)
def ismodel(ctx, arg): istype(ctx, arg, Model)
def istext(ctx, arg): istype(ctx, arg, str)

def check(ctx,arg, predicates): [p(ctx, arg) for p in predicates]

class Model:
    def __init__(self, matlab_var, engine):
        self.engine = engine
        self.matlab_var = matlab_var
        self.Mode = {Mode(m[0],engine)
                      for m in engine.find(matlab_var,'-isa','Stateflow.State')}
        self.Trans = {Transition(t[0],engine)
                      for t in engine.find(matlab_var,'-isa','Stateflow.Transition')}
        for t in self.Trans.copy():
             if t.source.matlab_var.size == (0,0):
                 self.Trans.remove(t)
        self.param = None

    def addMode(self, ctx, mode):
        check(ctx,mode,[ismode, issingle])

        raw_mode = self.engine.addState(self.matlab_var, mode.matlab_var)
        newmode = Mode(raw_mode, self.engine)
        self.modes.add(newmode)
        return newmode

    def addTransition(self, ctx, src, dest, eqn):
        check(ctx, src, [ismode, issingle])
        check(ctx, dest,[ismode, issingle])
        istext(ctx, eqn)

        raw_trans = self.engine.addTransition(self.matlab_var,
                                             src.matlab_var, dest.matlab_var, eqn)
        newtrans = Transition(raw_trans, self.engine)
        self.Trans.add(newtrans)
        return newtrans

    def addParam(self, ctx, param):
        istext(ctx, param)
        self.param = self.engine.addParam(self.matlab_var,param)

    def addLocalVar(self, ctx, localvar):
        istext(ctx, localvar)
        self.localVar = self.engine.addVariable(self.matlab_var,localvar,'Local')

    def copyModel(self, ctx):
        mvar = self.engine.copyModel(self.matlab_var, "chart")
        return CopyModel(mvar, self.engine)

    def getCopy(self, ctx, mode):
        copymodes = [m for m in self.modes if m.name == (mode.name + '_copy')]
        if copymodes == []:
            errorClose(ctx, "In '" + ctx.getText() + "', did not find a copy of the mode ")
        elif len(copymodes) > 1:
            errorClose(ctx, "Error: In '" + ctx.getText() + "', multiple copies found.")

        return copymodes[0]


class CopyModel:
    def __init__(self, matlab_var, engine, copy=None):
        self.engine = engine
        self.matlab_var = matlab_var
        self.Mode = {Mode(m[0],engine)
                          for m in engine.find(matlab_var,'states')}
        self.Trans = {Transition(t[0],engine)
                          for t in engine.find(matlab_var,'trans')}
        for t in self.Trans.copy():
            if t.source.matlab_var.size == (0,0):
                self.Trans.remove(t)

    def copyModel(self, ctx):
        return CopyModel(self, self.engine.copyModel(self.matlab_var,"copyModel"),
                         engine, "copy")


class Mode:
    def __init__(self, matlab_var, engine):
        self.engine = engine
        self.matlab_var = matlab_var
        self.outgoing = 2
        self.incoming = 2

    def replace(self,ctx, old_var,new_var):
        istext(ctx, old_var)
        istext(ctx, new_var)
        old_flow = self.engine.get(self.matlab_var,'LabelString')
        new_flow = old_flow.replace(old_var,new_var)
        self.engine.set(self.matlab_var,'LabelString',new_flow,nargout=0)

    #Flow is read-only, since updates must happen per-mode otherwise
    #changes will not be propagated to MATLAB
    @property
    def flow(self):
        return self.engine.get(self.matlab_var,'LabelString')

    @property
    def size(self):
        return self.matlab_var.size

    @property
    def name(self):
        return self.engine.get(self.matlab_var,'Name')

    def addFlow(self, ctx, eqn):
        istext(ctx, eqn)
        self.engine.addFlow(self.matlab_var, eqn,nargout=0)


class Transition:
    def __init__(self, matlab_var, engine):
        self.matlab_var = matlab_var
        self.engine = engine

        getField = lambda f : engine.get(matlab_var, f)
        #TODO: note, this might be really bad, since we are creating
        #multiple Python mode wrappers that point to the same
        #underlying MATLAB object. I don't know if this will be a
        #problem or not.
        self.source = Mode(getField('Source'),engine)
        self.destination = Mode(getField('Destination'),engine)
        self.guard = getField('LabelString')
        self.start = False

    def addGuardLabel(self, ctx, relation, label):
        istext(ctx, relation)
        istext(ctx, label)

        self.engine.addGuardLabel(self.matlab_var,relation,label,nargout=0)

    def addResetLabel(self, ctx, label):
        istext(ctx, label)

        self.engine.addResetLabel(self.matlab_var,label,nargout=0)

    @property
    def size(self):
        return self.matlab_var.size


class MATLABVisitor(ReaffirmVisitor):
    def __init__(self, e, modelfile, modelname=None):
        self.env = {}
        self.functions = {}
        print("Initializing!")
        self.modelfile = modelfile
        self.eng = e
        m = None
        if modelname:
            m = e.find(e.find(e.sfroot(),'-isa','Simulink.BlockDiagram')
                            ,'-isa','Stateflow.Chart','-and','Name',modelname)
        else:
            m = e.find(e.find(e.sfroot(),'-isa','Simulink.BlockDiagram')
                            ,'-isa','Stateflow.Chart')
        if not m.size == (1,1):
            raise Exception("Unable to Initialize Model")

        self.env['model'] = Model(m, e)

    # visit a parse tree produced by ReaffirmParser#prog.
    def visitProg(self, ctx:ReaffirmParser.ProgContext):
        print("Entering Program")
        self.visitChildren(ctx)

        print("Script Successful - saving model")

        self.eng.sfsave(self.modelfile, self.modelfile + '_resilient',nargout=0)
        return

    # Visit a parse tree produced by ReaffirmParser#printExpr.
    def visitPrintExpr(self, ctx:ReaffirmParser.PrintExprContext):
        return self.visitChildren(ctx)


    # Visit a parse tree produced by ReaffirmParser#assignment.
    def visitAssignment(self, ctx:ReaffirmParser.AssignmentContext):
        return self.visitChildren(ctx)

    # Visit a parse tree produced by ReaffirmParser#loop.
    def visitLoop(self, ctx:ReaffirmParser.LoopContext):
        print("visitLoop")
        return self.visitChildren(ctx)


    # Visit a parse tree produced by ReaffirmParser#condtion.
    def visitCondtion(self, ctx:ReaffirmParser.CondtionContext):
        print("visitCondtion")
        return self.visitChildren(ctx)

    # Visit a parse tree produced by ReaffirmParser#blank.
    def visitBlank(self, ctx:ReaffirmParser.BlankContext):
        print("visitBlank")
        return self.visitChildren(ctx)


    # Visit a parse tree produced by ReaffirmParser#block.
    def visitBlock(self, ctx:ReaffirmParser.BlockContext):
        print("visitBlock")
        return self.visitChildren(ctx)

    # Visit a parse tree produced by ReaffirmParser#id.
    def visitId(self, ctx:ReaffirmParser.IdContext):
        print("visitId")
        try:
            return self.env[ctx.getText()]
        except KeyError as e:
            errorClose(ctx,"Unknown reference to '" + ctx.getText() + "'")

    # Visit a parse tree produced by ReaffirmParser#objectRef.
    def visitObjectRef(self, ctx:ReaffirmParser.ObjectRefContext):
        print("visit objectref")
        refs = ctx.children[0].children[:]
        ident = refs.pop(0).getText() #must be Terminal

        #need to check that ident is in env
        try:
            obj = self.env[ident]
        except KeyError as e:
            errorClose(ctx,"Unknown reference to '" + ident + "'")

        for ref in refs:
            attr = None
            #find the attr name. methods have junk after '(' that we
            #have to get rid of. also strip leading '.'
            refname = ref.getText().split('(')[0][1:]
            try:
                attr = getattr(obj,refname)
            except AttributeError as e:
                errorClose(ref,"Unknown reference to " + refname)

            #if attr is a fieldref, resolve it.

            if not callable(attr):
                obj = attr
            else:
                # if attr is methodref, find args, eval them, and apply
                # the method

                # if attr is methodref, find args (if any), eval them
                # and pass to the method. Evaluation is therefore eager
                getNonTerminals = \
                lambda children : [ctx for ctx in children
                                   if not type(ctx).__name__ == 'TerminalNodeImpl']

                arglist = getNonTerminals(ref.children[1].children)
                assert(len(arglist) <= 1)
                if arglist:
                    args = getNonTerminals(arglist[0].children)
                    try:
                        obj = attr(ref, *[self.visit(arg) for arg in args])
                    except TypeError:
                        raise
                        errorClose(ctx,"Incorrect number of arguments in '"
                                   + ctx.getText() + "'")
                else:
                    obj = attr(ref)

        return obj

    # Visit a parse tree produced by ReaffirmParser#fieldref.
    def visitFieldref(self, ctx:ReaffirmParser.FieldrefContext):
        print("Visiting fieldref")
        return self.visitChildren(ctx)


    # Visit a parse tree produced by ReaffirmParser#methodref.
    def visitMethodref(self, ctx:ReaffirmParser.MethodrefContext):
        print("Visiting methodref")
        return self.visitChildren(ctx)

    # Visit a parse tree produced by ReaffirmParser#string.
    def visitString(self, ctx:ReaffirmParser.StringContext):
        print("visitString")
        return ctx.getText().strip('"')


    # Visit a parse tree produced by ReaffirmParser#varDec.
    def visitVarDec(self, ctx:ReaffirmParser.VarDecContext):
        print("visitVarDec")
        return self.visitChildren(ctx)


    # Visit a parse tree produced by ReaffirmParser#assign.
    def visitAssign(self, ctx:ReaffirmParser.AssignContext):
        print("visitAssign")
        val = self.visit(ctx.expr())
        self.env[ctx.ID().getText()] = val
        pass


    # Visit a parse tree produced by ReaffirmParser#exprList.
    def visitExprList(self, ctx:ReaffirmParser.ExprListContext):
        print("visitExprList")
        return self.visitChildren(ctx)


    # Visit a parse tree produced by ReaffirmParser#forloop.
    def visitForloop(self, ctx:ReaffirmParser.ForloopContext):
        print("visitForloop")
        self.visit(ctx.children[1]) #get the local loop assignment

        # loop variable is assigned to each element per iteration
        loop_var = ctx.children[1].children[0].getText()
        try:
            arr = self.env[loop_var]
        except KeyError:
            errorClose(ctx,"Unknown reference to '" + loop_var + "'")
        if len(arr) < 1:
            errorClose(ctx,"Error: '" + loop_var +"' is empty, unable to loop")

        for val in arr.copy():
            self.env[loop_var] = val
            _ = [self.visit(c) for c in ctx.children[2:]]

        #once loop is finished local variable is cleared
        self.env.pop(loop_var)
        return


    # Visit a parse tree produced by ReaffirmParser#ifstat.
    def visitIfstat(self, ctx:ReaffirmParser.IfstatContext):
        print("visitIfstat")
        return self.visitChildren(ctx)

    # Visit a parse tree produced by ReaffirmParser#funcall.
    def visitFuncall(self, ctx:ReaffirmParser.FuncallContext):
        fname = ctx.children[0].getText()
        if not fname in self.functions:
            errorClose(ctx, "Unknown reference to '" + fname + "'")
        return self.visitChildren(ctx)

    # Visit a parse tree produced by ReaffirmParser#objref.
    def visitObjref(self, ctx:ReaffirmParser.ObjrefContext):
        print("visitObjref")
        return self.visitChildren(ctx)

    # Visit a parse tree produced by ReaffirmParser#varDecl.
    def visitVarDecl(self, ctx:ReaffirmParser.VarDeclContext):
        print("visitVarDecl")
        return self.visitChildren(ctx)

    # Visit a parse tree produced by ReaffirmParser#types.
    def visitTypes(self, ctx:ReaffirmParser.TypesContext):
        print("visitTypes")
        return self.visitChildren(ctx)

    # Visit a parse tree produced by ReaffirmParser#bexpr.
    def visitBexpr(self, ctx:ReaffirmParser.BexprContext):
        print("visitBexpr")
        return self.visitChildren(ctx)


def runHATL(script, modelfile,modelname=None,fromMATLAB=False):

    global scriptFile
    scriptFile = script

    s = FileStream(script)
    parser = ReaffirmParser(CommonTokenStream(ReaffirmLexer(s)))
    tree = parser.prog()
    print(tree.toStringTree(recog=parser))

    sessions = engine.find_matlab()
    eng = None
    if sessions == () or fromMATLAB:
        print("Starting MATLAB engine")
        eng = engine.start_matlab()
    else:
        print("Connecting to MATLAB engine")
        eng = engine.connect_matlab(sessions[0])

    #set the appropriate path and then restore the cwd
    oldpwd = eng.pwd()
    assert('REAFFIRM_ROOT' in os.environ)
    eng.cd(os.environ['REAFFIRM_ROOT'])
    eng.addpath(eng.genpath('functions'))
    eng.cd(oldpwd)

    print("Loading Initial Model")
    eng.clear('all',nargout=0)
    eng.bdclose('all',nargout=0)

    try:
        eng.load_system(modelfile)
    except MatlabExecutionError as e:
        print("Unable to open model '" + modelfile + "'", file=sys.stderr)
        exit()

    v = MATLABVisitor(eng,modelfile, modelname)
    v.visit(tree)
    print(v)

    return v


if __name__ == '__main__':

    parser = argparse.ArgumentParser(description='Run the HATL interpreter on an input script and model file')
    parser.add_argument('script',nargs=1,type=str)
    parser.add_argument('model',nargs=1,type=str,metavar='modelFile')
    parser.add_argument('--name',nargs=1,type=str,metavar='modelName',
                        help='If the model file contains multiple models, '
                        'specify a single model by name as the script target')
    parser.add_argument('--fromMATLAB',action='store_const',const=True)

    args = vars(parser.parse_args())

    name = None
    if args['name']:
        name = args['name'].pop()
    runHATL(args['script'].pop(),args['model'].pop(),modelname=name,fromMATLAB=args['fromMATLAB'])
