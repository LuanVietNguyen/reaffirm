__author__ = 'LuanNguyen'

import sys
from antlr4 import *
from antlr4.InputStream import InputStream

from ReaffirmLexer import ReaffirmLexer
from ReaffirmParser import ReaffirmParser
from ReaffirmListener import ReaffirmListener


class MatlabEmitter(ReaffirmListener):
    def __init__(self):
        self.matlab = {}
        # declare a dictionay of equivalent functions
        self.funcMap = {'replace':'strrep', 'addTransition':'add_transition'}
        self.fieldMap = {'flow': 'Label', 'guardLabel': 'LabelString'}


    def getMatlab(self, ctx):
        return self.matlab[ctx]

    def setMatlab(self, ctx, value):
        self.matlab[ctx] = value


    # Exit a parse tree produced by ReaffirmParser#prog.
    def exitProg(self, ctx:ReaffirmParser.ProgContext):
        prog = "";
        for i in range(0,ctx.getChildCount()):
            prog += self.getMatlab(ctx.getChild(i)) + "\n";
        self.setMatlab(ctx, prog)

    # Exit a parse tree produced by ReaffirmParser#printExpr.
    def exitPrintExpr(self, ctx:ReaffirmParser.PrintExprContext):
        self.setMatlab(ctx, ctx.getText())

    # Exit a parse tree produced by ReaffirmParser#assignment.
    def exitAssignment(self, ctx:ReaffirmParser.AssignmentContext):
        self.setMatlab(ctx, ctx.assign())

    # Exit a parse tree produced by ReaffirmParser#loop.
    def exitLoop(self, ctx:ReaffirmParser.LoopContext):
        # print(ctx.getChildCount())
        loopAssign = ctx.forloop().assign()
        obj = loopAssign.ID().getText()
        chart = loopAssign.expr().objref().getChild(0).getText()
        modes = loopAssign.expr().objref().getChild(2).getText()
        loop = chart + " = model.find('-isa', 'Stateflow.Chart');\n"
        loop += modes + " = getState(" + chart + ");\nnumOfStates = length("+ modes +");\n"
        if "formode" in ctx.forloop().getText():
            loop += "for i = 1 : numOfStates\n"
            loop += "\t" + obj + " = " + modes + "(i);\n"
        else:
            loop += "for i : numOfTrans\n"
            loop += "\t" + obj + " = " + modes + "(i);\n"     
        #loop += self.getMatlab(ctx.forloop().assign()) + '\n'
        # handle for loop block
        #block =  ctx.forloop().block().getText()
        block =  self.handleBlock(ctx.forloop().block())
        loop += block + "end\n"
        self.setMatlab(ctx, loop)

    # Exit a parse tree produced by ReaffirmParser#id.
    def exitId(self, ctx:ReaffirmParser.IdContext):
        self.setMatlab(ctx, ctx.getText())        

    # Exit a parse tree produced by ReaffirmParser#condtion.
    def exitCondtion(self, ctx:ReaffirmParser.CondtionContext):
        self.setMatlab(ctx, ctx.ifstat())

    # Exit a parse tree produced by ReaffirmParser#block.
    def exitBlock(self, ctx:ReaffirmParser.BlockContext):
        self.setMatlab(ctx, ctx.getText())

    # Exit a parse tree produced by ReaffirmParser#method.
    def exitMethod(self, ctx:ReaffirmParser.MethodContext):
        self.setMatlab(ctx, ctx.getText())   

    # Exit a parse tree produced by ReaffirmParser#funcall.
    def exitFuncall(self, ctx:ReaffirmParser.FuncallContext):
        self.setMatlab(ctx, ctx.getText())  

    # Exit a parse tree produced by ReaffirmParser#fieldref.
    def exitFieldref(self, ctx:ReaffirmParser.FieldrefContext):
        self.setMatlab(ctx, ctx.getText())      

    # Exit a parse tree produced by ReaffirmParser#objref.
    def exitObjref(self, ctx:ReaffirmParser.ObjrefContext):
        self.setMatlab(ctx, ctx.getText())  

    # Exit a parse tree produced by ReaffirmParser#assignment.
    def exitAssignment(self, ctx:ReaffirmParser.AssignmentContext):
        self.setMatlab(ctx, ctx.getText())

    # Exit a parse tree produced by ReaffirmParser#blank.
    def exitBlank(self, ctx:ReaffirmParser.BlankContext):
        self.setMatlab(ctx, "")           

    # Handle a block context with function call
    def handleBlock(self, ctx:ReaffirmParser.BlockContext):
        buf = ""
        for ex in ctx.stat():
            stm = ex.getChild(0)
            if isinstance(stm.getChild(0), ReaffirmParser.FuncallContext):    
                funcstat= self.funcMap[stm.getChild(0).getChild(0).getText()] # retrieve function name first
                if stm.getChild(0).getChildCount() > 3:
                    atrList = stm.getChild(0).getChild(2)
                    firstExpr = atrList.getChild(0)
                    if isinstance(firstExpr, ReaffirmParser.ObjectRefContext):
                        fieldName = firstExpr.getChild(0).getChild(2).getText()
                        oldObjName = firstExpr.getText()
                        newObjName = oldObjName.replace(fieldName, self.fieldMap[fieldName])
                        #self.setMatlab(atrList.getChild(0), obj)
                        # print(self.getMatlab(atrList.getChild(0).getChild(0)))
                        funcstat= "\t" + newObjName  + " = " + funcstat + "("                          
                        for i in range(0, atrList.getChildCount()):
                            if atrList.getChild(i).getText() == oldObjName:
                                funcstat += newObjName
                            else:
                                funcstat += atrList.getChild(i).getText()
                        funcstat += ")"    
                else:
                    for i in range(1, stm.getChild(0).getChildCount()):   
                        funcstat += stm.getChild(0).getChild(i).getText()    
                buf  += funcstat+ ";\n"    
            else:
                buf += "\t" + self.getMatlab(ex.getChild(0)) + ";\n"
        return buf

    

    # Print inital set up for stateflow conversion
    def printHeader(self, modelName):
        header = "clc; clear all; bdclose all;\n" + "load_system('" + modelName+"');\n"
        header += "root = sfroot;\nmodel = root.find('-isa','Simulink.BlockDiagram');\n"
        return header


if __name__ == '__main__':

    # file handling
    outputName = "output" # defaut output name
    modelName  = "original_model" # default method name
    if len(sys.argv) < 1:
        input_stream = InputStream(sys.stdin.read())
    else:
        input_stream = FileStream(sys.argv[1])
        print(sys.argv[1])
        if len(sys.argv) > 1:
            modelName = sys.argv[2]
        if len(sys.argv) > 2:  
            outputName = sys.argv[3]    
    print(len(sys.argv))  
    outputFile = outputName +".m"     

    # lexering and parsing
    lexer = ReaffirmLexer(input_stream)
    token_stream = CommonTokenStream(lexer)
    parser = ReaffirmParser(token_stream)
    tree = parser.prog()

    lisp_tree_str = tree.toStringTree(recog=parser)
    print(lisp_tree_str)

    # listener
    print("Start Walking...")
    listener = MatlabEmitter()
    print(listener.printHeader(modelName))
    walker = ParseTreeWalker()
    walker.walk(listener, tree)
    print(listener.getMatlab(tree))

    # save output file
    f = open(outputFile,'w')
    f.write(listener.printHeader(modelName))
    f.write(listener.getMatlab(tree))
    f.close()

