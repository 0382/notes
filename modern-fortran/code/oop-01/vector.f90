module vector
    implicit none
    private

    public :: veci
    type :: veci
        private
        integer, dimension(:), allocatable :: m_data
        integer :: m_size
        integer :: m_capacity
    contains
        procedure :: at => veci_at
        procedure :: front => veci_front
        procedure :: back => veci_back
        procedure :: data => veci_data
        procedure :: empty => veci_empty
        procedure :: size => veci_size
        procedure :: max_size => veci_max_size
        procedure :: capcity => veci_capacity
        procedure :: reserve => veci_reserve
        procedure :: shrink_to_fit => veci_shrink_to_fit
        procedure :: clear => veci_clear
        procedure :: resize => veci_resize
        procedure :: push_back => veci_push_back
        procedure :: swap => veci_swap
        procedure :: print => veci_print
        final :: destroy_veci
    end type veci
    
    interface veci
        procedure :: make_veci_empty
        procedure :: make_veci_raw
        procedure :: make_veci_filled
    end interface
contains
    function make_veci_empty() result(ans)
        type(veci) :: ans
        ans%m_size = 0
        allocate(ans%m_data(1))
        ans%m_capacity = 1
    end function make_veci_empty

    function make_veci_raw(n) result(ans)
        integer, intent(in) :: n
        type(veci) :: ans
        ans%m_size = n
        ans%m_capacity = n
        allocate(ans%m_data(n))
    end function make_veci_raw

    function make_veci_filled(n, val) result(ans)
        integer, intent(in) :: n, val
        type(veci) :: ans
        ans%m_size = n
        ans%m_capacity = n
        allocate(ans%m_data(n))
        ans%m_data = val
    end function make_veci_filled

    subroutine destroy_veci(this)
        type(veci), intent(inout) :: this
        if(allocated(this%m_data)) deallocate(this%m_data)
    end subroutine

    ! ----- 元素访问 -----
    
    function veci_at(this, idx) result(ans)
        class(veci), intent(in) :: this
        integer, intent(in) :: idx
        integer :: ans
        if(idx <= 0 .or. idx >= this%m_size) error stop "veci out of range"
        ans = this%m_data(idx)
    end function veci_at

    function veci_front(this) result(ans)
        class(veci), intent(in) :: this
        integer :: ans
        if(this%m_size == 0) error stop "veci out of range"
        ans = this%at(1)
    end function veci_front

    function veci_back(this) result(ans)
        class(veci), intent(in) :: this
        integer :: ans
        if(this%m_size == 0) error stop "veci out of range"
        ans = this%at(this%m_size)
    end function veci_back

    function veci_data(this) result(ans)
        class(veci), intent(in) :: this
        integer, dimension(:), pointer :: ans
        allocate(ans(this%m_size))
        ans(:) = this%m_data(1:this%m_size)
    end

    ! ----- 容量 -----
    
    function veci_empty(this) result(ans)
        class(veci), intent(in) :: this
        logical :: ans
        ans = this%m_size == 0
    end function veci_empty

    function veci_size(this) result(ans)
        class(veci), intent(in) :: this
        integer :: ans
        ans = this%m_size
    end function veci_size

    function veci_max_size(this) result(ans)
        class(veci), intent(in) :: this
        integer :: ans
        ans = huge(this%m_size)
    end function veci_max_size

    function veci_capacity(this) result(ans)
        class(veci), intent(in) :: this
        integer :: ans
        ans = this%m_capacity
    end function veci_capacity

    subroutine veci_reserve(this, n)
        class(veci), intent(inout) :: this
        integer, intent(in) :: n
        integer, dimension(:), allocatable :: buffer
        if(n <= this%m_capacity) return
        call move_alloc(this%m_data, buffer)
        allocate(this%m_data(n))
        this%m_data(1:this%m_size) = buffer(1:this%m_size)
        deallocate(buffer)
    end subroutine veci_reserve

    subroutine veci_shrink_to_fit(this)
        class(veci), intent(inout) :: this
        integer, dimension(:), allocatable :: buffer
        if(this%m_size == this%m_capacity) return
        call move_alloc(this%m_data, buffer)
        allocate(this%m_data(this%m_size))
        this%m_data = buffer(1:this%m_size)
        deallocate(buffer)
    end subroutine veci_shrink_to_fit

    ! ----- 修改器 -----

    subroutine veci_clear(this)
        class(veci), intent(inout) :: this
        this%m_size = 0
    end subroutine

    subroutine veci_resize(this, n, val)
        class(veci), intent(inout) :: this
        integer, intent(in) :: n
        integer, intent(in), optional :: val
        integer, dimension(:), allocatable :: buffer
        integer :: filled_val
        filled_val = 0
        if(present(val)) filled_val = val
        if(n <= this%m_size) then
        else if(n <= this%m_capacity) then
            this%m_data(this%m_size+1:n) = filled_val
        else
            call move_alloc(this%m_data, buffer)
            allocate(this%m_data(n))
            this%m_data(1:this%m_size) = buffer(1:this%m_size)
            this%m_data(this%m_size+1:n) = filled_val
            this%m_capacity = n
        end if
        this%m_size = n
    end subroutine veci_resize

    subroutine veci_swap(this, other)
        class(veci), intent(inout) :: this
        type(veci), intent(inout) :: other
        integer :: temp
        integer, dimension(:), allocatable :: buffer
        temp = this%m_size
        this%m_size = other%m_size
        other%m_size = temp
        temp = this%m_capacity
        this%m_capacity = other%m_capacity
        other%m_capacity = temp
        call move_alloc(this%m_data, buffer)
        call move_alloc(other%m_data, this%m_data)
        call move_alloc(buffer, other%m_data)
    end subroutine veci_swap

    subroutine veci_push_back(this, val)
        class(veci), intent(inout) :: this
        integer, intent(in) :: val
        integer, dimension(:), allocatable :: buffer
        if(this%m_size == this%m_capacity) then
            call move_alloc(this%m_data, buffer)
            this%m_capacity = 2 * this%m_capacity
            allocate(this%m_data(this%m_capacity))
            this%m_data(1:this%m_size) = buffer(:)
            deallocate(buffer)
        end if
        this%m_size = this%m_size + 1
        this%m_data(this%m_size) = val
    end subroutine

    subroutine veci_print(this)
        class(veci), intent(inout) :: this
        integer :: i
        print '(A,$)', "["
        do i = 1, this%m_size - 1
            print '(I5,",",$)', this%m_data(i)
        end do
        print '(I5,"]")', this%m_data(this%m_size)
    end subroutine
end module

program test
    use vector
    implicit none
    type(veci) :: va, vb
    integer :: i
    va = veci()
    call va%reserve(20)
    vb = veci(10, 100)
    do i = 1,20
        call va%push_back(i*i)
    end do
    call va%swap(vb)
    call va%print()
    call vb%print()
end program test