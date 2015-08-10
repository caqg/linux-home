;;; preproc-font-lock-autoloads.el --- automatically extracted autoloads
;;
;;; Code:


;;;### (autoloads (preproc-font-lock-global-mode preproc-font-lock-mode
;;;;;;  preproc-font-lock-modes) "preproc-font-lock" "preproc-font-lock.el"
;;;;;;  (21583 7009 182877 232000))
;;; Generated autoloads from preproc-font-lock.el

(defvar preproc-font-lock-modes '(c-mode c++-mode objc-mode) "\
List of major modes where Preproc Font Lock Global mode should be enabled.")

(custom-autoload 'preproc-font-lock-modes "preproc-font-lock" t)

(autoload 'preproc-font-lock-mode "preproc-font-lock" "\
Minor mode that highlights preprocessor directives.

\(fn &optional ARG)" t nil)

(defvar preproc-font-lock-global-mode nil "\
Non-nil if Preproc-Font-Lock-Global mode is enabled.
See the command `preproc-font-lock-global-mode' for a description of this minor mode.
Setting this variable directly does not take effect;
either customize it (see the info node `Easy Customization')
or call the function `preproc-font-lock-global-mode'.")

(custom-autoload 'preproc-font-lock-global-mode "preproc-font-lock" nil)

(autoload 'preproc-font-lock-global-mode "preproc-font-lock" "\
Toggle Preproc-Font-Lock mode in all buffers.
With prefix ARG, enable Preproc-Font-Lock-Global mode if ARG is positive;
otherwise, disable it.  If called from Lisp, enable the mode if
ARG is omitted or nil.

Preproc-Font-Lock mode is enabled in all buffers where
`(lambda nil (when (apply (quote derived-mode-p) preproc-font-lock-modes) (preproc-font-lock-mode 1)))' would do it.
See `preproc-font-lock-mode' for more information on Preproc-Font-Lock mode.

\(fn &optional ARG)" t nil)

;;;***

;;;### (autoloads nil nil ("preproc-font-lock-pkg.el") (21583 7009
;;;;;;  299801 378000))

;;;***

(provide 'preproc-font-lock-autoloads)
;; Local Variables:
;; version-control: never
;; no-byte-compile: t
;; no-update-autoloads: t
;; coding: utf-8
;; End:
;;; preproc-font-lock-autoloads.el ends here
