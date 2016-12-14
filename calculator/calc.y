/* simplest version of calculator */
%{
#include <stdio.h>

int yylex();
int yyerror();
%}

%union {
    int token;
    int op;
    double doubletype;
}

/* declare tokens */
%token <token> NUMBER
%token <op> ADD SUB MUL DIV ABS
%token <token> EOL

%type <doubletype> exp
%type <doubletype> factor
%type <doubletype> term

%%

calclist: /* nothing  matches at beginning of input */
 | calclist exp EOL { printf("value = %lf\n", $2); }
 ;

exp: factor       { $$ = $1; }
 | exp ADD factor { $$ = $1 + $3; }
 | exp SUB factor { $$ = $1 - $3; }
 ;

factor: term       { $$ = $1; }
 | factor MUL term { $$ = $1 * $3; }
 | factor DIV term { $$ = $1 / $3; }
 ;

term: NUMBER     { $$ = $1; }
 | ABS term { $$ = $2 >= 0? $2 : - $2; }
;

%%

int main(int argc, char **argv) {
    yyparse();
}

int yyerror(char *s) {
    fprintf(stderr, "error: %s\n", s);
    return 0;
}