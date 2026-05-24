#ifndef CALC3_H
#define CALC3_H

#include <stdio.h>
#include <stdlib.h>

typedef enum { typeCon, typeId, typeOpr, typeInt } nodeEnum;

typedef enum{
        TOKEN_COS = 300,
        TOKEN_SIN = 301,
        TOKEN_TAN = 302,
        TOKEN_CTAN = 303,
        TOKEN_LOG = 304,
        TOKEN_LN = 305,
        TOKEN_ABS = 306,
        TOKEN_SQRT = 307
} FuncType;

typedef struct nodeTypeTag {
    nodeEnum type;
    union {
        double value;
        int index;
        struct {
            int oper;
            int nops;
            struct nodeTypeTag *op[1];
        } opr;
    } u;
    struct{
        struct nodeTypeTag *lower_val;
        struct nodeTypeTag *upper_val;
        char var;
        struct nodeTypeTag *expr;
    } integral;
} nodeType;

#endif