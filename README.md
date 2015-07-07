#i_rewriter

##Usage
```
  $ i_rewriter RUBY_EXPRESSION file
```
i_rewriter iterates through each line of file, evaluating RUBY_EXPRESSION in a block whose arguments are

  - index : current line index starting at 0
  - line : the current line

Each argument will be replaced in-place, with whatever your RUBY_EXPRESSION evaluates to.

#Example:

```bash
  $ i_rewriter ‘index == 0 ? “prepended text\n” + line : line’ myfile
```
will prepend a line with “prepended text” to `myfile`.

##Warranties:
None. Use at your own peril. GPL2 applies. `i_rewriter` may corrupt your file.



