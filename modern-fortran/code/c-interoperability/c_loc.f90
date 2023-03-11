program test
    use iso_c_binding
    implicit none
    real, target :: x
    type(c_ptr) :: p
    p = c_loc(x)
    print *, p
end program test