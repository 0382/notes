# 面向对象-01：类

面向对象是Fortran2003引入的最为重要的特性之一，相关的内容是非常丰富的。这一节简单介绍一下类的基本语法。

## 类

总之先看一段代码
```fortran
module people_module
    implicit none
    private
    integer, parameter :: people_name_len = 32

    public :: People
    type :: People
        character(len=people_name_len), private :: name
        contains
            procedure :: init => init_people
            procedure :: greet => people_greet
    end type People
contains
    subroutine init_people(this, name)
        class(People), intent(inout) :: this
        character(len=*), intent(in) :: name
        this%name = name
    end subroutine init_people
    
    subroutine people_greet(this, name)
        class(People), intent(in) :: this
        character(len=*), intent(in) :: name
        print "(A,'.')", "Hello "//trim(name)//"! My name is "//trim(this%name)
    end subroutine people_greet
end module people_module

program test
    use people_module
    implicit none
    type(People) :: lihua
    call lihua%init("Li Hua")
    call lihua%greet("Alice")
    ! print '(A)', lihua%name ! 不能访问 private 成员
end program test
```

从这个例子来看，我可以清楚的看到类的基本定义与用法。`type`其实是Fortran 90就已经存在的概念，类似c语言中的`struct`。而Fortran的类实际上就是在`type`的基础上允许`contains`一些函数。需要注意的是，代码中的`greet => people_greet`并不是必须得，比如你完全可以这样写
```fortran
procedure :: people_greet
! ......
call lihua%people_greet("Alice")
```
或者直接这样写
```fortran
procedure :: greet
! ......
subroutine greet(this, name)
    class(People), intent(in) :: this
    character(len=*), intent(in) :: name
    print "(A,'.')", "Hello "//trim(name)//"! My name is "//trim(this%name)
end subroutine greet
! ......
call lihua%greet("Alice")
```
Fortran不太方便的地方在于你不能在`type`内写函数体，写在外面的函数为了避免重名通常会带上类名标识。比如如果你还要写一个类`Student`，它也需要实现一个`greet`函数，你不能都命名为`greet`。所以提供了`procedure :: greet => people_greet`这样的语法来给类方法重命名

> 在github上看到Fortran的面向对象代码，可能有不少都是类似示例中的命名风格。我想除了避免重名这个原因之外，可能还因为不少代码继承自上一个时代。没有“类”的语法糖时，我们也可以用类似于`list_create(lst), list_push_back(lst, item)`这样的函数来模拟面向对象。

类函数的调用，实际上和普通的函数是一样的，`subroutine`就用`call`，`function`就类似于`x = obj%get_val()`。和成员变量一样，函数也通过`%`来访问。

#### Tips

- 这里我给`name`加上了`private`限定符，使得其在外面无法直接访问。`type`的成员默认是`public`的，你可以这样指定为默认`private`:
```fortran
type :: People
    private
    character(len=people_name_len) :: name
    contains
        ! private ! 函数和类内成员默认限定是分开的
        procedure :: init => init_people
        procedure :: greet => people_greet
end type People
```
- 与其他语言略有不同的是，Fortran的`private`限定的成员，指的是不能在`module`之外使用，在`module`内部其实是可以随意访问的；无论修饰的内类的成员还是类外的一般变量或函数。
- `class(People), intent(in) :: this`，这里必须使用`class`而不能用`type`。这与多态有关，我们后面会讲到。
- Fortran的类不支持定义在`module`之外，不过`module`可是好东西，新写的代码还有什么理由不写在module里面呢。
- 例子中`integer, parameter :: people_name_len = 32`是不能写在类里面的，即无法做到c++的类内常量。不过实际上也只是差了一个命名空间而已，有`module`的隔离，无伤大雅。

## 构造函数与析构函数

再看一个例子
```fortran
module vector
    implicit none
    private

    public :: veci
    type :: veci
        private
        integer, dimension(:), allocatable :: data
        integer :: size
        integer :: capacity
    contains
        procedure :: push_back => veci_push_back
        procedure :: at => veci_at
        procedure :: print => veci_print
        final :: destroy_veci
    end type veci
    
    interface veci
        procedure :: make_veci
    end interface
contains
    function make_veci() result(ans)
        type(veci) :: ans
        ans%size = 0
        allocate(ans%data(1))
        ans%capacity = 1
    end function make_veci

    subroutine destroy_veci(this)
        type(veci), intent(inout) :: this
        if(allocated(this%data)) deallocate(this%data)
        print '(A)', "destructor called"
    end subroutine

    subroutine veci_push_back(this, val)
        class(veci), intent(inout) :: this
        integer, intent(in) :: val
        integer, dimension(:), allocatable :: buffer
        if(this%size == this%capacity) then
            call move_alloc(this%data, buffer)
            this%capacity = 2 * this%capacity
            allocate(this%data(this%capacity))
            this%data(1:this%size) = buffer(:)
            deallocate(buffer)
        end if
        this%size = this%size + 1
        this%data(this%size) = val
    end subroutine

    function veci_at(this, idx) result(ans)
        class(veci), intent(inout) :: this
        integer, intent(in) :: idx
        integer :: ans
        if(idx >= this%size) then
            error stop "veci out of range"
        end if
        ans = this%data(idx)
    end function veci_at

    subroutine veci_print(this)
        class(veci), intent(inout) :: this
        integer :: i
        print '(A,$)', "["
        do i = 1, this%size - 1
            print '(I3,",",$)', this%data(i)
        end do
        print '(I3,"]")', this%data(this%size)
    end subroutine
end module

program test
    use vector
    implicit none
    block
        type(veci) :: v
        integer :: i
        v = veci()
        do i = 1,10
            call v%push_back(i)
        end do
        call v%print()
        print *, v%at(5)
    end block
end program test
```

这里展示了一个简单的动态数组，因为涉及到数据的申请和释放，所以构造函数和析构函数是非常重要的。先说析构函数，Fortran提供了一个语法糖`final`来表示析构函数。我这里使用了一个`block`来展示对象离开作用域时自动调用析构函数的现象（按照c++类比，按理不加这个`block`也应该调用析构函数，但是并没有，我也不明白原因）。

关于构造函数，其实并没有一个特定的语法糖。这里我只是使用了`interface`的函数重载功能，定义了一个和`veci`同名的`interface`。实际上，你完全可以不定义这个`interface`而直接使用`make_veci`，本质上是完全一样的。得益于`interface`的重载功能，我们当然也可以重载不同的构造函数。

在我看来，Fortran没有禁止`type`和`interface`的重名，某种程度上算是鼓励我们去这样做，从而实现类似于其他语言中构造函数的功能。不过这终究只是一个风格问题，大家按照自己的习惯来就好。

> c++中有一个比较好用的特性是写了某个构造函数之后，默认构造函数就不可用了。我们这里的`make_veci`构造一个空的数组时，申请了一个空间，这是为了后面不用每次遇到`data`的时候都判断它是否`allocated`。但是Fortran并没有一个机制强迫你必须使用构造函数初始化，而如果不初始化，那么后面直接调用其他函数就可能发生奇怪的问题。像`rust`也没有c++意义上的构造函数，但是`rust`定义的变量要求必须初始化，例如`let mut s = String::new()`，就不会出现问题。而`Fortran`必须先声明变量，再使用，那么声明之后不去调用构造函数，是完全合法的，这实在是一个大坑。

## `pass`和`nopass`关键字

`pass`和`nopass`是Fortran 2003中一个非常有趣的语法，示例如下
```fortran
module People_m
    implicit none
    private
    type, public :: People
        character(len=32), private :: name
    contains
        procedure, pass(this) :: set_name
        procedure, pass(self) :: greet
        procedure, nopass :: max_name_len
    end type
contains
    subroutine set_name(name, this)
        character(len=*), intent(in) :: name
        class(People), intent(inout) :: this
        this%name = name
    end subroutine

    subroutine greet(other, self)
        class(People), intent(in) :: self, other
        print '(A,".")', "Hello "//trim(other%name)//"! My name is "//trim(self%name)
    end subroutine

    integer function max_name_len()
        max_name_len = 32
    end function
end module People_m

program test
    use People_m
    implicit none
    type(People) :: alice, diana
    call alice%set_name("Alice")
    call diana%set_name("Diana")
    call alice%greet(diana)
    print *, alice%max_name_len()
end program test
```
一般而言，类内函数第一个参数是类本身。但是Fortran可以通过`pass(this)`指定某个特定命名的参数表示类本身。其实通常的类内函数默认的属性为`pass`，它表示第一个参数表示类本身，且不限定名称。而`nopass`表示的就是没有参数表示类本身，类似于c++的静态类成员函数。

通常使用，`nopass`用于定义静态函数自然是非常有用的。`pass`不是必须得，不过在后面的多态中，它可以用于定义抽象接口，约束子类必须用`this`或`self`表示类本身，便于统一风格。此外，这两个关键字也在函数指针特性中发挥作用，我们在相关章节再详细介绍。

> 与Python一样，默认情况下Fortran并不限制表示类本身的参数名称。但是本专栏会按照c++的习惯，在大部分情况下使用`this`。

## 一些闲话

总的来说，最基本的类功能，Fortran实现的中规中矩。这实际上也是科学计算中最需要的那一部分面向对象能力：对数据和函数进行一定程度的封装。

也许有人说，Fortran的`module`也可以进行一定程度的封装，不过`module`更像是一种单例模式。当我们需要的某种对象存在多份不同的实例时，面向对象是非常有效的一种代码组织方式。
