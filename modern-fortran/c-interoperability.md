# Fortran 2003：与c语言的交互

我之前讲编译的时候，讲过利用命名粉碎原理进行c语言和Fortran的混编。不过这种方式比较复杂，且只适用于`module`之外的函数。`module`内的函数编译后的符号是包含`module`信息的，不好根据符号名来链接。

Fortran 2003标准提供了语言级别的与c语言交互的机制，使得Fortran和c语言的狡猾更加方便且健壮了。

## `ios_c_binding`

Fortran 2003引入了内置模块`ios_c_binding`，其中提供了一些c语言相关的常数和函数。

### 一些常数
让我们先看一些c语言常数
```fortran
program test
    use iso_c_binding
    implicit none
    integer(kind=c_size_t) :: n
    real(kind=c_long_double) :: x
    logical(kind=c_bool) :: b
    character(kind=c_char) :: c
    print *, huge(n)
    print *, huge(x)
    b = .true.
    print *, b
    c = c_horizontal_tab ! 等价于 c 语言 '\t'
    print '(A)', c//"Hello world!"
end program test
```
模块定义了和c语言等价的一系列基本类型常数，包括复数类型以及`c_int_fast32_t`等。这样一来，Fortran和c语言之间的数据交换更加具有鲁棒性。

> 之前利用命名粉碎技术时，我们需要既要主要Fortran的默认`integer`和`real`的长度，又要注意c语言默认的`int`长度，加上Fortran传参靠指针，一旦数据长度对不上，结果是灾难性的。有了`iso_c_binding`定义的这些常数，就不用担心这些问题了。

一个比较坑爹的问题是，Fortran中是没有无符号整数的，所以`ios_c_binding`中也没有任何`unsigned`版本的整数；并且`c_size_t`实际上也是有符号的。

除了类型常数之外，这个例子中还展示了字符常数`c_horizontal_tab`。Fortran是不支持转义字符的，这些常数在我们与c语言互相传递字符串时很有用。

更多内容请参考[Fortran Wiki](https://fortranwiki.org/fortran/show/iso_c_binding).

## `bind`关键字

在继续看`ios_c_binding`模块之前，先看看函数互相调用的基本语法。

### Fortran调用c

主程序在Fortran文件中
```fortran
program test
    use iso_c_binding, only : c_int
    implicit none
    interface
        function f_add1(x) result(ans) bind(c, name="add1")
            import :: c_int
            integer(kind=c_int), intent(in), value :: x
            integer(kind=c_int) :: ans
        end function
    end interface
    integer :: i, a
    a = 0
    do i = 1,5
        a = f_add1(a)
    end do
    print *, a
end program test
```
被调用的函数在c文件
```c
#include <stdio.h>

int add1(int x)
{
    printf("called add1\n");
    return x + 1;
}
```
先看c文件，定义了一个函数`add1`，函数类型是`int(int)`。再看Fortran文件，我们需要写一个`interface`来声明这个函数存在。然后，使用`bind`关键字来指定它的链接属性。`name = "add1"`是指定它在c语言中的名字，是可以省略的。省略那么就假定c语言中的名字就是函数名，即也可以这样写
```fortran
function add1(x) result(ans) bind(c)
```
这解决了符号的命名粉碎问题。

除此之外还需要注意另外一个重要的关键字`value`。我们指定了`x`参数的属性为`value`，意思是按照值传递参数。因为Fortran默认的传参方式是引用，在于c语言交互是就表现为传指针。如果我们不加`value`属性，那么c语言的函数必须这样写
```c
int add1(int *x) {return *x + 1;}
```
显然，除非有必要用指针，否则按照值传递总是更清爽的。

> 目前仅支持`bind(c)`即c语言。也就是说理论上以后有可能会有`bind(cpp), bind(rust)`。哦天哪，我在做什么白日梦。

### c语言调用Fortran

主程序为c语言
```c
#include <stdio.h>

extern int add(int, int);

int main(int argc, char const *argv[])
{
    printf("%d\n", add(1,2));
    return 0;
}
```
被调用的函数由Fortran提供
```fortran
module what_ever_module
    use iso_c_binding
    implicit none
contains
    integer(c_int) function add(x, y) result(ans) bind(c)
        integer(c_int), intent(in), value :: x, y
        ans = x + y
    end function
end module what_ever_module
```
理解了前一个例子，这个例子就非常简单的。需要注意的是，任何模块中的函数，`bind(c)`之后，编译符号就不在含有模块的信息了，所以`add`函数你写在任何模块都是一样的。

> 毕竟是`bind(c)`，c语言是没有函数重载的语言，没有命名粉碎。

## `ios_c_binding`的几个函数

`ios_c_binding`中除了常数之外，还定义了几个函数，以及c语言指针类型`type(c_ptr)`，函数指针类型`type(c_funptr)`。

### 激情互调

在`bind(c)`解决了命名粉碎问题，`value`解决了值传递问题之后，c和Fortran之间的相互调用已经不存在任何障碍了。我们再看一个比较复杂的例子。