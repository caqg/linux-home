;;; ada-mode-autoloads.el --- automatically extracted autoloads (do not edit)   -*- lexical-binding: t -*-
;; Generated by the `loaddefs-generate' function.

;; This file is part of GNU Emacs.

;;; Code:

(add-to-list 'load-path (directory-file-name
                         (or (file-name-directory #$) (car load-path))))



;;; Generated autoloads from ada-build.el

(autoload 'ada-build-prompt-select-prj-file "ada-build" "\
Prompt for a project file, parse and select it.
The file must have an extension from `wisi-prj-file-extensions'.
Returns the project if a file is selected, nil otherwise." t)
(autoload 'ada-build-check "ada-build" "\
Run the check_cmd project variable.
By default, this checks the current file for syntax errors.
If CONFIRM is non-nil, prompt for user confirmation of the command.

(fn &optional CONFIRM)" t)
(autoload 'ada-build-make "ada-build" "\
Run the make_cmd project variable.
By default, this compiles and links the main program.
If CONFIRM is non-nil, prompt for user confirmation of the command.

(fn &optional CONFIRM)" t)
(autoload 'ada-build-set-make "ada-build" "\
Set the main project variable to the current file, then run make_cmd.
By default, this compiles and links the new main program.
If CONFIRM is non-nil, prompt for user confirmation of the command.

(fn &optional CONFIRM)" t)
(autoload 'ada-build-run "ada-build" "\
Run the run_cmd project variable.
By default, this runs the main program.
If CONFIRM is non-nil, prompt for user confirmation of the command.

(fn &optional CONFIRM)" t)
(register-definition-prefixes "ada-build" '("ada-build-"))


;;; Generated autoloads from ada-compiler-gnat.el

(register-definition-prefixes "ada-compiler-gnat" '("ada-gnat-"))


;;; Generated autoloads from ada-core.el

(autoload 'create-ada-prj "ada-core" "\


(fn &key NAME COMPILE-ENV (COMPILER-LABEL ada-compiler) (XREF-LABEL ada-xref-tool) SOURCE-PATH PLIST FILE-PRED)")
(autoload 'ada-prj-default "ada-core" "\
Return the default `ada-prj' object.
If SRC-DIR is non-nil, use it as the default for project.source-path.

(fn &optional NAME SRC-DIR)")
(autoload 'ada-prj-make-compiler "ada-core" "\


(fn LABEL)")
(autoload 'ada-select-prj-file "ada-core" "\
Select PRJ-FILE as the current project file, parsing it if necessary.
Deselects the current project first.

(fn PRJ-FILE)")
(register-definition-prefixes "ada-core" '("ada-"))


;;; Generated autoloads from ada-gnat-xref.el

(autoload 'create-gnat-xref "ada-gnat-xref" "\


(fn &key GPR-FILE RUN-BUFFER-NAME PROJECT-PATH TARGET RUNTIME GNAT-STUB-OPTS GNAT-STUB-CARGS)")
(register-definition-prefixes "ada-gnat-xref" '("ada-gnat-" "gnatxref-buffer-name-prefix"))


;;; Generated autoloads from ada-imenu.el

(register-definition-prefixes "ada-imenu" '("ada--imenu-"))


;;; Generated autoloads from ada-indent-user-options.el

(register-definition-prefixes "ada-indent-user-options" '("ada-"))


;;; Generated autoloads from ada-mode.el

(autoload 'ada-add-extensions "ada-mode" "\
Define SPEC and BODY as being valid extensions for Ada files.
SPEC and BODY are two regular expressions that must match against
the file name.

(fn SPEC BODY)")
(autoload 'ada-fix-compiler-error "ada-mode" nil t)
(autoload 'ada-parse-prj-file "ada-mode" "\


(fn PRJ-FILE)")
(autoload 'ada-select-prj-file "ada-mode" "\


(fn PRJ-FILE)")
(defalias 'ada-project-current #'wisi-prj-current-cached)
(autoload 'ada-parse-require-process "ada-mode" "\
Start the Ada parser in an external process, if not already started.
Unless WAIT, does not wait for parser to respond. Returns the parser object.

(fn &key WAIT)" t)
(autoload 'ada-mode "ada-mode" "\
The major mode for editing Ada code.

(fn)" t)
(add-to-list 'auto-mode-alist '("\\.ad[abs]\\'" . ada-mode))
(register-definition-prefixes "ada-mode" '("ada-"))


;;; Generated autoloads from ada-skel.el

(register-definition-prefixes "ada-skel" '("ada-skel-"))


;;; Generated autoloads from ada_annex_p-process.el

(register-definition-prefixes "ada_annex_p-process" '("ada_annex_p-process-"))


;;; Generated autoloads from benchmark-xref.el

(register-definition-prefixes "benchmark-xref" '("ada-mode-test" "bench"))


;;; Generated autoloads from gpr-indent-user-options.el

(register-definition-prefixes "gpr-indent-user-options" '("gpr-indent"))


;;; Generated autoloads from gpr-mode.el

(autoload 'gpr-mode "gpr-mode" "\
The major mode for editing GNAT project files." t)
(add-to-list 'auto-mode-alist '("\\.gpr\\'" . gpr-mode))
(register-definition-prefixes "gpr-mode" '("gpr-"))


;;; Generated autoloads from gpr-process.el

(register-definition-prefixes "gpr-process" '("gpr-process-"))


;;; Generated autoloads from gpr-query.el

(autoload 'create-gpr_query-xref "gpr-query" "\


(fn &key GPR-FILE)")
(register-definition-prefixes "gpr-query" '("gpr-query"))


;;; Generated autoloads from gpr-skel.el

(register-definition-prefixes "gpr-skel" '("gpr-skel-"))

;;; End of scraped data

(provide 'ada-mode-autoloads)

;; Local Variables:
;; version-control: never
;; no-byte-compile: t
;; no-update-autoloads: t
;; no-native-compile: t
;; coding: utf-8-emacs-unix
;; End:

;;; ada-mode-autoloads.el ends here
