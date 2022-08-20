;;; editorconfig-custom-majormode-autoloads.el --- automatically extracted autoloads
;;
;;; Code:

(add-to-list 'load-path (directory-file-name
                         (or (file-name-directory #$) (car load-path))))


;;;### (autoloads nil "editorconfig-custom-majormode" "editorconfig-custom-majormode.el"
;;;;;;  (0 0 0 0))
;;; Generated autoloads from editorconfig-custom-majormode.el

(autoload 'editorconfig-custom-majormode "editorconfig-custom-majormode" "\
Get emacs_mode property from HASH and set major mode.

If `package' is installed on your Emacs and the major mode specified is
installable, this plugin asks whether you want to install and enable it
automatically.

\(fn HASH)" nil nil)

(if (fboundp 'register-definition-prefixes) (register-definition-prefixes "editorconfig-custom-majormode" '("editorconfig-custom-majormode--")))

;;;***

;; Local Variables:
;; version-control: never
;; no-byte-compile: t
;; no-update-autoloads: t
;; coding: utf-8
;; End:
;;; editorconfig-custom-majormode-autoloads.el ends here
