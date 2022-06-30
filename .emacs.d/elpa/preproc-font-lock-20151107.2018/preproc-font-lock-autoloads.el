;;; preproc-font-lock-autoloads.el --- automatically extracted autoloads  -*- lexical-binding: t -*-
;;
;;; Code:

(add-to-list 'load-path (directory-file-name
                         (or (file-name-directory #$) (car load-path))))


;;;### (autoloads nil "preproc-font-lock" "preproc-font-lock.el"
;;;;;;  (0 0 0 0))
;;; Generated autoloads from preproc-font-lock.el

(defvar preproc-font-lock-modes '(c-mode c++-mode objc-mode) "\
List of major modes where Preproc Font Lock Global mode should be enabled.")

(custom-autoload 'preproc-font-lock-modes "preproc-font-lock" t)

(autoload 'preproc-font-lock-mode "preproc-font-lock" "\
Minor mode that highlights preprocessor directives.

If called interactively, toggle `Preproc-Font-Lock mode'.  If the
prefix argument is positive, enable the mode, and if it is zero
or negative, disable the mode.

If called from Lisp, toggle the mode if ARG is `toggle'.  Enable
the mode if ARG is nil, omitted, or is a positive number.
Disable the mode if ARG is a negative number.

The mode's hook is called both when the mode is enabled and when
it is disabled.

\(fn &optional ARG)" t nil)

(put 'preproc-font-lock-global-mode 'globalized-minor-mode t)

(defvar preproc-font-lock-global-mode nil "\
Non-nil if Preproc-Font-Lock-Global mode is enabled.
See the `preproc-font-lock-global-mode' command
for a description of this minor mode.
Setting this variable directly does not take effect;
either customize it (see the info node `Easy Customization')
or call the function `preproc-font-lock-global-mode'.")

(custom-autoload 'preproc-font-lock-global-mode "preproc-font-lock" nil)

(autoload 'preproc-font-lock-global-mode "preproc-font-lock" "\
Toggle Preproc-Font-Lock mode in all buffers.
With prefix ARG, enable Preproc-Font-Lock-Global mode if ARG is positive;
otherwise, disable it.  If called from Lisp, enable the mode if ARG is omitted or
nil.

Preproc-Font-Lock mode is enabled in all buffers where `(lambda nil (when
\(apply 'derived-mode-p preproc-font-lock-modes) (preproc-font-lock-mode 1)))' would
do it.

See `preproc-font-lock-mode' for more information on Preproc-Font-Lock mode.

\(fn &optional ARG)" t nil)

(register-definition-prefixes "preproc-font-lock" '("preproc-font-lock-"))

;;;***

;; Local Variables:
;; version-control: never
;; no-byte-compile: t
;; no-update-autoloads: t
;; coding: utf-8
;; End:
;;; preproc-font-lock-autoloads.el ends here
