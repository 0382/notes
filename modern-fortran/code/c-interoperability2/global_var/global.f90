module global_mod
    use iso_c_binding
    implicit none
    private
    
    integer(c_int), bind(c) :: global_count

contains
    integer(c_int) function inc() bind(c)
        global_count = global_count + 1
        inc = global_count
    end function inc
end module global_mod