%code requires {
    #include "calc3.h"
}

%{
    #include <stdio.h>
    #include <stdlib.h>
    #include <stdarg.h>
    #include "calc3.h"

    void yyerror(const char *s);

    nodeType *opr(int oper, int nops, ...);
    nodeType *id(int i);
    nodeType *con(double value);
    void freeNode(nodeType *p);
    double ex(nodeType *p);
    int yydebug = 1;
%}
%union {
    double dval;
    nodeType *nPtr;
    int func;
};

%token <dval> INTEGER

%left '+' '-'
%left '*' '/'
// right "**" '^' same operand
%right UMINUS

%type <nPtr> expr line
%%

program:
        | program line
        ;
line:
        expr '\n' { 
            printf("= %g\n", ex($1)); 
            freeNode($1); 
        }
        | error '\n' { 
            yyerrok; 
            printf("Syntax error\n");
        }
        ;

expr:
        INTEGER                     { $$ = con($1); }
        | expr '+' expr             { $$ = opr('+', 2, $1, $3); }
        | expr '-' expr             { $$ = opr('-', 2, $1, $3); }
        | expr '*' expr             { $$ = opr('*', 2, $1, $3); }
        | expr '/' expr             { $$ = opr('/', 2, $1, $3); }
        | '(' expr ')'              { $$ = $2; }
        | '-' expr %prec UMINUS    { $$ = opr(UMINUS, 1, $2); }
        ;

%%

nodeType *con(double value) {
    nodeType *p;
    /* allocate node */
    if ((p = malloc(sizeof(nodeType))) == NULL)
        yyerror("out of memory");
    /* copy information */
    p->type = typeCon;
    p->u.value = value;

    return p;
}
nodeType *id(int i) {
    nodeType *p;
    /* allocate node */
    if ((p = malloc(sizeof(nodeType))) == NULL)
        yyerror("out of memory");
    /* copy information */
    p->type = typeId;
    p->u.index = i;
    return p;
}
nodeType *opr(int oper, int nops, ...) {
    va_list ap;
    nodeType *p;
    size_t size;
    int i;
    /* allocate node */
    size = sizeof(nodeType) + (nops- 1) * sizeof(nodeType*);
    if ((p = malloc(size)) == NULL)
        yyerror("out of memory");
    /* copy information */
    p->type = typeOpr;
    p->u.opr.oper = oper;
    p->u.opr.nops = nops;
    va_start(ap, nops);
    for (i = 0; i < nops; i++)
        p->u.opr.op[i] = va_arg(ap, nodeType*);
    va_end(ap);
    return p;
}

void freeNode(nodeType *p) {
    int i;
    if (!p) return;
    if (p->type == typeOpr) {
        for (i = 0; i < p->u.opr.nops; i++)
        freeNode(p->u.opr.op[i]);
    }
    free (p);
}

double ex(nodeType *p)
{
    if (!p) return 0;
    switch(p->type) {
        case typeCon:   return p->u.value;
        case typeOpr:   
        switch(p->u.opr.oper){
            case UMINUS:   return -ex(p->u.opr.op[0]);
            case '+':      return ex(p->u.opr.op[0]) + ex(p->u.opr.op[1]);
            case '-':      return ex(p->u.opr.op[0]) - ex(p->u.opr.op[1]);
            case '*':      return ex(p->u.opr.op[0]) * ex(p->u.opr.op[1]);
            case '/':      return ex(p->u.opr.op[0]) / ex(p->u.opr.op[1]);
            default: return 0;
        }
        default: return 0;
    }
}

void yyerror(const char *s) {
    fprintf(stdout, "%s\n", s);
}

int main() {
    printf("Enter expressions, Ctrl+D to exit.\n");
    yyparse();
    return 0;
}