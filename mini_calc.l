%{
    #include "mini_calc.tab.h"
    #include <stdio.h>
    #include "calc3.h"
    #include <math.h>
    #include <string.h>
    #include <ctype.h>
    void yyerror(const char *s);
%}
%option noyywrap
%%
[0-9]+[x] {
    char *s = yytext;
    char num[12];
    int i=0;
    while (isdigit(s[i])){
        num[i] = s[i];
        i++;
    }
    num[i] = '\0';
    yylval.dval = atof(num);
    yyless(i);
    return INTEGER;
}
[0-9]+ {
    yylval.dval = atof(yytext);
    return INTEGER;
}
[0-9]*\.[0-9]+ {
    yylval.dval = atof(yytext);
    return INTEGER;
}
[-+()=*/] {
    return *yytext;
}
[x] { yylval.index = 0;
      return VARIABLE;
}
"**"|"^" {  return POWER; }

sin {
    yylval.func = TOKEN_SIN;
    return FUNCTION;
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