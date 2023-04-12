#include <stdio.h>

extern int inc();
extern int global_count;

int main(){
    global_count = 10;
    for(int i = 0; i < 5; ++i)
    {
        printf("inc() = %d, ", inc()); // 在 Fortran 中改变
        printf("global_count = %d\n", global_count);
        global_count += i; // 在 c 中改变
    }
    return 0;
}