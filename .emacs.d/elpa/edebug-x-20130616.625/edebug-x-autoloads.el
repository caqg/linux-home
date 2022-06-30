;;; edebug-x-autoloads.el --- automatically extracted autoloads  -*- lexical-binding: t -*-
;;
;;; Code:

(add-to-list 'load-path (directory-file-name
                         (or (file-name-directory #$) (car load-path))))


;;;### (autoloads nil "edebug-x" "edebug-x.el" (0 0 0 0))
;;; Generated autoloads from edebug-x.el

(autoload 'edebug-x-modify-breakpoint-wrapper "edebug-x" "\
Set a breakpoint from an Elisp file.
The current function that pointer is in will be instrumented if
not already. When called with a prefix argument a conditional
breakpoint is set.

\(fn ARG)" t nil)

(autoload 'edebug-x-evaluate-function "edebug-x" "\
Evaluate function on line.
This removes all breakpoints in this function." t nil)

(autoload 'edebug-x-show-data "edebug-x" "\
Display instrumented functions and edebug breakpoints.
Frame is split into two vertically showing the tabluated buffers
for each." t nil)

(autoload 'edebug-x-show-breakpoints "edebug-x" "\
Display breakpoints in a tabulated list buffer." t nil)

(autoload 'edebug-x-show-instrumented "edebug-x" "\
Display instrumented functions in a tabluated list buffer." t nil)

(autoload 'edebug-x-mode "edebug-x" "\
A minor mode that makes it easier to use Edebug

If called interactively, toggle `Edebug-X mode'.  If the prefix
argument is positive, enable the mode, and if it is zero or
negative, disable the mode.

If called from Lisp, toggle the mode if ARG is `toggle'.  Enable
the mode if ARG is nil, omitted, or is a positive number.
Disable the mode if ARG is a negative number.

The mode's hook is called both when the mode is enabled and when
it is disabled.

\(fn &optional ARG)" t nil)

(add-hook 'emacs-lisp-mode-hook 'edebug-x-mode)

(register-definition-prefixes "edebug-x" '("edebug-x-" "instrumented" "list-edebug-x-"))

;;;***

;; Local Variables:
;; version-control: never
;; no-byte-compile: t
;; no-update-autoloads: t
;; coding: utf-8
;; End:
;;; edebug-x-autoloads.el ends here
