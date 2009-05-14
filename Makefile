all:
	yacc -b parser -dv parser.y
	lex -o lex.c lex.l
	gcc -O2 -o acotiescript parser.tab.c lex.c
clean:
	rm parser.tab.[ch] lex.c parser.output acotiescript
