#include <stdio.h>

extern int add(int, int);

int main(int argc, char const *argv[])
{
    printf("%d\n", add(1,2));
    return 0;
}
