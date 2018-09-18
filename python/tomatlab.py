__author__ = 'LuanNguyen'

import sys
from antlr4 import *
from antlr4.InputStream import InputStream

from ReaffirmLexer import ReaffirmLexer
from ReaffirmParser import ReaffirmParser
from ReaffirmListener import ReaffirmListener
import re

class MatlabEmitter(ReaffirmListener):
    def __init__(self):
        self.matlab = {}
        # declare a dictionay of equivalent functions
        self.funcMap = {'replace':'strrep', 'addTransition':'addTransition', 'copyMode': 'copy_state', 'addState': 'addState', 'copyModel':'copyModel', 
        'getCopyState':'getCopyState', 'notDefaultTransition':'notDefaultTransition','copyTransition':'copyTransition','addParam':'addParam',
        'addLocalVar':'addLocalVar', 'addFlow':'addFlow', 'addGuardLabel':'addGuardLabel','addResetLabel':'addResetLabel','getChartByName':'getChartByName'}
        self.fieldMap = {'flow':'Label', 'guard':'LabelString','modes':'modes','trans':'trans', 'source':'Source', 'destination':'Destination'}


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
        text = ctx.getChild(0).getChild(0).getText() + ' = ' 
        ex = ctx.getChild(0).getChild(2).getChild(0)
        if isinstance(ex, ReaffirmParser.ObjrefContext):
            text += self.getMatlab(ex) +";\n"
        else:
            text += ex.getText() + ";\n"
        self.setMatlab(ctx, text)

    # Exit a parse tree produced by ReaffirmParser#objref.
    def exitObjref(self, ctx:ReaffirmParser.ObjrefContext):
        if isinstance(ctx.getChild(2), ReaffirmParser.FieldrefContext):
            text = ctx.getChild(0).getText() + "." + self.getMatlab(ctx.getChild(2))
        else:
            text = ctx.getText()      
        self.setMatlab(ctx, text)

    # Exit a parse tree produced by ReaffirmParser#loop.
    def exitLoop(self, ctx:ReaffirmParser.LoopContext):
        # print(ctx.getChildCount())
        loopAssign = ctx.forloop().assign()
        obj = loopAssign.ID().getText()
        chart = loopAssign.expr().objref().getChild(0).getText()
        #loop = chart + " = model.find('-isa', 'Stateflow.Chart');\n"
        if "formode" in ctx.forloop().getText():
            modes = loopAssign.expr().objref().getChild(2).getText()
            loop = modes + " = getStates(" + chart + ");\nnumOfStates = length("+ modes +");\n"
            loop += "for i = 1 : numOfStates\n"
            loop += "\t" + obj + " = " + modes + "(i);\n"
            block =  self.handleBlock(ctx.forloop().block())
            loop += block + "end\n"
        else:      
            trans = loopAssign.expr().objref().getChild(2).getText()
            loop = trans + " = getTransitions(" + chart + ");\nnumOfTrans = length("+ trans +");\n"
            loop += "for i = 1 : numOfTrans\n"
            loop += "\t" + obj + " = " + trans + "(i);\n"  
            # bypass the default transition in Matlab
            loop += "\t" + "if " + "notDefaultTransition(" + obj + ")\n" 
            block = self.handleBlock(ctx.forloop().block())
            listOfString = re.split('\n',block)
            for string in listOfString[:-1]:
                loop += "\t" + string +"\n"
            loop += "\tend\nend\n" 

        #loop += self.getMatlab(ctx.forloop().assign()) + '\n'
        # handle for loop block
        #block =  ctx.forloop().block().getText()
        # block =  self.handleBlock(ctx.forloop().block())
        # loop += block + "end\n"
        self.setMatlab(ctx, loop)

    # Exit a parse tree produced by ReaffirmParser#id.
    def exitId(self, ctx:ReaffirmParser.IdContext):
        self.setMatlab(ctx, ctx.getText())        

    # Exit a parse tree produced by ReaffirmParser#condtion.
    def exitCondtion(self, ctx:ReaffirmParser.CondtionContext):
        self.setMatlab(ctx, ctx.getText())

    # Exit a parse tree produced by ReaffirmParser#block.
    def exitBlock(self, ctx:ReaffirmParser.BlockContext):
        self.setMatlab(ctx, ctx.getText())

    # Exit a parse tree produced by ReaffirmParser#method.
    # def exitMethod(self, ctx:ReaffirmParser.MethodContext):
    #     self.setMatlab(ctx, ctx.getText())   

    # Exit a parse tree produced by ReaffirmParser#funcall.
    def exitFuncall(self, ctx:ReaffirmParser.FuncallContext):
        self.setMatlab(ctx, self.handleFuncal(ctx))  

    # Exit a parse tree produced by ReaffirmParser#fieldref.
    def exitFieldref(self, ctx:ReaffirmParser.FieldrefContext):
        fieldName = ctx.getChild(0).getText()
        self.setMatlab(ctx, self.fieldMap[fieldName])      

    # Exit a parse tree produced by ReaffirmParser#objref.
    # def exitObjref(self, ctx:ReaffirmParser.ObjrefContext):
    #     self.setMatlab(ctx, ctx.getText())  

    # Exit a parse tree produced by ReaffirmParser#assignment.
    def exitExprList(self, ctx:ReaffirmParser.ExprListContext):
        text = ctx.getText()
        for ex in ctx.expr():
            if isinstance(ex.getChild(0), ReaffirmParser.ObjrefContext):
                fieldName = ex.getChild(0).getChild(2).getText()
                text = text.replace(fieldName, self.fieldMap[fieldName])
        self.setMatlab(ctx, text)

    # Exit a parse tree produced by ReaffirmParser#blank.
    def exitBlank(self, ctx:ReaffirmParser.BlankContext):
        self.setMatlab(ctx, "")           

    # Handle a block context with function call
    def handleBlock(self, ctx:ReaffirmParser.BlockContext):
        buf = ""
        for stm in ctx.stat():
            ex = stm.getChild(0)
            if isinstance(ex.getChild(0), ReaffirmParser.FuncallContext):    
                buf  += "\t" + self.handleFuncal(ex.getChild(0)) + ";\n" 
            elif isinstance(stm, ReaffirmParser.AssignmentContext): 
                buf += "\t" + ex.getChild(0).getText()+ " = "
                if isinstance(ex.getChild(2).getChild(0), ReaffirmParser.FuncallContext):
                    buf += self.handleFuncal(ex.getChild(2).getChild(0)) + ";\n" 
                elif isinstance(ex.getChild(2).getChild(0), ReaffirmParser.ObjrefContext):
                    buf += self.getMatlab(ex.getChild(2).getChild(0)) + ";\n"     
            else:
                buf += "\t" + stm.getText() + ";\n"
                #buf += "\t" + self.getMatlab(ex.getChild(0)) + ";\n"
        return buf

    def handleFuncal(self, ctx:ReaffirmParser.FuncallContext):   
        text = self.funcMap[ctx.getChild(0).getText()] # retrieve function name first
        if ctx.getChildCount() > 3:
            atrList = ctx.getChild(2)
            firstExpr = atrList.getChild(0)
            if isinstance(firstExpr, ReaffirmParser.ObjectRefContext):
                fieldName = firstExpr.getChild(0).getChild(2).getText()
                oldObjName = firstExpr.getText()
                newObjName = oldObjName.replace(fieldName, self.fieldMap[fieldName])
                #self.setMatlab(atrList.getChild(0), obj)
                # print(self.getMatlab(atrList.getChild(0).getChild(0)))
                text=  newObjName  + " = " + text + "("                          
                for i in range(0, atrList.getChildCount()):
                    if atrList.getChild(i).getText() == oldObjName:
                        text += newObjName 
                    else:
                        text += atrList.getChild(i).getText()
                text += ")"  
            else:
                text += "(" + self.getMatlab(atrList)+ ")"
                #text = ctx.getText().replace(ctx.getChild(0).getText(),text)
        else:
            #for i in range(1, ctx.getChildCount()): 
                #text += ctx.getChild(i).getText() 
            text = text +"()"   
        return text   


    # Print inital set up for stateflow conversion
    def printHeader(self, modelName):
        header =  "load_system('" + modelName+"');\n"
        header += "root = sfroot;\ndiagram = root.find('-isa','Simulink.BlockDiagram');\nmodel = diagram.find('-isa', 'Stateflow.Chart');\n"
        return header


if __name__ == '__main__':

    # file handling
    outputName = "output" # defaut output name
    modelName  = "original_model" # default method name
    if len(sys.argv) < 1:
        input_stream = InputStream(sys.stdin.read())
    else:
        input_stream = FileStream(sys.argv[1])
        if len(sys.argv) > 1:
            modelName = sys.argv[2]
        if len(sys.argv) > 2:  
            outputName = sys.argv[3]    
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

