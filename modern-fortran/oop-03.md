# 面向对象-03：继承和多态

一个简单的继承例子
```fortran
module people_m
    implicit none
    private
    integer, parameter :: max_name_len = 32
    type, public :: People
        character(len=max_name_len), private :: name
    contains
        procedure :: set_name
        procedure :: greet
    end type

    type, public, extends(People) :: Student
        real, private :: GPA
    end type
contains
    subroutine set_name(this, name)
        class(People), intent(inout) :: this
        character(len=*), intent(in) :: name
        this%name = name
    end subroutine

    subroutine greet(this)
        class(People), intent(in) :: this
        print '(A,".")', "Hello, my name is "//trim(this%name)
    end subroutine
end module people_m

program test
    use people_m
    implicit none
    type(Student) :: alice
    call alice%set_name("Alice")
    call alice%greet()
end program test
```
Fortran 2003引入的新关键字`extends`主要就是为了继承而出现的。

Fortran中类的成员函授默认可以被重写（override）
```fortran
module people_m
    implicit none
    private
    integer, parameter :: max_name_len = 32
    type, public :: People
        character(len=max_name_len), private :: name
    contains
        procedure :: set_name
        procedure :: greet
    end type

    type, public, extends(People) :: Student
        real, private :: GPA
    contains
        procedure :: greet => stu_greet
    end type
contains
    subroutine set_name(this, name)
        class(People), intent(inout) :: this
        character(len=*), intent(in) :: name
        this%name = name
    end subroutine

    subroutine greet(this)
        class(People), intent(in) :: this
        print '(A,".")', "Hello, my name is "//trim(this%name)
    end subroutine

    subroutine stu_greet(this)
        class(Student), intent(in) :: this
        print '(A,".")', "Hello, I'm a student, my name is "//trim(this%name)
    end subroutine
end module people_m

program test
    use people_m
    implicit none
    type(Student) :: alice
    call alice%set_name("Alice")
    call alice%greet()
end program test
```
如果你想禁止这么做，就需要另一个关键字`non_overridable`
```fortran
type, public :: People
    character(len=max_name_len), private :: name
contains
    procedure :: set_name
    procedure, non_overridable :: greet
end type
```

## 抽象类

类继承的起点除了通常的类之外，还可以是抽象类。下面是一个例子
```fortran
module array_m
    use iso_fortran_env
    implicit none

    type, abstract :: AbstractArray
    contains
        procedure(array_size), pass(this), deferred :: size
    end type

    abstract interface
        integer function array_size(this)
            import :: AbstractArray
            class(AbstractArray), intent(in) :: this
        end function
    end interface

    type, abstract, extends(AbstractArray) :: Real64Array
    contains
        procedure, nopass :: kind => real64_arr_data_kind
    end type

    type, extends(Real64Array) :: MatrixXd
        real(kind=real64), dimension(:,:), allocatable :: m_data
    contains
        procedure :: size => matxd_size
    end type
contains
    integer function real64_arr_data_kind()
        real64_arr_data_kind = real64
    end function

    integer function matxd_size(this)
        class(MatrixXd), intent(in) :: this
        matxd_size = size(this%m_data)
    end function
end module array_m

program test
    use array_m
    implicit none
    type(MatrixXd) :: ma
    allocate(ma%m_data(10, 10))
    print *, ma%size()
end program test
```

其中涉及到的语法非常多，我们一个一个来解释。首先是抽象类的定义语法
```fortran
type, abstract :: TypeName
end type
```
在这个例子中，我的抽象类没有成员变量的，实际上成员变量是完全允许的。抽象类的成员函数可以是抽象接口(`array_size`)，也可以真实的函数(`real64_arr_data_kind`)。抽象类也可以继承自另一个抽象类。

定义抽象接口的语法为
```fortran
abstract interface
    integer function array_size(this)
        import :: AbstractArray
        class(AbstractArray), intent(in) :: this
    end function
end interface
```
其中，抽象接口之外的所有类名、函数名、变量等都需要使用`import :: `语法引入到抽象接口的定义中。

在抽象类中定义抽象接口使用如下语法
```fortran
procedure(array_size), pass(this), deferred :: size
```
其中，`drferred`关键字是必须得，它似乎只是在这里使用。

抽象子类不需要实现抽象接口，而一般子类则必须实现抽象接口，否则编译不通过。而并非抽象接口的函数`kind`，子类可以实现，也可以不实现；若不实现，则采用父类的这个函数。

### 再次理解`class`关键字

`class`关键字如果在传递参数的时候使用，它表示这个参数可以是这个类以及其所以子类。而`type`参数表示只能是这个了本身。

由于Fortran没有类似`final`的关键字，所以得类都存在被继承的可能性。所以类的成员函数，必须使用`class`参数。

## 多态指针

`class`关键字除了在传递参数是使用，还可以用来定义多态指针。用前面的`people_m`举例如下
```fortran
program test
    use people_m
    implicit none
    class(People), allocatable :: alice
    allocate(Student :: alice)
    call alice%set_name("Alice")
    call alice%greet()
    deallocate(alice)
    allocate(People :: alice)
    call alice%set_name("Alice")
    call alice%greet()
end program test
```

可以看到，`alice`的类型声明为`class(People), allocatable`，而不是某个`type`。在后面，它可以申请内存为基类，或者子类，并且表现出对应类型的行为。

> Fortran的`allocatable`本质上是类似指针的，只是它有一些与`pointer`不同的语法糖。需要申请内存的工作，`allocatable`通常是心智负担更少的一个选择。

## `select type`语法

其实前面的语法已经可以实现大部分的多态功能了。

`select type`算是对Fortran多态功能的进一步拓展。我们还是用上述`people_m`来举个例子
```fortran
program test
    use people_m
    implicit none
    class(People), allocatable :: alice
    allocate(Student :: alice)
    call call_people(alice)
    deallocate(alice)
    allocate(People :: alice)
    call call_people(alice)
contains
    subroutine call_people(p)
        class(People), intent(in) :: p
        select type (x => p)
            type is (People)
                print *, "called a people"
            type is (Student)
                print *, "called a student"
            ! class is (xxx) ! 使用 class 选择也是可以的，比如对于复杂的继承链
            class default
                error stop "unrecognized class"
        end select
    end subroutine
end program test
```
实际上，上述功能完全可以通过重载来实现。不过由于Fortran的重载写起来比较笨重，增加这样一个语法也可以理解。

## `class(*)`语法

`class(*)`语法是`select type`语法的进一步增强。一个例子如下
```fortran
program test
    implicit none
    integer :: a
    real :: b
    real(kind=8) :: c
    call set_default(a)
    call set_default(b)
    call set_default(c)
    print *, a, b, c
contains
    subroutine set_default(x)
        class(*), intent(inout) :: x
        select type(p => x)
            type is (integer)
                p = 1
            type is (real)
                p = 2.0
            type is(real(kind=8))
                p = 3.0d0
            class default
                error stop "unsupport type"
        end select
    end subroutine
end program test
```

我个人是不太喜欢这个语法的，不过不少人拿它当做`any`类型用。因为`class(*)`也可以用于变量定义，所以是可以由此定义一个无限任意类型的容器的，比如
```fortran
type link
     class(*), allocatable :: value => null()
     type(link), pointer :: next => null()
end type link
```
这个特性也被称为无限多态。

## 总结

Fortran的继承和多态功能，大体上还不错。它没有多继承，不多这种邪恶语法大多数语言也不支持。`select type`和`class(*)`有点邪恶，但也是Fortran语法糖不足不得已而为之，建议谨慎使用。