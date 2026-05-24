%code requires {
    #include "calc3.h"
}

%{
    #include <stdio.h>
    #include <stdlib.h>
    #include <stdarg.h>
    #include <string.h>
    #include <math.h>
    #include "calc3.h"
    #define PI 3.141592653

    void yyerror(const char *s);

    nodeType *opr(int oper, int nops, ...);
    nodeType *id(int i);
    nodeType *con(double value);
    void freeNode(nodeType *p);
    double ex(nodeType *p, double x);
    // Функция отладки. Выводит сообщение через stdin.
    int yydebug = 1;
    // Численный метод вычисления определенного интеграла
    double Simpson(nodeType *expr, nodeType* global_lower,nodeType* global_upper, int n);
    // Поле структуры хранит полное выражение
    nodeType *global_expr = NULL;
    // Поле структуры хранит что число, что математическую константу
    nodeType *global_upper = NULL;
    nodeType *global_lower = NULL;
    // функция проверки на слишком длинные числа
    int sizeCheck(double x);
    // Флаг на обработку одного из полей структуры, что описано выше.
    int parse_mode = 0;
%}
// Структура данных хранит что константы, выражения, узлы
%union {
    double dval;
    nodeType *nPtr;
    FuncType func;
    int index;
};

// Данная функции берут из лексера определенный тип данных. Используются для дальнейших вычислений дальше
%token <dval> INTEGER
%token <func> FUNCTION
%token <index> VARIABLE

// Передача ассоциативности операндам. Важное замечание: в Bison каждая ассоциативность прописанная позже остальных имеют больший приоритет.
%left '+' '-'
%left '*' '/'
%right UMINUS
%right POWER

// Функция определения типов значений для нетерминалов.
// Нетерминалы - строка, содержащая все терминалы
// Терминалы - строки, не имеющие смысла без объединения. Пример - '+', '5.0', sin(x) и т.д.
%type <nPtr> expr line
%%
//Блок правил.
// Правило программы: Программа состоит из одной строки (line) и завершается. Позваоляет сразу после ввода выражения сразу вычисляется.
program:
         line
        ;
// Правило строки: состоит либо из выражения, либо из ошибки.
// В 1 случае передается выражение и перенос строки. Выполняются семантические действия: освобождение памяти старого выражения и
// сохранение нового выражения в глобальную переменную
line:
        expr '\n' { 
            if(parse_mode == 0){
                if (global_expr) freeNode(global_expr);
            global_expr = $1;
            } 
            else if(parse_mode == 1){
                if (global_lower) freeNode(global_lower);
                global_lower = $1;
            }
            else if (parse_mode == 2){
                if (global_upper) freeNode(global_upper);
                global_upper = $1;
            }
        }
        // yyerrok - функция сбрасывания режима ошибки
        | error '\n' { 
            yyerrok; 
            printf("Syntax error\n");
        }
        ;

// блок правил выражения. В каждом определении взовращается узел дерева
expr:
        // при встрече с числом возвращается тип double
        INTEGER                     { $$ = con($1); }
        // при встрече с переменной возвращается char
        | VARIABLE                  { $$ = id($1); }
        // при встрече с умножением (2x) возвращается умножение переменной на число
        | INTEGER VARIABLE          { $$ = opr('*', 2, con($1), id($2));}
        // возвращает отдельные терминалы
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
    // специальные буфферы ввода и удаления ввода. Так как yyparse ожидает \n, то он никогда на закроется.
    extern void *yy_scan_string(const char *str);
    extern void yy_delete_buffer(void *buffer);

    int n;
    char line[256];
    void *buffer;

    printf("нижняя граница интеграла a = ");
    fgets(line, sizeof(line), stdin);
    parse_mode = 1;
    buffer = yy_scan_string(line);
    yyparse();
    yy_delete_buffer(buffer);

    printf("верхняя граница интеграла b = ");
    fgets(line, sizeof(line), stdin);
    parse_mode = 2;
    buffer = yy_scan_string(line);
    yyparse();
    yy_delete_buffer(buffer);

    printf("Количество шагов = ");
    scanf("%d", &n);

    printf("Введите выражение: ");
    while(getchar() != '\n');
    parse_mode = 0;
    fgets(line, sizeof(line), stdin);
    
    buffer = yy_scan_string(line);
    yyparse();
    yy_delete_buffer(buffer);

    double result = Simpson(global_expr, global_lower, global_upper, n);
    printf("Результат : %lf\n", result);
    return 0;
}

// Функция выделения памяти под тип данных double из nodeType (в данном случае обрабатываются числовые константы)
nodeType *con(double value) {
    nodeType *p;
    if ((p = malloc(sizeof(nodeType))) == NULL)
        yyerror("out of memory");
    p->type = typeCon;
    p->u.value = value;

    return p;
}

// Функция выделения памяти под тип данных char из nodeType (обрабатывается переменная x из каждой функции)
nodeType *id(int i) {
    nodeType *p;
    if ((p = malloc(sizeof(nodeType))) == NULL)
        yyerror("out of memory");
    p->type = typeId;
    p->u.index = i;
    return p;
}

// Функция выделения памяти под операнды и матфункции. Обрабатывается каждый нетерминал (токен)
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

// Функция освобождения узла из дерева
void freeNode(nodeType *p) {
    int i;
    if (!p) return;
    if (p->type == typeOpr) {
        for (i = 0; i < p->u.opr.nops; i++)
        freeNode(p->u.opr.op[i]);
    }
    free (p);
}

// Функция обработки одного из полей структуры.
// При определении одного из полей возвращаются значения из nodeType в double, char
// Вдобавок проверки на бесконечные числаЮ деления на 0, невозможные значения
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
            case '/':      double divisor = ex(p->u.opr.op[1],x);
                         if (divisor == 0.0){
                divisor = 1e-12;
            }
                return ex(p->u.opr.op[0],x) / divisor;
            case POWER:    return pow(ex(p->u.opr.op[0],x), ex(p->u.opr.op[1],x));
            case TOKEN_SIN: return sin(ex(p->u.opr.op[0],x));
            case TOKEN_COS: return cos(ex(p->u.opr.op[0],x));
            case TOKEN_TAN: if (ex(p->u.opr.op[0],x) == PI/2){
                printf("Деление на 0.\n");
                return 0;
            }
                    return tan(ex(p->u.opr.op[0],x));
            case TOKEN_CTAN: if(tan(ex(p->u.opr.op[0],x)) == PI || tan(ex(p->u.opr.op[0],x)) == 0){
                printf("Деление не 0.\n");
                return 0;
            }
                    return 1.0/tan(ex(p->u.opr.op[0],x));
            case TOKEN_ABS: return fabs(ex(p->u.opr.op[0],x));
            case TOKEN_LN: if (ex(p->u.opr.op[0], x) <= 0){
                printf("Ошибка: у логарифма не может быть 0 или отрицательным в аргументе.\n");
                return 0;
            }
                return log(ex(p->u.opr.op[0],x));
            case TOKEN_LOG: if(ex(p->u.opr.op[0], x) == 0){
                printf("Ошибка: у логарифма не может быть 0 или отрицательым в аргументе.\n");
                return 0;
            }
                return log10(ex(p->u.opr.op[0],x));
            case TOKEN_SQRT: if (ex(p->u.opr.op[0],x) < 0){
                printf("Комплексные числа не поддерживаются в данной версии.\n");
                return 0;
            }
                            return sqrt(ex(p->u.opr.op[0],x));
            default: return 0;
        }
        default: return 0;
    }
}

void yyerror(const char *s) {
    fprintf(stdout, "%s\n", s);
}

double Simpson(nodeType *expr, nodeType *global_lower, nodeType *global_upper, int n)
{
    double a = ex(global_lower, 0);
    double b = ex(global_upper, 0);
    if(a >= b){
        printf("нижняя граница должна быть меньше верхней границы.\n");
        return 0;
    }
    if (n%2 == 1){
        printf("Количество шагов должно быть чётным.\n");
        return 0;
    }
    if (sizeCheck(a) == 0){
        printf("Размер нижней границы слишком большая.\n");
        return 0;
    }
    if (sizeCheck(b) == 0){
        printf("Размер верхней границы слишком большая,\n");
        return 0;
    }
    if (n < 2 || n > 10000000){
        printf("Длина шага слишком большая/маленькая.\n");
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

int sizeCheck(double x){
    char num[30];
    sprintf(num, "%lf", x);
    if (strlen(num) >= 10){
        return 0;
    }
    return 1;
}