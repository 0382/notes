module People_m
    implicit none
    private
    type, public :: People
        character(len=32), private :: name
    contains
        procedure, pass(this) :: set_name
        procedure, pass(self) :: greet
        procedure, nopass :: max_name_len
    end type
contains
    subroutine set_name(name, this)
        character(len=*), intent(in) :: name
        class(People), intent(inout) :: this
        this%name = name
    end subroutine

    subroutine greet(other, self)
        class(People), intent(in) :: self, other
        print '(A,".")', "Hello "//trim(other%name)//"! My name is "//trim(self%name)
    end subroutine

    integer function max_name_len()
        max_name_len = 32
    end function
end module People_m

program test
    use People_m
    implicit none
    type(People) :: alice, diana
    call alice%set_name("Alice")
    call diana%set_name("Diana")
    call alice%greet(diana)
    print *, alice%max_name_len()
end program test
