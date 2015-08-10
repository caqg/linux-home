;;; codesearch-autoloads.el --- automatically extracted autoloads
;;
;;; Code:


;;;### (autoloads (codesearch-list-directories codesearch-reset codesearch-update-index
;;;;;;  codesearch-build-index codesearch-search) "codesearch" "codesearch.el"
;;;;;;  (21572 33751 400894 579000))
;;; Generated autoloads from codesearch.el

(autoload 'codesearch-search "codesearch" "\
Search files matching FILE-PATTERN in the index for PATTERN.

\(fn PATTERN FILE-PATTERN)" t nil)

(autoload 'codesearch-build-index "codesearch" "\
Add the contents of DIR to the index.

\(fn DIR)" t nil)

(autoload 'codesearch-update-index "codesearch" "\
Rescan all of the directories currently in the index, updating
the index with the new contents.

\(fn)" t nil)

(autoload 'codesearch-reset "codesearch" "\
Reset (delete) the codesearch index.

\(fn)" t nil)

(autoload 'codesearch-list-directories "codesearch" "\
List the directories currently being indexed.

\(fn)" t nil)

;;;***

;;;### (autoloads nil nil ("codesearch-pkg.el") (21572 33751 558972
;;;;;;  751000))

;;;***

(provide 'codesearch-autoloads)
;; Local Variables:
;; version-control: never
;; no-byte-compile: t
;; no-update-autoloads: t
;; coding: utf-8
;; End:
;;; codesearch-autoloads.el ends here
