;;; wisi-autoloads.el --- automatically extracted autoloads
;;
;;; Code:

(add-to-list 'load-path (directory-file-name
                         (or (file-name-directory #$) (car load-path))))


;;;### (autoloads nil "wisi" "wisi.el" (0 0 0 0))
;;; Generated autoloads from wisi.el

(if (fboundp 'register-definition-prefixes) (register-definition-prefixes "wisi" '("wisi-")))

;;;***

;;;### (autoloads nil "wisi-fringe" "wisi-fringe.el" (0 0 0 0))
;;; Generated autoloads from wisi-fringe.el

(if (fboundp 'register-definition-prefixes) (register-definition-prefixes "wisi-fringe" '("wisi-fringe-")))

;;;***

;;;### (autoloads nil "wisi-parse-common" "wisi-parse-common.el"
;;;;;;  (0 0 0 0))
;;; Generated autoloads from wisi-parse-common.el

(if (fboundp 'register-definition-prefixes) (register-definition-prefixes "wisi-parse-common" '("wisi-")))

;;;***

;;;### (autoloads nil "wisi-process-parse" "wisi-process-parse.el"
;;;;;;  (0 0 0 0))
;;; Generated autoloads from wisi-process-parse.el

(autoload 'wisi-process-parse-get "wisi-process-parse" "\
Return a ‘wisi-process--parser’ object matching PARSER label.
If label found in ‘wisi-process--alist’, return that.
Otherwise add PARSER to ‘wisi-process--alist’, return it.

\(fn PARSER)" nil nil)

(if (fboundp 'register-definition-prefixes) (register-definition-prefixes "wisi-process-parse" '("wisi-")))

;;;***

;;;### (autoloads nil "wisi-run-indent-test" "wisi-run-indent-test.el"
;;;;;;  (0 0 0 0))
;;; Generated autoloads from wisi-run-indent-test.el

(if (fboundp 'register-definition-prefixes) (register-definition-prefixes "wisi-run-indent-test" '("run-test" "skip-" "test-")))

;;;***

;;;### (autoloads nil "wisi-tests" "wisi-tests.el" (0 0 0 0))
;;; Generated autoloads from wisi-tests.el

(if (fboundp 'register-definition-prefixes) (register-definition-prefixes "wisi-tests" '("test-syntax-" "wisi-test")))

;;;***

;;;### (autoloads nil "wisitoken-parse_table-mode" "wisitoken-parse_table-mode.el"
;;;;;;  (0 0 0 0))
;;; Generated autoloads from wisitoken-parse_table-mode.el

(autoload 'wisitoken-parse_table-mode "wisitoken-parse_table-mode" "\
Provides navigation in wisi-generate parse table output.

If called interactively, enable Wisitoken-Parse_Table mode if ARG is positive, and
disable it if ARG is zero or negative.  If called from Lisp,
also enable the mode if ARG is omitted or nil, and toggle it
if ARG is `toggle'; disable the mode otherwise.

\(fn &optional ARG)" t nil)

(add-to-list 'auto-mode-alist '("\\.parse_table.*\\'" . wisitoken-parse_table-mode))

(if (fboundp 'register-definition-prefixes) (register-definition-prefixes "wisitoken-parse_table-mode" '("wisitoken-parse_table--xref-backend")))

;;;***

;;;### (autoloads nil nil ("wisi-pkg.el") (0 0 0 0))

;;;***

;; Local Variables:
;; version-control: never
;; no-byte-compile: t
;; no-update-autoloads: t
;; coding: utf-8
;; End:
;;; wisi-autoloads.el ends here
