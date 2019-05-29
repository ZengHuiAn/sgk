



OBJ=$(patsubst %.c, %.o, $(wildcard *.c))


all: $(OBJ)
	gcc -O -shared -fPIC -o network.so $(OBJ) -lpthread

%.o : %.c
	gcc -fpic -Wall -Wmissing-prototypes -c -o $@ $< -I. -I../lua-5.3.3/src


clean:
	rm *.o
