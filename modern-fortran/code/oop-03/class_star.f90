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