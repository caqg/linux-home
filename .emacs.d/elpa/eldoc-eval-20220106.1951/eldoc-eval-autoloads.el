;;; eldoc-eval-autoloads.el --- automatically extracted autoloads  -*- lexical-binding: t -*-
;;
;;; Code:

(add-to-list 'load-path (directory-file-name
                         (or (file-name-directory #$) (car load-path))))


;;;### (autoloads nil "eldoc-eval" "eldoc-eval.el" (0 0 0 0))
;;; Generated autoloads from eldoc-eval.el

(defvar eldoc-in-minibuffer-mode nil "\
Non-nil if Eldoc-In-Minibuffer mode is enabled.
See the `eldoc-in-minibuffer-mode' command
for a description of this minor mode.
Setting this variable directly does not take effect;
either customize it (see the info node `Easy Customization')
or call the function `eldoc-in-minibuffer-mode'.")

(custom-autoload 'eldoc-in-minibuffer-mode "eldoc-eval" nil)

(autoload 'eldoc-in-minibuffer-mode "eldoc-eval" "\
Show eldoc for current minibuffer input.

This is a minor mode.  If called interactively, toggle the
`Eldoc-In-Minibuffer mode' mode.  If the prefix argument is
positive, enable the mode, and if it is zero or negative, disable
the mode.

If called from Lisp, toggle the mode if ARG is `toggle'.  Enable
the mode if ARG is nil, omitted, or is a positive number.
Disable the mode if ARG is a negative number.

To check whether the minor mode is enabled in the current buffer,
evaluate `(default-value \\='eldoc-in-minibuffer-mode)'.

The mode's hook is called both when the mode is enabled and when
it is disabled.

\(fn &optional ARG)" t nil)

(autoload 'eldoc-eval-expression "eldoc-eval" "\
Eval expression with eldoc support in mode-line." t nil)

(register-definition-prefixes "eldoc-eval" '("eldoc-" "with-eldoc-in-minibuffer"))

;;;***

;; Local Variables:
;; version-control: never
;; no-byte-compile: t
;; no-update-autoloads: t
;; coding: utf-8
;; End:
;;; eldoc-eval-autoloads.el ends here
