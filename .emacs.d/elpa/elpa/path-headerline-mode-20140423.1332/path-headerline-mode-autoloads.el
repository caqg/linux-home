;;; path-headerline-mode-autoloads.el --- automatically extracted autoloads  -*- lexical-binding: t -*-
;;
;;; Code:

(add-to-list 'load-path (directory-file-name
                         (or (file-name-directory #$) (car load-path))))


;;;### (autoloads nil "path-headerline-mode" "path-headerline-mode.el"
;;;;;;  (0 0 0 0))
;;; Generated autoloads from path-headerline-mode.el

(defvar path-headerline-mode nil "\
Non-nil if Path-Headerline mode is enabled.
See the `path-headerline-mode' command
for a description of this minor mode.
Setting this variable directly does not take effect;
either customize it (see the info node `Easy Customization')
or call the function `path-headerline-mode'.")

(custom-autoload 'path-headerline-mode "path-headerline-mode" nil)

(autoload 'path-headerline-mode "path-headerline-mode" "\
Displaying file path on headerline.

If called interactively, toggle `Path-Headerline mode'.  If the
prefix argument is positive, enable the mode, and if it is zero
or negative, disable the mode.

If called from Lisp, toggle the mode if ARG is `toggle'.  Enable
the mode if ARG is nil, omitted, or is a positive number.
Disable the mode if ARG is a negative number.

The mode's hook is called both when the mode is enabled and when
it is disabled.

\(fn &optional ARG)" t nil)

(register-definition-prefixes "path-headerline-mode" '("path-header-line-o" "ph--"))

;;;***

;; Local Variables:
;; version-control: never
;; no-byte-compile: t
;; no-update-autoloads: t
;; coding: utf-8
;; End:
;;; path-headerline-mode-autoloads.el ends here
