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