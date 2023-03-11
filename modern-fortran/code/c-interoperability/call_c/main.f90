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