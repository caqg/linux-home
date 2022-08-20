;;; ruby-test-mode-autoloads.el --- automatically extracted autoloads  -*- lexical-binding: t -*-
;;
;;; Code:

(add-to-list 'load-path (directory-file-name
                         (or (file-name-directory #$) (car load-path))))


;;;### (autoloads nil "ruby-test-mode" "ruby-test-mode.el" (0 0 0
;;;;;;  0))
;;; Generated autoloads from ruby-test-mode.el

(autoload 'ruby-test-mode "ruby-test-mode" "\
Toggle Ruby-Test minor mode.
With no argument, this command toggles the mode. Non-null prefix
argument turns on the mode. Null prefix argument turns off the
mode.

If called interactively, toggle `Ruby-Test mode'.  If the prefix
argument is positive, enable the mode, and if it is zero or
negative, disable the mode.

If called from Lisp, toggle the mode if ARG is `toggle'.  Enable
the mode if ARG is nil, omitted, or is a positive number.
Disable the mode if ARG is a negative number.

The mode's hook is called both when the mode is enabled and when
it is disabled.

\(fn &optional ARG)" t nil)

(autoload 'ruby-test-run "ruby-test-mode" "\
Run the current buffer's file as specification or unit test." t nil)

(autoload 'ruby-test-run-at-point "ruby-test-mode" "\
Run test at point individually, using the same search strategy as `ruby-test-run-file'." t nil)

(autoload 'ruby-test-rerun "ruby-test-mode" "\
Rerun the last test that was run by ruby-test.

When no tests had been run before calling this function, do nothing." t nil)

(autoload 'ruby-test-toggle-implementation-and-specification "ruby-test-mode" "\
Toggle between the implementation and specification/test file for the current buffer or the optional FILENAME.

\(fn &optional FILENAME)" t nil)

(register-definition-prefixes "ruby-test-mode" '("find-all" "ruby-test-"))

;;;***

;; Local Variables:
;; version-control: never
;; no-byte-compile: t
;; no-update-autoloads: t
;; coding: utf-8
;; End:
;;; ruby-test-mode-autoloads.el ends here
