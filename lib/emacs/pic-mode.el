;;;; -*- Mode: Emacs-Lisp -*-
;;;
;;; Mode for editing pic input.  Trivial variation on generic-code

(provide 'pic-mode)
(defvar pic-mode-map            nil)
(defvar pic-mode-syntax-table   nil)
(defvar pic-mode-abbrev-table   nil)
(defvar pic-mode-hook           nil)

(defun pic-mode ()
  "Mode for editing raw pic input.
Uses generic-code-mode as a basic mode."
  (interactive)
  (generic-code-mode)
  (set-scripts-syntax)
  (lsetq
   pic-mode-map            (copy-keymap generic-code-mode-map)
   pic-mode-syntax-table   generic-code-mode-syntax-table
   pic-mode-abbrev-table   generic-code-mode-abbrev-table
   paragraph-start         "^[ 	]*$\\|^[^ 	]")
  (use-local-map pic-mode-map)
  (set-syntax-table pic-mode-syntax-table)
  (setq local-abbrev-table pic-mode-abbrev-table)
  (setq major-mode 'pic-mode
        mode-name  "Pic Input")
  (run-hooks 'pic-mode-hook))

;;; end of pic-mode.el
