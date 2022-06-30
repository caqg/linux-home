;;; clhs-autoloads.el --- automatically extracted autoloads  -*- lexical-binding: t -*-
;;
;;; Code:

(add-to-list 'load-path (directory-file-name
                         (or (file-name-directory #$) (car load-path))))


;;;### (autoloads nil "clhs" "clhs.el" (0 0 0 0))
;;; Generated autoloads from clhs.el

(autoload 'clhs-doc "clhs" "\
Browse the Common Lisp HyperSpec documentation for SYMBOL-NAME.
Finds the HyperSpec at `clhs-root'.
With prefix arg KILL, save the URL in the `kill-ring' instead.

\(fn SYMBOL-NAME &optional KILL)" t nil)

(register-definition-prefixes "clhs" '("clhs-"))

;;;***

;; Local Variables:
;; version-control: never
;; no-byte-compile: t
;; no-update-autoloads: t
;; coding: utf-8
;; End:
;;; clhs-autoloads.el ends here
