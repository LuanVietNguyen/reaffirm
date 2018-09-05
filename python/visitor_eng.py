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

class MatlabEmitter(ReaffirmListener):
    def __init__(self, inputargs):
        self.matlab = {}
        # declare a dictionay of equivalent functions
        self.funcMap = {'replace':'strrep', 'addTransition':'add_transition'}
        self.fieldMap = {'flow': 'Label', 'guardLabel': 'LabelString'}

        sessions = engine.find_matlab()
        if sessions == ():
            print("Starting MATLAB engine")
            self.eng = engine.start_matlab()
        else:
            print("Connecting to MATLAB engine")
            self.eng = engine.connect_matlab(sessions[0])

        print("loading model")
        # TODO: how do we handle/catch MatlabExecutionErrors?
        self.eng.load_system(args['modelName'])
        e = self.eng
        self.model = e.find(e.find(e.sfroot(),'-isa','Simulink.BlockDiagram')
                            ,'-isa','Stateflow.Chart')

    # Enter a parse tree produced by ReaffirmParser#prog.
    def enterProg(self, ctx:ReaffirmParser.ProgContext):
        print(ctx)
        print("calling enterProg")
        print(ctx.getPayload())

    # Exit a parse tree produced by ReaffirmParser#prog.
    def exitProg(self, ctx:ReaffirmParser.ProgContext):
        print(ctx)
        print("calling exitProg")

    # Enter a parse tree produced by ReaffirmParser#printExpr.
    def enterPrintExpr(self, ctx:ReaffirmParser.PrintExprContext):
        print(ctx)
        print("calling enterPrintExpr")
        pass
    # Exit a parse tree produced by ReaffirmParser#printExpr.
    def exitPrintExpr(self, ctx:ReaffirmParser.PrintExprContext):
        print(ctx)
        print("calling exitPrintExpr")


    # Enter a parse tree produced by ReaffirmParser#assignment.
    def enterAssignment(self, ctx:ReaffirmParser.AssignmentContext):
        pdb.set_trace()
        print(ctx)
        print("calling enterAssignment")

    # Exit a parse tree produced by ReaffirmParser#assignment.
    def exitAssignment(self, ctx:ReaffirmParser.AssignmentContext):
        pdb.set_trace()
        print(ctx)
        print("calling exitAssignment")


    # Enter a parse tree produced by ReaffirmParser#loop.
    def enterLoop(self, ctx:ReaffirmParser.LoopContext):
        print(ctx)
        print("calling enterLoop")

    # Exit a parse tree produced by ReaffirmParser#loop.
    def exitLoop(self, ctx:ReaffirmParser.LoopContext):
        print(ctx)
        print("calling exitLoop")


    # Enter a parse tree produced by ReaffirmParser#condtion.
    def enterCondtion(self, ctx:ReaffirmParser.CondtionContext):
        print(ctx)
        print("calling enterCondtion")

    # Exit a parse tree produced by ReaffirmParser#condtion.
    def exitCondtion(self, ctx:ReaffirmParser.CondtionContext):
        print(ctx)
        print("calling exitCondtion")


    # Enter a parse tree produced by ReaffirmParser#blank.
    def enterBlank(self, ctx:ReaffirmParser.BlankContext):
        print(ctx)
        print("calling enterBlank")

    # Exit a parse tree produced by ReaffirmParser#blank.
    def exitBlank(self, ctx:ReaffirmParser.BlankContext):
        print(ctx)
        print("calling exitBlank")


    # Enter a parse tree produced by ReaffirmParser#block.
    def enterBlock(self, ctx:ReaffirmParser.BlockContext):
        print(ctx)
        print("calling enterBlock")

    # Exit a parse tree produced by ReaffirmParser#block.
    def exitBlock(self, ctx:ReaffirmParser.BlockContext):
        print(ctx)
        print("calling exitBlock")


    # Enter a parse tree produced by ReaffirmParser#method.
    def enterMethod(self, ctx:ReaffirmParser.MethodContext):
        print(ctx)
        print("calling enterMethod")

    # Exit a parse tree produced by ReaffirmParser#method.
    def exitMethod(self, ctx:ReaffirmParser.MethodContext):
        print(ctx)
        print("calling exitMethod")


    # Enter a parse tree produced by ReaffirmParser#id.
    def enterId(self, ctx:ReaffirmParser.IdContext):
        print(ctx)
        print("calling enterId")

    # Exit a parse tree produced by ReaffirmParser#id.
    def exitId(self, ctx:ReaffirmParser.IdContext):
        print(ctx)
        print("calling exitId")


    # Enter a parse tree produced by ReaffirmParser#objectRef.
    def enterObjectRef(self, ctx:ReaffirmParser.ObjectRefContext):
        print(ctx)
        print("calling enterObjectRef")

    # Exit a parse tree produced by ReaffirmParser#objectRef.
    def exitObjectRef(self, ctx:ReaffirmParser.ObjectRefContext):
        print(ctx)
        print("calling exitObjectRef")


    # Enter a parse tree produced by ReaffirmParser#string.
    def enterString(self, ctx:ReaffirmParser.StringContext):
        print(ctx)
        print("calling enterString")

    # Exit a parse tree produced by ReaffirmParser#string.
    def exitString(self, ctx:ReaffirmParser.StringContext):
        print(ctx)
        print("calling exitString")


    # Enter a parse tree produced by ReaffirmParser#varDec.
    def enterVarDec(self, ctx:ReaffirmParser.VarDecContext):
        print(ctx)
        print("calling enterVarDec")

    # Exit a parse tree produced by ReaffirmParser#varDec.
    def exitVarDec(self, ctx:ReaffirmParser.VarDecContext):
        print(ctx)
        print("calling exitVarDec")


    # Enter a parse tree produced by ReaffirmParser#assign.
    def enterAssign(self, ctx:ReaffirmParser.AssignContext):
        print(ctx)
        print("calling enterAssign")

    # Exit a parse tree produced by ReaffirmParser#assign.
    def exitAssign(self, ctx:ReaffirmParser.AssignContext):
        print(ctx)
        print("calling exitAssign")


    # Enter a parse tree produced by ReaffirmParser#exprList.
    def enterExprList(self, ctx:ReaffirmParser.ExprListContext):
        print(ctx)
        print("calling enterExprList")

    # Exit a parse tree produced by ReaffirmParser#exprList.
    def exitExprList(self, ctx:ReaffirmParser.ExprListContext):
        print(ctx)
        print("calling exitExprList")


    # Enter a parse tree produced by ReaffirmParser#forloop.
    def enterForloop(self, ctx:ReaffirmParser.ForloopContext):
        print(ctx.getPayload())
        print("calling enterForloop")

    # Exit a parse tree produced by ReaffirmParser#forloop.
    def exitForloop(self, ctx:ReaffirmParser.ForloopContext):
        print(ctx)
        print("calling exitForloop")


    # Enter a parse tree produced by ReaffirmParser#ifstat.
    def enterIfstat(self, ctx:ReaffirmParser.IfstatContext):
        print(ctx)
        print("calling enterIfstat")

    # Exit a parse tree produced by ReaffirmParser#ifstat.
    def exitIfstat(self, ctx:ReaffirmParser.IfstatContext):
        print(ctx)
        print("calling exitIfstat")


    # Enter a parse tree produced by ReaffirmParser#funcall.
    def enterFuncall(self, ctx:ReaffirmParser.FuncallContext):
        print(ctx)
        print("calling enterFuncall")

    # Exit a parse tree produced by ReaffirmParser#funcall.
    def exitFuncall(self, ctx:ReaffirmParser.FuncallContext):
        print(ctx)
        print("calling exitFuncall")


    # Enter a parse tree produced by ReaffirmParser#fieldref.
    def enterFieldref(self, ctx:ReaffirmParser.FieldrefContext):
        print(ctx)
        print("calling enterFieldref")

    # Exit a parse tree produced by ReaffirmParser#fieldref.
    def exitFieldref(self, ctx:ReaffirmParser.FieldrefContext):
        print(ctx)
        print("calling exitFieldref")


    # Enter a parse tree produced by ReaffirmParser#objref.
    def enterObjref(self, ctx:ReaffirmParser.ObjrefContext):
        print(ctx)
        print("calling enterObjref")

    # Exit a parse tree produced by ReaffirmParser#objref.
    def exitObjref(self, ctx:ReaffirmParser.ObjrefContext):
        print(ctx)
        print("calling exitObjref")


    # Enter a parse tree produced by ReaffirmParser#varDecl.
    def enterVarDecl(self, ctx:ReaffirmParser.VarDeclContext):
        print(ctx)
        print("calling enterVarDecl")

    # Exit a parse tree produced by ReaffirmParser#varDecl.
    def exitVarDecl(self, ctx:ReaffirmParser.VarDeclContext):
        print(ctx)
        print("calling exitVarDecl")


    # Enter a parse tree produced by ReaffirmParser#types.
    def enterTypes(self, ctx:ReaffirmParser.TypesContext):
        print(ctx)
        print("calling enterTypes")

    # Exit a parse tree produced by ReaffirmParser#types.
    def exitTypes(self, ctx:ReaffirmParser.TypesContext):
        print(ctx)
        print("calling exitTypes")


    # Enter a parse tree produced by ReaffirmParser#bexpr.
    def enterBexpr(self, ctx:ReaffirmParser.BexprContext):
        print(ctx)
        print("calling enterBexpr")

    # Exit a parse tree produced by ReaffirmParser#bexpr.
    def exitBexpr(self, ctx:ReaffirmParser.BexprContext):
        print(ctx)
        print("calling exitBexpr")

def parse_script(script, args):

    s = FileStream(script)
    parser = ReaffirmParser(CommonTokenStream(ReaffirmLexer(s)))

    tree = parser.prog()
    print(tree.toStringTree(recog=parser))

    listener = MatlabEmitter(args)
    walker = ParseTreeWalker()
    walker.walk(listener, tree)
    print(listener)

    return listener


if __name__ == '__main__':
    args = {'modelName' : 'test_model'}; l = parse_script('toy',args)
