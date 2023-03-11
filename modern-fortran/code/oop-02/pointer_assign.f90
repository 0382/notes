module veci_m
    implicit none
    private

    public :: veci
    type :: veci
        integer, dimension(:), pointer :: data => null()
    contains
        procedure :: assign_veci
        generic :: assignment(=) => assign_veci
        final :: destroy_veci
    end type veci
contains
    subroutine assign_veci(this, other)
        class(veci), intent(inout) :: this
        type(veci), intent(in) :: other
        if(associated(this%data)) then
            deallocate(this%data)
        end if
        allocate(this%data(size(other%data)))
        this%data(:) = other%data(:)
    end subroutine
    subroutine destroy_veci(this)
        type(veci), intent(inout) :: this
        if(associated(this%data)) deallocate(this%data)
    end subroutine destroy_veci
end module

program test
    use veci_m
    implicit none
    block
        type(veci) :: v1, v2
        allocate(v1%data(10))
        v1%data = 3
        v2 = v1
        deallocate(v1%data)
        print *, associated(v1%data)
        print *, associated(v2%data)
        print *, v2%data
    end block
end program test
