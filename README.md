# zen-coding-yacc
A command line tool to expand HTML code from very sintetic string (similar to Emmet - http://www.emmet.io/)

# why?
Emmet (http://www.emmet.io/) is distributed as an editor plugin.
This is convenient, but on some systems is easier to use a command line tool, indipendent from the installed text editor.

In addition I wanted to see if it was possible to write the tool using only yacc/lex and gcc.
Apparently I was able to code the essential features of Emmet using ~250 lines of code.
A not so bad result considering that the Sublime Text version of Emmet is ~800 lines of code and the Emacs version is ~4000 lines of code.

Clearly I do not have a text editor to interface with, so it was a little easier for me to write a short program.
Nevertheless it was a very good approach to learning yacc, and the tool works satisfactorily.

# usage
The syntax is a little different from Emmet.
An example that (hopefully) illustrate most of it is the following (many spaces can be omitted, I added them for clarity):
```
.header > h1 { Title } < 2 * #holder > 3 * p { paragraph text } < .footer > a$href="index.php$name=foo"
```

The expanded HTML code is the following:
```html
  <div class="header">
    <h1>Title</h1>
  </div>

  <div id="holder">
    <p>paragraph text</p>
    <p>paragraph text</p>
    <p>paragraph text</p>
  </div>

  <div id="holder">
    <p>paragraph text</p>
    <p>paragraph text</p>
    <p>paragraph text</p>
  </div>

  <div class="footer">
    <a href="index.php" name="foo"></a>
  </div>
```

The emmet syntax is cleaner at the moment, but I plan to improve the tool in the future.

The main differences with emmet are:
* we use '>' instead of '^' to go up a level
* we use spaces instead of '+' to place tags on the same level
* we use '$attr1=value$attr2=value2$...' instead of '[attr1="value1" attr2="value2" ...]'
* to repeat a block several times we use a prefix 'num * block', instead emmet uses a suffix 'block * num'

To see what you miss using this tool see the emmet syntax documentation: http://docs.emmet.io/abbreviations/syntax/
