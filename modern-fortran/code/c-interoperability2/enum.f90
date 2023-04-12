module test_enum
    implicit none
    
    enum, bind(c)
        enumerator :: RED
        enumerator :: GREEN = 100
        enumerator :: YELLOW
    end enum

contains
    
end module test_enum

program test
    use test_enum
    implicit none
    integer :: color
    color = RED
    print *, color
    print *, YELLOW
end program test