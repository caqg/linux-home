;;; ctags-update-autoloads.el --- automatically extracted autoloads  -*- lexical-binding: t -*-
;;
;;; Code:

(add-to-list 'load-path (directory-file-name
                         (or (file-name-directory #$) (car load-path))))


;;;### (autoloads nil "ctags-update" "ctags-update.el" (0 0 0 0))
;;; Generated autoloads from ctags-update.el

(autoload 'ctags-update "ctags-update" "\
ctags-update in parent directory using `exuberant-ctags'.
1. you can call this function directly,
2. enable `ctags-auto-update-mode',
3. with prefix `C-u' then you can generate a new TAGS file in selected directory,
4. with prefix `C-uC-u' save the command to kill-ring instead of execute it.

\(fn &optional ARGS)" t nil)

(autoload 'ctags-auto-update-mode "ctags-update" "\
auto update TAGS using `exuberant-ctags' in parent directory.

If called interactively, toggle `Ctags-Auto-Update mode'.  If the
prefix argument is positive, enable the mode, and if it is zero
or negative, disable the mode.

If called from Lisp, toggle the mode if ARG is `toggle'.  Enable
the mode if ARG is nil, omitted, or is a positive number.
Disable the mode if ARG is a negative number.

The mode's hook is called both when the mode is enabled and when
it is disabled.

\(fn &optional ARG)" t nil)

(autoload 'turn-on-ctags-auto-update-mode "ctags-update" "\
turn on `ctags-auto-update-mode'." t nil)

(put 'ctags-global-auto-update-mode 'globalized-minor-mode t)

(defvar ctags-global-auto-update-mode nil "\
Non-nil if Ctags-Global-Auto-Update mode is enabled.
See the `ctags-global-auto-update-mode' command
for a description of this minor mode.
Setting this variable directly does not take effect;
either customize it (see the info node `Easy Customization')
or call the function `ctags-global-auto-update-mode'.")

(custom-autoload 'ctags-global-auto-update-mode "ctags-update" nil)

(autoload 'ctags-global-auto-update-mode "ctags-update" "\
Toggle Ctags-Auto-Update mode in all buffers.
With prefix ARG, enable Ctags-Global-Auto-Update mode if ARG is positive;
otherwise, disable it.  If called from Lisp, enable the mode if ARG is omitted or
nil.

Ctags-Auto-Update mode is enabled in all buffers where
`turn-on-ctags-auto-update-mode' would do it.

See `ctags-auto-update-mode' for more information on Ctags-Auto-Update mode.

\(fn &optional ARG)" t nil)

(register-definition-prefixes "ctags-update" '("ctags-"))

;;;***

;; Local Variables:
;; version-control: never
;; no-byte-compile: t
;; no-update-autoloads: t
;; coding: utf-8
;; End:
;;; ctags-update-autoloads.el ends here
