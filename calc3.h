#ifndef CALC3_H
#define CALC3_H

#include <stdio.h>
#include <stdlib.h>

// Структура для строения AST дерева. Запоминает каждую константуЮ операнд, переменную, функцию
typedef enum { typeCon, typeId, typeOpr, typeInt } nodeEnum;

// словарь функций. Каждая функция имеет свой номер чтобы избежать конфликт с назначениями кодов из ASCII (значения до 255)
// Кодировка токенов в бизоне начинается с 258
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

// объявление каждого поля структуры
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