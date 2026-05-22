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
        TOKEN_LOG,
        TOKEN_LN,
        TOKEN_ABS,
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