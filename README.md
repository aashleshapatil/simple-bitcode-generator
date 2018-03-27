# simple-bitcode-generator
A Simple Code Generator Targeting LLVM IR

Objectives
•	Implement an LLVM bitcode generator for a simple programming language on your own.
•	Gain experience reading and interpreting a language specification.
•	Gain experience implementing a simple programming language using parser generators: Flex & Bison.
•	Practice code generation with LLVM and gain experience using the LLVM software infrastructure.
•	Learn to use the course’s project infrastructure.

Description
This project is based on the programming language, P1, described by the following tokens and grammar:
Keyword/Regular Expression	Token Name	Description
vars	VARS	Declaration of variables (parameters to the function)
$[a-z0-9][a-z0-9]?	TMP	These hold temporary results. Examples: $1, $2
[a-zA-Z_]+	IDENT	The names of variables (parameters to function)
[0-9]+	NUM	A decimal number
=	ASSIGN	
;	SEMI	
-	MINUS	
+	PLUS	
*	MULTIPLY	
/	DIVIDE	
,	COMMA	
[	LBRACE	Used to implement lists.
]	RBRACE	
min	MIN	Find the minimum in a list.
max	MAX	Find the maximum in a list.
sum	SUM	Find the sum of all elements in a list.

varlist:  varlist COMMA IDENT
         | IDENT;
		 
Further Explaination
a, b, c	Allows a comma separated list of variables to be declared at the top of the program.  These become the parameters of a function.

decl:  VARS varlist SEMI	vars a, b, c; 	Declare the variables that will be used in the program.

stmt: TMP ASSIGN expr_or_list SEMI	$1 = a + b;	Each statement must put its result into a TMP.  This interpretation is that we assign $1 the result of a+b.
	$2 = [1, 2];	This statement assigns $2 a list made up of 1 and 2.

list : LBRACE list_ops RBRACE	[a,b,c]	This part of the grammar allows us to create a list of identifiers, constants, or temporaries.

stmtlist: stmtlist stmt
        | stmt;
	$0 = [1,2];
	$1 = $0+$0;
	$3 = sum $1;	This allows multiple statements in the program. Here, the second statement adds two lists, creating a new list, $1, with the values [2,4]. The last statement sums up the values of the list and sets $3 = 6.

TMP ASSIGN MIN expr_or_list SEMI
	$0 = [1,2];
	$1 = $0+$0;
	$3 = min $1;	Sets $3 = 2;

TMP ASSIGN MAX expr_or_list SEMI
	$0 = [1,2];
	$1 = $0+$0;
	$3 = max $1;	Sets $3 = 4;


