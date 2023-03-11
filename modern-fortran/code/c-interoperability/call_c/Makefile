test.exe : main.o test.o
	gfortran main.o test.o -o test.exe

main.o : main.f90
	gfortran -c main.f90 -o main.o

test.o : test.c
	gcc -c test.c -o test.o