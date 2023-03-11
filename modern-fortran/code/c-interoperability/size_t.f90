program test
    use iso_c_binding
    implicit none
    integer(kind=c_size_t) :: n
    real(kind=c_long_double) :: x
    logical(kind=c_bool) :: b
    character(kind=c_char) :: c
    print *, huge(n)
    print *, huge(x)
    b = .true.
    print *, b
    c = c_horizontal_tab ! 等价于 c 语言 '\t'
    print '(A)', c//"Hello world!"
end program test