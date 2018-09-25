;;; magit-filenotify-autoloads.el --- automatically extracted autoloads
;;
;;; Code:

(add-to-list 'load-path (directory-file-name
                         (or (file-name-directory #$) (car load-path))))


;;;### (autoloads nil "magit-filenotify" "magit-filenotify.el" (0
;;;;;;  0 0 0))
;;; Generated autoloads from magit-filenotify.el

(autoload 'magit-filenotify-mode "magit-filenotify" "\
Refresh status buffer if source tree changes.

If called interactively, enable Magit-Filenotify mode if ARG is positive, and
disable it if ARG is zero or negative.  If called from Lisp,
also enable the mode if ARG is omitted or nil, and toggle it
if ARG is `toggle'; disable the mode otherwise.

\(fn &optional ARG)" t nil)

(if (fboundp 'register-definition-prefixes) (register-definition-prefixes "magit-filenotify" '("magit-filenotify-")))

;;;***

;; Local Variables:
;; version-control: never
;; no-byte-compile: t
;; no-update-autoloads: t
;; coding: utf-8
;; End:
;;; magit-filenotify-autoloads.el ends here
