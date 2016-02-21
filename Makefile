all:
	yacc zen.y
	gcc -o zen y.tab.c

clean:
	rm -f zen y.tab.c
