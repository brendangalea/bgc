%{

#include <string>
#include <golite/source_file.hpp>

extern int yylineno;
extern char* yytext;

int yylex();

void yyerror(...) {
    std::cerr << "error: " << yytext << " on line " << yylineno << std::endl;
    return;
}

SourceFile sf;

%}

%union {
    int token;
    int op;
    const char* str;
    Identifier* identifier;
    Expression* expression;
    Statement* stmt;
    SimpleStatement* simple;
    Decl* decl;
    Type* tp;
    TypeDecl* tdecl;
    IdentifierList* ids;
    ExpressionList* exprs;
    StatementList* stmts;
    CaseList* cases;
    std::vector<std::unique_ptr<Decl>>* decls;
    Parameters* params;
    Block* block;
}

%token <token> TBREAK TCASE TCHAN TCONST TCONTINUE TDEFAULT TDEFER TELSE TFALLTHROUGH TFOR TFUNC TGO TGOTO TIF TIMPORT TINTERFACE TMAP TPACKAGE TRANGE TRETURN TSELECT TSTRUCT TSWITCH TTYPE TVAR TINVALID

%token <op> PLUS MINUS MULT DIV MOD AND OR XOR LSHIFT RSHIFT ANDXOR PLUSEQ MINUSEQ MULTEQ DIVEQ MODEQ ANDEQ OREQ XOREQ LSHIFTEQ RSHIFTEQ ANDXOREQ LAND LOR LARROW RARROW INC DEC EQEQ LE GE EQ NOT NOTEQ LEQ GEQ ASSIGN ELLIPSIS

%token TIDENTIFIER

%token TINT TFLOAT TBOOL TRUNE TSTRING TRSTRING TPRINT TPRINTLN TAPPEND

%left LOR
%left LAND
%left EQEQ  NOTEQ LE LEQ GE GEQ
%left PLUS MINUS OR XOR
%left MULT DIV MOD LSHIFT RSHIFT AND ANDXOR


%token TINTLIT TFLOATLIT TRUNELIT TSTRINGLIT

%start SourceFile

%type <identifier> TIDENTIFIER
%type <expression> TINTLIT TRUNELIT TFLOATLIT TSTRINGLIT Expression Operand PrimaryExpr UnaryExpr OptionalExpression
%type <stmt> ForStmt Statement SwitchStmt IfStmt ElseStmt
%type <simple> SimpleStmt
%type <decl> FuncDecl TypeSpec VarSpec Declaration TypeDecl VarDecl
%type <decls> TypeSpecList VarSpecList
%type <ids> IdentifierList
%type <exprs> ExpressionList OptionalExpressionList Arguments ExprCase
%type <stmts> StatementList
%type <cases> ExprCaseList
%type <block> Block
%type <tp> OptionalType Type ScalarType
%type <params> ParameterList ParameterPack FieldList
%type <str> AssignOP UnaryOP

%%

SourceFile : Package TopLevelDecls

Package : TPACKAGE TIDENTIFIER ';' { sf._package_name = $2; }

TopLevelDecls : /*empty*/ | TopLevelDecls TopLevelDecl ';';

TopLevelDecl : FuncDecl
             | Declaration { sf.add_decl($1); }
;

FuncDecl : TFUNC TIDENTIFIER '(' ParameterList ')' OptionalType Block {
    sf.add_decl(new FuncDecl($2, std::move(*$4), std::move(*$7), $6)); delete $4; delete $7;
};

ParameterList : /*empty*/ { $$ = new Parameters(); }
              | ParameterPack { $$ = $1; }
;

ParameterPack : IdentifierList Type {
                $$ = new Parameters();
                std::shared_ptr<Type> distributed($2);
                for(std::unique_ptr<Identifier>& i : *$1 ){
                    $$->emplace_back(std::unique_ptr<Identifier>(i.release()), distributed); // change owenership
                }
                delete $1;
              }
              | IdentifierList Type ',' ParameterPack {
                $$ = new Parameters();
                std::shared_ptr<Type> distributed($2);
                for(std::unique_ptr<Identifier>& i : *$1 ){
                    $$->emplace_back(std::unique_ptr<Identifier>(i.release()), distributed); // change ownership
                }
                std::move($4->begin(), $4->end(), std::back_inserter(*$$));
                delete $1;
                delete $4;
            }
;

Declaration : VarDecl { $$ = $1; }
            | TypeDecl { $$ = $1; }
;

VarSpec : IdentifierList OptionalType { $$ = new VarDecl(std::move(*$1), $2); delete $1;}
        | IdentifierList OptionalType EQ ExpressionList { $$ = new VarDecl(std::move(*$1), $2, std::move(*$4)); delete $1; delete $4; }
        ;

VarSpecList : /*empty*/ { $$ = new std::vector<std::unique_ptr<Decl>>(); }
            | VarSpecList VarSpec ';' { $$ = $1; $$->emplace_back($2); }
;

VarDecl : TVAR VarSpec { $$ = $2; }
        | TVAR '(' VarSpecList ')' { $$ = new VarDeclBlock(std::move(*$3)); delete $3; }
;


TypeSpec : TIDENTIFIER Type { $$ = new TypeDecl($1,$2); }
TypeSpecList : /*empty*/  { $$ = new std::vector<std::unique_ptr<Decl>>(); }
             | TypeSpecList TypeSpec ';' { $$ = $1; $$->emplace_back($2); }
;
TypeDecl : TTYPE TypeSpec { $$ = ($2); }
         | TTYPE '(' TypeSpecList ')' { $$ = new TypeDeclBlock(std::move(*$3)); delete $3; }
;

OptionalType : { $$ = new VoidType(); }
             | Type { $$ = $1; }
;

ScalarType : TINT { $$ = new TypeName("int"); }
           | TFLOAT { $$ = new TypeName("float64"); }
           | TRUNE { $$ = new TypeName("rune"); }
           | TBOOL { $$ = new TypeName("bool"); }
;

Type : ScalarType { $$ = $1; }
     | TSTRING { $$ = new TypeName("string"); }
     | TIDENTIFIER { $$ = new TypeName($1); }
     | '[' ']' Type { $$ = new SliceType($3); }
     | '[' TINTLIT ']' Type { $$ = new ArrayType($2, $4); }
     | TSTRUCT '{' FieldList '}' { $$ = new StructType(std::move(*$3)); delete $3; }
;


FieldList : /*empty*/ { $$ = new Parameters(); }
          | FieldList IdentifierList Type ';' {
                std::shared_ptr<Type> distributed($3);
                for(std::unique_ptr<Identifier>& id : *$2) {
                    $1->emplace_back(std::unique_ptr<Identifier>(id.release()), distributed); // change ownership
                }
                delete $2;
                $$ = $1;
            };

IdentifierList : TIDENTIFIER { $$ = new IdentifierList(); $$->emplace_back($1); }
               | IdentifierList ',' TIDENTIFIER { $$ = $1; $$->emplace_back($3); }
;

OptionalExpression : /*empty*/ { $$ = new EmptyExpression(); }
                   | Expression { $$ = $1; }
;

Expression : UnaryExpr { $$ = $1; }
           | Expression AND Expression { $$ = new BinaryExpr($1, "&", $3); }
           | Expression ANDXOR Expression { $$ = new BinaryExpr($1, "&^", $3); }
           | Expression DIV Expression { $$ = new BinaryExpr($1, "/", $3); }
           | Expression EQEQ Expression { $$ = new BinaryExpr($1, "==", $3); }
           | Expression GE Expression { $$ = new BinaryExpr($1, ">", $3); }
           | Expression GEQ Expression { $$ = new BinaryExpr($1, ">=", $3); }
           | Expression LAND Expression { $$ = new BinaryExpr($1, "&&", $3); }
           | Expression LE Expression { $$ = new BinaryExpr($1, "<", $3); }
           | Expression LEQ Expression { $$ = new BinaryExpr($1, "<=", $3); }
           | Expression LOR Expression { $$ = new BinaryExpr($1, "||", $3); }
           | Expression LSHIFT Expression { $$ = new BinaryExpr($1, "<<", $3); }
           | Expression MINUS Expression { $$ = new BinaryExpr($1, "-", $3); }
           | Expression MOD Expression { $$ = new BinaryExpr($1, "%", $3); }
           | Expression MULT Expression { $$ = new BinaryExpr($1, "*", $3); }
           | Expression NOTEQ Expression { $$ = new BinaryExpr($1, "!=", $3); }
           | Expression OR Expression { $$ = new BinaryExpr($1, "|", $3); }
           | Expression PLUS Expression { $$ = new BinaryExpr($1, "+", $3); }
           | Expression RSHIFT Expression { $$ = new BinaryExpr($1, ">>", $3); }
           | Expression XOR Expression { $$ = new BinaryExpr($1, "^", $3); }
;

UnaryExpr : PrimaryExpr { $$ = $1; }
          | TAPPEND '(' TIDENTIFIER ',' Expression ')' { $$ = new Append($3, $5); }
          | UnaryOP UnaryExpr { $$ = new UnaryExpr($1[0], $2); }
;

PrimaryExpr : Operand { $$ = $1; }
            | ScalarType '(' Expression ')' { $$ = new Conversion($1, $3); }
            | PrimaryExpr '.' TIDENTIFIER { $$ = new Selector($1, $3); }
            | PrimaryExpr '[' Expression ']' { $$ = new Index($1, $3); }
            | PrimaryExpr Arguments { $$ = new Arguments($1, std::move(*$2)); delete $2; }
;

Operand : TIDENTIFIER { $$ = $1; }
        | TINTLIT { $$ = $1; }
        | TFLOATLIT { $$ = $1; }
        | TRUNELIT { $$ = $1; }
        | TSTRINGLIT { $$ = $1; }
        | '(' Expression ')' { $$ = $2; }
;

Arguments : '(' OptionalExpressionList ')' { $$ = $2; };

OptionalExpressionList : /*empty*/ { $$ = new ExpressionList(); }
                       | ExpressionList { $$ = $1; }
;

ExpressionList : Expression { $$ = new ExpressionList(); $$->emplace_back($1); }
               | ExpressionList ',' Expression { $$ = $1; $$->emplace_back($3); }
;

AssignOP : EQ { $$ = "="; }
         | PLUSEQ { $$ = "+="; }
         | MINUSEQ { $$ = "-="; }
         | MULTEQ { $$ = "*="; }
         | DIVEQ { $$ = "/="; }
         | MODEQ { $$ = "%="; }
         | ANDEQ { $$ = "&="; }
         | OREQ { $$ = "|="; }
         | XOREQ { $$ = "^="; }
         | LSHIFTEQ { $$ = "<<="; }
         | RSHIFTEQ { $$ = ">>="; }
         | ANDXOREQ { $$ = "&^="; }
;

UnaryOP : PLUS { $$ = "+"; }
        | MINUS { $$ = "-"; }
        | NOT { $$ = "!"; }
        | XOR { $$ = "^"; }
;


Block : '{' StatementList '}'  { $$ = new Block(std::move(*$2)); delete $2; };

StatementList : /*empty*/ { $$ = new StatementList(); }
              | StatementList Statement ';' { $$ = $1; $$->emplace_back($2); }
;

Statement : Declaration { $$ = $1; }
          | SimpleStmt { $$ = $1; }
          | TBREAK { $$ = new Break(); }
          | TCONTINUE { $$ = new Continue(); }
          | Block { $$ = $1; }
          | IfStmt { $$ = $1; }
          | SwitchStmt { $$ = $1; }
          | ForStmt { $$ = $1; }
          | TRETURN OptionalExpression { $$ = new Return($2); }
          | TPRINT '(' OptionalExpressionList ')' { $$ = new Print(std::move(*$3)); delete $3; }
          | TPRINTLN '(' OptionalExpressionList ')' { $$ = new PrintLn(std::move(*$3)); delete $3; }
;

SimpleStmt : /*empty*/ { $$ = new EmptyStatement(); }
           | Expression { $$ = $1; }
           | Expression INC { $$ = new Inc($1); }
           | Expression DEC { $$ = new Dec($1); }
           | ExpressionList AssignOP ExpressionList { $$ = new Assignment(std::move(*$1), $2, std::move(*$3)); delete $1; delete $3; }
           | ExpressionList ASSIGN ExpressionList { $$ = new ShortVarDecl(std::move(*$1), std::move(*$3)); delete $1; delete $3; }
;

IfStmt : TIF Expression Block ElseStmt { $$ = new If($2, std::move(*$3), $4); delete $3; }
       | TIF SimpleStmt ';' Expression Block ElseStmt { $$ = new If($4,std::move(*$5), $6, $2); delete $5; }
       ;

ElseStmt : /*empty*/ { $$ = new EmptyStatement(); }
         | TELSE IfStmt { $$ = $2; }
         | TELSE Block { $$ = $2; }
;

SwitchStmt : TSWITCH OptionalExpression '{' ExprCaseList '}' { $$ = new Switch($2, $4); }
           | TSWITCH SimpleStmt ';' OptionalExpression '{' ExprCaseList '}' { $$ = new Switch($4, $6, $2); }
;

ExprCaseList : /*empty*/ { $$ = new CaseList(); }
             | ExprCaseList ExprCase ':' StatementList {
    $$ = $1;
    $$->emplace_back(std::move(*$2), std::move(*$4));
};

ExprCase : TCASE ExpressionList { $$ = $2; }
         | TDEFAULT { $$ = new ExpressionList(); }
;

ForStmt : TFOR Block { $$ = new For(std::move(*$2)); delete $2; }
        | TFOR Expression Block { $$ = new For(std::move(*$3), $2); delete $3; }
        | TFOR SimpleStmt ';' OptionalExpression ';' SimpleStmt Block { $$ = new For(std::move(*$7), $2, $4, $6); delete $7; }
;
