;;; editorconfig-domain-specific-autoloads.el --- automatically extracted autoloads
;;
;;; Code:

(add-to-list 'load-path (directory-file-name
                         (or (file-name-directory #$) (car load-path))))


;;;### (autoloads nil "editorconfig-domain-specific" "editorconfig-domain-specific.el"
;;;;;;  (0 0 0 0))
;;; Generated autoloads from editorconfig-domain-specific.el

(autoload 'editorconfig-domain-specific "editorconfig-domain-specific" "\
Apply brace style and other \"domain-specific\" EditorConfig properties

Properties are applied from HASH to the current buffer (but only
when they make sense for the current major mode).  Unknown
properties and invalid property values are ignored.

To use:

  (add-hook 'editorconfig-custom-hooks 'editorconfig-domain-specific)

or do M-x `customize-variable' `editorconfig-custom-hooks' and
insert `editorconfig-domain-specific' there.

Supported EditorConfig properties:

* `indent_brace_style' -- can be one of Allman, GNU, K&R

See:
https://github.com/editorconfig/editorconfig/wiki/EditorConfig-Properties
section `Ideas for Domain-Specific Properties'.

\(fn HASH)" nil nil)

(if (fboundp 'register-definition-prefixes) (register-definition-prefixes "editorconfig-domain-specific" '("editorconfig-domain-specific-c-like-modes")))

;;;***

;; Local Variables:
;; version-control: never
;; no-byte-compile: t
;; no-update-autoloads: t
;; coding: utf-8
;; End:
;;; editorconfig-domain-specific-autoloads.el ends here
