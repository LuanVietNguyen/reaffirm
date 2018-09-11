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
        self.modes = {Mode(m,engine)
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
        self.matlab_var = matlab_var
        self.outgoing = 2
        self.incoming = 2
        self.flow = 2

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
        return self.visitChildren(ctx)


    # Visit a parse tree produced by ReaffirmParser#printExpr.
    def visitPrintExpr(self, ctx:ReaffirmParser.PrintExprContext):
        print("visitPrintExpr")
        return self.visitChildren(ctx)


    # Visit a parse tree produced by ReaffirmParser#assignment.
    def visitAssignment(self, ctx:ReaffirmParser.AssignmentContext):
        print("visitAssignment")
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
    def visitMethod(self, ctx:ReaffirmParser.MethodContext):
        print("visitMethod")
        return self.visitChildren(ctx)


    # Visit a parse tree produced by ReaffirmParser#id.
    def visitId(self, ctx:ReaffirmParser.IdContext):
        print("visitId")
        return self.visitChildren(ctx)


    # Visit a parse tree produced by ReaffirmParser#objectRef.
    def visitObjectRef(self, ctx:ReaffirmParser.ObjectRefContext):
        print("visitObjectRef")
        refs = ctx.children[0].children[:]
        ident = refs.pop(0).getText() #must be Terminal
        #need to check that ident is in env
        if ident not in self.env:
            #throw an error here
            pass
        obj = self.env[ident]
        for ref in refs:
            attr = None
            refname = ref.getText()[1:] #strip away leading '.'
            try:
                attr = getattr(obj,refname)
            except AttributeError:
                print("Unknown field/method ", refname)

            #if attr is a fieldref, resolve it.
            obj = attr

            #TODO: if it's a methodref, we have to invoke it with the
            #proper arguments
            #obj = attr(...)

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
        return self.visitChildren(ctx)


    # Visit a parse tree produced by ReaffirmParser#varDec.
    def visitVarDec(self, ctx:ReaffirmParser.VarDecContext):
        print("visitVarDec")
        return self.visitChildren(ctx)


    # Visit a parse tree produced by ReaffirmParser#assign.
    def visitAssign(self, ctx:ReaffirmParser.AssignContext):
        print("visitAssign")
        val = self.visit(ctx.expr())
        pdb.set_trace()
        self.env[ctx.ID().getText()] = val
        pass


    # Visit a parse tree produced by ReaffirmParser#exprList.
    def visitExprList(self, ctx:ReaffirmParser.ExprListContext):
        print("visitExprList")
        return self.visitChildren(ctx)


    # Visit a parse tree produced by ReaffirmParser#forloop.
    def visitForloop(self, ctx:ReaffirmParser.ForloopContext):
        print("visitForloop")
        return self.visitChildren(ctx)


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
