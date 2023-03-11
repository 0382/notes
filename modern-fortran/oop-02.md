# 面向对象-02：类的函数和运算符重载

## 类内成员函数重载

我们知道Fortran是可以通过`interface`来实现一般函数的重载的，那么类内的函数如何重载呢？

看一个例子
```fortran
module vec3_m
    implicit none
    private

    public :: vec3
    type :: vec3
        real(kind=8), dimension(3) :: m_data
    contains
        procedure :: plus_integer
        procedure :: plus_double
        procedure :: plus_vec3
        ! generic 指向的是类内函数，所以前面这三行时必须写的
        generic :: plus => plus_integer, plus_double, plus_vec3
    end type vec3

contains
    pure function plus_integer(this, val) result(ans)
        class(vec3), intent(in) :: this
        integer, intent(in) :: val
        type(vec3) :: ans
        ans%m_data = this%m_data + dble(val)
    end function plus_integer

    pure function plus_double(this, val) result(ans)
        class(vec3), intent(in) :: this
        real(kind=8), intent(in) :: val
        type(vec3) :: ans
        ans%m_data = this%m_data + val
    end function plus_double

    pure function plus_vec3(this, val) result(ans)
        class(vec3), intent(in) :: this
        type(vec3), intent(in) :: val
        type(vec3) :: ans
        ans%m_data = this%m_data + val%m_data
    end function plus_vec3

end module vec3_m

program test
    use vec3_m
    implicit none
    type(vec3) :: v
    v%m_data = 0d0
    v = v%plus_integer(1) ! 当然你还是可以用原来的函数名
    print *, v%m_data
    v = v%plus(2.0d0)
    print *, v%m_data
    v = v%plus(v)
    print *, v%m_data
end program test
```

`generic`是Fortran 2003引入的新关键字，其功能主要就是上述例子中展示的，用于类内函数的重载。

## 运算符重载

不仅可以重载函数，类内运算符重载也是完全可以的
```fortran
module vec3_m
    implicit none
    private

    public :: vec3
    type :: vec3
        real(kind=8), dimension(3) :: m_data
    contains
        procedure :: plus_integer
        procedure :: plus_double
        procedure :: plus_vec3
        generic :: operator(+) => plus_integer, plus_double, plus_vec3
    end type vec3

contains
    ! ...... 省略，和前面一样

end module vec3_m

program test
    use vec3_m
    implicit none
    type(vec3) :: v
    v%m_data = 0d0
    v = v + 1
    print *, v%m_data
    v = v + 2.0d0
    print *, v%m_data
    v = v + v
    print *, v%m_data
end program test
```
当然在这个例子中，从语义上来说，加法运算符最好还是定义为类外的一般函数，用`interface`来重载。

一个非常重要的运算符是赋值运算符，也是可以重载的，需要用`assignment(=)`，注意不再是`oprtator`了
```fortran
module vec3_m
    implicit none
    private

    public :: vec3
    type :: vec3
        real(kind=8), dimension(3) :: m_data
    contains
        procedure :: assign_integer
        procedure :: assign_double
        generic :: assignment(=) => assign_integer, assign_double
    end type vec3

contains
    pure subroutine assign_integer(this, val)
        class(vec3), intent(inout) :: this
        integer, intent(in) :: val
        this%m_data = dble(val)
    end subroutine assign_integer

    pure subroutine assign_double(this, val)
        class(vec3), intent(inout) :: this
        real(kind=8), intent(in) :: val
        this%m_data = val
    end subroutine assign_double

end module vec3_m

program test
    use vec3_m
    implicit none
    type(vec3) :: v
    v = 1
    print *, v%m_data
    v = 2.0d0
    print *, v%m_data
end program test
```
从例子可以看到，赋值运算符也是可以重载的。不过`Fortran`没有`+=`这样的运算符，所以赋值运算符也就这点内容了。

## 含指针的类

同一个`type`之间的赋值，是默认就存在的。比如
```fortran
type(vec3) :: v1, v2
v1 = v2
```
你不写赋值运算符的重载，上述代码都是成立。对于成员变量都是值类型的情况，这种默认的赋值当然没有任何问题。但是成员变量存在`pointer`时，就可能有问题了。

Fortran的`pointer`本质上和c语言的指针是一样的，除了指向已经存在的对象之外，也是可以通过`allocate`申请内存的。

但是`pointer`和`allocatable`是不一样的。`allocatable`之间赋值`a2 = a1`，那么`a2`会自动在`a1`之外的空闲内存中申请内存并赋值，两者占有不同的内存，算是Fortran特有的一种语法糖。而`pointer`之间赋值`p2 = p1`，`p2`只是指向了`p1`，它们的地址是完全一致的（这个行为与c语言的指针也是类似的）。

这就可能出现问题
```fortran
module veci_m
    implicit none
    private

    public :: veci
    type :: veci
        integer, dimension(:), pointer :: data => null()
    contains
        final :: destroy_veci
    end type veci
contains
    subroutine destroy_veci(this)
        type(veci), intent(inout) :: this
        if(associated(this%data)) deallocate(this%data)
    end subroutine destroy_veci
end module

program test
    use veci_m
    implicit none
    block
        type(veci) :: v1, v2
        allocate(v1%data(10))
        v1%data = 3
        v2 = v1
        deallocate(v1%data)
        print *, associated(v1%data) ! 结果为 `F`，很好理解
        print *, associated(v2%data) ! 这个结果理论上是未定义的，实现上大概率是 `T`
        print *, v2%data             ! 可能打印出奇怪的东西
        ! 析构 `v1` 没有问题，因为 `associated(this%data) == .false.`
        ! 析构 `v2`，就会发生对同一块内存 `double free`
    end block
end program test
```

有经验的c++程序员不难发现，这也是c++中，类成员有指针时常见的错误，解决问题的方法是写出正确的复制构造函数和复制赋值运算符。当然Fortran没有复制构造函数，我们这里只写一个复制运算符
```fortran
module veci_m
    implicit none
    private

    public :: veci
    type :: veci
        integer, dimension(:), pointer :: data => null()
    contains
        procedure :: assign_veci
        generic :: assignment(=) => assign_veci
        final :: destroy_veci
    end type veci
contains
    subroutine assign_veci(this, other)
        class(veci), intent(inout) :: this
        type(veci), intent(in) :: other
        if(associated(this%data)) then
            deallocate(this%data)
        end if
        allocate(this%data(size(other%data)))
        this%data(:) = other%data(:)
    end subroutine
    subroutine destroy_veci(this)
        type(veci), intent(inout) :: this
        if(associated(this%data)) deallocate(this%data)
    end subroutine destroy_veci
end module

program test
    use veci_m
    implicit none
    block
        type(veci) :: v1, v2
        allocate(v1%data(10))
        v1%data = 3
        v2 = v1
        deallocate(v1%data)
        print *, associated(v1%data)
        print *, associated(v2%data)
        print *, v2%data
    end block
end program test
```

注意，这里我们写`assign_veci`时，依然使用了`associated`来判断是否申请了数据，因为语法上`pointer`是无法判断是否`allocated`的。而前一个例子已经证明了`associated`是不可靠。这就要求在写代码的时候需要时刻注意不能在犯那样的错误，以保证赋值运算符是正确。这里为了例子简单，`data`没有设为`private`，当`data`设为`private`之后，就只有`veci`这个类的作者可能会犯错误。而如果作者总是写了正确的代码，那么使用`veci`的用户是不用担心的。

这里举的例子，要求`veci`要占有`data`数据的所有权。如果要写某种视图类，不占据数据的所有权，那么指针不需要申请内存，析构函数也不需要释放内存，就是另外一种写法了。

> 实际上，写c++的类，也需要关注同样的问题。

以上这个例子，更多的还是结合这个例子，展示Fortran管理资源时所需的语法。实际应用中，需要管理内存，其实更加推荐使用`allocatable`而不是`pointer`，正确使用`allocatable`所需的心智负担要小一点（当然也还是要注意及时`deallocate`）。

