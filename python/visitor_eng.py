import sys
from antlr4 import *
from antlr4.InputStream import InputStream
import pdb

sys.path.append("/Users/gautam/research/CASE/reaffirm/python")
os.chdir("python")

from ReaffirmLexer import ReaffirmLexer
from ReaffirmParser import ReaffirmParser
from ReaffirmVisitor import ReaffirmVisitor

from matlab import engine
import io

class MATLABVisitor(ReaffirmVisitor):
    def __init__(self):
        self.model = None
        self.env = {}

        # sessions = engine.find_matlab()
        # if sessions == ():
        #     print("Starting MATLAB engine")
        #     self.eng = engine.start_matlab()
        # else:
        #     print("Connecting to MATLAB engine")
        #     self.eng = engine.connect_matlab(sessions[0])
        print("initializing!")

    # Visit a parse tree produced by ReaffirmParser#prog.
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


    # Visit a parse tree produced by ReaffirmParser#fieldref.
    def visitFieldref(self, ctx:ReaffirmParser.FieldrefContext):
        print("visitFieldref")
        pdb.set_trace()
        return self.visitChildren(ctx)


    # Visit a parse tree produced by ReaffirmParser#objref.
    def visitObjref(self, ctx:ReaffirmParser.ObjrefContext):
        print("visitObjref")
        pdb.set_trace()
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
