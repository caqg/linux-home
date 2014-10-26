;;; javadoc-lookup-autoloads.el --- automatically extracted autoloads
;;
;;; Code:


;;;### (autoloads (add-java-import sort-java-imports) "java-import"
;;;;;;  "java-import.el" (21580 40637 827046 320000))
;;; Generated autoloads from java-import.el

(autoload 'sort-java-imports "java-import" "\
Sort the imports in the import section in proper order.

\(fn)" t nil)

(autoload 'add-java-import "java-import" "\
Insert an import statement at import section at the top of the file.

\(fn)" t nil)

;;;***

;;;### (autoloads (javadoc-lookup) "javadoc-lookup" "javadoc-lookup.el"
;;;;;;  (21580 40637 763046 323000))
;;; Generated autoloads from javadoc-lookup.el

(autoload 'javadoc-lookup "javadoc-lookup" "\
Lookup based on class name.

\(fn NAME)" t nil)

;;;***

;;;### (autoloads (javadoc-add-artifacts) "maven-fetch" "maven-fetch.el"
;;;;;;  (21580 40638 95046 309000))
;;; Generated autoloads from maven-fetch.el

(autoload 'javadoc-add-artifacts "maven-fetch" "\
Add Maven repository artifacts to the javadoc-lookup index.
An artifact is specified by a sequence of three strings:
 [groupId artifactId version].

\(fn &rest ARTIFACTS)" nil nil)

;;;***

;;;### (autoloads nil nil ("javadoc-lookup-pkg.el") (21580 40638
;;;;;;  150428 424000))

;;;***

(provide 'javadoc-lookup-autoloads)
;; Local Variables:
;; version-control: never
;; no-byte-compile: t
;; no-update-autoloads: t
;; coding: utf-8
;; End:
;;; javadoc-lookup-autoloads.el ends here
