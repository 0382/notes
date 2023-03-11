module array_m
    use iso_fortran_env
    implicit none

    type, abstract :: AbstractArray
    contains
        procedure(array_size), pass(this), deferred :: size
    end type

    abstract interface
        integer function array_size(this)
            import :: AbstractArray
            class(AbstractArray), intent(in) :: this
        end function
    end interface

    type, abstract, extends(AbstractArray) :: Real64Array
    contains
        procedure, nopass :: kind => real64_arr_data_kind
    end type

    type, extends(Real64Array) :: MatrixXd
        real(kind=real64), dimension(:,:), allocatable :: m_data
    contains
        procedure :: size => matxd_size
    end type
contains
    integer function real64_arr_data_kind()
        real64_arr_data_kind = real64
    end function

    integer function matxd_size(this)
        class(MatrixXd), intent(in) :: this
        matxd_size = size(this%m_data)
    end function
end module array_m

program test
    use array_m
    implicit none
    type(MatrixXd) :: ma
    allocate(ma%m_data(10, 10))
    print *, ma%size()
    print *, ma%kind()
end program test