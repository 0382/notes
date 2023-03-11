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