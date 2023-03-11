module integral_m
    use iso_c_binding
    implicit none
    interface
        real function real_func(x)
            real, intent(in), value :: x
        end function
    end interface
contains
    impure real function real_integral(f, a, b, N) result(ans)
        procedure(real_func), pointer, intent(in) :: f
        real, intent(in) :: a, b
        integer, optional :: N
        integer :: Npoints, i
        real :: x, h
        Npoints = 10000
        if(present(N)) Npoints = N
        h = (b - a) / Npoints
        ans = 0.0
        do i = 1, Npoints
            x = a + (i - 0.5) * h
            ans = ans + f(x)
        end do
        ans = ans * h
    end function
end module integral_m

program test
    use iso_c_binding
    use integral_m
    implicit none
    interface
        function choose_func(c_name) bind(c)
            import :: c_ptr, c_funptr
            ! const char*，但是 `ios_c_binding` 只有`c_ptr`类型
            type(c_ptr), value, intent(in) :: c_name
            type(c_funptr) :: choose_func
        end function

        real(c_float) function float_func(x)
            import :: c_float
            real(c_float), intent(in), value :: x
        end function
    end interface
    character(len=:), allocatable, target :: name
    procedure(real_func), pointer :: f
    type(c_funptr) :: cf
    ! 使用 Fortran 原生的函数指针
    f => circle
    print*, real_integral(f, 0., 2.0)

    name = "sin"
    cf = choose_func(c_loc(name))
    ! c 函数指针赋值给 Fortran
    call c_f_procpointer(cf, f)
    print*, real_integral(f, 0., 3.14)

    name = "cos"
    cf = choose_func(c_loc(name))
    f => wapper
    print *, real_integral(f, 0., 1.57)

contains
    real function circle(x) result(ans)
        real, intent(in), value :: x
        ans = sqrt(4.0 - x * x)
    end function

    ! 不确定 c 的 `float` 与 Fortran 的 `real` 是否一致
    ! 较真的写法最好做一下转化
    real function wapper(x) result(ans)
        real, intent(in), value :: x
        real(c_float) :: temp
        procedure(float_func), pointer :: ff
        call c_f_procpointer(cf, ff)
        temp = real(x, kind=c_float)
        temp = ff(temp)
        ans = real(temp)
    end function
end program test