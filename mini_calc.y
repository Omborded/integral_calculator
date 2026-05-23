%code requires {
    #include "calc3.h"
}

%{
    #include <stdio.h>
    #include <stdlib.h>
    #include <stdarg.h>
    #include <math.h>
    #include "calc3.h"

    void yyerror(const char *s);

    nodeType *opr(int oper, int nops, ...);
    nodeType *id(int i);
    nodeType *con(double value);
    void freeNode(nodeType *p);
    double ex(nodeType *p, double x);
    int yydebug = 1;
    double Simpson(nodeType *expr, double lower_val,double upper_val, int n);
    nodeType *global_expr = NULL;
%}
%union {
    double dval;
    nodeType *nPtr;
    FuncType func;
    int index;
};

%token <dval> INTEGER
%token <func> FUNCTION
%token <index> VARIABLE

%left '+' '-'
%left '*' '/'
%right UMINUS
%right POWER

%type <nPtr> expr line
%%

program:
         line
        ;
line:
        expr '\n' { 
            if(global_expr) freeNode(global_expr);
            global_expr = $1;
        }
        | error '\n' { 
            yyerrok; 
            printf("Syntax error\n");
        }
        ;

expr:
        INTEGER                     { $$ = con($1); }
        | VARIABLE                  { $$ = id($1); }
        | expr '+' expr             { $$ = opr('+', 2, $1, $3); }
        | expr '-' expr             { $$ = opr('-', 2, $1, $3); }
        | expr '*' expr             { $$ = opr('*', 2, $1, $3); }
        | expr '/' expr             { $$ = opr('/', 2, $1, $3); }
        | '(' expr ')'              { $$ = $2; }
        | '-' expr %prec UMINUS    { $$ = opr(UMINUS, 1, $2); }
        | expr POWER expr           { $$ = opr(POWER, 2, $1, $3);}
        | FUNCTION '(' expr ')'     { $$ = opr($1, 1, $3);}
        ;

%%

int main() {
    double a,b;
    int n;
    char line[256];
    printf("нижняя граница интеграла a = ");
    scanf("%lf", &a);
    printf("верхняя граница интеграла b = ");
    scanf("%lf", &b);
    printf("Количество шагов = ");
    scanf("%d", &n);

    printf("Введите выражение: ");
    while(getchar() != '\n');

    fgets(line, sizeof(line), stdin);
    extern void *yy_scan_string(const char *str);
    extern void yy_delete_buffer(void *buffer);

    void *buffer = yy_scan_string(line);
    yyparse();
    yy_delete_buffer(buffer);

    double result = Simpson(global_expr, a, b, n);
    printf("Результат : %lf\n", result);
    return 0;
}

nodeType *con(double value) {
    nodeType *p;
    if ((p = malloc(sizeof(nodeType))) == NULL)
        yyerror("out of memory");
    p->type = typeCon;
    p->u.value = value;

    return p;
}
nodeType *id(int i) {
    nodeType *p;
    if ((p = malloc(sizeof(nodeType))) == NULL)
        yyerror("out of memory");
    p->type = typeId;
    p->u.index = i;
    return p;
}
nodeType *opr(int oper, int nops, ...) {
    va_list ap;
    nodeType *p;
    size_t size;
    int i;
    size = sizeof(nodeType) + (nops- 1) * sizeof(nodeType*);
    if ((p = malloc(size)) == NULL)
        yyerror("out of memory");
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

double ex(nodeType *p, double x)
{
    if (!p) return 0;
    switch(p->type) {
        case typeCon:   return p->u.value;
        case typeId: return x;
        case typeOpr:   
        switch(p->u.opr.oper){
            case UMINUS:   return -ex(p->u.opr.op[0],x);
            case '+':      return ex(p->u.opr.op[0],x) + ex(p->u.opr.op[1],x);
            case '-':      return ex(p->u.opr.op[0],x) - ex(p->u.opr.op[1],x);
            case '*':      return ex(p->u.opr.op[0],x) * ex(p->u.opr.op[1],x);
            case '/':      return ex(p->u.opr.op[0],x) / ex(p->u.opr.op[1],x);
            case POWER:    return pow(ex(p->u.opr.op[0],x), ex(p->u.opr.op[1],x));
            case TOKEN_SIN: return sin(ex(p->u.opr.op[0],x));
            case TOKEN_COS: return cos(ex(p->u.opr.op[0],x));
            case TOKEN_TAN: return tan(ex(p->u.opr.op[0],x));
            case TOKEN_CTAN: return 1.0/tan(ex(p->u.opr.op[0],x));
            case TOKEN_ABS: return fabs(ex(p->u.opr.op[0],x));
            case TOKEN_LN: return log(ex(p->u.opr.op[0],x));
            case TOKEN_LOG: return log10(ex(p->u.opr.op[0],x));
            default: return 0;
        }
        default: return 0;
    }
}

void yyerror(const char *s) {
    fprintf(stdout, "%s\n", s);
}

double Simpson(nodeType *expr, double a, double b, int n)
{
    if(a >= b){
        printf("нижняя граница должна быть меньше верхней границы.\n");
        return 0;
    }
    double h = (b - a)/n;
    double result = ex(expr, a) + ex(expr, b);
    for (int i =1; i <n; i++){
        double x = a + i *h;
        double fx = ex(expr, x);
        if (i% 2 == 0){
            result += 2*fx;
        }
        else{
            result += 4*fx;
        }
    }
    result *= h/3;
    return result;
}