all: _bsearch _exp _gray _sort

_bsearch: bsearch
	cd bsearch && $(MAKE) && ./gendata.sh 32768 4096 && ./gendata.sh 8192 1024

_exp: exp
	cd exp && $(MAKE) && ./gendata.sh 16384

_gray: gray
	cd gray && $(MAKE) && ./gendata.sh 524288 && ./gendata.sh 131072

_sort: sort
	cd sort && $(MAKE) && ./gendata.sh 131072 && ./gendata.sh 16384

