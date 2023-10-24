%{

    #include<stdio.h>
    #include<stdlib.h>
    #include<string.h>
    #include "symboltable.c"

    void codegen_incdec(int o);
    void pushi(char * i);
void pusha();
void pushx();
void pushab();
void codegen();
void codegen_assign();
void for1();
void for2();
void for3();
void for4();
    char st[100][100];
    int top=-1;
    char i_[2]="0";
    //Temporary variable counter
    int temp_i=0;
    //Char string to store temporary varoable number
    char tmp_i[3];
    char temp[2]="t";
    //Array for labels
    int label[20];
    //Label number counter
    int lnum=0;
    //Top of label stack
    int ltop=0;
    //Label counter for loop
    int l_for=0;
    typedef struct quadruples
        {
           char *op;
           char *arg1;
           char *arg2;
           char *res;
         }quad;
      int quadlen = 0;
      //Quadraples data structure
      quad q[100];


    int bri = 0;
    extern void yyerror(char* s);  /* prints grammar violation message */
    extern int yylex();
    extern FILE *yyin;
    extern FILE *yyout;
    extern int yylineno;
    //extern YYLTYPE yylloc;
    extern char* yytext;
    extern int functionid;
    int yyscope=0;
    /* 0 implies global yyscope */
    int flag=0;
    int valid=1;
    
    struct quad{
        char op[1000];
        char arg1[1000];
        char arg2[1000];
        char result[1000];
    }QUAD[100];
    
    struct stack{
        int items[1000];
        int top;
    }stk;

    int labels[100];
    int labelIndex=0;

    struct switches{
        char switchvalue[100];
        int index;
        int cases;
        int hasdefault;
    }switches[1000];
    
    int recentswitch=0,test;
    int Index=0,tIndex=0,StNo,Ind,Ind2,Ind3,tInd;
    int tacLines=0;
    char resulttemp[1000];
    void AddQuadruple(char op[1000],char arg1[1000],char arg2[1000],char result[1000],char lhs[1000]);
    void GenerateTemp(char op[1000],char arg1[1000],char arg2[1000],char result[1000]);
    void switchCaseGenerate(char arg1[100]);
    void switchFillJumps();
    void repeatUntilGen(char arg1[100]);
    void push(int data);
    int pop();
    void createLabel();
    char doldol[1000];
    int paramscount;
    
%}
%locations
%union { char *str;  }
%start program

%token T_PACKAGE T_MAIN T_FUNC T_PRINT T_VAR T_RETURN 

%token T_FALLTHROUGH T_DEFAULT T_SWITCH T_CASE T_REPEAT T_UNTIL T_IMPORT T_FMT T_ELSE T_IF T_FOR T_DEFER T_TYPE T_STRUCT T_MAP
%token T_COMMA T_COLON T_PAREN_OPEN T_PAREN_CLOSE T_CURLY_OPEN T_CURLY_CLOSE T_BRACKET_OPEN T_BRACKET_CLOSE T_DOT T_U
%token T_SPLUS T_SMINUS T_SMUL T_SDIV T_SMOD T_SAND T_SOR  T_LSHIFT T_RSHIFT T_PLUS T_MINUS T_DIV T_MUL T_MOD T_WALRUS T_BAND T_BOR T_BXOR T_DECREMENT T_INCREMENT


%token <str> T_FALSE T_TRUE
%token <str> T_INTEGER
%token <str> T_STRING 
%token T_ASSIGN T_SEMI
%token <str> T_FLOAT64
%token <str> T_IDENTIFIER
%token <str> T_NOTEQ T_COMP T_LTE T_GTE T_AND T_OR T_BNOT T_LT T_GT LEFT_ARR
%token <str> T_INT T_STR T_BOOL T_FLT64

%type <str> strexpressions number expressions arithmeticExpression relationalExpression logicalExpression relationalOperator help_bruh1 ExpressionList Defer 
%type <str> L M N T F switchValue type value arrayvalues parameter parameterlist parameters returntype funccall argslist arg args 

%%

program                         : T_PACKAGE T_MAIN imports body
                                | T_PACKAGE T_IDENTIFIER imports body
                                | T_PACKAGE T_IDENTIFIER imports Typestart body
                                ;

imports                         : import
                                | import imports
                                |
                                ;

import                          : T_IMPORT importname
                                | T_IMPORT T_PAREN_OPEN importnames T_PAREN_CLOSE
                                | T_IMPORT T_PAREN_OPEN importnames 
                                | T_IMPORT importnames T_PAREN_CLOSE 
                                ;

importnames                     : importname
                                | importname importnames
                                ;

importname                      :T_STRING
                                ;
                                
Typestart                       : T_TYPE T_IDENTIFIER type compoundType //compoundStatement compoundType
                                ;

compoundType                    : T_CURLY_OPEN{++yyscope;} Typestatements {--yyscope;}T_CURLY_CLOSE
                                ;

Typestatements                  : Typestatement Typestatements
                                |
                                ;
                                
Typestatement                   : T_IDENTIFIER type
                                | T_IDENTIFIER T_MUL T_IDENTIFIER T_DOT T_IDENTIFIER
                                ;

semi                            : T_SEMI
                                | /* EPSILON */
                                ;

body                            :  mainFunctionDefinition
                                |  functionDefinitions mainFunctionDefinition
                                |  functionDefinitions
                                |  mainFunctionDefinition functionDefinitions
                                |  functionDefinitions mainFunctionDefinition functionDefinitions
                                ;
//body                              :  functionDefinitions
//                                  ;


mainFunctionDefinition          : T_FUNC T_MAIN {++functionid;functions[functionid].symbolCount=0;AddQuadruple("func","begin","main","",resulttemp);} T_PAREN_OPEN T_PAREN_CLOSE
                                {
                                    functions[functionid].funcid=functionid;
                                    strcpy(functions[functionid].name,"main");
                                    strcpy(functions[functionid].params,"");
                                    strcpy(functions[functionid].returntype,"");
                                }
                                compoundStatement
                                {
                                    AddQuadruple("func","end","main","",resulttemp);
                                }               
                                ;

functionDefinitions             : functionDefinition
                                | functionDefinitions functionDefinition
                                ;
//T_IDENTIFIER {++functionid;functions[functionid].symbolCount=0;AddQuadruple("func","begin","main","",resulttemp);}
functionDefinition              : T_FUNC T_IDENTIFIER {++functionid;functions[functionid].symbolCount=0;AddQuadruple("func","begin","main","",resulttemp);} T_PAREN_OPEN parameterlist T_PAREN_CLOSE returntype 
                                {
                                    
                                    functions[functionid].funcid=functionid;
                                    strcpy(functions[functionid].name,$2);
                                    strcpy(functions[functionid].params,$5);
                                    strcpy(functions[functionid].returntype,$7);

                                }
                                compoundStatement
                                {
                                   AddQuadruple("func","end",$2,"",resulttemp);
                                   //bri++;
                                   //if (bri==1) printf("3"); 
                                }
                                | T_FUNC T_PAREN_OPEN T_IDENTIFIER T_MUL T_IDENTIFIER T_PAREN_CLOSE T_IDENTIFIER T_PAREN_OPEN T_PAREN_CLOSE returntype compoundStatement
                                 /*{
                                   
                                   bri++;
                                   if (bri==1) {printf("\tsuccess\n");
    fclose(yyin);
    return 0;} 
                                }*/
                                ;

parameterlist                   : parameters
                                { strcpy($$,$1); }
                                | {strcpy($$,"");}
                                ;

parameters                      : parameter
                                {
                                    strcpy($$,$1);
                                }
                                | parameters T_COMMA parameter
                                {
                                    char temp[100];
                                    strcpy(temp,",");
                                    strcat(temp,$3);
                                    strcat($$,temp);
                                }
                                ;

parameter                       : T_IDENTIFIER type
                              /*  {
                                    AddQuadruple("Reparam",$1,"","",resulttemp);
                                    int foundIndex = checkDeclared(yyscope+1,$1);
                                    if(foundIndex == -1)
                                    {
                                        insertSymbolEntry($1, yylineno, @1.first_column, yyscope+1, $2,"",findSize($2));
                                    }
                                    else
                                    {
                                        printf("\033[0;31mError at line number %d\n\033[0;0m \033[0;36m%s\033[0;0m Redeclared in this block.\n\n", yylineno, $1);
                                        valid=0;
                                    }
                                    strcpy($$,$1);
                                    strcat($$," ");
                                    strcat($$,$2);
                                }*/
                                | T_IDENTIFIER T_IDENTIFIER
                                | T_IDENTIFIER FULL_IDENTIFICATOR
                                ;

returntype                      : type {strcpy($$,$1);}
                                | {strcpy($$,"");}
                                ;

type                            : T_INT    
                                | T_STR    
                                | T_FLT64
                                | T_BOOL
                                | T_INTEGER
                                | T_STRUCT
                                | MAP_TYPE
                                ;
                                
MAP_TYPE                        : T_MAP T_BRACKET_OPEN type T_BRACKET_CLOSE type ;

returnStatement                 : T_RETURN {strcpy(doldol,"");} expressions semi
                                /*{
                                    AddQuadruple("return",doldol,"","",resulttemp);
                                }*/
                                | T_RETURN T_IDENTIFIER T_DOT T_IDENTIFIER
                                | T_RETURN T_IDENTIFIER 
                                ;

compoundStatement               : T_CURLY_OPEN{++yyscope;} statements {--yyscope;}T_CURLY_CLOSE
                                ;


statements                      : statement statements
                                | /*EPSILON */
                                ;

statement                       : printStatement
                                | SimpleStmt 
                                | returnStatement
                                | variableDeclaration
                                | arrayDeclaration 
                                | variableAssignment
                                | arrayAssignment
                                | switchStatement
                                | repeatUntilStatement
                                | ifStatement
                                | funccall
                                | T_DEFER EXPRESSION_NO_LIT
                                | ForStmt
                              
                                ;

printStatement                  : T_FMT T_DOT T_PRINT T_PAREN_OPEN T_STRING T_PAREN_CLOSE semi
                                | T_FMT T_DOT T_PRINT T_PAREN_OPEN T_IDENTIFIER T_COMMA T_STRING T_PAREN_CLOSE semi
                                | T_FMT T_DOT T_PRINT T_PAREN_OPEN T_IDENTIFIER T_COMMA T_STRING T_PAREN_CLOSE
                                | T_FMT T_DOT T_PRINT T_PAREN_OPEN T_IDENTIFIER T_COMMA T_STRING T_COMMA T_IDENTIFIER T_PAREN_CLOSE
                                | T_FMT T_DOT T_PRINT T_PAREN_OPEN T_IDENTIFIER T_COMMA T_STRING T_COMMA FULL_IDENTIFICATOR T_PAREN_CLOSE
                                | T_FMT T_DOT T_PRINT T_PAREN_OPEN T_IDENTIFIER T_COMMA FULL_IDENTIFICATOR T_PAREN_CLOSE
                                ;

switchStatement                 : T_SWITCH switchValue
                                {
                                    recentswitch++;
                                    switches[recentswitch].index=Index;
                                    sprintf(switches[recentswitch].switchvalue,"%s",$2);
                                }
                                T_CURLY_OPEN {++yyscope;} switchCaseStatements {--yyscope;}T_CURLY_CLOSE
                                {
                                    switchFillJumps();
                                }
                                | T_SWITCH T_PAREN_OPEN switchValue T_PAREN_CLOSE
                                {
                                    recentswitch++;
                                    switches[recentswitch].index=Index;
                                    sprintf(switches[recentswitch].switchvalue,"%s",$3);
                                }
                                T_CURLY_OPEN {++yyscope;} switchCaseStatements {--yyscope;}T_CURLY_CLOSE
                                {
                                    switchFillJumps();
                                }
                                ;

switchValue                     : T_IDENTIFIER
                                | T_INTEGER
                                | T_FLOAT64
                                | T_STRING
                                |{strcpy($$,"");}
                                ;

switchCaseStatements            : switchCaseStatement
                                | switchCaseStatements switchCaseStatement
                                ;

switchCaseStatement             :T_CASE
                                {
                                    push(Index);
                                    createLabel();
                                } 
                                expressions T_COLON
                                {
                                    switchCaseGenerate($3);
                                }
                                statements
                                {
                                    push(Index);
                                    AddQuadruple("GOTO","","","-1",resulttemp);
                                } 
                                fallthroughStatement
                                | T_DEFAULT {push(Index);createLabel();}T_COLON statements
                                {
                                    switches[recentswitch].hasdefault=1;
                                    push(Index);
                                    AddQuadruple("GOTO","","","-1",resulttemp);
                                } 
                                ;

fallthroughStatement            : T_FALLTHROUGH
                                | /* EPSILON */
                                ;

expressions                     : arithmeticExpression
                                {
                                    strcpy($$,$1);
                                }
                                | relationalExpression
                                {
                                    strcpy($$,$1);
                                }
                                | logicalExpression
                                {
                                    strcpy($$,$1);
                                }
                                ;

arithmeticExpression            : arithmeticExpression {strcat(doldol,"+");}T_PLUS T
                                {
                                    GenerateTemp("+",$1,$4,$$);
                                }
                                | arithmeticExpression {strcat(doldol,"-");} T_MINUS T
                                {
                                    GenerateTemp("-",$1,$4,$$);
                                }
                                | T
                                {
                                    strcpy($$,$1);
                                }
                                ;

T                               : T {strcat(doldol,"*");} T_MUL F
                                {
                                    GenerateTemp("*",$1,$4,$$);
                                }
                                | T {strcat(doldol,"/");} T_DIV F
                                {
                                    GenerateTemp("/",$1,$4,$$);
                                }
                                | T  {strcat(doldol,"%");} T_MOD F
                                {
                                    GenerateTemp("%",$1,$4,$$);
                                }
                                | F
                                {
                                    strcpy($$,$1);
                                }
                                ;

F                               : T_PAREN_OPEN {strcat(doldol,"(");} arithmeticExpression {strcat(doldol,")");}T_PAREN_CLOSE
                                {
                                    strcpy($$,$3);
                                }
                                | T_IDENTIFIER
                                {
                                    int foundIndex = searchSymbol(yyscope, $1);
                                    if(foundIndex == -1)
                                    {
                                        //printf("\033[0;31mError at line number %d\n\033[0;0m ReferenceError : assignment to undeclared variable \033[0;35m%s\033[0;0m\n\n", yylineno, $1);
                                        //valid=0;
                                    }
                                    else
                                    {
                                        strcat(doldol,$1);
                                    }
                                }
                                | T_IDENTIFIER T_BRACKET_OPEN{strcat(doldol,$1);strcat(doldol,"[");} arithmeticExpression {strcat(doldol,"]");} T_BRACKET_CLOSE
                                {
                                    
                                    int foundIndex = searchSymbol(yyscope, $1);
                                    if(foundIndex == -1)
                                    {
                                       // printf("\033[0;31mError at line number %d\n\033[0;0m ReferenceError : assignment to undeclared variable \033[0;35m%s\033[0;0m\n\n", yylineno, $1);
                                        //valid=0;
                                    }
                                    else
                                    {
                                        GenerateTemp("*",findSize(SymbolTable[functionid][foundIndex].type),$4,resulttemp);
                                        GenerateTemp("=[]",$1,resulttemp,$$);
                                    }
                                }
                                | number
                                {
                                    strcat(doldol,$1);
                                    strcpy($$,$1);
                                }
                                ;

number                          : T_INTEGER
                                | T_FLOAT64
                                ;

relationalExpression            : arithmeticExpression relationalOperator {strcat(doldol,$2);} arithmeticExpression
                                {
                                    GenerateTemp($2,$1,$4,$$);
                                }
                                | T_STRING {strcat(doldol,$1);} relationalOperator {strcat(doldol,$3);} T_STRING
                                {
                                    strcat(doldol,$5);
                                    GenerateTemp($3,$1,$5,$$);
                                }
                                | T_TRUE
                                | T_FALSE
                                ;

relationalOperator              : T_NOTEQ //!=
                                | T_COMP //==
                                | T_LTE //<=
                                | T_GTE //>=
                                | T_LT //<
                                | T_GT //>
                                ;

logicalExpression               : T_BNOT {strcat(doldol,$1);} L
                                {
                                    GenerateTemp("!",$3,"",$$);
                                }
                                | L
                                {
                                    strcpy($$,$1);
                                }
                                ;

L                               : L T_AND {strcat(doldol,$2);} M
                                {
                                    GenerateTemp("AND",$1,$4,$$);
                                }
                                | M
                                {
                                    strcpy($$,$1);
                                }
                                ;
                       
M                               : M T_OR {strcat(doldol,$2);} N
                                {
                                    GenerateTemp("OR",$1,$4,$$);
                                }
                                | N
                                {
                                    strcpy($$,$1);
                                }
                                ;

N                               : T_PAREN_OPEN relationalExpression T_PAREN_CLOSE
                                {
                                    strcpy($$,$2);
                                    strcat(doldol,")");
                                }
                                ;


help_bruh1:
    expressions semi
    | '(' expressions ')' semi
    ;

repeatUntilStatement            : T_REPEAT T_CURLY_OPEN { ++yyscope;push(Index);createLabel();} statements {--yyscope;}T_CURLY_CLOSE T_UNTIL help_bruh1
                                {
                                    repeatUntilGen($8);
                                }
                                | T_REPEAT {++yyscope;push(Index);createLabel(); } statement {--yyscope;}T_UNTIL help_bruh1
                                {
                                    repeatUntilGen($6);
                                }
                                ;
                                
ifStatement                     : T_IF expressions compoundStatement
                                | T_IF expressions compoundStatement T_ELSE  compoundStatement
	                        | T_IF expressions compoundStatement T_ELSE ifStatement
	                        | T_IF T_IDENTIFIER T_PAREN_OPEN T_IDENTIFIER T_PAREN_CLOSE relationalOperator T_INTEGER compoundStatement
	                        | T_IF T_IDENTIFIER T_PAREN_OPEN T_IDENTIFIER T_PAREN_CLOSE relationalOperator T_INTEGER compoundStatement T_ELSE  compoundStatement
	                        | T_IF T_IDENTIFIER T_PAREN_OPEN T_IDENTIFIER T_PAREN_CLOSE relationalOperator T_INTEGER compoundStatement T_ELSE ifStatement
	                        ;
	                      
SimpleStmt                      : expressions T_ASSIGN expressions {codegen_assign();} 
	                        | strexpressions T_INCREMENT {codegen_incdec(1);} T_SEMI
	                        | strexpressions T_INCREMENT {codegen_incdec(1);} 
	                        | expressions T_DECREMENT {codegen_incdec(0);} 
	                        | expressions T_DECREMENT {codegen_incdec(0);} T_SEMI
	                        //
	                        | T_IDENTIFIER T_COMMA T_IDENTIFIER T_WALRUS T_INTEGER T_IDENTIFIER//argslist T_DOT argslist T_PAREN_OPEN argslist T_PAREN_CLOSE
	                        | expressions T_COMMA expressions T_ASSIGN expressions T_COMMA expressions
	                       // | expressions  T_COMMA expressions  T_WALRUS T_STRING T_DOT T_STRING T_PAREN_OPEN T_PAREN_CLOSE
	                        | expressions T_COMMA T_INTEGER T_WALRUS argslist T_DOT argslist T_PAREN_OPEN T_PAREN_CLOSE
	                        | T_IDENTIFIER T_COMMA T_INTEGER T_WALRUS argslist T_DOT argslist T_PAREN_OPEN argslist T_PAREN_CLOSE
	                        
	                        | T_IDENTIFIER T_WALRUS argslist T_DOT argslist T_PAREN_OPEN T_PAREN_CLOSE 
	                        | T_IDENTIFIER T_WALRUS T_INTEGER T_IDENTIFIER T_DOT T_IDENTIFIER T_DOT T_IDENTIFIER
	                        | T_IDENTIFIER T_WALRUS T_INTEGER T_IDENTIFIER T_DOT T_IDENTIFIER 
	                        | T_IDENTIFIER T_WALRUS T_INTEGER argslist
	                        | T_IDENTIFIER T_WALRUS T_STRING
	                        | T_IDENTIFIER T_WALRUS T_STRING T_SEMI
	                        | T_IDENTIFIER T_WALRUS argslist
	                        | T_IDENTIFIER T_DOT T_IDENTIFIER T_PAREN_OPEN argslist T_PAREN_CLOSE
	                        //
	                        | ExpressionList T_ASSIGN ExpressionList {
		                  // b,c = 2,3 T_STRING T_IDENTIFIER T_INTEGER argslist T_U strexpressions
	                        }
	                        //| 
	                       
ExpressionList                  :
	                        expressions {};
	                        
	/*                      
ForStmt                         : T_FOR SimpleStmt{for1();} T_SEMI expressions{for2();} T_SEMI SimpleStmt{for3();} compoundStatement{for4();}
                                | T_FOR SimpleStmt{for1();} T_SEMI expressions{for2();} T_SEMI SimpleStmt{for3();} compoundStatement{for4();} T_SEMI
                                | T_FOR T_U T_COMMA SimpleStmt compoundStatement{for4();}
                                | T_FOR SimpleStmt compoundStatement{for4();}  
                                ;*/
                                
ForStmt                         : T_FOR SimpleStmt T_SEMI expressions T_SEMI SimpleStmt compoundStatement
                                | T_FOR SimpleStmt T_SEMI expressions T_SEMI SimpleStmt compoundStatement T_SEMI
                                | T_FOR T_U T_COMMA SimpleStmt compoundStatement
                                | T_FOR SimpleStmt compoundStatement 
                                ;                                


variableDeclaration             : T_VAR T_IDENTIFIER type T_ASSIGN {strcpy(doldol,"");} strexpressions semi
                                /*{
                                    AddQuadruple("=",$6,"",$2,resulttemp);

                                    int foundIndex = checkDeclared(yyscope,$2);
                                    if(foundIndex == -1)
                                    {
                                        char* curType = DetermineType(doldol);
                                        if(strcmp(curType, $3) == 0 || strcmp(curType,"expr")==0)
                                        {
                                            insertSymbolEntry($2 , yylineno, @2.first_column, yyscope, $3, doldol,findSize($3));   
                                        }
                                        else if(strcmp($3,"float64")==0 && strcmp(curType,"int")==0)
                                        {
                                            insertSymbolEntry($2 , yylineno, @2.first_column, yyscope, "float", doldol,findSize("float"));
                                        } 
                                        else
                                        {
                                            printf("\033[0;31mError at line number %d\n\033[0;0m Cannot use %s (type untyped %s) as type %s in assignment\n\n", yylineno, doldol, curType, $3);
                                            valid=0;
                                        }
                                    }

                                    else
                                    {
                                        printf("\033[0;31mError at line number %d\n\033[0;0m \033[0;36m%s\033[0;0m Redeclared in this block.\n\n", yylineno, $2);
                                        valid=0;
                                    }
                                }*/
                                | T_VAR T_IDENTIFIER type semi
                               /* {
                                    int foundIndex = checkDeclared(yyscope,$2);
                                    if(foundIndex == -1)
                                    {
                                        insertSymbolEntry($2 , yylineno, @2.first_column, yyscope, $3, "",findSize($3));   
                                    }

                                    else
                                    {
                                        printf("\033[0;31mError at line number %d\n\033[0;0m \033[0;36m%s\033[0;0m Redeclared in this block.\n\n", yylineno, $2);
                                        valid=0;
                                    }
                                }*/
                                | T_VAR T_IDENTIFIER T_ASSIGN {strcpy(doldol,"");} strexpressions semi
                               /* {
                                    AddQuadruple("=",$5,"",$2,resulttemp);

                                    int foundIndex = checkDeclared(yyscope, $2);
                           
                                    if(foundIndex == -1)
                                    {
                                        char* curType = DetermineType(doldol);
                                        if(strcmp(curType,"expr")==0)
                                        {
                                           strcpy( curType,"expr");
                                        }
                                        insertSymbolEntry($2 , yylineno, @2.first_column, yyscope, curType, doldol, findSize(curType));
                                           
                                    }
                                    else
                                    {
                                        printf("\033[0;31mError at line number %d\n\033[0;0m \033[0;36m%s\033[0;0m Redeclared in this block.\n\n", yylineno, $2);
                                        valid=0;
                                    }
                                }*/
                                | T_IDENTIFIER T_WALRUS {strcpy(doldol,"");} strexpressions semi
                                /*{
                                    AddQuadruple("=",$4,"",$1,resulttemp);

                                    int foundIndex = checkDeclared(yyscope, $1);
                           
                                    if(foundIndex == -1)
                                    {
                                        char* curType = DetermineType(doldol);
                                        if(strcmp(curType,"expr")==0)
                                        {
                                           strcpy( curType,"expr");
                                        }
                                        insertSymbolEntry($1 , yylineno, @1.first_column, yyscope, curType, doldol, findSize(curType));
                                    }
                                    else
                                    {
                                        printf("\033[0;31mError at line number %d\n\033[0;0m \033[0;36m%s\033[0;0m Redeclared in this block.\n\n", yylineno, $1);
                                        valid=0;
                                    }
                                }*/
                                ;

arrayDeclaration                : T_VAR T_IDENTIFIER T_BRACKET_OPEN {strcpy(doldol,"");} arraylength T_BRACKET_CLOSE type T_CURLY_OPEN arrayvalues T_CURLY_CLOSE semi
                                /*{
                                    char arrayvalues[100];
                                    strcpy(arrayvalues,"{");
                                    strcat(arrayvalues,$9);
                                    strcat(arrayvalues,"}");
                                    AddQuadruple("=",arrayvalues,"",$2,resulttemp);

                                    int foundIndex = checkDeclared(yyscope, $2);
                                    if(foundIndex != -1)
                                    {
                                        printf("\033[0;31mError at line number %d\n\033[0;0m \033[0;36m%s\033[0;0m Redeclared in this block.\n\n", yylineno, $2);
                                        valid=0;
                                    }

                                    else
                                    {
                                        char temp[100];
                                        strcpy(temp,$9);
                                        int istypeOK = checkArrayValType(temp,$7);
                                        if(istypeOK)
                                        {
                                            char size[100];
                                            sprintf(size, "%d", atoi(doldol)*atoi(findSize($7)));
                                            insertSymbolEntry($2 , yylineno, @2.first_column, yyscope, $7, $9,size);  
                                        }
                                        else 
                                        {
                                            printf("\033[0;31mError at line number %d\n\033[0;0m \033[0;36m%s\033[0;0m array value(s) do not match array type.\n\n", yylineno, $9);
                                            valid=0;
                                        }
                                    }
                                }*/
                                | T_IDENTIFIER T_WALRUS T_BRACKET_OPEN {strcpy(doldol,"");} arraylength T_BRACKET_CLOSE type T_CURLY_OPEN arrayvalues T_CURLY_CLOSE semi
                                /*{
                                    char temp[100];
                                    strcpy(temp,$9);
                                    char arrayvalues[100];
                                    strcpy(arrayvalues,"{");
                                    strcat(arrayvalues,$9);
                                    strcat(arrayvalues,"}");
                                    AddQuadruple("=",arrayvalues,"",$1,resulttemp);

                                    int foundIndex = checkDeclared(yyscope, $1);
                                    if(foundIndex != -1)
                                    {
                                        printf("\033[0;31mError at line number %d\n\033[0;0m \033[0;36m%s\033[0;0m Redeclared in this block.\n\n", yylineno, $1);
                                        valid=0;
                                    }

                                    else
                                    {
                                        
                                        int istypeOK = checkArrayValType(temp,$7);
                                        
                                        if(istypeOK)
                                        {
                                            char size[100];
                                            sprintf(size, "%d", atoi(doldol)*atoi(findSize($7)));
                                            insertSymbolEntry($1 , yylineno, @1.first_column, yyscope, $7, $9,size);  
                                        }
                                        else 
                                        {
                                            printf("\033[0;31mError at line number %d\n\033[0;0m \033[0;36m%s\033[0;0m array value(s) do not match array type.\n\n", yylineno, $9);
                                            valid=0;
                                        }
                                    }

                                }*/
                                ;
 
arraylength                     : arithmeticExpression
                                ;

arrayvalues                     : value
                                {
                                    strcpy($$,$1);
                                }
                                | arrayvalues T_COMMA value
                                {
                                    char temp[100];
                                    strcpy(temp,",");
                                    strcat(temp,$3);
                                    strcat($$,temp);
                                } 
                                ;

value          	                : T_INTEGER
                                | T_FLOAT64
                                | T_STRING
                                | T_TRUE
                                | T_FALSE
                                ;

strexpressions                  : T_STRING
                                {
                                    strcat(doldol,$1);
                                    strcpy($$,$1);
                                }
                                | expressions
                                {
                                    strcpy($$,$1);
                                }
                                | funccall
                                {
                                    strcpy($$,$1);
                                }
                                ;

variableAssignment              : T_IDENTIFIER T_ASSIGN {strcpy(doldol,"");} strexpressions semi
                                /*{
                                    //AddQuadruple("=",$4,"",$1,resulttemp);

                                    int foundIndex = searchSymbol(yyscope, $1);
                           
                                    if(foundIndex == -1)
                                    {
                                        //printf("\033[0;31mError at line number %d\n\033[0;0m ReferenceError : assignment to undeclared variable \033[0;35m%s\033[0;0m\n\n", yylineno, $1);
                                        //valid=0;
                                    }
                                    else
                                    {
                                        char* curType = DetermineType(doldol);

                                        if(strcmp(SymbolTable[functionid][foundIndex].type, curType) == 0 || strcmp(curType,"expr")==0 || strcmp(SymbolTable[functionid][foundIndex].type,"float64")==0 && strcmp(curType,"int")==0)
                                        {
                                            updateSymbolEntry($1, yylineno, @1.first_column, yyscope, SymbolTable[functionid][foundIndex].type, doldol);
                                        }
                                        else if(strcmp(SymbolTable[functionid][foundIndex].type,"expr")==0)
                                        {
                                            updateSymbolEntry($1, yylineno, @1.first_column, yyscope, curType, doldol);
                                        }
                                        else
                                        {
                                            printf("\033[0;31mError at line number %d\n\033[0;0m Cannot use %s (type untyped %s) as type %s in assignment\n\n", yylineno, doldol, curType, SymbolTable[functionid][foundIndex].type);
                                            valid=0;
                                        }
                                    }
                                }*/
                                ;

arrayAssignment                 : T_IDENTIFIER T_BRACKET_OPEN arithmeticExpression T_BRACKET_CLOSE T_ASSIGN {strcpy(doldol,"");} strexpressions semi
                                /*{
                                    int foundIndex = searchSymbol(yyscope, $1);
                                    if(foundIndex == -1)
                                    {
                                        //printf("\033[0;31mError at line number %d\n\033[0;0m ReferenceError : assignment to undeclared variable \033[0;35m%s\033[0;0m\n\n", yylineno, $1);
                                        //valid=0;
                                    }
                                    else
                                    {
                                        
                                        GenerateTemp("*",findSize(SymbolTable[functionid][foundIndex].type),$3,resulttemp);
                                        AddQuadruple("[]=",resulttemp,doldol,$1,resulttemp);
                   
                                        char* curType =  DetermineType($7);

                                        if(strcmp(curType, SymbolTable[functionid][foundIndex].type) != 0)
                                        {
                                            //printf("\033[0;31mError at line number %d\n\033[0;0m Type Mismatch \033[0;35m%s\033[0;0m\n\n", yylineno, $1);   
                                            //valid=0;
                                        }
                                    }
                                }*/
                                ;

funccall                        : T_IDENTIFIER {paramscount=0;} T_PAREN_OPEN argslist T_PAREN_CLOSE
                               /* {

                                    int foundIndex = searchFunction($1);
                                    strcpy(doldol,$1);
                                    if(foundIndex == -1)
                                    {
                                        printf("\033[0;31mError at line number %d\n\033[0;0m ReferenceError : access to undefined function \033[0;35m%s\033[0;0m\n\n", yylineno, $1);
                                        valid=0;
                                    }
                                    
                                    char temp[100];
                                    sprintf(temp,"%d",paramscount);
                                    GenerateTemp("call",$1,temp,resulttemp);
                                    
                                    strcpy($$,resulttemp);
                                    
                                    strcat(doldol,"(");
                                    strcat(doldol,$4);
                                    strcat(doldol,")");
                                }*/
                                ;

argslist                        : args
                                { 
                                    strcpy($$,$1);
                                }
                                | {strcpy($$,"");}
                                ;

args                            : arg
                                {
                                    strcpy($$,$1);
                                }
                                | args T_COMMA arg
                                {
                                    char temp[100];
                                    strcpy(temp,",");
                                    strcat(temp,$3);
                                    strcat($$,temp);
                                }
                                ;

arg                             : T_IDENTIFIER
                               /* {
                                    ++paramscount;
                                    AddQuadruple("param",$1,"","",resulttemp);
                                    int foundIndex = searchSymbol(yyscope,$1);
                                   // if(foundIndex == -1)
                                    //{
                                     //   printf("\033[0;31mError at line number %d\n\033[0;0m ReferenceError : access to undeclared variable \033[0;35m%s\033[0;0m\n\n", yylineno, $1);
                                    //    valid=0;
                                    //}
                                    strcpy($$,$1);
                                }*/
                                | value
                                /*{
                                    ++paramscount;
                                    AddQuadruple("param",$1,"","",resulttemp);
                                    strcpy($$,$1);
                                }*/
                                ;
                                
EXPRESSION_NO_LIT               : EXPRESSION_NO_LIT binary_op UnaryExpr 
                                | UnaryExpr
                                ;
                                
UnaryExpr                       : PrimaryExpr 
                                | unary_op UnaryExpr
                                ;

binary_op                       : T_OR        
                                | T_AND   
                                | relationalOperator            
                                | add_op           
                                | mul_op          
                                ;
                                

mul_op                          : T_DIV | T_MOD | T_LSHIFT | T_RSHIFT | T_BAND;

add_op                          : T_PLUS | T_MINUS | T_BNOT | T_BXOR ;

unary_op                        : T_PLUS | T_MINUS | T_BNOT | T_BXOR | address_op | LEFT_ARR;

address_op                      : T_MUL | T_BAND ; //T_MUL="*"
                          
PrimaryExpr                     : OPERAND //statement
                                //| PrimaryExpr Selector      //{ print("PrimaryEXPR selector");}
                                //| PrimaryExpr Index 
                                //| PrimaryExpr Slice 
                                //| PrimaryExpr TypeAssertion 
                                //| PrimaryExpr Arguments    // { print("PrimaryEXPRESSION Arguments"); }
                                | T_PAREN_OPEN PrimaryExpr T_PAREN_CLOSE
                                ;
                                
OPERAND                         : LITERAL              
                                | LITERAL_TYPE     // { print("Literal_Type in OPERAND");}
                                ;

TypeAssertion                   : T_DOT T_PAREN_OPEN TYPE T_PAREN_CLOSE ;

TYPE                            : TYPE_LIT
                                | FULL_IDENTIFICATOR
                                //  | '(' TYPE ')'
                                ;

TYPE_LIT                        : FUNCTION_TYPE
                                //ARRAY_TYPE
                                //| '[' DOT_DOT_DOT ']' TYPE  
                                //| STRUCT_TYPE
                                //| POINTER_TYPE
                                //| FUNCTION_TYPE
                                //| INTERFACE_TYPE
                                //| SLICE_TYPE
                                //| MAP_TYPE
                                //| CHANNEL_TYPE     // +8 Reduce/reduce
                                ;
                                
FULL_IDENTIFICATOR              : T_IDENTIFIER 
                                | T_IDENTIFIER T_DOT T_IDENTIFIER
                                | T_IDENTIFIER T_DOT T_IDENTIFIER T_PAREN_OPEN T_PAREN_CLOSE
                                ;
                                
FUNCTION_TYPE                   : T_FUNC T_PAREN_OPEN parameterlist T_PAREN_CLOSE ;

LITERAL_TYPE                    :FULL_IDENTIFICATOR
  //STRUCT_TYPE 
  //| ARRAY_TYPE 
  //| '[' DOT_DOT_DOT ']' TYPE
  //| '[' ']' TYPE
  //| SLICE_TYPE 
  //| MAP_TYPE 
  //| FULL_IDENTIFICATOR //{print("FULL in Literal TYPE");}                                          
  ;
  
LITERAL                          : BASIC_LITERAL | ANON_FUNCTION  ; //| COMPOSITE_LITERAL;
BASIC_LITERAL                    : T_INTEGER | T_STRING | T_FLOAT64 | T_TRUE| T_FALSE  
                                 //| COMPLEX
                                 ;
                                 
ANON_FUNCTION: T_FUNC  T_PAREN_OPEN parameterlist T_PAREN_CLOSE  compoundStatement;                                
%%

extern void yyerror(char* si)
{
    //printf("\tsuccess\n");
    //fclose(yyin);
    printf("%s at line number %d\n",si,yylineno);
    valid=0;
}


void pushi(char * i)
{
    strcpy(st[++top],i);
} 

void push(int data)
{ 
	stk.top++;

	if(stk.top==100)
    {
		printf("\n Stack overflow\n");
		exit(0);
	}

	stk.items[stk.top]=data;
}

int pop()
{
	int data;

	if(stk.top==-1)
    {
		printf("\n Stack underflow\n");
		exit(0);
	}

	data=stk.items[stk.top--];
	return data;
}


void createLabel()
{
    labels[labelIndex]=Index;
    strcpy(QUAD[Index].op,"label");
	strcpy(QUAD[Index].arg1,"");
	strcpy(QUAD[Index].arg2,"");
	sprintf(QUAD[Index++].result,"L%d",labelIndex++);
}

void AddQuadruple(char op[1000],char arg1[1000],char arg2[1000],char result[1000],char lhs[1000]){
	strcpy(QUAD[Index].op,op);
	strcpy(QUAD[Index].arg1,arg1);
	strcpy(QUAD[Index].arg2,arg2);
	strcpy(QUAD[Index].result,result);
	strcpy(lhs,QUAD[Index++].result);
}

void GenerateTemp(char op[1000],char arg1[1000],char arg2[1000],char result[1000]){
	strcpy(QUAD[Index].op,op);
	strcpy(QUAD[Index].arg1,arg1);
	strcpy(QUAD[Index].arg2,arg2);
	sprintf(QUAD[Index].result,"t%d",tIndex++);
	strcpy(result,QUAD[Index++].result);

    char token[100];
    sprintf(token,"t%d",tIndex-1);
    insertSymbolEntry(token, 0, 0, 0, "", "","");
}

void switchCaseGenerate(char arg1[100])
{
    switches[recentswitch].cases+=1;
    if(strcmp(switches[recentswitch].switchvalue,"")==0)
    {
        push(Index);
        AddQuadruple("if",arg1,"TRUE","-1",resulttemp);
    }
    else
    {
        char result[100];
        GenerateTemp("==",switches[recentswitch].switchvalue,arg1,result);
        push(Index);
        AddQuadruple("if",result,"TRUE","-1",resulttemp);
    }
    push(Index);
    AddQuadruple("GOTO","","","-1",resulttemp);
    push(Index);
    createLabel();
}

void switchFillJumps(){
    int afterstmts,label,iffail,ifpass,caselabel;
    int FailoverIndex=Index;
    createLabel();
    if(switches[recentswitch].hasdefault==1)
    {
        FailoverIndex=pop();
        strcpy(QUAD[FailoverIndex].result,QUAD[Index-1].result);
        FailoverIndex=pop();
    }
    for(int i=0; i<switches[recentswitch].cases;++i)
    {
        afterstmts=pop();
        label=pop();
        iffail=pop();
        ifpass=pop();
        caselabel=pop();

        strcpy(QUAD[afterstmts].result,QUAD[Index-1].result);
        strcpy(QUAD[iffail].result,QUAD[FailoverIndex].result);
        strcpy(QUAD[ifpass].result,QUAD[label].result);
        FailoverIndex=caselabel;
    }
    strcpy(switches[recentswitch].switchvalue,"");
    switches[recentswitch].index=0;
    switches[recentswitch].cases=0;
    switches[recentswitch].hasdefault=0;
    --recentswitch;

}

void repeatUntilGen(char arg1[100])
{
    push(Index);
    AddQuadruple("if",arg1,"TRUE","-1",resulttemp);

    
    push(Index);
    AddQuadruple("GOTO","","","-1",resulttemp);
    createLabel(); //out of loop label

    Ind=pop();  //goto
    Ind2=pop(); //IF
    Ind3=pop(); //repeat Label
    strcpy(QUAD[Ind].result,QUAD[Index -1].result);
    strcpy(QUAD[Ind2].result,QUAD[Ind3].result);
}


void success(char* name){
    FILE*file=fopen("results.txt", "a");
    fprintf(file, "[+] %s\n", name);
    fclose(file);
}

void error(char* name){
    FILE*file=fopen("results.txt", "a");
    fprintf(file, "[-] %s\n", name);
    fclose(file);
}

void codegen()
{   //Intermediate operation assigned to temporary variable
    strcpy(temp,"T");
    sprintf(tmp_i, "%d", temp_i);
    strcat(temp,tmp_i);
    //Quad creation (eq. T = a + c)
    
    //Writing into output tac file
    
    q[quadlen].op = (char*)malloc(sizeof(char)*strlen(st[top-1]));
    q[quadlen].arg1 = (char*)malloc(sizeof(char)*strlen(st[top-2]));
    q[quadlen].arg2 = (char*)malloc(sizeof(char)*strlen(st[top]));
    q[quadlen].res = (char*)malloc(sizeof(char)*strlen(temp));
    strcpy(q[quadlen].op,st[top-1]);
    strcpy(q[quadlen].arg1,st[top-2]);
    strcpy(q[quadlen].arg2,st[top]);
    strcpy(q[quadlen].res,temp);
    quadlen++;
    //Pop 3 elements from stack (eq. a + c)
    top-=2;
    //Pushing temporary variable to stack
    strcpy(st[top],temp);
    temp_i++;
}
void codegen_assign()
{  
    //Assignment operation (eg. b = T2 )
    //T2 < = < b 
    
    //Quad creation
    q[quadlen].op = (char*)malloc(sizeof(char));
    q[quadlen].arg1 = (char*)malloc(sizeof(char)*strlen(st[top]));
    q[quadlen].arg2 = NULL;
    q[quadlen].res = (char*)malloc(sizeof(char)*strlen(st[top-2]));
    strcpy(q[quadlen].op,"=");
    strcpy(q[quadlen].arg1,st[top]);
    strcpy(q[quadlen].res,st[top-2]);
    quadlen++;
    //Pop elements from stack
    top-=2;
}
void codegen_incdec(int o){
    //Check if increment or decrement
    if(o)
        pushi("+");
    else
        pushi("-");
    // Push one to stack
    pushi("1");
    // Get identifier at position top-2 which has to be incremented
    char tempi[31];
    strcpy(tempi,st[top-2]);
    //quad generation like Tx = a + 1
    codegen();
    pushi("=");
    //Pushing temporary variable to top of stack and identifier downwards so Tx=a+1 and a=Tx
    pushi(st[top-1]);
    strcpy(st[top-2],tempi);
    //Quad genreation for a = Tx
    codegen_assign();
}
void for1()
{   //...initialisation statement
    //For loop lable count
    l_for = lnum;
    //Writing into output tac file
    
    //Creating quad for label after initialisation statement (condition)
    q[quadlen].op = (char*)malloc(sizeof(char)*6);
    q[quadlen].arg1 = NULL;
    q[quadlen].arg2 = NULL;
    q[quadlen].res = (char*)malloc(sizeof(char)*(lnum+2));
    strcpy(q[quadlen].op,"Label");
    char x[10];
    
    char l[]="L";
    strcpy(q[quadlen].res,strcat(l,x));
    quadlen++;
}
void for2()
{   //...Condition statement
    strcpy(temp,"T");
    
    strcat(temp,tmp_i);
    //Writing into output tac file
    
    //Generating quad for when condition is "not" true, Tx = not condition
    //Output of condition stored on top of stack as temp variable
    
    q[quadlen].op = (char*)malloc(sizeof(char)*4);
    q[quadlen].arg1 = (char*)malloc(sizeof(char)*strlen(st[top]));
    q[quadlen].arg2 = NULL;
    q[quadlen].res = (char*)malloc(sizeof(char)*strlen(temp));
    strcpy(q[quadlen].op,"not");
    strcpy(q[quadlen].arg1,st[top]);
    strcpy(q[quadlen].res,temp);
    quadlen++;
    //Writing into output tac file
    
    q[quadlen].op = (char*)malloc(sizeof(char)*3);
    q[quadlen].arg1 = (char*)malloc(sizeof(char)*strlen(temp));
    q[quadlen].arg2 = NULL;
    q[quadlen].res = (char*)malloc(sizeof(char)*(lnum+2));
    strcpy(q[quadlen].op,"if");
    strcpy(q[quadlen].arg1,temp);
    char x[10];
    
    char l[]="L";
    strcpy(q[quadlen].res,strcat(l,x));
    quadlen++;
    //Increase temp variable count
    temp_i++;
    //Label on top of stack is for instruction after loop
    label[++ltop]=lnum;
    //Increment label count
    lnum++;
    //Writing into output tac file
    
    //Generating goto for when condition is true (loop body)
    q[quadlen].op = (char*)malloc(sizeof(char)*5);
    q[quadlen].arg1 = NULL;
    q[quadlen].arg2 = NULL;
    q[quadlen].res = (char*)malloc(sizeof(char)*(lnum+2));
    strcpy(q[quadlen].op,"goto");
    char x1[10];
    sprintf(x1,"%d",lnum);
    char l1[]="L";
    strcpy(q[quadlen].res,strcat(l1,x1));
    quadlen++;
    //Label on top of stack is for loop body
    label[++ltop]=lnum;
    //Increment label number to get lable for increment statement
    
    //Creating quad for label for increment statement following condition
    q[quadlen].op = (char*)malloc(sizeof(char)*6);
    q[quadlen].arg1 = NULL;
    q[quadlen].arg2 = NULL;
    q[quadlen].res = (char*)malloc(sizeof(char)*(lnum+2));
    strcpy(q[quadlen].op,"Label");
    char x2[10];
    
    char l2[]="L";
    strcpy(q[quadlen].res,strcat(l2,x2));
    quadlen++;
 }
void for3()
{   //...Increment statement
    int x;
    //Get label for loop body from label stack top
    x=label[ltop--];
    //Writing into output tac file
  
    //Generating goto for checking condition label
    q[quadlen].op = (char*)malloc(sizeof(char)*5);
    q[quadlen].arg1 = NULL;
    q[quadlen].arg2 = NULL;
    q[quadlen].res = (char*)malloc(sizeof(char)*strlen(temp));
    strcpy(q[quadlen].op,"goto");
    char jug[10];
    
    char l[]="L";
    strcpy(q[quadlen].res,strcat(l,jug));
    quadlen++;
    //Writing into output tac file
    
    //Creating quad for label for loop body
    q[quadlen].op = (char*)malloc(sizeof(char)*6);
    q[quadlen].arg1 = NULL;
    q[quadlen].arg2 = NULL;
    q[quadlen].res = (char*)malloc(sizeof(char)*(x+2));
    strcpy(q[quadlen].op,"Label");
    char jug1[10];
    
    char l1[]="L";
    strcpy(q[quadlen].res,strcat(l1,jug1));
    quadlen++;

}
void for4()
{   //...Loop body
    int x;
    x=label[ltop--];
    //Writing into output tac file
   
    //Creating quad for goto to label for increment statement
    q[quadlen].op = (char*)malloc(sizeof(char)*5);
    q[quadlen].arg1 = NULL;
    q[quadlen].arg2 = NULL;
    q[quadlen].res = (char*)malloc(sizeof(char)*strlen(temp));
    strcpy(q[quadlen].op,"goto");
    char jug[10];
    
    char l[]="L";
    strcpy(q[quadlen].res,strcat(l,jug));
    quadlen++;
    //Writing into output tac file
    
    //Creating quad for label after loop , instruction after loop
    q[quadlen].op = (char*)malloc(sizeof(char)*6);
    q[quadlen].arg1 = NULL;
    q[quadlen].arg2 = NULL;
    q[quadlen].res = (char*)malloc(sizeof(char)*(x+2));
    strcpy(q[quadlen].op,"Label");
    char jug1[10];
    
    char l1[]="L";
    strcpy(q[quadlen].res,strcat(l1,jug1));
    quadlen++;
}




int main(int argc, char * argv[])
{
    yyin=fopen(argv[1],"r");
    yylloc.first_line=yylloc.last_line=1;
    yylloc.first_column=yylloc.last_column=0;
    //printf("LINENO \t TYPE      \tTOKENNAME\n");
    int accepted=yyparse();
    //if (bri==1) {  printf("\tsuccess\n");goto zzz;}
    if(accepted==0 && valid!=0){
        
       // printSymbolTable();

        //printf("\n\n\t\t -------------------------------------""\n\t\t \033[0;33mPos\033[0;36m Operator\033[0;35m \tArg1 \tArg2\033[0;32m \tResult\033[0;0m" "\n\t\t -------------------------------------");

       // for(int i=0;i<Index;i++){
         //   printf("\n\t\t \033[0;33m%d\033[0;36m\t %s\033[0;35m\t %s\t %s \033[0;32m\t%s\033[0;0m",i,QUAD[i].op,QUAD[i].arg1,QUAD[i].arg2,QUAD[i].result);
        //}

       // printf("\n");
        success(argv[1]);
        printf("\tsuccess\n");
    } else
    {
        //printf("\n\n\033[0;31mSyntax is Invalid, Cannot generate Three Address Code.\033[0;0m\n\n");
        error(argv[1]);
    }
    //zzz:
    //printf("\tsuccess\n");
    fclose(yyin);
    return 0;

}
