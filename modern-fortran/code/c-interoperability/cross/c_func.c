#include <math.h>
#include <string.h>
#include <stdio.h>

float circle(float x) {return 4.0 - x * x;}
float one(float x) {return 1.0;}

typedef float (*float_func)(float);

float_func choose_func(const char *name)
{
    if(strcmp(name, "sin") == 0)
        return sinf;
    if(strcmp(name, "cos") == 0)
        return cosf;
    if(strcmp(name, "circle") == 0)
        return circle;
    return one;
}