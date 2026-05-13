#ifndef CALC3_H
#define CALC3_H

#include <stdio.h>
#include <stdlib.h>

typedef enum { typeCon, typeId, typeOpr, typeInt } nodeEnum;

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