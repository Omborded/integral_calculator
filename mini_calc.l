%{
    #include "mini_calc.tab.h"
    #include <stdio.h>
    #include "calc3.h"
    #include <math.h>
    #include <string.h>
    void yyerror(const char *s);
    typedef enum{
        TOKEN_COS,
        TOKEN_SIN,
        TOKEN_TAN,
        TOKEN_CTAN,
        TOKEN_EXP,
        TOKEN_LOG,
        TOKEN_LN,
        TOKEN_ABS,
        TOKEN_PI,
        TOKEN_EOF
    } FUNCTION;
%}
%option noyywrap
%%
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
"**"|"^" {  return POWER; }

sin {
    return yylval.func = TOKEN_SIN;
    return FUNCTION;
}
cos {
    return yylval.func = TOKEN_COS;
    return FUNCTION;
}
tan {
    return yylval.func = TOKEN_TAN;
    return FUNCTION;
}
ctan {
    return yylval.func = TOKEN_CTAN;
    return FUNCTION;
}
exp {
    return yylval.func = TOKEN_EXP;
    return FUNCTION;
}
abs {
    return yylval.func = TOKEN_ABS;
    return FUNCTION;
}
log {
    return yylval.func = TOKEN_LOG;
    return FUNCTION;
}
ln {
    return yylval.func = TOKEN_LN;
    return FUNCTION;
}
[ \t] { /* ignore whitespace */ }

\n { return '\n'; }

. { yyerror("invalid character"); }

%%