%{
#include <stdio.h>
#include "parser.tab.h"

int yywrap(void)
{
    return 1;
}

char *string_buffer            = NULL;
int  string_buffer_size        = 0;
int  string_buffer_alloc_size  = 0;

void init_string_buffer(void)
{
    string_buffer            = NULL;
    string_buffer_alloc_size = 4;
    string_buffer            = calloc(string_buffer_alloc_size, sizeof(char));
    if (string_buffer == NULL) {
        fprintf(stderr, "おうっふ! mallocできない\n");
        exit(-1);
    }
    string_buffer_size       = 1;
    string_buffer[0]         = '\0';
}
void realocation_string_buffer(void)
{
    if (string_buffer_size <= string_buffer_alloc_size) {
        return;
    }

    while (string_buffer_size > string_buffer_alloc_size) {
        string_buffer_alloc_size *= 2;
    }

    string_buffer = realloc(string_buffer, string_buffer_alloc_size + 1);
    if (string_buffer == NULL) {
        fprintf(stderr, "おうっふ! remallocできない\n");
        exit(-1);
    }
}

%}

%x COMMENT
%x HTML_COMMENT
%x QUOTED_STRING
%x SINGLE_QUOTED_STRING

%%
[ \t]+  
\n      return LF;
\;      return SEMICOLON;
\{      return '{';
\}      return '}';
\^      return XOR;
print   return PRINT;

\" {
    init_string_buffer();
    BEGIN(QUOTED_STRING);
}
<QUOTED_STRING><<EOF>> {
    free(string_buffer);
    yyerror("おうっふ! 文字列リテラルがEOFまで閉じてないよ!");
    BEGIN(INITIAL);
}
<QUOTED_STRING>[^\\\"]+ {
    string_buffer_size += yyleng;
    realocation_string_buffer();
    strcat(string_buffer, yytext);
}
<QUOTED_STRING>\\[^\n] {
    string_buffer_size += yyleng;
    realocation_string_buffer();
    switch(yytext[yyleng-1]){
    case 't' :
               string_buffer[string_buffer_size - 2] = '\t';
               break;
    case 'n' :
               string_buffer[string_buffer_size - 2] = '\n';
               break;
    case 'r' :
               string_buffer[string_buffer_size - 2] = '\r';
               break;
    default  :
               string_buffer[string_buffer_size - 2] = yytext[yyleng-1];
               break;
    }
    string_buffer[string_buffer_size - 1] = '\0';
}
<QUOTED_STRING>\" {
    yylval.string = string_buffer;
    BEGIN(INITIAL);
    return STRING;
}

\' {
    init_string_buffer();
    BEGIN(SINGLE_QUOTED_STRING);
}
<SINGLE_QUOTED_STRING><<EOF>> {
    free(string_buffer);
    yyerror("おうっふ! 文字列リテラルがEOFまで閉じてないよ!");
    BEGIN(INITIAL);
}
<SINGLE_QUOTED_STRING>[^\\\']+ {
    string_buffer_size += yyleng;
    realocation_string_buffer();
    strcat(string_buffer, yytext);
}
<SINGLE_QUOTED_STRING>\\[^\n] {
    string_buffer_size += yyleng;
    realocation_string_buffer();
    switch(yytext[yyleng-1]){
    case '\'' :
                string_buffer_size--;
                string_buffer[string_buffer_size - 2] = '\'';
                break;
    default   :
                string_buffer[string_buffer_size - 3] = '\\';
                string_buffer[string_buffer_size - 2] = yytext[yyleng-1];
                break;
    }
    string_buffer[string_buffer_size - 1] = '\0';
}
<SINGLE_QUOTED_STRING>\' {
    yylval.string = string_buffer;
    BEGIN(INITIAL);
    return STRING;
}


"/*"                     BEGIN(COMMENT);
<COMMENT>[^*\n]*         
<COMMENT>[^*\n]*\n
<COMMENT>"*"+[^*/\n]*
<COMMENT>"*"+[^*/\n]*\n
<COMMENT><<EOF>>         yyerror("おうっふ! コメントがEOFまで閉じてないよ!");
<COMMENT>"*"+"/"         BEGIN(INITIAL);

"<!--"                        BEGIN(HTML_COMMENT);
<HTML_COMMENT>[^\-\n]*
<HTML_COMMENT>[^\-\n]*\n
<HTML_COMMENT>"-"+[^\->\n]*
<HTML_COMMENT>"-"+[^\->\n]*\n
<HTML_COMMENT><<EOF>>         yyerror("おうっふ! コメントがEOFまで閉じてないよ!");
<HTML_COMMENT>"-->"           BEGIN(INITIAL);

^REM.*$                    ;
(\#|"//"|\"\"\"|\'\'\'|:REM).*$ ;
.                  return     UNKNOWN;

%%
