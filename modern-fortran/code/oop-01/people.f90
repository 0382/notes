module people_module
    implicit none
    private
    integer, parameter :: people_name_len = 32

    public :: People
    type :: People
        character(len=people_name_len) :: name
        contains
            procedure :: init => init_people
            procedure :: greet => people_greet
    end type People
contains
    subroutine init_people(this, name)
        class(People), intent(inout) :: this
        character(len=*), intent(in) :: name
        this%name = name
    end subroutine init_people
    
    subroutine people_greet(this, name)
        class(People), intent(in) :: this
        character(len=*), intent(in) :: name
        print "(A,'.')", "Hello "//trim(name)//"! My name is "//trim(this%name)
    end subroutine people_greet
end module people_module

program test
    use people_module
    implicit none
    type(People) :: lihua
    call lihua%init("Li Hua")
    call lihua%greet("Alice")
    ! print '(A)', lihua%name ! 不能访问
end program test