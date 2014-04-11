;;; pp+-autoloads.el --- automatically extracted autoloads
;;
;;; Code:


;;;### (autoloads (pp-eval-expression pp-eval-expression-print-level
;;;;;;  pp-eval-expression-print-length) "pp+" "pp+.el" (21319 38693
;;;;;;  391947 955000))
;;; Generated autoloads from pp+.el

(defvar pp-eval-expression-print-length nil "\
*Value for `print-length' while printing value in `pp-eval-expression'.
A value of nil means no limit.")

(custom-autoload 'pp-eval-expression-print-length "pp+" t)

(defvar pp-eval-expression-print-level nil "\
*Value for `print-level' while printing value in `pp-eval-expression'.
A value of nil means no limit.")

(custom-autoload 'pp-eval-expression-print-level "pp+" t)

(autoload 'pp-eval-expression "pp+" "\
Evaluate Emacs-Lisp sexp EXPRESSION, and pretty-print its value.
Add the value to the front of the variable `values'.
With a prefix arg, insert the value into the current buffer at point.
 With a negative prefix arg, if the value is a string, then insert it
 into the buffer without double-quotes (`\"').
With no prefix arg:
 If the value fits on one line (frame width) show it in the echo area.
 Otherwise, show the value in buffer `*Pp Eval Output*'.

This command respects options user `pp-eval-expression-print-length',
`pp-eval-expression-print-level', and
`eval-expression-debug-on-error'.

Emacs-Lisp mode completion and indentation bindings are in effect.

\(fn EXPRESSION &optional INSERT-VALUE)" t nil)

;;;***

;;;### (autoloads nil nil ("pp+-pkg.el") (21319 38693 500146 813000))

;;;***

(provide 'pp+-autoloads)
;; Local Variables:
;; version-control: never
;; no-byte-compile: t
;; no-update-autoloads: t
;; coding: utf-8
;; End:
;;; pp+-autoloads.el ends here
