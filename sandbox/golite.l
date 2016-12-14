%{
#include <string>
#include <iostream>
#include <stdlib.h>

#include <golite/source_file.hpp>

#include "golite.tab.h"
extern int yylineno;

int last_token = 0;
int line_empty = 0;
int needs_semi_colon();

%}

%s comment
%s linecomment

OCT     0[0-7]+
DEC     ([1-9][0-9]*)|0
HEX     0[xX][0-9A-Fa-f]+

DIGIT   [0-9]
NOQUOTE [\x00-\x21\x23-\x5F\x61-\x7F]
NOQUOTESLASH [\x20\x21\x23-\x5B\x5D-\x5F\x61-\x7F]
IDENT   [_a-zA-Z][_a-zA-Z0-9]*

RUNE    [\x20-\x7F]

ESCAPED [abfnrtv\'\\]

%%

"/*" 	BEGIN(comment);

<comment>([^\n*]|"*"[^/])*\n {
	// eat up each new line keeping track of lineno
	if (needs_semi_colon()) {
  		line_empty = 1;
  		unput('\n');
  		return ';';
  	}
  	yylineno++;
  	line_empty = 1;
}

<comment>([^\n*]|"*"[^/])*"*/"	 BEGIN(INITIAL);

<comment><<EOF>> {

	// eat up each new line keeping track of lineno
	if (needs_semi_colon()) {
  		line_empty = 1;
  		unput('\n');
  		return ';';
  	}
  	yylineno++;
  	line_empty = 1;

	BEGIN(INITIAL);
	return TINVALID; /*check for EOF in comment */
}



"//" 	BEGIN(linecomment);

<linecomment>[^\n]*   /* Eat up everything except newline */


<linecomment>\n	{

 	BEGIN(INITIAL);
	if (needs_semi_colon()) {
  		line_empty = 1;
  		unput('\n');
  		return ';';
  	}
  	yylineno++;
  	line_empty = 1;
}


<linecomment><<EOF>>  {

	// check if semicolon is needed
	if (needs_semi_colon()) {
  		line_empty = 1;
  		unput('\n');
  		return ';';
  	}
  	yylineno++;
  	line_empty = 1;

	BEGIN(INITIAL);
	yyterminate();
}

<<EOF>>  {

	// check for last semicolon
	if (needs_semi_colon()) {
  		line_empty = 1;
  		return ';';
  	} else {
  		yyterminate();
  	}

}


break 		line_empty = 0;  last_token = TBREAK; return TBREAK;
case        line_empty = 0;  last_token = 0; return TCASE;
chan        line_empty = 0;  last_token = 0; return TCHAN;
const       line_empty = 0;  last_token = 0; return TCONST;
continue    line_empty = 0;  last_token = TCONTINUE; return TCONTINUE;
default     line_empty = 0;  last_token = 0; return TDEFAULT;
defer       line_empty = 0;  last_token = 0; return TDEFER;
else        line_empty = 0;  last_token = 0; return TELSE;
fallthrough line_empty = 0;  last_token = TFALLTHROUGH; return TFALLTHROUGH;
for         line_empty = 0;  last_token = 0; return TFOR;
func        line_empty = 0;  last_token = 0; return TFUNC;
go          line_empty = 0;  last_token = 0; return TGO;
goto        line_empty = 0;  last_token = 0; return TGOTO;
if          line_empty = 0;  last_token = 0; return TIF;
import      line_empty = 0;  last_token = 0; return TIMPORT;
interface   line_empty = 0;  last_token = 0; return TINTERFACE;
map         line_empty = 0;  last_token = 0; return TMAP;
package     line_empty = 0;  last_token = 0; return TPACKAGE;
range       line_empty = 0;  last_token = 0; return TRANGE;
return      line_empty = 0;  last_token = TRETURN; return TRETURN;
select      line_empty = 0;  last_token = 0; return TSELECT;
struct      line_empty = 0;  last_token = 0; return TSTRUCT;
switch      line_empty = 0;  last_token = 0; return TSWITCH;
type        line_empty = 0;  last_token = 0; return TTYPE;
var         line_empty = 0;  last_token = 0; return TVAR;

int 		line_empty = 0; last_token = TINT; return TINT;
float64		line_empty = 0; last_token = TFLOAT; return TFLOAT;
bool		line_empty = 0; last_token = TBOOL; return TBOOL;
rune		line_empty = 0; last_token = TRUNE; return TRUNE;
string		line_empty = 0; last_token = TSTRING; return TSTRING;
print 		line_empty = 0; last_token = 0; return TPRINT;
println 	line_empty = 0; last_token = 0; return TPRINTLN;
append 		line_empty = 0; last_token = 0; return TAPPEND;



"+"         line_empty = 0; last_token = 0; return PLUS;
"-"         line_empty = 0; last_token = 0; return MINUS;
"*"         line_empty = 0; last_token = 0; return MULT;
"/"         line_empty = 0; last_token = 0; return DIV;
"%"         line_empty = 0; last_token = 0; return MOD;
"&"         line_empty = 0; last_token = 0; return AND;
"|"         line_empty = 0; last_token = 0; return OR;
"^"         line_empty = 0; last_token = 0; return XOR;
"<<"        line_empty = 0; last_token = 0; return LSHIFT;
">>"        line_empty = 0; last_token = 0; return RSHIFT;
"&^"        line_empty = 0; last_token = 0; return ANDXOR;
"+="        line_empty = 0; last_token = 0; return PLUSEQ;
"-="        line_empty = 0; last_token = 0; return MINUSEQ;
"*="        line_empty = 0; last_token = 0; return MULTEQ;
"/="        line_empty = 0; last_token = 0; return DIVEQ;
"%="        line_empty = 0; last_token = 0; return MODEQ;
"&="        line_empty = 0; last_token = 0; return ANDEQ;
"|="        line_empty = 0; last_token = 0; return OREQ;
"^="        line_empty = 0; last_token = 0; return XOREQ;
"<<="       line_empty = 0; last_token = 0; return LSHIFTEQ;
">>="       line_empty = 0; last_token = 0; return RSHIFTEQ;
"&^="       line_empty = 0; last_token = 0; return ANDXOREQ;
"&&"        line_empty = 0; last_token = 0; return LAND;
"||"        line_empty = 0; last_token = 0; return LOR;
"<-"        line_empty = 0; last_token = 0; return LARROW;
"->"        line_empty = 0; last_token = 0; return RARROW;
"++"        line_empty = 0; last_token = INC; return INC;
"--"        line_empty = 0; last_token = DEC; return DEC;
"=="        line_empty = 0; last_token = 0; return EQEQ;
"<"         line_empty = 0; last_token = 0; return LE;
">"         line_empty = 0; last_token = 0; return GE;
"="         line_empty = 0; last_token = 0; return EQ;
"!"         line_empty = 0; last_token = 0; return NOT;
"!="        line_empty = 0; last_token = 0; return NOTEQ;
"<="        line_empty = 0; last_token = 0; return LEQ;
">="        line_empty = 0; last_token = 0; return GEQ;
":="        line_empty = 0; last_token = 0; return ASSIGN;
"..."       line_empty = 0; last_token = 0; return ELLIPSIS;

{OCT} {
	// match octal integer
	yylval.expression = new Integer(yytext, 8);
	line_empty = 0;
    last_token = TINTLIT;
	return TINTLIT;
}

{DEC} {
	// match decimal integer
	yylval.expression = new Integer(yytext, 10);
	line_empty = 0;
    last_token = TINTLIT;
	return TINTLIT;
}
{HEX} {
	// match hexadecimal integer
	yylval.expression = new Integer(yytext, 16);
	line_empty = 0;
    last_token = TINTLIT;
	return TINTLIT;
}

({DIGIT}+"."{DIGIT}*)|("."{DIGIT}+) {
	yylval.expression = new Real(yytext);
	line_empty = 0;
    last_token = TFLOATLIT;
	return TFLOATLIT;

}

\'\\[abfnrtv\'\\]\' {
	switch (yytext[2]) {
            case 'a':
                yylval.expression = new Rune('\a');
                break;
            case 'b':
                yylval.expression = new Rune('\b');
                break;
            case 'f':
                yylval.expression = new Rune('\f');
                break;
            case 'n':
                yylval.expression = new Rune('\n');
                break;
            case 'r':
                yylval.expression = new Rune('\r');
                break;
            case 't':
                yylval.expression = new Rune('\t');
                break;
            case 'v':
                yylval.expression = new Rune('\v');
                break;
            case '\\':
                yylval.expression = new Rune('\\');
                break;
            case '\'':
                yylval.expression = new Rune('\'');
                break;
            default:
            	break;
    }

    line_empty = 0;
    last_token = TRUNELIT;
	return TRUNELIT;
}

\'[\x20-\x26\x28-\x7F]\'  {
	// everything except '
	yylval.expression = new Rune(yytext[1]);
	line_empty = 0;
    last_token = TRUNELIT;
	return TRUNELIT;
}

\"({NOQUOTESLASH}|\\\"|"`"|\\{ESCAPED})*\" {
	// String literals

	// remove quotations
	yytext[yyleng-1] = '\0';
	yylval.expression = new String(yytext+1);
	line_empty = 0;
    last_token = TSTRINGLIT;
	return TSTRINGLIT;
}

"`"({NOQUOTE}|\\\")*"`" {
	// remove back quotes
	yytext[yyleng-1] = '\0';
	std::string rstring;
	for (char* pos = yytext+1; *pos != '\0'; pos++) {
		if (*pos == '\\') rstring += '\\';
		rstring += *pos;
	}
	yylval.expression = new String(rstring.c_str());
	line_empty = 0;
    last_token = TSTRINGLIT;
	return TSTRINGLIT;
}

{IDENT} {
	yylval.identifier = new Identifier(yytext);
	line_empty = 0;
    last_token = TIDENTIFIER;
	return TIDENTIFIER;
}

[ \t]+  /* eat up whitespace */

\n {
  // eat up new line an increment lineno

  if (needs_semi_colon()) {
  	line_empty = 1;
  	unput('\n');
  	return ';';
  }
  yylineno++;
  line_empty = 1;
}

.        {

	line_empty = 0;
	last_token = yytext[0];
	return yytext[0];
}

%%


int needs_semi_colon() {

	if (line_empty)
		return 0;

	switch (last_token){

		// identifiers and literals
		case TIDENTIFIER:
			return 1;
		case TINTLIT:
			return 1;
		case TFLOATLIT:
			return 1;
		case TRUNELIT:
			return 1;
		case TSTRINGLIT:
			return 1;

		// keywords
		case TBREAK:
			return 1;
		case TCONTINUE:
			return 1;
		case TFALLTHROUGH:
			return 1;
		case TRETURN:
			return 1;
		case TSTRING:
			return 1;
		case TINT:
			return 1;
		case TFLOAT:
			return 1;
		case TBOOL:
			return 1;
		case TRUNE:
			return 1;

		// operators and delimiters
		case INC:
			return 1;
		case DEC:
			return 1;
		case ')':
			return 1;
		case ']':
			return 1;
		case '}':
			return 1;
	}

	return 0;

}
