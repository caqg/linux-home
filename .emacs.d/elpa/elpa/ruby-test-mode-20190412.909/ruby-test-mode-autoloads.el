;;; ruby-test-mode-autoloads.el --- automatically extracted autoloads
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

If called interactively, enable Ruby-Test mode if ARG is positive, and
disable it if ARG is zero or negative.  If called from Lisp,
also enable the mode if ARG is omitted or nil, and toggle it
if ARG is `toggle'; disable the mode otherwise.

\(fn &optional ARG)" t nil)

(autoload 'ruby-test-run "ruby-test-mode" "\
Run the current buffer's file as specification or unit test." t nil)

(autoload 'ruby-test-run-at-point "ruby-test-mode" "\
Run test at point individually, using the same search strategy as `ruby-test-run-file'." t nil)

(autoload 'ruby-test-toggle-implementation-and-specification "ruby-test-mode" "\
Toggle between the implementation and specification/test file for the current buffer or the optional FILENAME.

\(fn &optional FILENAME)" t nil)

(if (fboundp 'register-definition-prefixes) (register-definition-prefixes "ruby-test-mode" '("find-all" "ruby-test-")))

;;;***

;; Local Variables:
;; version-control: never
;; no-byte-compile: t
;; no-update-autoloads: t
;; coding: utf-8
;; End:
;;; ruby-test-mode-autoloads.el ends here
