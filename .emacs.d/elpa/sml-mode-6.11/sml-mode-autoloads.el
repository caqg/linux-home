;;; sml-mode-autoloads.el --- automatically extracted autoloads (do not edit)   -*- lexical-binding: t -*-
;; Generated by the `loaddefs-generate' function.

;; This file is part of GNU Emacs.

;;; Code:

(add-to-list 'load-path (or (and load-file-name (file-name-directory load-file-name)) (car load-path)))



;;; Generated autoloads from sml-mode.el

(defalias 'run-sml 'sml-run)
(autoload 'sml-run "sml-mode" "\
Run the program CMD with given arguments ARG.
The command is run in buffer *CMD* using mode `inferior-sml-mode'.
If the buffer already exists and has a running process, then
just go to this buffer.

If a prefix argument is used, the user is also prompted for a HOST
on which to run CMD using `remote-shell-program'.

(Type \\[describe-mode] in the process's buffer for a list of commands.)

(fn CMD ARG &optional HOST)" t)
(add-to-list 'auto-mode-alist '("\\.s\\(ml\\|ig\\)\\'" . sml-mode))
(autoload 'sml-mode "sml-mode" "\
Major mode for editing Standard ML code.
This mode runs `sml-mode-hook' just before exiting.
See also (info \"(sml-mode)Top\").

(fn)" t)
(add-to-list 'completion-ignored-extensions ".cm/")
(add-to-list 'auto-mode-alist '("\\.cm\\'" . sml-cm-mode))
(autoload 'sml-cm-mode "sml-mode" "\
Major mode for SML/NJ's Compilation Manager configuration files.

(fn)" t)
(autoload 'sml-lex-mode "sml-mode" "\
Major Mode for editing ML-Lex files.

(fn)" t)
(add-to-list 'auto-mode-alist '("\\.grm\\'" . sml-yacc-mode))
(autoload 'sml-yacc-mode "sml-mode" "\
Major Mode for editing ML-Yacc files.

(fn)" t)
(register-definition-prefixes "sml-mode" '("font-lock-" "inferior-sml-" "sml-"))

;;; End of scraped data

(provide 'sml-mode-autoloads)

;; Local Variables:
;; version-control: never
;; no-byte-compile: t
;; no-update-autoloads: t
;; no-native-compile: t
;; coding: utf-8-emacs-unix
;; End:

;;; sml-mode-autoloads.el ends here
