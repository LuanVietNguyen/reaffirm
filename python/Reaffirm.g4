grammar Reaffirm;

/** The start rule; begin parsing here. */

prog		: 	stat+	;


stat   		:	expr NEWLINE?     # printExpr
    		|   assign				# assignment
    		|   forloop				# loop
    		|	ifstat				# condtion
    		| 	NEWLINE             # blank
    		;

block		: 	'{' stat* '}' ; // possibly empty statement block

expr   		:   ID					# id
    		|   objref				# objectRef
    		|	STRING				# string
    		|   varDecl	            # varDec
    		;

assign		: 	ID '=' expr;
exprList 	: 	expr (',' expr)* ; // arg list
forloop		:	('formode' |'fortran') assign block ; // forloop over modes or transitions
ifstat		:	'if' ( expr | bexpr ) 'then' block ('else' block)? ;

funcall		:	ID '(' exprList? ')' ; // function call

fieldref	: 	 '.' ID ; // e.g., model.mode.flowstring

methodref	: 	 '.' funcall ; // e.g., model.mode.flowstring

objref		:	ID (fieldref | methodref )* ;	// e.g., model.mode.addVariable

varDecl		:	types ID ;
types		:	'local' | 'input' | 'output'| 'param' ; // user-defined types

bexpr		:	expr (BOOLOP expr)* ;

ID  		:   [a-zA-Z0-9_]+ ;
STRING 		: 	'"' .*? '"' ;
BOOLOP		:	'&&' | '||' | '==' ;
NEWLINE 	:	'\r'? '\n';
WS  		:   [ \t\r\n]+ -> skip; // toss out whitespace
