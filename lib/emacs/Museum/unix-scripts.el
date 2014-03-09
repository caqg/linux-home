;;;; -*- Mode: Emacs-Lisp -*-

;;; An elaboration of generic-code-mode, that provides the usual
;;; syntax for Unix shell scripts, awk programs, icon programs, ...

(provide 'unix-script-mode)
(require 'generic-code-mode)

(defun unix-script-mode ()
  "Almost a major mode, this is just an elaboration of
generic-code-mode (q.v.).  This mode provides also the scripts syntax
defined by set-scripts-syntax.")
