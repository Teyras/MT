all: _bsearch _exp _gray _sort

_bsearch: bsearch
	cd bsearch && $(MAKE) && ./gendata.sh 16384 2048

_exp: exp
	cd exp && $(MAKE) && ./gendata.sh 16384

_gray: gray
	cd gray && $(MAKE) && ./gendata.sh 32768

_sort: sort
	cd sort && $(MAKE) && ./gendata.sh 16384

