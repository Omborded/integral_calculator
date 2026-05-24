%{
    // Блок определения
    #include "mini_calc.tab.h"
    #include <stdio.h>
    #include "calc3.h"
    #include <math.h>
    #include <string.h>
    #include <ctype.h>
    // Функция обработки синтаксических ошибок. Вызывается, когда обнаруживаются символы не из блока правил.
    // Выводит сообщение через stdout.
    void yyerror(const char *s);
%}
%option noyywrap
%%
[0-9]+[x] {
    // проверка умножения константы на переменную x (2x вместо 2*x)
    char *s = yytext;
    char num[12];
    int i=0;
    while (isdigit(s[i])){
        num[i] = s[i];
        i++;
    }
    num[i] = '\0';
    yylval.dval = atof(num);
    // yyless
    yyless(i);
    return INTEGER;
    // Так как в этой программе учитывается умножение чисел на некоторую константу, вызвать return что для константы и
    // переменной невозможно. Используется специальная функция yyless
}

[0-9]+ {
    yylval.dval = atof(yytext);
    return INTEGER;
    // Выражение означает, что встречается от 1 раза минимум. Передаётся токен числа в парсер.
    // yylval - глобальная переменная для передачи значения токена из лексера в парсер.
    // Также возвращает в yylval конкретное число. Нужно это для формирования AST дерева. 
    // Это и касается математических констант.
    // КАЖДОЕ число или функция формирует узлы в AST дереве.
}
[0-9]*\.[0-9]+ {
    yylval.dval = atof(yytext);
    return INTEGER;
    // то же самое, только для дробного числа
}
[-+()=*/] {
    return *yytext;
}
[x] { yylval.index = 0;
      return VARIABLE;
}

"**"|"^" {  // возведение в степень обрабатывается как ** или ^
    return POWER; }

sin {
    yylval.func = TOKEN_SIN;
    return FUNCTION;
    // передает FUNCTION, где в парсере будут проверятся какая матфункция используется
    // то же самое происходит и для всех остальных функций
}
cos {
     yylval.func = TOKEN_COS;
    return FUNCTION;
}
tan {
     yylval.func = TOKEN_TAN;
    return FUNCTION;
}
ctan {
     yylval.func = TOKEN_CTAN;
    return FUNCTION;
}
abs {
     yylval.func = TOKEN_ABS;
    return FUNCTION;
}
log {
     yylval.func = TOKEN_LOG;
    return FUNCTION;
}
ln {
     yylval.func = TOKEN_LN;
    return FUNCTION;
}
sqrt {
    yylval.func = TOKEN_SQRT;
    return FUNCTION;
}
e {
    yylval.dval = 2.718281828;
    return INTEGER;
}
pi {
    yylval.dval = 3.141592653;
    return INTEGER;
}
[ \t] { /* ignore whitespace */ }

\n { return '\n'; }

. { yyerror("invalid character"); }

%%