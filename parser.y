%{
#include <stdio.h>
#include "llvm-c/Core.h"
#include "llvm-c/BitReader.h"
#include "llvm-c/BitWriter.h"
#include <string.h>

#include "uthash.h"

#include <errno.h>
  //#include <search.h>

extern FILE *yyin;
int yylex(void);
int yyerror(const char *);

extern char *fileNameOut;

extern LLVMModuleRef Module;
extern LLVMContextRef Context;

LLVMValueRef Function;
LLVMBasicBlockRef BasicBlock;
LLVMBuilderRef Builder;


int params_cnt=0;

struct TmpMap{
  char *key;                  /* key */
  void *val;                /* data */
  UT_hash_handle hh;         /* makes this structure hashable */
};
 

struct TmpMap *map = NULL;    /* important! initialize to NULL */

void add_val(char *tmp, void* val) { 
  struct TmpMap *s; 
  s = malloc(sizeof(struct TmpMap)); 
  s->key = strdup(tmp); 
  s->val = val; 
  HASH_ADD_KEYPTR( hh, map, s->key, strlen(s->key), s ); 
}

void * get_val(char *tmp) {
  struct TmpMap *s;
  HASH_FIND_STR( map, tmp, s );  /* s: output pointer */
  if (s) 
    return s->val;
  else 
    return NULL; // returns NULL if not found
}

typedef struct myvalue {
  int size;
  LLVMValueRef val[32];
} MyValue;
 MyValue store[1000];
int index_store=0;

%}

%union {
  char *tmp;
  int num;
  char *id;
  MyValue value; 
}

%token ASSIGN SEMI COMMA MINUS PLUS VARS MIN MAX LBRACE RBRACE SUM TMP NUM ID
%type <tmp> TMP 
%type <num> NUM 
%type <id> ID
%type <value> primitive expr expr_or_list stmt stmtlist program list_ops list


//%nonassoc QUESTION COLON
%left PLUS MINUS
%left MULTIPLY DIVIDE
	

%start program
%%

program: decl stmtlist 
{ 
  /* 
    IMPLEMENT: return value, program is over
  */  

   LLVMBuildRet(Builder,$2.val[0]);
}
;

decl: VARS varlist SEMI 
{  
  /* NO NEED TO CHANGE ANYTHING IN THIS RULE */

  /* Now we know how many parameters we need.  Create a function type
     and add it to the Module */

  LLVMTypeRef Integer = LLVMInt64TypeInContext(Context);

  LLVMTypeRef *IntRefArray = malloc(sizeof(LLVMTypeRef)*params_cnt);
  int i;
  
  /* Build or function */
  for(i=0; i<params_cnt; i++)
    IntRefArray[i] = Integer;

  LLVMBool var_arg = 0; /* false */
  LLVMTypeRef FunType = LLVMFunctionType(Integer,IntRefArray,params_cnt,var_arg);

  /* Found in LLVM-C -> Core -> Modules */
  char *tmp, *out = fileNameOut;

  if ((tmp=strchr(out,'.'))!='\0')
    {
      *tmp = 0;
    }

  /* Found in LLVM-C -> Core -> Modules */
  Function = LLVMAddFunction(Module,out,FunType);

  /* Add a new entry basic block to the function */
  BasicBlock = LLVMAppendBasicBlock(Function,"entry");

  /* Create an instruction builder class */
  Builder = LLVMCreateBuilder();

  /* Insert new instruction at the end of entry block */
  LLVMPositionBuilderAtEnd(Builder,BasicBlock);
}
;

varlist:   varlist COMMA ID 
{
  /* IMPLEMENT: remember ID and its position so that you can
     reference the parameter later
   */
	/* Add variable along with its position in a hashmap*/
	add_val($3,params_cnt+1);
	params_cnt++;
}
| ID
{
  /* IMPLEMENT: remember ID and its position for later reference*/
	/* Add variable along with its position in a hashmap*/
	add_val($1,params_cnt+1);
	params_cnt++;

 
}
;

stmtlist:  stmtlist stmt 
{
	$$=$2;
}
| stmt 
{
	$$=$1;
}                  
;         

stmt: TMP ASSIGN expr_or_list SEMI
{
	int i;
	/* Making a list */
	for(i=0;i<$3.size;i++)
	{
		store[index_store].val[i]=$3.val[i];
	}	
	/* store the size of the list*/
	store[index_store].size=$3.size; 
	/* add the temp variable in hashmap along with the its position in store struct */
	add_val($1,index_store+1); 
	$$=$3;
	index_store++;
	
}
| TMP ASSIGN MIN expr_or_list SEMI
{	

	int j; 
	LLVMValueRef result,t;
	t=$4.val[0];
		/* Finding minimum of the values in list */
		for(j=1;j<$4.size;j++)
		{
			result=LLVMBuildICmp(Builder,LLVMIntSLT,$4.val[j],t,"");
			t=LLVMBuildSelect(Builder,result,$4.val[j],t,"");
		}


	/* store the size of the list*/
	store[index_store].size=1;
	store[index_store].val[0]=t;
	/* add the temp variable in hashmap along with the its position in store struct */
	add_val($1,index_store+1);
	$$=store[index_store];
	index_store++;
	

}
| TMP ASSIGN MAX expr_or_list SEMI
{ 
        int j;
        LLVMValueRef result,t;
        t=$4.val[0];
		/* Finding maximum of the values in list */
		for(j=1;j<$4.size;j++)
		{
				result=LLVMBuildICmp(Builder,LLVMIntSGT,$4.val[j],t,"");
				t=LLVMBuildSelect(Builder,result,$4.val[j],t,"");

		}
		/* store the size of the list*/
        store[index_store].size=1;
        store[index_store].val[0]=t;
		/* add the temp variable in hashmap along with the its position in store struct */
        add_val($1,index_store+1);
        $$=store[index_store];
        index_store++;

}
| TMP ASSIGN SUM expr_or_list SEMI
{
	int i;
	LLVMValueRef sum1;
	MyValue temp;
	sum1=$4.val[0];
	/* Finding sum of the values in list */
	for (i=1;i<$4.size;i++)
	{
		sum1=LLVMBuildAdd(Builder,sum1,$4.val[i],"");
	}
	/* store the size of the list*/
	store[index_store].size=1;
	/* store the sum in store struct */
	store[index_store].val[0]=sum1;
	/* add the temp variable in hashmap along with the its position in store struct */
	add_val($1,index_store+1);
	$$=store[index_store];
	index_store++;

}
;

expr_or_list:   expr
{
	$$=$1;
}
               | list
{
	$$=$1;
}
;

list : LBRACE list_ops RBRACE
{
	$$=$2;
	
}	
;

list_ops :    primitive
{
	MyValue temp;
	int i;
	temp.size=0;
	/* This is to form a list , forloop is needed if the primitive is also a list*/
	for (i=0;i<$1.size;i++)
	{
		temp.val[i]=$1.val[i];		
		temp.size++;
		/* The size of list is restricted to remain 32*/
		if(temp.size>=32)
		{
			break;
		}
	}
	$$=temp;
} 
| list_ops COMMA primitive
{	
	int i,count;
	count=$1.size;
	/* This is to form a list , forloop is needed if the primitive is also a list*/
	for (i=$1.size;i<($3.size+$1.size);i++)
	{
		$1.val[i]=$3.val[i-($1.size)];
		count++;     
                if(count>=32)
                {
                        break;
                }
		
	}
	$1.size=count;
	$$=$1;
}
;


expr:   expr MINUS expr
	{
		int i;
		const char *str;
		MyValue temp;
		/* program should be aborted if the sizes of lists are different*/
		if($1.size!=$3.size)
		{
		str="sizes different";
		yyerror(str);
		YYABORT;
		}
		/* Subtraction. Forloop is needed is the inputs are lists */
		for (i=0;i<$1.size;i++)
		{
			temp.val[i]=LLVMBuildSub(Builder,$1.val[i],$3.val[i],"");	
	
		}
		temp.size=$1.size;
		$$=temp;

				
	}
     | expr PLUS expr
	{
 
		int i;
		const char *str;
		MyValue temp;
		/* program should be aborted if the sizes of lists are different*/
		if($1.size!=$3.size)
		{
		 str="sizes different";
                yyerror(str);
		YYABORT;
		}
		/* Addition. Forloop is needed is the inputs are lists */
		for (i=0;i<$1.size;i++)
		{
			temp.val[i]=LLVMBuildAdd(Builder,$1.val[i],$3.val[i],"");	
		}
		temp.size=$1.size;
		$$=temp;
	
	
	}
      | MINUS expr
	{
		MyValue temp;
		int i;
		/* Negation. Forloop is needed is the inputs are lists */
		for(i=0;i<$2.size;i++)
		{
			temp.val[i]=LLVMBuildNeg(Builder,$2.val[i],"");
		}
		temp.size=$2.size;
		$$=temp;
	}	 	
      | expr MULTIPLY expr
{
		int i;
		const char *str;
		MyValue temp;
		/* program should be aborted if the sizes of lists are different*/
		if($1.size!=$3.size)
		{
		str="sizes different";
		yyerror(str);
		YYABORT;
		}
		/* Multiplication. Forloop is needed is the inputs are lists */
		for (i=0;i<$1.size;i++)
		{
			temp.val[i]=LLVMBuildMul(Builder,$1.val[i],$3.val[i],"");	
		}
		temp.size=$1.size;
		$$=temp;


}
      | expr DIVIDE expr
{
		int i;
		MyValue temp;
		const char *str;
		/* program should be aborted if the sizes of lists are different*/
		if($1.size!=$3.size)
		{ 
		str="sizes different";
                yyerror(str);
		YYABORT;
		}
		/* Division. Forloop is needed is the inputs are lists */
		for (i=0;i<$1.size;i++)
		{
			temp.val[i]=LLVMBuildSDiv(Builder,$1.val[i],$3.val[i],"");	
		}
		temp.size=$1.size;
		$$=temp;


}
      | primitive
	{
		$$=$1;
	}
;

primitive :   ID
{
	int i,pos;
	const char *str;
	MyValue temp;
	pos=get_val($1);
	/* if the variable is not in the hash map means it is uninitialized */
	if(get_val($1)==NULL)
	{
		pos=1;
		str="Error:unintitialized variable";
			i=yyerror(str);
		YYABORT;
	}
	temp.val[0]=LLVMGetParam(Function,pos-1);
	temp.size=1;
	$$=temp;	
}
| TMP
{
	int pos,i;
	char *str;
	pos=get_val($1);
	/* if the variable is not in the hash map means it is uninitialized */
	if(get_val($1)==NULL)
		{
				pos=1;
				str="Error:unintitialized variable";
				i=yyerror(str);
				YYABORT;
		}

	$$=store[pos-1];	
}
| NUM
{       MyValue temp;
	temp.val[0]=LLVMConstInt(LLVMInt64Type(),$1,0);
	temp.size=1;
	$$=temp;
}
;


%%

void initialize()
{
  /* IMPLEMENT: add something here if needed */
}

int line;

int yyerror(const char *msg)
{
  printf("%s at line %d.\n",msg,line);
  return 0;
}
