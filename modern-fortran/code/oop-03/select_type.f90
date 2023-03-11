module people_m
    implicit none
    private
    integer, parameter :: max_name_len = 32
    type, public :: People
        character(len=max_name_len), private :: name
    contains
        procedure :: set_name
        procedure :: greet
    end type

    type, public, extends(People) :: Student
        real, private :: GPA
    contains
        procedure :: greet => stu_greet
    end type
contains
    subroutine set_name(this, name)
        class(People), intent(inout) :: this
        character(len=*), intent(in) :: name
        this%name = name
    end subroutine

    subroutine greet(this)
        class(People), intent(in) :: this
        print '(A,".")', "Hello, my name is "//trim(this%name)
    end subroutine

    subroutine stu_greet(this)
        class(Student), intent(in) :: this
        print '(A,".")', "Hello, I'm a student, my name is "//trim(this%name)
    end subroutine
end module people_m

program test
    use people_m
    implicit none
    class(People), allocatable :: alice
    allocate(Student :: alice)
    call call_people(alice)
    deallocate(alice)
    allocate(People :: alice)
    call call_people(alice)
contains
    subroutine call_people(p)
        class(People), intent(in) :: p
        select type (x => p)
            type is (People)
                print *, "called a people"
            type is (Student)
                print *, "called a student"
            ! class is (xxx) ! 使用 class 选择也是可以的，比如对于复杂的继承链
            class default
                error stop "unrecognized class"
        end select
    end subroutine
end program test