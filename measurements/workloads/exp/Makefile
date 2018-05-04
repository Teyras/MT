all: exp_double exp_float

exp_double: exp.c
	gcc -Wall -o $@ $<

exp_float: exp.c
	gcc -DFLOAT -Wall -o $@ $<

clean:
	rm -f exp
	rm -f data.*.in
