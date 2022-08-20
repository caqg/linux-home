;;; ada-mode-autoloads.el --- automatically extracted autoloads
;;
;;; Code:

(add-to-list 'load-path (directory-file-name
                         (or (file-name-directory #$) (car load-path))))


;;;### (autoloads nil "ada-build" "ada-build.el" (0 0 0 0))
;;; Generated autoloads from ada-build.el

(if (fboundp 'register-definition-prefixes) (register-definition-prefixes "ada-build" '("ada-build-")))

;;;***

;;;### (autoloads nil "ada-fix-error" "ada-fix-error.el" (0 0 0 0))
;;; Generated autoloads from ada-fix-error.el

(if (fboundp 'register-definition-prefixes) (register-definition-prefixes "ada-fix-error" '("ada-")))

;;;***

;;;### (autoloads nil "ada-gnat-compile" "ada-gnat-compile.el" (0
;;;;;;  0 0 0))
;;; Generated autoloads from ada-gnat-compile.el

(if (fboundp 'register-definition-prefixes) (register-definition-prefixes "ada-gnat-compile" '("ada-gnat-")))

;;;***

;;;### (autoloads nil "ada-gnat-xref" "ada-gnat-xref.el" (0 0 0 0))
;;; Generated autoloads from ada-gnat-xref.el

(if (fboundp 'register-definition-prefixes) (register-definition-prefixes "ada-gnat-xref" '("ada-gnat-")))

;;;***

;;;### (autoloads nil "ada-gps" "ada-gps.el" (0 0 0 0))
;;; Generated autoloads from ada-gps.el

(if (fboundp 'register-definition-prefixes) (register-definition-prefixes "ada-gps" '("ada-gps-")))

;;;***

;;;### (autoloads nil "ada-grammar-wy" "ada-grammar-wy.el" (0 0 0
;;;;;;  0))
;;; Generated autoloads from ada-grammar-wy.el

(if (fboundp 'register-definition-prefixes) (register-definition-prefixes "ada-grammar-wy" '("ada-grammar-wy--")))

;;;***

;;;### (autoloads nil "ada-imenu" "ada-imenu.el" (0 0 0 0))
;;; Generated autoloads from ada-imenu.el

(if (fboundp 'register-definition-prefixes) (register-definition-prefixes "ada-imenu" '("ada--imenu-")))

;;;***

;;;### (autoloads nil "ada-indent-user-options" "ada-indent-user-options.el"
;;;;;;  (0 0 0 0))
;;; Generated autoloads from ada-indent-user-options.el

(if (fboundp 'register-definition-prefixes) (register-definition-prefixes "ada-indent-user-options" '("ada-")))

;;;***

;;;### (autoloads nil "ada-mode" "ada-mode.el" (0 0 0 0))
;;; Generated autoloads from ada-mode.el

(autoload 'ada-parse-prj-file "ada-mode" "\
Read Emacs Ada or compiler-specific project file PRJ-FILE, set project properties in `ada-prj-alist'.

\(fn PRJ-FILE)" nil nil)

(autoload 'ada-add-extensions "ada-mode" "\
Define SPEC and BODY as being valid extensions for Ada files.
SPEC and BODY are two regular expressions that must match against
the file name.

\(fn SPEC BODY)" nil nil)

(autoload 'ada-mode "ada-mode" "\
The major mode for editing Ada code.

\(fn)" t nil)

(if (fboundp 'register-definition-prefixes) (register-definition-prefixes "ada-mode" '("ada-")))

;;;***

;;;### (autoloads nil "ada-skel" "ada-skel.el" (0 0 0 0))
;;; Generated autoloads from ada-skel.el

(if (fboundp 'register-definition-prefixes) (register-definition-prefixes "ada-skel" '("ada-skel-")))

;;;***

;;;### (autoloads nil "ada-wisi" "ada-wisi.el" (0 0 0 0))
;;; Generated autoloads from ada-wisi.el

(if (fboundp 'register-definition-prefixes) (register-definition-prefixes "ada-wisi" '("ada-wisi-")))

;;;***

;;;### (autoloads nil "ada-wisi-opentoken" "ada-wisi-opentoken.el"
;;;;;;  (0 0 0 0))
;;; Generated autoloads from ada-wisi-opentoken.el

(autoload 'ada-indent-opentoken-mode "ada-wisi-opentoken" "\
Minor mode for indenting grammar definitions for the OpenToken package.
Enable mode if ARG is positive

\(fn &optional ARG)" t nil)

(if (fboundp 'register-definition-prefixes) (register-definition-prefixes "ada-wisi-opentoken" '("ada-wisi-opentoken")))

;;;***

;;;### (autoloads nil "gnat-core" "gnat-core.el" (0 0 0 0))
;;; Generated autoloads from gnat-core.el

(if (fboundp 'register-definition-prefixes) (register-definition-prefixes "gnat-core" '("ada-gnat-" "gpr-query--sessions" "gnat")))

;;;***

;;;### (autoloads nil "gpr-grammar-wy" "gpr-grammar-wy.el" (0 0 0
;;;;;;  0))
;;; Generated autoloads from gpr-grammar-wy.el

(if (fboundp 'register-definition-prefixes) (register-definition-prefixes "gpr-grammar-wy" '("gpr-grammar-wy--")))

;;;***

;;;### (autoloads nil "gpr-mode" "gpr-mode.el" (0 0 0 0))
;;; Generated autoloads from gpr-mode.el

(autoload 'gpr-mode "gpr-mode" "\
The major mode for editing GNAT project files.

\(fn)" t nil)

(add-to-list 'auto-mode-alist '("\\.gpr\\'" . gpr-mode))

(if (fboundp 'register-definition-prefixes) (register-definition-prefixes "gpr-mode" '("gpr-")))

;;;***

;;;### (autoloads nil "gpr-query" "gpr-query.el" (0 0 0 0))
;;; Generated autoloads from gpr-query.el

(if (fboundp 'register-definition-prefixes) (register-definition-prefixes "gpr-query" '("ada-gpr-query" "gpr-")))

;;;***

;;;### (autoloads nil "gpr-skel" "gpr-skel.el" (0 0 0 0))
;;; Generated autoloads from gpr-skel.el

(if (fboundp 'register-definition-prefixes) (register-definition-prefixes "gpr-skel" '("gpr-skel-" "skeleton-")))

;;;***

;;;### (autoloads nil "gpr-wisi" "gpr-wisi.el" (0 0 0 0))
;;; Generated autoloads from gpr-wisi.el

(if (fboundp 'register-definition-prefixes) (register-definition-prefixes "gpr-wisi" '("gpr-wisi-")))

;;;***

;;;### (autoloads nil nil ("ada-mode-compat.el" "ada-mode-pkg.el"
;;;;;;  "ada-prj.el" "ada-stmt.el" "ada-xref.el") (0 0 0 0))

;;;***

;; Local Variables:
;; version-control: never
;; no-byte-compile: t
;; no-update-autoloads: t
;; coding: utf-8
;; End:
;;; ada-mode-autoloads.el ends here
