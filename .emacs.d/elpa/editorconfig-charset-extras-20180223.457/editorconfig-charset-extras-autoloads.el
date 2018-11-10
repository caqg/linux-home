;;; editorconfig-charset-extras-autoloads.el --- automatically extracted autoloads
;;
;;; Code:

(add-to-list 'load-path (directory-file-name
                         (or (file-name-directory #$) (car load-path))))


;;;### (autoloads nil "editorconfig-charset-extras" "editorconfig-charset-extras.el"
;;;;;;  (0 0 0 0))
;;; Generated autoloads from editorconfig-charset-extras.el

(autoload 'editorconfig-charset-extras "editorconfig-charset-extras" "\
Add support for extra charsets to editorconfig from editorconfig HASH.

The list of supported charsets is taken from the result of function
`coding-system-list'.

\(fn HASH)" nil nil)

(if (fboundp 'register-definition-prefixes) (register-definition-prefixes "editorconfig-charset-extras" '("editorconfig-charset-extras--decide")))

;;;***

;; Local Variables:
;; version-control: never
;; no-byte-compile: t
;; no-update-autoloads: t
;; coding: utf-8
;; End:
;;; editorconfig-charset-extras-autoloads.el ends here
