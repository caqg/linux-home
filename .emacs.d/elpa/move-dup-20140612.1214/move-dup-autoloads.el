;;; move-dup-autoloads.el --- automatically extracted autoloads
;;
;;; Code:


;;;### (autoloads (global-move-dup-mode move-dup-mode) "move-dup"
;;;;;;  "move-dup.el" (21402 25061 798943 455000))
;;; Generated autoloads from move-dup.el

(autoload 'move-dup-mode "move-dup" "\
Minor mode for Eclipse-like moving and duplicating lines or
rectangles with default key bindings.

The default key bindings are:

\([M-up] . md/move-lines-up)
\([M-down] . md/move-lines-down)
\([C-M-up] . md/duplicate-up)
\([C-M-down] . md/duplicate-down)

\(fn &optional ARG)" t nil)

(defvar global-move-dup-mode nil "\
Non-nil if Global-Move-Dup mode is enabled.
See the command `global-move-dup-mode' for a description of this minor mode.
Setting this variable directly does not take effect;
either customize it (see the info node `Easy Customization')
or call the function `global-move-dup-mode'.")

(custom-autoload 'global-move-dup-mode "move-dup" nil)

(autoload 'global-move-dup-mode "move-dup" "\
Toggle Move-Dup mode in all buffers.
With prefix ARG, enable Global-Move-Dup mode if ARG is positive;
otherwise, disable it.  If called from Lisp, enable the mode if
ARG is omitted or nil.

Move-Dup mode is enabled in all buffers where
`move-dup-on' would do it.
See `move-dup-mode' for more information on Move-Dup mode.

\(fn &optional ARG)" t nil)

;;;***

;;;### (autoloads nil nil ("move-dup-pkg.el") (21402 25062 73798
;;;;;;  698000))

;;;***

(provide 'move-dup-autoloads)
;; Local Variables:
;; version-control: never
;; no-byte-compile: t
;; no-update-autoloads: t
;; coding: utf-8
;; End:
;;; move-dup-autoloads.el ends here
