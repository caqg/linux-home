;;; tramp-term-autoloads.el --- automatically extracted autoloads  -*- lexical-binding: t -*-
;;
;;; Code:

(add-to-list 'load-path (directory-file-name
                         (or (file-name-directory #$) (car load-path))))


;;;### (autoloads nil "tramp-term" "tramp-term.el" (0 0 0 0))
;;; Generated autoloads from tramp-term.el

(autoload 'tramp-term "tramp-term" "\
Create an `ansi-term` running ssh session.
And automatically enable tramp integration in that terminal.
Optional argument HOST-ARG is a list or one or two elements,
the last of which is the host name.

\(fn &optional HOST-ARG)" t nil)

(register-definition-prefixes "tramp-term" '("tramp-term-"))

;;;***

;; Local Variables:
;; version-control: never
;; no-byte-compile: t
;; no-update-autoloads: t
;; coding: utf-8-emacs-unix
;; End:
;;; tramp-term-autoloads.el ends here
