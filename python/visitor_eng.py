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
import io

class Variable():
    def __init__(self, vartype, matlab_var):
        self.vartype = vartype
        self.matlab = matlab_var

class Model:
    def __init__(self, matlab_var, engine):
        self.engine = engine
        self.matlab_var = matlab_var
        self.modes = {Mode(m[0],engine)
                      for m in engine.find(matlab_var,'-isa','Stateflow.State')}
        self.transitions = 2 #TODO create this

    def addMode():
        pass

    def addTransition():
        pass

    #todo: should we add dimensionality to the variable or should
    #that be calculated on the fly?

class Mode:
    def __init__(self, matlab_var, engine):
        self.engine = engine
        self.matlab_var = matlab_var
        self.outgoing = 2
        self.incoming = 2

    def replace(self,old_var,new_var):
        pdb.set_trace()
        old_flow = self.engine.get(self.matlab_var,'LabelString')
        new_flow = old_flow.replace(old_var,new_var)
        self.engine.set(self.matlab_var,'LabelString',new_flow,nargout=0)

    #Flow is read-only, since updates must happen per-mode otherwise
    #changes will not be propagated to MATLAB
    @property
    def flow(self):
        return self.engine.get(self.matlab_var,'LabelString')


class Transition:
    def __init__(self, matlab_var, engine):
        self.matlab_var = matlab_var
        self.source = 2
        self.dest = 2
        self.guard = 2
        self.guard = 2

    def extend():
        pass

# class Flow:
#     def __init__(self, matlab_var, engine):
#         self.matlab_var = matlab_var

class MATLABVisitor(ReaffirmVisitor):
    def __init__(self):
        print("Initializing!")
        self.env = {}

        sessions = engine.find_matlab()
        if sessions == ():
            print("Starting MATLAB engine")
            self.eng = engine.start_matlab()
        else:
            print("Connecting to MATLAB engine")
            self.eng = engine.connect_matlab(sessions[0])

        print("Loading Initial Model")
        self.eng.load_system('test_model')
        e = self.eng
        m = e.find(e.find(e.sfroot(),'-isa','Simulink.BlockDiagram')
                            ,'-isa','Stateflow.Chart')
        self.env['initial_model'] = Model(m, e)

    # visit a parse tree produced by ReaffirmParser#prog.
    def visitProg(self, ctx:ReaffirmParser.ProgContext):
        print("visitProg")
        print(self.env)
        self.visitChildren(ctx)

        self.eng.sfsave('test_model','test_model_resilient',nargout=0)

        return


    # Visit a parse tree produced by ReaffirmParser#printExpr.
    def visitPrintExpr(self, ctx:ReaffirmParser.PrintExprContext):
        print("visitPrintExpr")
        print(self.env)
        return self.visitChildren(ctx)


    # Visit a parse tree produced by ReaffirmParser#assignment.
    def visitAssignment(self, ctx:ReaffirmParser.AssignmentContext):
        print("visitAssignment")
        print(self.env)
        return self.visitChildren(ctx)


    # Visit a parse tree produced by ReaffirmParser#loop.
    def visitLoop(self, ctx:ReaffirmParser.LoopContext):
        print("visitLoop")
        print(self.env)
        return self.visitChildren(ctx)


    # Visit a parse tree produced by ReaffirmParser#condtion.
    def visitCondtion(self, ctx:ReaffirmParser.CondtionContext):
        print("visitCondtion")
        print(self.env)
        return self.visitChildren(ctx)


    # Visit a parse tree produced by ReaffirmParser#blank.
    def visitBlank(self, ctx:ReaffirmParser.BlankContext):
        print("visitBlank")
        print(self.env)
        return self.visitChildren(ctx)


    # Visit a parse tree produced by ReaffirmParser#block.
    def visitBlock(self, ctx:ReaffirmParser.BlockContext):
        print("visitBlock")
        print(self.env)
        return self.visitChildren(ctx)


    # Visit a parse tree produced by ReaffirmParser#method.
    def visitMethod(self, ctx:ReaffirmParser.MethodContext):
        print("visitMethod")
        print(self.env)
        return self.visitChildren(ctx)


    # Visit a parse tree produced by ReaffirmParser#id.
    def visitId(self, ctx:ReaffirmParser.IdContext):
        print("visitId")
        print(self.env)
        return self.visitChildren(ctx)


    # Visit a parse tree produced by ReaffirmParser#objectRef.
    def visitObjectRef(self, ctx:ReaffirmParser.ObjectRefContext):
        print("visitObjectRef")
        print(self.env)
        refs = ctx.children[0].children[:]
        ident = refs.pop(0).getText() #must be Terminal
        #need to check that ident is in env
        if ident not in self.env:
            #throw an error here
            pass
        obj = self.env[ident]
        for ref in refs:
            attr = None
            #find the attr name. methods have junk after '(' that we
            #have to get rid of. also strip leading '.'
            refname = ref.getText().split('(')[0][1:]
            try:
                attr = getattr(obj,refname)
            except AttributeError:
                print("Unknown field/method ", refname)

            #if attr is a fieldref, resolve it.

            if not callable(attr):
                obj = attr
            else:
                # if attr is methodref, find args, eval them, and apply
                # the method
                args = [ct for ct in ref.children[1].children[2].children
                        if not type(ct).__name__ == 'TerminalNodeImpl']
                obj = attr(*[self.visit(arg) for arg in args])

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
        print(self.env)
        return self.visitChildren(ctx)


    # Visit a parse tree produced by ReaffirmParser#assign.
    def visitAssign(self, ctx:ReaffirmParser.AssignContext):
        print("visitAssign")
        print(self.env)
        val = self.visit(ctx.expr())
        self.env[ctx.ID().getText()] = val
        pass


    # Visit a parse tree produced by ReaffirmParser#exprList.
    def visitExprList(self, ctx:ReaffirmParser.ExprListContext):
        print("visitExprList")
        print(self.env)
        return self.visitChildren(ctx)


    # Visit a parse tree produced by ReaffirmParser#forloop.
    def visitForloop(self, ctx:ReaffirmParser.ForloopContext):
        print("visitForloop")
        print(self.env)
        self.visit(ctx.children[1]) #get the local loop assignment

        # loop variable is assigned to each element per iteration
        loop_var = ctx.children[1].children[0].getText()
        arr = self.env[loop_var]
        if len(arr) < 1:
            print("Error: cannot loop over empty variable")

        for val in arr:
            self.env[loop_var] = val
            _ = [self.visit(c) for c in ctx.children[2:]]

        #once loop is finished local variable is cleared
        self.env.pop(loop_var)
        return


    # Visit a parse tree produced by ReaffirmParser#ifstat.
    def visitIfstat(self, ctx:ReaffirmParser.IfstatContext):
        print("visitIfstat")
        print(self.env)
        return self.visitChildren(ctx)

    # Visit a parse tree produced by ReaffirmParser#funcall.
    def visitFuncall(self, ctx:ReaffirmParser.FuncallContext):
        print("visitFuncall")
        print(self.env)
        return self.visitChildren(ctx)

    # Visit a parse tree produced by ReaffirmParser#objref.
    def visitObjref(self, ctx:ReaffirmParser.ObjrefContext):
        print("visitObjref")
        print(self.env)
        return self.visitChildren(ctx)


    # Visit a parse tree produced by ReaffirmParser#varDecl.
    def visitVarDecl(self, ctx:ReaffirmParser.VarDeclContext):
        print("visitVarDecl")
        print(self.env)
        return self.visitChildren(ctx)


    # Visit a parse tree produced by ReaffirmParser#types.
    def visitTypes(self, ctx:ReaffirmParser.TypesContext):
        print("visitTypes")
        print(self.env)
        return self.visitChildren(ctx)


    # Visit a parse tree produced by ReaffirmParser#bexpr.
    def visitBexpr(self, ctx:ReaffirmParser.BexprContext):
        print("visitBexpr")
        print(self.env)
        return self.visitChildren(ctx)


def parse_script(script, args):

    s = FileStream(script)
    parser = ReaffirmParser(CommonTokenStream(ReaffirmLexer(s)))

    tree = parser.prog()
    print(tree.toStringTree(recog=parser))

    v = MATLABVisitor()
    v.visit(tree)
    print(v)

    return v


if __name__ == '__main__':
    args = {'modelName' : 'test_model'}; l = parse_script('toy',args)
