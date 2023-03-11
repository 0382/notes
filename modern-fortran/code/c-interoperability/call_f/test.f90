module what_ever_module
    use iso_c_binding
    implicit none
contains
    integer(c_int) function add(x, y) result(ans) bind(c)
        integer(c_int), intent(in), value :: x, y
        ans = x + y
    end function
end module what_ever_module
