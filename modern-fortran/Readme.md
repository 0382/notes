# 现代Fortran

## 目录

- Fortran 2003
  - [Fortran OOP-01：类](oop-01.md)
  - [Fortran OOP-02：类的函数和运算符重载](oop-02.md)
  - [Fortran OOP-03：继承和多态](oop-03.md)
  - [Fortran OOP-04：自定义输入输出](oop-04.md)
  - [Fortran 2003：与C语言交互](c-interoperability.md)
  - [Fortran 2003：函数指针](procedure-pointer.md)
  - [Fortran 2003：IEEE浮点数模块](IEEE-arithmetic.md)
  - [Fortran 2003：参数化派生类型](parametrized-derived-types.md)
  - [Fortran 2003：新增函数](new-intrinsics.md)
  - [Fortran 2003：I/O的一些新特性](IO-f03.md)


## 关于本专栏

Fortran的标准一直在更新，并且增加了不少很有用的特性，但是中文互联网上相关的资料并不丰富（其实英文资料也并不十分丰富）。我试着搬运一些过来，详细地介绍Fortran 95之后的一系列新标准。

本专栏的大部分内容来自于[Fortran Wiki](https://fortranwiki.org/fortran/show/HomePage)以及[Intel编译器文档](https://www.intel.com/content/www/us/en/develop/documentation/fortran-compiler-oneapi-dev-guide-and-reference/top.html)，如果你能够阅读英文的话，直接看Wiki这个网站是很不错的。不过我不完全是翻译内容，会按照自己的理解组织内容，并且争取做到大部分的代码示例都是自己想的。

限于个人知识和能力有限，不太可能介绍新标准的所有内容。对于完整的新标准内容感兴趣的，Fortran Wiki和Intel的编译器文档都是比较好资料。

### 前置知识

读者需要对于Fortran90有比较完整的知识和比较熟练的使用经验。在讲述某些比较冷门（实践中较少用到）的特性在新版有哪些变换时，我不会复述原版的知识。请善用搜索引擎。

有c/c++的知识和经验会对理解本专栏有非常大的帮助。我会下意识的与其他语言进行对比，并大量使用其他编程语言的概念，c/c++肯定会是最多被提到的。

### 关于术语

关于Fortran语言各种术语，我会在必要的地方给出英文原文，但是很多时候我不会给出中文翻译。相反我可能会直接使用其他编程语言的称呼，你需要注意它们不会是术语的标准翻译。例如，我会把`subroutine`和`function`统一称为函数，（就像c语言那样），或者（在必要使）直接写这两个关键字。再例如`Procedure Overloading`，我直接称呼为函数重载。

之所以这样做，一方面是由于我没有把握给出一个绝对精确的翻译，另一方面是我个人认为Fortran的很多术语与很多主流编程语言相去甚远。实际上Fortran的很多特性与其他语言本质上是一样的，但是使用了一个奇怪的术语很容易造成交流障碍。

> 换句话说，我希望本专栏的读者不应该只会Fortran这一种编程语言。如果是，你应该再自学一门。另外也考虑到，现在大多数学校本科的编程入门课应该还是c/c++或者python为主，而Fortran往往是开始搞科研之后，不得已而接触的语言。采用比较主流的术语称呼，应该是有助于这部分读者理解相关内容的。

> 总之不要指望我做专业的现代Fortran标准的翻译，你只负责教会你如何使用语言的这些新特性。

## Reference

- [Fortran Wiki](https://fortranwiki.org/fortran/show/HomePage)
- [Intel Fortran编译器文档](https://www.intel.com/content/www/us/en/develop/documentation/fortran-compiler-oneapi-dev-guide-and-reference/top.html)
- [GCC wiki of Gfortran](https://gcc.gnu.org/wiki/GFortran)
