;;; pandoc-mode-autoloads.el --- automatically extracted autoloads
;;
;;; Code:
(add-to-list 'load-path (or (file-name-directory #$) (car load-path)))

;;;### (autoloads nil "pandoc-mode" "pandoc-mode.el" (21605 45226
;;;;;;  258251 845000))
;;; Generated autoloads from pandoc-mode.el

(autoload 'pandoc-mode "pandoc-mode" "\
Minor mode for interacting with Pandoc.

\(fn &optional ARG)" t nil)

(autoload 'turn-on-pandoc "pandoc-mode" "\
Unconditionally turn on pandoc-mode.

\(fn)" t nil)

(autoload 'conditionally-turn-on-pandoc "pandoc-mode" "\
Turn on pandoc-mode if a pandoc settings file exists.
This is for use in major mode hooks.

\(fn)" nil nil)

;;;***

;;;### (autoloads nil nil ("pandoc-mode-pkg.el") (21605 45226 574070
;;;;;;  326000))

;;;***

;; Local Variables:
;; version-control: never
;; no-byte-compile: t
;; no-update-autoloads: t
;; End:
;;; pandoc-mode-autoloads.el ends here