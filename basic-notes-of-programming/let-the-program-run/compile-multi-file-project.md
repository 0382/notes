# 【程序的运行（三）】编译多文件项目

本文讲一讲c/c++/fortran的多文件编译以及其中用到的工具。

## 多文件项目

将代码都写在一个文件内，不利于阅读，也不利于组织程序，并且每次做一个小改动，都要重新编译整个文件，浪费时间。

c/c++/fortran都支持将代码写在多个文件中，可以对文件分别编译，然后再链接到一起。下面举个简单的例子，在某文件夹下新建如下三个文件

```c
// hello.h
#ifndef HELLO_H
#define HELLO_H

#include <stdio.h>

extern void greet(const char *name);

#endif // HELLO_H
```

```c
// hello.c
#include "hello.h"

void greet(const char *name)
{
    printf("Hello, %s!\n", name);
}
```

```c
// main.c
#include "hello.h"

int main(){
    greet("Alice");
}
```

首先我们在`hello.h`文件中声明了`greet`函数，但是并没有实现它。我们在`hello.c`文件中实现`greet`函数，在`main.c`函数中使用了该函数。怎么编译这个项目呢？依次使用如下三个命令
```bash
gcc -c hello.c -o hello.o
gcc -c main.c -o main.o
gcc main.o hello.o -o main.exe
```

然后就可以运行程序`main.exe`了。这三行命令中，前两行分别对`hello.c`和`main.c`文件做了预处理，编译，汇编步骤，但是没有做链接步骤（简单起见，我们将前三个步骤统称为编译，于是我们称称这个过程为**只进行编译，而不链接**）。最后一行，将`mian.o, hello.o`文件进行链接，最终得到可执行程序`main.exe`。

我们不可避免要用到很多开源的项目，它们项目大多具有非常多的文件，但编译的过程基本上和前面的过程是一致的。

将项目分成多个文件，首先可以方便组织文件结构。比如将实现同一个功能的代码放在一个文件内，不同功能的代码放在不同的文件内。并且，如果修改其中一个文件，只需要重新编译这一个文件，最后再重新链接就好了，可以减少编译时间。

### Makefile

如果一个项目有很多的文件，每个文件都要一个一个输入命令编译太麻烦了。GNU make软件提供了一个自动化做这些事情的工具。

首先我们需要在刚才的文件夹下新建一个名字为`Makefile`（注意大小写）的文件，写入如下内容
```makefile
main.exe : main.o hello.o
        gcc main.o hello.o -o main.exe

main.o : main.c hello.h
        gcc -c main.c -o main.o

hello.o: hello.c hello.h
        gcc -c hello.c -o hello.o
```

然后输入命令

```bash
make
```

就会自动完成上述编译工作。以后你修改文件的内容，只需要再用`make`命令就可以自动编译了。而且make软件可以自动检测文件修改时间，对于上次编译后没有修改的文件不再进行编译，从而减少编译的消耗。

关于如何写`Makefile`，可以看看[这个教程](https://seisman.github.io/how-to-write-makefile/)。

> Windows下，如果使用[MinGW-w64](http://mingw-w64.org/doku.php/download/mingw-builds)，会一起安装上`mingw32-make.exe`这个软件，其实就是GNU make在windows下的移植。你可以用`mingw32-make`命令代替`make`命令，或者你去安装目录把那个文件改成`make.exe`也可以。

### CMake

写`Makefile`文件依然是很麻烦的事情，更现代的构建工具能够帮助自动化生成`Makefile`文件，[cmake](https://cmake.org/)是比较受欢迎的一种自动构建工具。想学习的可以看看[这个github项目](https://github.com/ttroy50/cmake-examples)。其他的自动构建工具比如[autoconf](https://www.gnu.org/software/autoconf/autoconf.html)，[xmake](https://xmake.io/)，感兴趣的可以自己了解。

## 多语言混编

链接技术给多语言混编提供了可能。我们前面提到了，编译过程中，会将高级语言编译成汇编语言。对于同一个系列的编译器，是能够将不同的编程语言编译到同一种汇编语言的，他们底层是没有什么区别的，因而也是可以链接到一起的。对于GNU编译器系列组件`gcc/g++/gfortran`，对应的三种语言c/c++/fortran的混编非常容易。

先看一个c/fortran混编的简单例子。

```fortran
// hello.f90
function add(a, b)
    implicit none
    real(kind=8), intent(in) :: a, b
    real(kind=8) :: add
    add = a + b
end function add
```

```c
// main.c
#include <stdio.h>

extern double add_(double *a, double *b);

int main(){
    double a = 100, b = 3.14;
    printf("%f", add_(&a, &b));
}
```

以及编译过程
```bash
gfortran -c hello.f90 -o hello.o
gcc -c main.c -o main.o
gcc main.o hello.o -o main.exe
```

编译运行，可以看到c语言程序成功的调用了fortran写的函数。

上面的混编，仔细看会发现有两个问题，其一是为什么c语言中实际上调用的函数是`add_`函数，而不是fortran中写好的`add`函数，其二是c语言中参数为什么变成了指针。

#### 命名粉碎(name mangling)

命名粉碎可以解释第一问题。c/c++/fortran语言编译成的字节码，其中还含有函数名的信息，这称为符号(symbol)，可以用`nm xxx.o`或`nm xxx.exe`看文件中的符号。这些符号，和你在代码中实际写的函数名是有一定关系的。c语言是完全没有命名粉碎的语言，即你写的是什么名字，在字节码中对应的符号就是什么。这是c语言不能进行函数重载的原因，因为如果允许函数重载，就会产生符号冲突。

c++允许函数重载，其实是通过命名粉碎实现的。即符号和代码中原来的函数名不一样，符号中还包括了函数的参数类型，命名空间等信息，从而保证重载的函数在二进制中的符号不会冲突。

fortran的命名粉碎是不得已而为之。fortran是不区分大小写的语言，那么`add`函数和`aDd`函数在代码里面是一个东西，写到机器码中符号需要保证统一，那就必然要有命名粉碎。对于gfortran编译器和intel的ifort编译器，都采取统一小写的约定。此外，为了和c语言有区别，还在最后加一个下划线。所以在fortran中，不管你写`add, AdD, aDd`还是`Add`，编译到二进制中统统都变成了`add_`。

随着fortran90中`module`语法的引入，`module`实际上也提供了命名空间类似的东西，于是在`module`中命名的变量命名粉碎后是带有`module`名信息的，具体规则比较复杂就不赘述了。

因此在上面的例子中，`hello.f90`的`add`函数在命名粉碎之后，在机器码中的符号是`add_`，而c语言没有命名粉碎，只能使用`add_`来调用该函数。

c/fortran的符号命名约定都比较简单，但是c++为了重载，命名粉碎规则非常复杂，感兴趣可以用`nm xxx.exe`命令看一看。c/fortran要调用c++的函数，一般来说要在c++文件中采用下面的方式
```c++
extern "C" {
    // 这里声明的函数不会被命名粉碎
}
// 外面写一般的c++代码
```

#### fortran的参数传递

另外一个问题，为什么c语言调用`add_`函数时，参数变成了指针。实际上，fortran的变量在参数传递时就相当于c语言的指针。fortran没有值类型和引用类型的概念，传入函数体内的变量都可以修改（除非用`intent(in)`约束），就是因为fortran的参数传递实际上传入的是变量的地址。

fortran不支持隐式类型转换，一个接受`real(kind=8)`的函数，如果传入`real(kind=4)`的变量会产生非常严重的错误，也是由参数传指针造成的。这种转换在一些fortran编译器中不会报错，只会给出warning，实在是很糟糕的事情。
