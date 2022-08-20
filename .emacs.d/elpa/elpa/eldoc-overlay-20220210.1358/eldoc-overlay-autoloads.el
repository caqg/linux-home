;;; eldoc-overlay-autoloads.el --- automatically extracted autoloads  -*- lexical-binding: t -*-
;;
;;; Code:

(add-to-list 'load-path (directory-file-name
                         (or (file-name-directory #$) (car load-path))))


;;;### (autoloads nil "eldoc-overlay" "eldoc-overlay.el" (0 0 0 0))
;;; Generated autoloads from eldoc-overlay.el

(autoload 'eldoc-overlay-mode "eldoc-overlay" "\
Minor mode for displaying eldoc contextual documentation using a text overlay.

This is a minor mode.  If called interactively, toggle the
`Eldoc-Overlay mode' mode.  If the prefix argument is positive,
enable the mode, and if it is zero or negative, disable the mode.

If called from Lisp, toggle the mode if ARG is `toggle'.  Enable
the mode if ARG is nil, omitted, or is a positive number.
Disable the mode if ARG is a negative number.

To check whether the minor mode is enabled in the current buffer,
evaluate `eldoc-overlay-mode'.

The mode's hook is called both when the mode is enabled and when
it is disabled.

\(fn &optional ARG)" t nil)

(put 'global-eldoc-overlay-mode 'globalized-minor-mode t)

(defvar global-eldoc-overlay-mode nil "\
Non-nil if Global Eldoc-Overlay mode is enabled.
See the `global-eldoc-overlay-mode' command
for a description of this minor mode.
Setting this variable directly does not take effect;
either customize it (see the info node `Easy Customization')
or call the function `global-eldoc-overlay-mode'.")

(custom-autoload 'global-eldoc-overlay-mode "eldoc-overlay" nil)

(autoload 'global-eldoc-overlay-mode "eldoc-overlay" "\
Toggle Eldoc-Overlay mode in all buffers.
With prefix ARG, enable Global Eldoc-Overlay mode if ARG is positive; otherwise,
disable it.

If called from Lisp, toggle the mode if ARG is `toggle'.
Enable the mode if ARG is nil, omitted, or is a positive number.
Disable the mode if ARG is a negative number.

Eldoc-Overlay mode is enabled in all buffers where `eldoc-overlay-mode' would do
it.

See `eldoc-overlay-mode' for more information on Eldoc-Overlay mode.

\(fn &optional ARG)" t nil)

(register-definition-prefixes "eldoc-overlay" '("eldoc-overlay-"))

;;;***

;; Local Variables:
;; version-control: never
;; no-byte-compile: t
;; no-update-autoloads: t
;; coding: utf-8-emacs-unix
;; End:
;;; eldoc-overlay-autoloads.el ends here
