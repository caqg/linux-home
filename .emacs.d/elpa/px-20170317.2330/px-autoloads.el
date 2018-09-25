;;; px-autoloads.el --- automatically extracted autoloads
;;
;;; Code:

(add-to-list 'load-path (directory-file-name
                         (or (file-name-directory #$) (car load-path))))


;;;### (autoloads nil "px" "px.el" (0 0 0 0))
;;; Generated autoloads from px.el

(autoload 'px-preview "px" "\
Preview LaTeX fragments in the current buffer.

\(fn)" t nil)

(autoload 'px-preview-region "px" "\
Preview LaTeX fragments in region.

\(fn BEG END)" t nil)

(autoload 'px-remove "px" "\
Remove LaTeX preview images in current buffer.

\(fn)" t nil)

(autoload 'px-toggle "px" "\
Toggle display of LaTeX preview in the current buffer.

\(fn)" t nil)

(if (fboundp 'register-definition-prefixes) (register-definition-prefixes "px" '("px-")))

;;;***

;; Local Variables:
;; version-control: never
;; no-byte-compile: t
;; no-update-autoloads: t
;; coding: utf-8
;; End:
;;; px-autoloads.el ends here
