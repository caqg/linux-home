;;; relative-line-numbers-autoloads.el --- automatically extracted autoloads
;;
;;; Code:


;;;### (autoloads (global-relative-line-numbers-mode relative-line-numbers-mode)
;;;;;;  "relative-line-numbers" "relative-line-numbers.el" (21523
;;;;;;  52466 493190 146000))
;;; Generated autoloads from relative-line-numbers.el

(autoload 'relative-line-numbers-mode "relative-line-numbers" "\
Display relative line numbers on the left margin.

Toggle Relative Line Numbers on or off.

With a prefix argument ARG, enable Relative Line Numbers mode if ARG
is positive, and disable it otherwise. If called from Lisp, enable the
mode if ARG is omitted or nil, and toggle it if ARG is `toggle'.

\(fn &optional ARG)" t nil)

(defvar global-relative-line-numbers-mode nil "\
Non-nil if Global-Relative-Line-Numbers mode is enabled.
See the command `global-relative-line-numbers-mode' for a description of this minor mode.
Setting this variable directly does not take effect;
either customize it (see the info node `Easy Customization')
or call the function `global-relative-line-numbers-mode'.")

(custom-autoload 'global-relative-line-numbers-mode "relative-line-numbers" nil)

(autoload 'global-relative-line-numbers-mode "relative-line-numbers" "\
Toggle Relative-Line-Numbers mode in all buffers.
With prefix ARG, enable Global-Relative-Line-Numbers mode if ARG is positive;
otherwise, disable it.  If called from Lisp, enable the mode if
ARG is omitted or nil.

Relative-Line-Numbers mode is enabled in all buffers where
`(lambda nil (unless (minibufferp) (relative-line-numbers-mode)))' would do it.
See `relative-line-numbers-mode' for more information on Relative-Line-Numbers mode.

\(fn &optional ARG)" t nil)

;;;***

;;;### (autoloads nil nil ("relative-line-numbers-pkg.el") (21523
;;;;;;  52466 647454 99000))

;;;***

(provide 'relative-line-numbers-autoloads)
;; Local Variables:
;; version-control: never
;; no-byte-compile: t
;; no-update-autoloads: t
;; coding: utf-8
;; End:
;;; relative-line-numbers-autoloads.el ends here
