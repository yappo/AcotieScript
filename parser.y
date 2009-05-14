%{
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
%}

%union 
{
    char *string;
}

%token LF
%token PRINT
%token <string> STRING
%token SEMICOLON
%token UNKNOWN
%token '{' '}'

%left   XOR
%left	PRINT

%%
program:
	lines
	;

lines:
	|
	lines block semicolon
	|
	lines line semicolon
	;

block:
	'{' lines '}'
	;

line:
	expression LF
	;

semicolon:
	|
	semicolon SEMICOLON
	;

expression:
	|
	expression term semicolon
	;

term:
	print
	|
	xor
	;

print:
	PRINT STRING { printf("おうっふー %s", $2); }
       ;

xor:
	STRING XOR STRING { fprintf(stderr, "おうっふ! xor わかんない＞＜\n"); exit(-1); }

%%

int
yyerror(char const *str)
{
    extern char *yytext;
    fprintf(stderr, "おうっふ! 構文エラー '%s'\n", yytext);
    return 0;
}

int main(int argc, char **argv)
{
    extern int yyparse(void);
    extern FILE *yyin;
 
    if (argc == 2) {
        FILE* fp = fopen(argv[1], "rb");
        if (!fp) {
            fprintf(stderr, "おふっふ! ファイルが開かない! '%s'", argv[1]);
            exit(-1);
        }
        char buf[BUFSIZ];
        while (fgets(buf, sizeof(buf), fp)) {
            if (strncmp(buf, "#!", 2) == 0) {
                yyin = fp;
            }
            break;
        }
    }

    if (yyparse()) {
        exit(1);
    }
}
