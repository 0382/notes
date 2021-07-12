# 【程序的运行（二）】编译c语言

本文开始讲编译，介绍c语言的编译过程。

本章的大标题是程序的运行，不过解释型语言的运行实在过于简单，没什么好说的。但是要搞定c/c++/fortran的编译，则要困难的多。

更现代的编译型语言比如go, rust等，虽然由于包管理器的存在要简单不少。但是毕竟本系列的主旨还是为了物理系学生做数值计算普及一些计算机基础知识。所以学习这些老古董的编译还是非常必要的。

## 开始使用编译器

首先你要安装一下gcc编译器，不知道怎么安装请先看[Visual Studio Code](../code-edit/vscode.md)的c++配置示例部分。

然后我们学习一下在命令行使用`gcc`编译器。本文的实验是在linux下进行的，windows下得到的结果是差不多的。

写一个简单的c语言程序，命名为`hello.c`
```c
#include <stdio.h>
#define MSG "Hello world!"

int main(){
    printf("%s", MSG);
}
```

在这个文件所在目录下，在命令行输入
```bash
gcc hello.c -o hell.exe
```

当前目录下会生成一个编译后的文件`hello.exe`。然后输入`./hello.exe`，windows的cmd下则是输入`hello.exe`，既可以运行这个程序。你会发现确实打印出了`Hello world!`字符串。

以上就是在命令行下使用编译器的方法。可以很清楚的看到，c语言程序分成编译和运行两个步骤。此时即使你删掉`hello.c`文件，也还是能够运行`hello.exe`，即编译之后的二进制文件是不依赖源文件的。

## 编译的四个步骤

上述编译命令非常简单。不过，c语言编译实际上经过了四个步骤。还是使用上面的`hello.c`程序为例，看看四个步骤都发生了什么。

### 1. 预处理(preprocess)

使用命令
```bash
gcc -E hello.c -o hello.i
```

打开看`hello.i`文件，是一个文本文件，会看到非常长的内容，下面是摘要
```c
// 省略...
extern int printf (const char *__restrict __format, ...);
// 省略 ...
int main()
{
    printf("%s", "Hello world!");
}
```

有两点需要注意。其一是，引入了`printf`函数的声明(`extern`行)，其二是原来是`MSG`的地方被替换成了`"Hello world!"`。

c/c++中以`#`开头的代码，叫做预处理命令。`#include`命令的作用是将标准库的`stdio.h`文件完全复制到当前文件内，其中`stdio.h`中声明了`printf`函数，`extern`行就是`stdio.h`文件中的内容。我们都知道c/c++中函数必须先声明才能使用，`#include <stdio.h>`命令就是为了我们在`main`函数中可以使用`printf`函数。`#define`命令是替换命令，这里是将代码所有单独存在的`MSG`替换成`"Hello world!"`。

#### 2. 编译(compile)

**狭义的编译**，是将c语言代码编译成汇编代码。使用如下命令
```bash
gcc -S hello.i -o hello.s
```

得到的`hello.s`如下
```assembly
        .file   "hello.c"
        .text
        .section        .rodata
.LC0:
        .string "Hello world!"
.LC1:
        .string "%s"
        .text
        .globl  main
        .type   main, @function
main:
.LFB0:
        .cfi_startproc
        endbr64
        pushq   %rbp
        .cfi_def_cfa_offset 16
        .cfi_offset 6, -16
        movq    %rsp, %rbp
        .cfi_def_cfa_register 6
        leaq    .LC0(%rip), %rsi
        leaq    .LC1(%rip), %rdi
        movl    $0, %eax
        call    printf@PLT
        movl    $0, %eax
        popq    %rbp
        .cfi_def_cfa 7, 8
        ret
        .cfi_endproc
.LFE0:
        .size   main, .-main
        .ident  "GCC: (Ubuntu 9.3.0-17ubuntu1~20.04) 9.3.0"
        .section        .note.GNU-stack,"",@progbits
        .section        .note.gnu.property,"a"
        .align 8
        .long    1f - 0f
        .long    4f - 1f
        .long    5
0:
        .string  "GNU"
1:
        .align 8
        .long    0xc0000002
        .long    3f - 2f
2:
        .long    0x3
3:
        .align 8
4:
```

汇编语言也是一种编程语言，是c/fortran等这些高级语言出现之前的编程语言。汇编语言在不同的操作系统和cpu上也是不同的，不同编译器生成的汇编语言也不同。我们也可以看到上面的`hello.s`中含有一些编译器和操作系统信息。

#### 3. 汇编(assembly)

汇编过程，就是将汇编代码文件，转换成机器码的二进制文件。使用如下命令进行汇编
```bash
gcc -c hello.s -o hello.o
```

现在你打开`hello.o`就是一堆乱码了，`.o`文件已经是二进制文件了。不过你可以使用如下命令看看`hello.o`的一些信息
```bash
nm hello.o
```

输出为
```bash
                 U _GLOBAL_OFFSET_TABLE_
0000000000000000 T main
                 U printf
```

可以看到定义的`main`函数，以及程序使用了`printf`等信息。

#### 4. 链接(link)

使用如下命令进行链接
```bash
gcc hello.o -o hello.exe
```

生成的`hello.exe`文件就是可以运行的程序了。

链接是非常重要的一步，很多错误都和这一步有关。在这个例子中，链接的作用在于将我们的程序和标准库链接起来，使得我们的程序能够使用`printf`函数。请注意我们之前`#include <stdio.h>`步骤中，其实只引入了`printf`函数的声明，但是并没有看到`printf`函数的实现。`printf`函数的声明存在于标准库的某个库文件中，我们需要将其链接过来，才能够真正调用`printf`函数。

除了标准库，很多时候，我们使用别人开发的库，比如`blas`库，则需要链接到对应的库文件。


实际工作中我们并不需要逐步使用命令编译。对于单个文件程序的编译，只需要使用最开始的简单命令就好了。对于多文件的编译，后面一篇文章会详细介绍。但是认识这四个步骤，对于我们理解程序，发现程序的问题很有帮助。认识到你的错误发生在那个阶段，才能够帮助你更好的定位到错误发生的位置。

下面介绍一下使用别人的库的一些要点，就需要上述知识。

## 库的种类

这里的库仅仅指c/c++库。

### 1. 头文件库(Head only library)

仅使用头文件的库，函数的声明和定义都放在头文件中。一般只有c++才能实现纯头文件库。

这种库只需要使用`#include`引入头文件就行了，在预处理阶段就引入了所有的依赖项，不需要链接步骤。`Eigen3`就是这样的库。这种库用起来很方便，相对的编译时间会比较长。

### 2. 链接库

链接库分为静态(static)链接库和动态(shared)链接库。当然这些库也必须提供头文件，但是头文件只有函数的声明，没有函数的实现。函数的实验已经被编译成了库文件。

上述汇编步骤我们得到了`.o`文件，通常的静态链接库就是一系列`.o`文件打包起来得到`.a`文件。而动态链接库，则是在编译阶段另外加上`-shared`选项编译得到的`.so`文件。

> 以上只针对linux系统而言，Windows下如果是gcc编译器，那么是一样的，如果是微软的`cl`编译器，则静态库是`.lib`文件，动态库是`.dll`文件。

#### 使用链接库

如果一个库提供动态链接库，比如`gsl`库，需要这样编译
```bash
gcc main.c -lgsl -o test.exe
```

其中`-lgsl`选项指定链接到`gsl`动态库。如果是静态链接库，则需要再加一个`-static`参数。

确切的说，静态链接库是在上面的链接步骤引入程序中的。程序编译完成后，使用的库里面的函数的实现也一同被引入了最终的程序中。因此最终的程序不再依赖于任何库文件，可以独立运行。相反动态链接库在链接步骤中，实际上并没有真正完成链接，而只是记住了用到了某个动态链接库。在程序运行时，才找到动态链接库，调用其中的函数。这也是为什么编译型语言运行时会依赖于动态链接库。

静态链接库的缺点是，如果库更新了，程序需要重新编译。而动态链接库更新则不需要重新编译，代价是程序运行时，必须依赖于动态链接库。

> linux系统上的大部分程序，基本上都运行时依赖于glibc，或者说一个名为`libc.so`的动态链接库文件。这是GNU开发的c语言标准库加上一系列linux下的c语言扩展库组成的，是linux及其重要的组件之一，任何时候不应该动这个文件。
