%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
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

char *source_filename;
char *cmdline_source;
int cmdline_source_seek;
void parse_comandlines(int argc, char **argv)
{
    int ch;
    cmdline_source  = NULL;
    source_filename = NULL;

    if (argc > 1) {
        if (argv[1][0] != '-') {
            source_filename = argv[1];
            return;
        }
    }

    while ((ch = getopt(argc, argv, "e:")) != -1) {
       switch (ch) {
        case 'e':
                  cmdline_source = optarg;
                  cmdline_source_seek = 0;
                  break;
        case '?':
                  break;
        default:
                  break;
        }
    }
    return;
}

int cmdline_source_read(void *v, char *buf, int size)
{
    int cmdline_source_len = strlen(cmdline_source);
    char *current = cmdline_source + cmdline_source_seek;
    int copy_size;

    if (cmdline_source_len <= cmdline_source_seek) {
        return 0;
    }

    if (strlen(current) < size) {
        copy_size = strlen(current);
    } else {
        copy_size = size;
    }

    memcpy(buf, current, copy_size);
    buf[copy_size] = '\0';
    cmdline_source_seek += copy_size;
    return copy_size;
}

int main(int argc, char **argv)
{
    extern int yyparse(void);
    extern FILE *yyin;

    parse_comandlines(argc, argv);

    if (cmdline_source != NULL) {
        yyin = fropen(0, cmdline_source_read);
    } else if (source_filename != NULL) {
        FILE* fp = fopen(source_filename, "rb");
        if (!fp) {
            fprintf(stderr, "おふっふ! ファイルが開かない! '%s'", argv[1]);
            exit(-1);
        }
        char buf[BUFSIZ];
        while (fgets(buf, sizeof(buf), fp)) {
            if (strncmp(buf, "#!", 2) == 0) {
                yyin = fp;
            } else {
                fclose(fp);
                yyin = fopen(source_filename, "rb");
            }
            break;
        }
    }

    if (yyparse()) {
        exit(1);
    }
}
