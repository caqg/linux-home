;;; bison-mode-autoloads.el --- automatically extracted autoloads
;;
;;; Code:
(add-to-list 'load-path (directory-file-name (or (file-name-directory #$) (car load-path))))

;;;### (autoloads nil "bison-mode" "bison-mode.el" (22372 46566 192191
;;;;;;  84000))
;;; Generated autoloads from bison-mode.el

(add-to-list 'auto-mode-alist '("\\.y\\'" . bison-mode))

(add-to-list 'auto-mode-alist '("\\.l\\'" . bison-mode))

(add-to-list 'auto-mode-alist '("\\.jison\\'" . jison-mode))

(autoload 'bison-mode "bison-mode" "\
Major mode for editing bison/yacc files.

\(fn)" t nil)

(autoload 'jison-mode "bison-mode" "\


\(fn)" t nil)

;;;***

;; Local Variables:
;; version-control: never
;; no-byte-compile: t
;; no-update-autoloads: t
;; End:
;;; bison-mode-autoloads.el ends here
