;;; path-headerline-mode-autoloads.el --- automatically extracted autoloads
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

If called interactively, enable Path-Headerline mode if ARG is positive, and
disable it if ARG is zero or negative.  If called from Lisp,
also enable the mode if ARG is omitted or nil, and toggle it
if ARG is `toggle'; disable the mode otherwise.

\(fn &optional ARG)" t nil)

(if (fboundp 'register-definition-prefixes) (register-definition-prefixes "path-headerline-mode" '("path-header-line-o" "ph--")))

;;;***

;; Local Variables:
;; version-control: never
;; no-byte-compile: t
;; no-update-autoloads: t
;; coding: utf-8
;; End:
;;; path-headerline-mode-autoloads.el ends here
