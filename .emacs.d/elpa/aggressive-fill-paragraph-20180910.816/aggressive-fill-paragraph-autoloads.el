;;; aggressive-fill-paragraph-autoloads.el --- automatically extracted autoloads  -*- lexical-binding: t -*-
;;
;;; Code:

(add-to-list 'load-path (directory-file-name
                         (or (file-name-directory #$) (car load-path))))


;;;### (autoloads nil "aggressive-fill-paragraph" "aggressive-fill-paragraph.el"
;;;;;;  (0 0 0 0))
;;; Generated autoloads from aggressive-fill-paragraph.el

(autoload 'aggressive-fill-paragraph-mode "aggressive-fill-paragraph" "\
Toggle automatic paragraph fill when spaces are inserted in comments.

If called interactively, toggle `Aggressive-Fill-Paragraph mode'.
If the prefix argument is positive, enable the mode, and if it is
zero or negative, disable the mode.

If called from Lisp, toggle the mode if ARG is `toggle'.  Enable
the mode if ARG is nil, omitted, or is a positive number.
Disable the mode if ARG is a negative number.

The mode's hook is called both when the mode is enabled and when
it is disabled.

\(fn &optional ARG)" t nil)

(autoload 'afp-setup-recommended-hooks "aggressive-fill-paragraph" "\
Install hooks to enable function ‘aggressive-fill-paragraph-mode’ in recommended major modes." t nil)

(register-definition-prefixes "aggressive-fill-paragraph" '("afp-" "aggressive-fill-paragraph-post-self-insert-function"))

;;;***

;; Local Variables:
;; version-control: never
;; no-byte-compile: t
;; no-update-autoloads: t
;; coding: utf-8
;; End:
;;; aggressive-fill-paragraph-autoloads.el ends here
