;;; -*- Mode: Emacs-Lisp -*-
;;;

(defun common-lisp-mode ()
  "Indentation for Common Lisp.  
   Uses the commands of lisp-mode, which see. CQ"
  (interactive)
  (lisp-mode)                           ;begin with something known to work
  ;; this is to anticipate a more comprehensive parser that will understand
  ;; comments of the #| ... |# style
  (modify-syntax-entry ?\# "' 14")
  (modify-syntax-entry ?\| "\\ 23")
  ;; fix indentation styles.  I'm not necessarily following Steele.
  ;; -- special forms --
  (put 'block 'lisp-indent-hook 1)
  (put 'catch 'lisp-indent-hook 1)
  (put 'compiler-let 'lisp-indent-hook 1)
  (put 'declare 'lisp-indent-hook nil)
  (put 'eval-when 'lisp-indent-hook 1)
  (put 'flet 'lisp-indent-hook 1)
  (put 'function 'lisp-indent-hook nil)
  (put 'go 'lisp-indent-hook 0)
  (put 'if 'lisp-indent-hook 3)
  (put 'labels 'lisp-indent-hook '1)
  (put 'let 'lisp-indent-hook 1)
  (put 'let* 'lisp-indent-hook 1)
  (put 'macrolet 'lisp-indent-hook 1)
  (put 'multiple-value-call 'lisp-indent-hook 1)
  (put 'multiple-value-prog1 'lisp-indent-hook 1)
  (put 'prog 'lisp-indent-hook 1)       ;labels are still mishandled
  (put 'progn 'lisp-indent-hook 0)
  (put 'progv 'lisp-indent-hook 1)
  (put 'quote 'lisp-indent-hook nil)
  (put 'return-from 'lisp-indent-hook 1)
  (put 'setq 'lisp-indent-hook nil)
  (put 'tagbody 'lisp-indent-hook nil)
  (put 'the 'lisp-indent-hook 1)
  (put 'throw 'lisp-indent-hook 1)
  (put 'unwind-protect 'lisp-indent-hook 1)
  ;; -- iterations --
  (put 'do 'lisp-indent-hook 2)
  (put 'do* 'lisp-indent-hook 2)
  (put 'dolist 'lisp-indent-hook 1)
  (put 'dotimes 'lisp-indent-hook 1)
  (put 'do-all-symbols 'lisp-indent-hook 1)
  (put 'do-external-symbols 'lisp-indent-hook 1)
  (put 'do-symbols 'lisp-indent-hook 1)
  ;; -- "with-" --
  (put 'with-input-from-string 'lisp-indent-hook 1)
  (put 'with-output-to-string 'lisp-indent-hook 1)
  (put 'with-open-file 'lisp-indent-hook 1)
  (put 'with-open-stream 'lisp-indent-hook 1)
  ;; -- "multiple-value-" --
  (put 'multiple-value-bind 'lisp-indent-hook 2)
  (put 'multiple-value-setq 'lisp-indent-hook 2)
  (put 'multiple-value-list 'lisp-indent-hook nil)
  ;; -- other conditionals --
  (put 'case 'lisp-indent-hook 1)
  (put 'ecase 'lisp-indent-hook 1)
  (put 'ccase 'lisp-indent-hook 1)
  (put 'typecase 'lisp-indent-hook 1)
  (put 'etypecase 'lisp-indent-hook 1)
  (put 'ctypecase 'lisp-indent-hook 1)
  (put 'when 'lisp-indent-hook 1)
  (put 'unless 'lisp-indent-hook 1)
  ;; -- other declarations --
  (put 'proclaim 'lisp-indent-hook nil)
  (put 'locally  'lisp-indent-hook nil)
  ;; wrap up change
  (setq major-mode 'common-lisp-mode)
  (setq mode-name "Common-Lisp")
  (run-hooks 'common-lisp-mode-hook))

