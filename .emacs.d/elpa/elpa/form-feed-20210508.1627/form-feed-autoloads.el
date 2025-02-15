;;; form-feed-autoloads.el --- automatically extracted autoloads  -*- lexical-binding: t -*-
;;
;;; Code:

(add-to-list 'load-path (directory-file-name
                         (or (file-name-directory #$) (car load-path))))


;;;### (autoloads nil "form-feed" "form-feed.el" (0 0 0 0))
;;; Generated autoloads from form-feed.el

(autoload 'form-feed-mode "form-feed" "\
Toggle form-feed-mode.

If called interactively, toggle `Form-Feed mode'.  If the prefix
argument is positive, enable the mode, and if it is zero or
negative, disable the mode.

If called from Lisp, toggle the mode if ARG is `toggle'.  Enable
the mode if ARG is nil, omitted, or is a positive number.
Disable the mode if ARG is a negative number.

The mode's hook is called both when the mode is enabled and when
it is disabled.

This minor mode displays page delimiters which usually appear as ^L
glyphs on a single line as horizontal lines spanning the entire
window.

\(fn &optional ARG)" t nil)

(put 'global-form-feed-mode 'globalized-minor-mode t)

(defvar global-form-feed-mode nil "\
Non-nil if Global Form-Feed mode is enabled.
See the `global-form-feed-mode' command
for a description of this minor mode.
Setting this variable directly does not take effect;
either customize it (see the info node `Easy Customization')
or call the function `global-form-feed-mode'.")

(custom-autoload 'global-form-feed-mode "form-feed" nil)

(autoload 'global-form-feed-mode "form-feed" "\
Toggle Form-Feed mode in all buffers.
With prefix ARG, enable Global Form-Feed mode if ARG is positive; otherwise,
disable it.  If called from Lisp, enable the mode if ARG is omitted or nil.

Form-Feed mode is enabled in all buffers where
`form-feed--turn-on-mode-if-desired' would do it.

See `form-feed-mode' for more information on Form-Feed mode.

\(fn &optional ARG)" t nil)

(register-definition-prefixes "form-feed" '("form-feed-"))

;;;***

;; Local Variables:
;; version-control: never
;; no-byte-compile: t
;; no-update-autoloads: t
;; coding: utf-8
;; End:
;;; form-feed-autoloads.el ends here
