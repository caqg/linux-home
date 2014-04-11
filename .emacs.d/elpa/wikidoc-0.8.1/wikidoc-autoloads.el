;;; wikidoc-autoloads.el --- automatically extracted autoloads
;;
;;; Code:


;;;### (autoloads (wikidoc-insert wikidoc-grab-list) "wikidoc" "wikidoc.el"
;;;;;;  (21319 39605 235971 676000))
;;; Generated autoloads from wikidoc.el

(autoload 'wikidoc-grab-list "wikidoc" "\
Grab a list or functions matching PREFIX possibly with NO-PRIVATE

\(fn PREFIX &optional NO-PRIVATE)" nil nil)

(autoload 'wikidoc-insert "wikidoc" "\
Make creole doc for functions beginning with ELISP-PREFIX in BUFFER.

When called interactively with a PREFIX argument this function
will use the current buffer for BUFFER.

Otherwise the BUFFER will be created named like:

 *wikidoc-ELISP-PREFIX*

If Transient Mark mode is set in the specified buffer the active
region is killed before the new wiki text is inserted.

\(fn ELISP-PREFIX BUFFER)" t nil)

;;;***

;;;### (autoloads nil nil ("wikidoc-pkg.el") (21319 39605 377159
;;;;;;  178000))

;;;***

(provide 'wikidoc-autoloads)
;; Local Variables:
;; version-control: never
;; no-byte-compile: t
;; no-update-autoloads: t
;; coding: utf-8
;; End:
;;; wikidoc-autoloads.el ends here
