;;; org-readme-autoloads.el --- automatically extracted autoloads
;;
;;; Code:


;;;### (autoloads (org-readme-changelog-to-readme org-readme-top-header-to-readme
;;;;;;  org-readme-to-commentary org-readme-sync org-readme-gen-info)
;;;;;;  "org-readme" "org-readme.el" (21319 38103 807932 616000))
;;; Generated autoloads from org-readme.el

(autoload 'org-readme-gen-info "org-readme" "\
With the proper tools, generates an info and dir from the current readme.org

\(fn)" t nil)

(autoload 'org-readme-sync "org-readme" "\
Syncs Readme.org with current buffer.
When COMMENT-ADDED is non-nil, the comment has been added and the syncing should begin.

\(fn &optional COMMENT-ADDED)" t nil)

(autoload 'org-readme-to-commentary "org-readme" "\
Change Readme.org to a Commentary section.

\(fn)" t nil)

(autoload 'org-readme-top-header-to-readme "org-readme" "\
This puts the top header into the Readme.org file as Library Information

\(fn)" t nil)

(autoload 'org-readme-changelog-to-readme "org-readme" "\
This puts the emacs lisp change-log into the Readme.org file.

\(fn)" t nil)

;;;***

;;;### (autoloads nil nil ("org-readme-pkg.el") (21319 38103 965378
;;;;;;  955000))

;;;***

(provide 'org-readme-autoloads)
;; Local Variables:
;; version-control: never
;; no-byte-compile: t
;; no-update-autoloads: t
;; coding: utf-8
;; End:
;;; org-readme-autoloads.el ends here
