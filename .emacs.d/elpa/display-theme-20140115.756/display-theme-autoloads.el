;;; display-theme-autoloads.el --- automatically extracted autoloads
;;
;;; Code:


;;;### (autoloads (global-display-theme-mode display-theme-mode)
;;;;;;  "display-theme" "display-theme.el" (21319 35736 391871 28000))
;;; Generated autoloads from display-theme.el

(autoload 'display-theme-mode "display-theme" "\
Minor mode to display current theme(s) at mode-line.

\(fn &optional ARG)" t nil)

(defvar global-display-theme-mode nil "\
Non-nil if Global-Display-Theme mode is enabled.
See the command `global-display-theme-mode' for a description of this minor mode.
Setting this variable directly does not take effect;
either customize it (see the info node `Easy Customization')
or call the function `global-display-theme-mode'.")

(custom-autoload 'global-display-theme-mode "display-theme" nil)

(autoload 'global-display-theme-mode "display-theme" "\
Toggle Display-Theme mode in all buffers.
With prefix ARG, enable Global-Display-Theme mode if ARG is positive;
otherwise, disable it.  If called from Lisp, enable the mode if
ARG is omitted or nil.

Display-Theme mode is enabled in all buffers where
`display-theme-mode' would do it.
See `display-theme-mode' for more information on Display-Theme mode.

\(fn &optional ARG)" t nil)

;;;***

;;;### (autoloads nil nil ("display-theme-pkg.el") (21319 35736 499971
;;;;;;  776000))

;;;***

(provide 'display-theme-autoloads)
;; Local Variables:
;; version-control: never
;; no-byte-compile: t
;; no-update-autoloads: t
;; coding: utf-8
;; End:
;;; display-theme-autoloads.el ends here
