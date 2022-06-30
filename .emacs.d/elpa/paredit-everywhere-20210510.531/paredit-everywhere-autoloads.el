;;; paredit-everywhere-autoloads.el --- automatically extracted autoloads  -*- lexical-binding: t -*-
;;
;;; Code:

(add-to-list 'load-path (directory-file-name
                         (or (file-name-directory #$) (car load-path))))


;;;### (autoloads nil "paredit-everywhere" "paredit-everywhere.el"
;;;;;;  (0 0 0 0))
;;; Generated autoloads from paredit-everywhere.el

(autoload 'paredit-everywhere-mode "paredit-everywhere" "\
A cut-down version of paredit which can be used in non-lisp buffers.

This is a minor mode.  If called interactively, toggle the
`Paredit-Everywhere mode' mode.  If the prefix argument is
positive, enable the mode, and if it is zero or negative, disable
the mode.

If called from Lisp, toggle the mode if ARG is `toggle'.  Enable
the mode if ARG is nil, omitted, or is a positive number.
Disable the mode if ARG is a negative number.

To check whether the minor mode is enabled in the current buffer,
evaluate `paredit-everywhere-mode'.

The mode's hook is called both when the mode is enabled and when
it is disabled.

\(fn &optional ARG)" t nil)

(register-definition-prefixes "paredit-everywhere" '("paredit-everywhere-mode-map" "turn-off-paredit-everywhere-mode"))

;;;***

;; Local Variables:
;; version-control: never
;; no-byte-compile: t
;; no-update-autoloads: t
;; coding: utf-8
;; End:
;;; paredit-everywhere-autoloads.el ends here
