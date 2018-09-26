import sys
from antlr4 import *
from antlr4.InputStream import InputStream
import pdb

from enum import Enum

sys.path.append("/Users/gautam/research/CASE/reaffirm/python")
os.chdir("python")

from ReaffirmLexer import ReaffirmLexer
from ReaffirmParser import ReaffirmParser
from ReaffirmVisitor import ReaffirmVisitor

from matlab import engine
from matlab.engine import MatlabExecutionError
import io

def doCleanup():
    print("TODO: cleanup MATLAB engine / Stateflow edits properly")

def errorClose(ctx, msg):
    print("At line " + repr(ctx.start.line) + ", column " +
          repr(ctx.start.column) + " in " + scriptFile + ":", file=sys.stderr)
    print("\t" + msg, file=sys.stderr)
    doCleanup()
    exit()

class ContextError(Exception):
    def __init__(self, ctx, message):
        self.line = ctx.start.line
        self.col = ctx.start.column
        self.message = "Line: " + str(self.line) + ", Column: " + str(self.col) + " " + message

class RefError(ContextError):
    def __str__(self):
        return self.message

class SizeError(ContextError):
    def __str__(self):
        return self.message

def issingle(ctx, arg):
    single = None
    if hasattr(arg,'size'): #arg is a matlab object
        single = arg.size == (1,1)
    else:
        single = len(arg) == 1

    if not single:
        raise(SizeError(ctx, "error: Argument in expression '" +
                        ctx.getText() + "' must be a single value"))

class Model:
    def __init__(self, matlab_var, engine):
        self.engine = engine
        self.matlab_var = matlab_var
        self.modes = {Mode(m[0],engine)
                      for m in engine.find(matlab_var,'-isa','Stateflow.State')}
        self.transitions = {Transition(t[0],engine)
                      for t in engine.find(matlab_var,'-isa','Stateflow.Transition')}
        for t in self.transitions.copy():
             if t.source.matlab_var.size == (0,0):
                 self.transitions.remove(t)
        self.param = None

    def addMode(self,ctx,  mode):
        pdb.set_trace()
        issingle(ctx, mode)

        raw_mode = self.engine.addState(self.matlab_var, mode.matlab_var)
        newmode = Mode(raw_mode, self.engine)
        self.modes.add(newmode)
        return newmode

    def addTransition(self, src, dest, eqn):

        raw_trans = self.engine.addTransition(self.matlab_var,
                                             src.matlab_var, dest.matlab_var, eqn)
        newtrans = Transition(raw_trans, self.engine)
        self.transitions.add(newtrans)
        return newtrans

    def addParam(self,param):
        self.param = self.engine.addParam(self.matlab_var,param)

    def addLocalVar(self, localvar):
        self.localVar = self.engine.addVariable(self.matlab_var,localvar,'Local')

    def copyModel(self):
        mvar = self.engine.copyModel(self.matlab_var, "chart")
        return CopyModel(mvar, self.engine)

    def getCopy(self, mode):
        copymodes = [m for m in self.modes if m.name == (mode.name + '_copy')]
        if copymodes == []:
            raise(Exception("Cannot find copy of mode"))
        elif len(copymodes) > 1:
            raise(Exception("Returned multiple modes...is this bad?"))

        return copymodes[0]


class CopyModel:
    def __init__(self, matlab_var, engine, copy=None):
        self.engine = engine
        self.matlab_var = matlab_var
        self.modes = {Mode(m[0],engine)
                          for m in engine.find(matlab_var,'states')}
        self.transitions = {Transition(t[0],engine)
                          for t in engine.find(matlab_var,'trans')}
        for t in self.transitions.copy():
            if t.source.matlab_var.size == (0,0):
                self.transitions.remove(t)

    def copyModel(self):
        return CopyModel(self, self.engine.copyModel(self.matlab_var,"copyModel"),
                         engine, "copy")


class Mode:
    def __init__(self, matlab_var, engine):
        self.engine = engine
        self.matlab_var = matlab_var
        self.outgoing = 2
        self.incoming = 2

    def replace(self,old_var,new_var):
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

    def addFlow(self, eqn):
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

    def addGuardLabel(self, relation, label):
        self.engine.addGuardLabel(self.matlab_var,relation,label,nargout=0)

    def addResetLabel(self, label):
        self.engine.addResetLabel(self.matlab_var,label,nargout=0)


class MATLABVisitor(ReaffirmVisitor):
    def __init__(self, e, modelfile, modelname=None):
        self.env = {}
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


    # Visit a parse tree produced by ReaffirmParser#method.
        # Visit a parse tree produced by ReaffirmParser#function.
    def visitFunction(self, ctx:ReaffirmParser.FunctionContext):
        print("visitFunction")
        return self.visitChildren(ctx)


    # Visit a parse tree produced by ReaffirmParser#id.
    def visitId(self, ctx:ReaffirmParser.IdContext):
        print("visitId")
        try:
            return self.env[ctx.getText()]
        except KeyError as e:
            raise(RefError(ctx,"Unknown reference to '" + ctx.getText() + "'")) from e

    # Visit a parse tree produced by ReaffirmParser#objectRef.
    def visitObjectRef(self, ctx:ReaffirmParser.ObjectRefContext):
        refs = ctx.children[0].children[:]
        ident = refs.pop(0).getText() #must be Terminal
        #need to check that ident is in env

        try:
            obj = self.env[ident]
        except KeyError as e:
            raise(RefError(ctx,"Unknown reference to '" + ident + "'")) from e

        for ref in refs:
            attr = None
            #find the attr name. methods have junk after '(' that we
            #have to get rid of. also strip leading '.'
            refname = ref.getText().split('(')[0][1:]
            try:
                attr = getattr(obj,refname)
            except AttributeError as e:
                raise(RefError(ref,"Unknown reference to " + refname)) from e

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
                    obj = attr(ref, *[self.visit(arg) for arg in args])
                else:
                    obj = attr()

        return obj

    # Visit a parse tree produced by ReaffirmParser#fieldref.
    def visitFieldref(self, ctx:ReaffirmParser.FieldrefContext):
        return self.visitChildren(ctx)


    # Visit a parse tree produced by ReaffirmParser#methodref.
    def visitMethodref(self, ctx:ReaffirmParser.MethodrefContext):
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
            raise(RefError(ctx,"Unknown reference to '" + loop_var + "'"))
        if len(arr) < 1:
            raise Exception("Cannot loop over empty variable")

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
        print("visitFuncall")
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


def parse_script(script, modelfile,modelname=None):

    s = FileStream(script)
    parser = ReaffirmParser(CommonTokenStream(ReaffirmLexer(s)))
    tree = parser.prog()
    print(tree.toStringTree(recog=parser))

    print("Initializing!")

    sessions = engine.find_matlab()
    eng = None
    if sessions == ():
        print("Starting MATLAB engine")
        eng = engine.start_matlab()
    else:
        print("Connecting to MATLAB engine")
        eng = engine.connect_matlab(sessions[0])

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
    pass
