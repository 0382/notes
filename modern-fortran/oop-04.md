# 面向对象-04：自定义输入输出

Fortran2003的自定义IO的标准叫法是：User-Defined Derived-Type I/O。

Fortran的输入输出是一个很大的槽点，它们几乎是为内置类型设计的，而且似乎完全不考虑扩展性。不过在Fortran2003中还是引入了自定义IO的语法。

先看一个简单的例子
```fortran
module vec3_m
    implicit none
    private

    public vec3
    type :: vec3
        real(kind=8), dimension(3) :: m_data
    contains
        ! 类内的函数重载
        procedure :: dtio_read_vec3
        generic :: read(formatted) => dtio_read_vec3
    end type vec3

    ! 也可以直接写接口
    ! 注意这只是为了展示两种不同的写法，你完全可以只用一种
    public :: write(formatted) ! 注意也要把它 `public`
    interface write(formatted)
        module procedure dtio_write_vec3
    end interface

contains
    subroutine dtio_read_vec3(this, unit, iotype, v_list, iostat, iomsg)
        class(vec3), intent(inout) :: this
        integer, intent(in) :: unit
        character(len=*), intent(in) :: iotype
        integer, intent(in) :: v_list(:)
        integer, intent(out) :: iostat
        character(len=*), intent(inout) :: iomsg
        read(unit, fmt=*, iostat=iostat, iomsg=iomsg) this%m_data
    end subroutine

    subroutine dtio_write_vec3(this, unit, iotype, v_list, iostat, iomsg)
        class(vec3), intent(in) :: this
        integer, intent(in) :: unit
        character(len=*), intent(in) :: iotype
        integer, intent(in) :: v_list(:)
        integer, intent(out) :: iostat
        character(len=*), intent(inout) :: iomsg
        write(unit, fmt=*, iostat=iostat, iomsg=iomsg) this%m_data
    end subroutine
end module vec3_m

program test
    use vec3_m
    implicit none
    type(vec3) :: v
    read(*,*) v
    print '(DT)', v
end program test
```

总的来说，自定义IO的写法稍显复杂，你必须完全按照例子中给出的格式来写（包括`intent`也必须完全一致）。不过它总算是为类的输入输出提供了新的可能性。

自定义IO的`format`基本字符都是`DT`（还可以附带一些参数，见后文）。

另外，前面定义的都是`fotmatted`格式的IO，还有所谓`unformatted`的IO，也就是二进制的IO，它的定义方式是类似，比如
```fortran
module vec3_m
    implicit none
    private

    public vec3
    type :: vec3
        real(kind=8), dimension(3) :: m_data
    contains
        ! 类内的函数重载
        procedure :: write_binary_vec3
        generic :: write(unformatted) => write_binary_vec3
    end type vec3

contains
    subroutine write_binary_vec3(this, unit, iostat, iomsg)
        class(vec3), intent(in) :: this
        integer, intent(in) :: unit
        integer, intent(out) :: iostat
        character(len=*), intent(inout) :: iomsg
        write(unit=unit, iostat=iostat, iomsg=iomsg) this%m_data
    end subroutine write_binary_vec3
end module vec3_m

program test
    use vec3_m
    implicit none
    type(vec3) :: v
    v%m_data = 1.d0
    open(unit=100, file='hello.bin', form='unformatted')
    write(100) v
    close(100)
    v%m_data = 0.d0
    open(unit=100, file='hello.bin', form='unformatted')
    read(100) v%m_data
    close(100)
    print*, v%m_data
end program test
```

此外，自定义IO也是可以通过`namelist`读写的，具体的例子就看Intel的文档吧：[Examples of User-Defined Derived-Type I/O](https://www.intel.com/content/www/us/en/develop/documentation/fortran-compiler-oneapi-dev-guide-and-reference/top/language-reference/data-transfer-i-o-statements/user-defined-derived-type-i-o/examples-of-user-defined-derived-type-i-o.html).


## 自定义IO的参数

上述例子似乎忽略了`iotype, v_list`两个参数，下面这个例子说明了它们的用法
```fortran
module veci_m
    implicit none
    private

    public veci
    type :: veci
        integer, dimension(:), allocatable :: m_data
    contains
        procedure :: dtio_write_veci
        generic :: write(formatted) => dtio_write_veci
    end type veci
contains

subroutine dtio_write_veci(this, unit, iotype, v_list, iostat, iomsg)
    class(veci), intent(in) :: this
    integer, intent(in) :: unit
    character(len=*), intent(in) :: iotype
    integer, intent(in) :: v_list(:)
    integer, intent(out) :: iostat
    character(len=*), intent(inout) :: iomsg
    character(len=64) :: buffer
    integer :: i, start, end
    if(iotype == 'DTsummary' .or. size(v_list) == 0) then
        write(unit=buffer, fmt=*) size(this%m_data)
        buffer = adjustl(buffer)
        write(unit=unit, fmt='(A)', iostat=iostat, iomsg=iomsg) "veci("//trim(buffer)//"-elements)"
    else if(iotype == 'DThead') then
        write(unit=unit, fmt='(A,$)', iostat=iostat, iomsg=iomsg) "veci("
        end = min(v_list(1), size(this%m_data))
        do i = 1, end
            write(unit=buffer, fmt=*) this%m_data(i)
            buffer = adjustl(buffer)
            write(unit=unit, fmt='(A,$)', iostat=iostat, iomsg=iomsg) trim(buffer)//","
        end do
        write(unit=unit, fmt='(A)', iostat=iostat, iomsg=iomsg) "...)"
    else if(iotype == 'DTtail') then
        write(unit=unit, fmt='(A,$)', iostat=iostat, iomsg=iomsg) "veci(..."
        end = size(this%m_data)
        start = max(1, end - v_list(1))
        do i = start, end
            write(unit=buffer, fmt=*) this%m_data(i)
            buffer = adjustl(buffer)
            write(unit=unit, fmt='(A,$)', iostat=iostat, iomsg=iomsg) ","//trim(buffer)
        end do
        write(unit=unit, fmt='(A)', iostat=iostat, iomsg=iomsg) ")"
    else if(iotype == 'DTcenter') then
        write(unit=unit, fmt='(A,$)', iostat=iostat, iomsg=iomsg) "veci(..."
        start = max(1, v_list(1))
        end = min(v_list(2), size(this%m_data))
        do i = start, end
            write(unit=buffer, fmt=*) this%m_data(i)
            buffer = adjustl(buffer)
            write(unit=unit, fmt='(A,$)', iostat=iostat, iomsg=iomsg) ","//trim(buffer)
        end do
        write(unit=unit, fmt='(A)', iostat=iostat, iomsg=iomsg) ",...)"
    else
        write(unit=unit, fmt=*, iostat=iostat, iomsg=iomsg) this%m_data
    end if
end subroutine

end module

program test
    use veci_m
    implicit none
    type(veci) :: v
    integer :: i
    allocate(v%m_data(100))
    do i = 1, 100
        v%m_data(i) = i
    end do
    print '(DT"summary")', v
    print '(DT"head"(10))', v
    print '(DT"tail"(10))', v
    print '(DT"center"(30, 40))', v
end program test
```

上述例子说明了自定义IO的完整语法，实际上其完整的格式字符为`DT"type-string"(integer-vector)`,对应于函数中`iotype == "DTtype-string", v_list = integer-vector`。

总的来说，自定义IO给了Fortran的输入输出语句以扩展性，甚至能够玩出不少花样。但是这种奇妙的语法似乎又把Fortran的输入输出带向了某种奇怪的方向。

没有类型检查的格式字符串，会带来无穷无尽的问题。而`DT`的格式字符串甚至还能够带一个字符参数和一个整数数组参数，需要考虑的特殊情况数不胜数，想想就觉得头痛。不过，如果仅仅使用`DT`，那么自定义IO还是一个非常不错的新特性。