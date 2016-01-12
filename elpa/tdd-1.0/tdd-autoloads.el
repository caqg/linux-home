;;; tdd-autoloads.el --- automatically extracted autoloads
;;
;;; Code:


;;;### (autoloads (tdd-mode) "tdd" "tdd.el" (21404 44038 579355 556000))
;;; Generated autoloads from tdd.el

(defvar tdd-mode nil "\
Non-nil if Tdd mode is enabled.
See the command `tdd-mode' for a description of this minor mode.
Setting this variable directly does not take effect;
either customize it (see the info node `Easy Customization')
or call the function `tdd-mode'.")

(custom-autoload 'tdd-mode "tdd" nil)

(autoload 'tdd-mode "tdd" "\
Test-driven development global minor mode.

Runs `recompile' every time a buffer is saved, and adjusts a mode
line indicator depending on the success or failure of that
compilation command.

\(fn &optional ARG)" t nil)

;;;***

;;;### (autoloads nil nil ("tdd-pkg.el") (21404 44038 685384 677000))

;;;***

(provide 'tdd-autoloads)
;; Local Variables:
;; version-control: never
;; no-byte-compile: t
;; no-update-autoloads: t
;; coding: utf-8
;; End:
;;; tdd-autoloads.el ends here
