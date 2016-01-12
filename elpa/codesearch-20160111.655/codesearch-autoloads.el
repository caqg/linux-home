;;; codesearch-autoloads.el --- automatically extracted autoloads
;;
;;; Code:
(add-to-list 'load-path (directory-file-name (or (file-name-directory #$) (car load-path))))

;;;### (autoloads nil "codesearch" "codesearch.el" (22164 40552 28778
;;;;;;  761000))
;;; Generated autoloads from codesearch.el

(defvar codesearch-pattern-history nil)

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

;; Local Variables:
;; version-control: never
;; no-byte-compile: t
;; no-update-autoloads: t
;; End:
;;; codesearch-autoloads.el ends here
