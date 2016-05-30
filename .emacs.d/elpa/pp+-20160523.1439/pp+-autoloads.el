;;; pp+-autoloads.el --- automatically extracted autoloads
;;
;;; Code:
(add-to-list 'load-path (directory-file-name (or (file-name-directory #$) (car load-path))))

;;;### (autoloads nil "pp+" "pp+.el" (22341 18822 115978 674000))
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
Read an Emacs-Lisp sexp, evaluate it, and pretty-print its value.
Add the value to the front of the variable `values'.
With no prefix arg, respect `pp-max-tooltip-size'.  If a tooltip is
 not used then if the value fits on one line (frame width) show it in
 the echo area.  Otherwise, show it in buffer `*Pp Eval Output*'.
With a zero prefix arg, this swaps the use of a tooltip according to
 `pp-max-tooltip-size': if that option is nil then a tooltip is used,
 and if non-nil a tooltip is not used.
With a non-zero prefix arg, insert the value into the current buffer
 at point.  If the prefix arg is negative and the value is a string
 then insert it into the buffer without double-quotes (`\"').

For Emacs prior to 24.4, the command has no support for a tooltip.
A zero prefix arg is then treated the same as a positive prefix arg.

Non-interactively:
 * Non-nil SWAP-TOOLTIP means swap the use of a tooltip.
 * Non-nil INSERT-VALUE is treated like a non-zero raw prefix arg:
   insert the value in the buffer (sans quotes if negative).

This command respects user options `pp-eval-expression-print-length',
`pp-eval-expression-print-level', `pp-max-tooltip-size', and
`eval-expression-debug-on-error'.

Emacs-Lisp mode completion and indentation bindings are in effect.

\(fn EXPRESSION &optional INSERT-VALUE SWAP-TOOLTIP)" t nil)

(autoload 'pp-eval-last-sexp "pp+" "\
Run `pp-eval-expression' on sexp before point.
With a zero prefix arg, this swaps the use of a tooltip according to
 `pp-max-tooltip-size': if that option is nil then a tooltip is used,
 and if non-nil a tooltip is not used.
With a non-zero prefix arg, pretty-print the value into the current
 buffer.
Ignores leading comment characters.

For Emacs prior to 24.4, the command has no support for a tooltip.
A zero prefix arg is then treated the same as a positive prefix arg.

Non-interactively:
 * Non-nil SWAP-TOOLTIP means swap the use of a tooltip.
 * Non-nil INSERT-VALUE is treated like a non-zero prefix arg:
   insert the value in the buffer.

This command respects user options `pp-eval-expression-print-length',
`pp-eval-expression-print-level', `pp-max-tooltip-size', and
`eval-expression-debug-on-error'.

\(fn INSERT-VALUE &optional SWAP-TOOLTIP)" t nil)

(autoload 'pp-display-expression "pp+" "\
Prettify and show EXPRESSION, respecting option `pp-max-tooltip-size'.
If `pp-max-tooltip-size' is non-`nil' then show it with a tooltip.
Else, if there is room then show it in the echo-area.
Else show it in buffer OUT-BUFFER-NAME.

\(fn EXPRESSION OUT-BUFFER-NAME)" nil nil)

;;;***

;; Local Variables:
;; version-control: never
;; no-byte-compile: t
;; no-update-autoloads: t
;; End:
;;; pp+-autoloads.el ends here
