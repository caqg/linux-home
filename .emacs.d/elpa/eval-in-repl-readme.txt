eval-in-repl: Consistent eval interface for various REPLs

This package does what ESS does for R for various REPLs, including ielm.

Emacs Speaks Statistics (ESS) package has a nice function called
ess-eval-region-or-line-and-step, which is assigned to C-RET.
This function sends a line or a selected region to the corresponding
shell (R, Julia, Stata, etc) visibly. It also start up a shell if there is none.

This package along with a REPL/shell specific packages implement similar
work flow for various REPLs.

This file alone is not functional.
Also require the following depending on your needs.

eval-in-repl-ielm.el	   for Emacs Lisp (via ielm)
eval-in-repl-cider.el   for Clojure (via cider.el)
eval-in-repl-slime.el   for SLIME (via slime.el)
eval-in-repl-scheme.el  for Scheme (if used through scheme.el and cmuscheme.el)
eval-in-repl-python.el  for Python (via python.el)
eval-in-repl-shell.el   for shell mode (via essh.el)

See below for installation and an configuration example.
https://github.com/kaz-yos/eval-in-repl/
