module veci_m
    implicit none
    private

    public veci
    type :: veci
        integer, dimension(:), allocatable :: m_data
    contains
        procedure :: dtio_write_veci
        generic :: write(formatted) => dtio_write_veci
    end type veci
contains

subroutine dtio_write_veci(this, unit, iotype, v_list, iostat, iomsg)
    class(veci), intent(in) :: this
    integer, intent(in) :: unit
    character(len=*), intent(in) :: iotype
    integer, intent(in) :: v_list(:)
    integer, intent(out) :: iostat
    character(len=*), intent(inout) :: iomsg
    character(len=64) :: buffer
    integer :: i, start, end
    if(iotype == 'DTsummary' .or. size(v_list) == 0) then
        write(unit=buffer, fmt=*) size(this%m_data)
        buffer = adjustl(buffer)
        write(unit=unit, fmt='(A)', iostat=iostat, iomsg=iomsg) "veci("//trim(buffer)//"-elements)"
    else if(iotype == 'DThead') then
        write(unit=unit, fmt='(A,$)', iostat=iostat, iomsg=iomsg) "veci("
        end = min(v_list(1), size(this%m_data))
        do i = 1, end
            write(unit=buffer, fmt=*) this%m_data(i)
            buffer = adjustl(buffer)
            write(unit=unit, fmt='(A,$)', iostat=iostat, iomsg=iomsg) trim(buffer)//","
        end do
        write(unit=unit, fmt='(A)', iostat=iostat, iomsg=iomsg) "...)"
    else if(iotype == 'DTtail') then
        write(unit=unit, fmt='(A,$)', iostat=iostat, iomsg=iomsg) "veci(..."
        end = size(this%m_data)
        start = max(1, end - v_list(1))
        do i = start, end
            write(unit=buffer, fmt=*) this%m_data(i)
            buffer = adjustl(buffer)
            write(unit=unit, fmt='(A,$)', iostat=iostat, iomsg=iomsg) ","//trim(buffer)
        end do
        write(unit=unit, fmt='(A)', iostat=iostat, iomsg=iomsg) ")"
    else if(iotype == 'DTcenter') then
        write(unit=unit, fmt='(A,$)', iostat=iostat, iomsg=iomsg) "veci(..."
        start = max(1, v_list(1))
        end = min(v_list(2), size(this%m_data))
        do i = start, end
            write(unit=buffer, fmt=*) this%m_data(i)
            buffer = adjustl(buffer)
            write(unit=unit, fmt='(A,$)', iostat=iostat, iomsg=iomsg) ","//trim(buffer)
        end do
        write(unit=unit, fmt='(A)', iostat=iostat, iomsg=iomsg) ",...)"
    else
        write(unit=unit, fmt=*, iostat=iostat, iomsg=iomsg) this%m_data
    end if
end subroutine

end module

program test
    use veci_m
    implicit none
    type(veci) :: v
    integer :: i
    allocate(v%m_data(100))
    do i = 1, 100
        v%m_data(i) = i
    end do
    print '(DT"summary")', v
    print '(DT"head"(10))', v
    print '(DT"tail"(10))', v
    print '(DT"center"(30, 40))', v
end program test