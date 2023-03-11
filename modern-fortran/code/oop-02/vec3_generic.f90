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
    v = v + 1 ! 当然你还是可以用原来的函数名
    print *, v%m_data
    v = v + 2.0d0
    print *, v%m_data
    v = v + v
    print *, v%m_data
end program test