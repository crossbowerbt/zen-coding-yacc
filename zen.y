%{

#include <stdio.h>
#include <ctype.h>
#include <string.h>

#define BUFSIZE 1024 * 4

char buffer[BUFSIZE];
int i;

int yylex(void);
int yyerror(const char *s);

%}

%code requires {
    struct tag_t {
        char *open;
        char *close;
    };
}

%union {
  char * string;
  int num;
  struct tag_t tag;
}

%start s
%token STRING NUM

%type <string> s e r id class attr STRING
%type <num> NUM
%type <tag> tag

%%

 /* first production: just output the HTML code */

s : e                              { printf("%s", $1); };

 /* expressions: concatenate repeatable block into a list */

e : r e                            { snprintf(buffer, BUFSIZE, "%s%s", $1, $2);
                                     $$ = strdup(buffer); };
  | /* empty */                    { $$ = ""; };

 /* repeatable blocks: are expressions that can be repeated */

r : NUM '*' r                      { if(strlen($3) * $1 < BUFSIZE) {
                                         buffer[0] = '\0';
                                         for(i = 0; i < $1; i++) {
					   strcat(buffer, $3);
					 }
					 $$ = strdup(buffer);
                                     } else {
                                         $$ = $3;
                                     } };
  | tag '{' STRING '}'             { snprintf(buffer, BUFSIZE, "%s\n%s\n%s\n", $1.open, $3, $1.close);
                                     $$ = strdup(buffer); };
  | tag '>' e '<'                  { snprintf(buffer, BUFSIZE, "%s\n%s%s\n", $1.open, $3, $1.close);
                                     $$ = strdup(buffer); };
  | tag                            { snprintf(buffer, BUFSIZE, "%s%s\n", $1.open, $1.close);
                                     $$ = strdup(buffer); };

 /* tags: HTML tags composed by an opening part and a closing part */

tag : STRING id class attr         { snprintf(buffer, BUFSIZE,
					      "<%s%s%s%s%s%s%s>",
					      $1,
					      $2[0] != '\0' ? " " : "",
					      $2,
					      $3[0] != '\0' ? " " : "",
					      $3,
					      $4[0] != '\0' ? " " : "",
					      $4);
                                     $$.open = strdup(buffer);
				     snprintf(buffer, BUFSIZE, "</%s>", $1);
                                     $$.close = strdup(buffer); };
    | id class attr                { snprintf(buffer, BUFSIZE,
					      "<div%s%s%s%s%s%s>",
					      $1[0] != '\0' ? " " : "",
					      $1,
					      $2[0] != '\0' ? " " : "",
					      $2,
					      $3[0] != '\0' ? " " : "",
					      $3);
                                     $$.open = strdup(buffer);
                                     $$.close = "</div>"; };

 /* id: the id of a tag */

id : '#' STRING                    { snprintf(buffer, BUFSIZE, "id=\"%s\"", $2);
                                     $$ = strdup(buffer); };
   | /* empty */                   { $$ = ""; };

 /* classes: the classes of a tag */

class : '.' STRING                 { snprintf(buffer, BUFSIZE, "class=\"%s\"", $2);
                                     $$ = strdup(buffer); };
      | /* empty */                { $$ = ""; };

 /* attributes: attributes of a tag */

attr : '$' STRING '=' STRING attr  { snprintf(buffer, BUFSIZE,
					      "%s=\"%s\"%s%s",
					      $2,
					      $4,
					      $5[0] != '\0' ? " " : "",
					      $5);
                                     $$ = strdup(buffer); };
     | '$' STRING attr             { $$ = $2; };
     | /* empty */                 { $$ = ""; };

%%

int yylex()
{
  static int levels_down = 0;
  static int in_parens = 0;
  static int in_quotes = 0;
    
  char str[1024];
  char c;

  int num;
  int i;

  do {
    c = getchar();

    if(in_parens && c != '}') { /* literal STRING in parentesis */

      str[0] = c;
	
      for(i = 1; i < 1024 - 1; i++) {
	c = getchar();

	if(c != EOF && c != '}')
	  str[i] = c;
	else
	  break;
      }

      str[i] = '\0';

      if(c == '}')
	ungetc(c, stdin);
      
      yylval.string = strdup(str);
      return STRING;
      
    }

    if(in_quotes && c != '"') { /* literal STRING in quotes */

      str[0] = c;
	
      for(i = 1; i < 1024 - 1; i++) {
	c = getchar();

	if(c != EOF && c != '"')
	  str[i] = c;
	else
	  break;
      }

      str[i] = '\0';

      in_quotes = 0;

      yylval.string = strdup(str);
      return STRING;
      
    }

    switch(c) {

      /* catch various symbols */

    case '>': levels_down++; goto symbol_char;
    case '<': levels_down--; goto symbol_char;
    case '{': in_parens = 1; goto symbol_char;
    case '}': in_parens = 0; goto symbol_char;
    case '#':
    case '.':
    case '$':
    case '=':
    case '*':
    symbol_char:
      return c;      

      /* skip spaces */

    case ' ':
    case '\n':
    case '\r':
      continue;

      /* quoted string */
      
    case '"':
      in_quotes = 1;
      continue;
    }
    
    if(isalpha(c)) { /* STRING */
      
      str[0] = c;
	
      for(i = 1; i < 1024 - 1; i++) {
	c = getchar();

	if(isalnum(c))
	  str[i] = c;
	else
	  break;

	/*
	switch(c) {
	case '>':
	case '<':
	case '{':
	case '}':
	case '#':
	case '.':
	case '$':
	case '=':
	case '*':
	case ' ':
	case '\n':
	case '\r':	  
	  break;
	default:
	  str[i] = c;
	}*/
      }

      str[i] = '\0';
      
      ungetc(c, stdin);
      
      yylval.string = strdup(str);
      return STRING;
      
    }

    if(isdigit(c)) { /* NUM */

      num = c - '0';
	
      for(i = 1; i < 1024 - 1; i++) {
	c = getchar();

	if(isdigit(c))
	  num = num * 10 + (c - '\0');
	else
	  break;
      }

      ungetc(c, stdin);
      
      yylval.num = num;
      return NUM;
      
    }
    
  } while (c != EOF);

  if(c == EOF && levels_down > 0) {
    levels_down --;
    return '<';
  }

  return 0;
}

int yyerror(const char *s)
{
  fprintf(stderr, "%s\n", s);
}

int main(int argc, char *argv[])
{
  yyparse();
}
