;;; orgtbl-show-header-autoloads.el --- automatically extracted autoloads
;;
;;; Code:

(add-to-list 'load-path (directory-file-name
                         (or (file-name-directory #$) (car load-path))))


;;;### (autoloads nil "orgtbl-show-header" "orgtbl-show-header.el"
;;;;;;  (0 0 0 0))
;;; Generated autoloads from orgtbl-show-header.el

(autoload 'orgtbl-show-header-of-current-column "orgtbl-show-header" "\
In a table, show the header of the column the point is in.

\(fn)" t nil)

(autoload 'orgtbl-show-header "orgtbl-show-header" "\
Show current header while navigating in the table.

If called interactively, enable Orgtbl-Show-Header mode if ARG is positive, and
disable it if ARG is zero or negative.  If called from Lisp,
also enable the mode if ARG is omitted or nil, and toggle it
if ARG is `toggle'; disable the mode otherwise.

\(fn &optional ARG)" t nil)

(if (fboundp 'register-definition-prefixes) (register-definition-prefixes "orgtbl-show-header" '("orgtbl-show-header-")))

;;;***

;; Local Variables:
;; version-control: never
;; no-byte-compile: t
;; no-update-autoloads: t
;; coding: utf-8
;; End:
;;; orgtbl-show-header-autoloads.el ends here
