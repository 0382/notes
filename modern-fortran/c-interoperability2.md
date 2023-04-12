# Fortran 2003：与c语言的交互的其他一些话题

前面一篇文章写了Fortran 2003标准引入的与c语言交互的语法和内置模块，只是讲了最基本的函数之间的交互。实际上还有很多东西是可以交互的。

## 全局变量

`bind(c)`不仅可以用于函数，也可以用于变量，对应于c语言中的全局变量。一个简单的例子如下

Fortran部分
```fortran
module global_mod
    use iso_c_binding
    implicit none
    private
    
    integer(c_int), bind(c) :: global_count

contains
    integer(c_int) function inc() bind(c)
        global_count = global_count + 1
        inc = global_count
    end function inc
end module global_mod
```
C语言部分
```c
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
```
它们分别对全局变量进行了操作，可以看到确实在操作同一个变量。


## 枚举类型

Fortran 2003引入了枚举语句。它和c语言有什么关系？例子如下
```fortran
module test_enum
    implicit none
    
    enum, bind(c)
        enumerator :: RED
        enumerator :: GREEN = 100
        enumerator :: YELLOW
    end enum

contains
    
end module test_enum

program test
    use test_enum
    implicit none
    integer :: color
    color = RED
    print *, color
    print *, YELLOW
end program test
```
是的，Fortran枚举语句必须是`bind(c)`的，而且不存在新的类型，你只能用整数类型来访问它。除了它的用法看起来和c语言差不多之外，我不知道为什么必须要使用`bind(c)`。

像c++那样给枚举变量一个新的类型现在还只是一个提案：[Typed enumerators](https://fortranwiki.org/fortran/show/Typed+enumerators)。

## 结构体的交互

除了内置类型可以交互，结构体当然也是可以交互的。比如c语言标准库的时间结构体
```fortran
type, public, bind(c) :: tm
    integer(c_int) :: tm_sec
    integer(c_int) :: tm_min
    integer(c_int) :: tm_hour
    integer(c_int) :: tm_mday
    integer(c_int) :: tm_mon
    integer(c_int) :: tm_year
    integer(c_int) :: tm_wday
    integer(c_int) :: tm_yday
    integer(c_int) :: tm_isdst
end type
```
`bind(c)`的结构体，其内部必须是**可与C语言交互**的，即必须使用`ios_c_binding`定义的那些类型。比如这里必须是`integer(c_int)`，而不能是默认的`integer`，尽管它们可能实际上是一个东西。

完整的代码请看我包装的C语言时间库的代码：[time-f](https://github.com/0382/time-f)，虽然可能没啥用，但是可以作为一个比较好的使用2003标准进行Fortran与C语言混编的例子。
