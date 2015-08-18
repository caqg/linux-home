;;;;                                                        -*- Emacs-Lisp -*-
;;; Copyright (C) 2015 by Cesar A Quiroz, Ph.D.
;;; 3595 Granada Ave Unit 114 / Santa Clara, CA 95051 / USA
;;; All Rights Reserved Worldwide
;;; mailto:cesar.quiroz@gmail.com

(require 'whitespace)

(defvar *cq/trim-whitespace-excluded-modes*
  (list 'fundamental-mode 'text-mode 'picture-mode 'markdown-mode)
  "A list of symbols, mode names, exempted by `cq/trim-whitespace'")

(defvar *cq/trim-whitespace-inherited-constraints*
  (list (cons 'makefile-mode #'(lambda (wspstyl)
                                 (mapc
                                  #'(lambda (excluded-style)
                                      (setq wspstyl
                                            (remove excluded-style wspstyl)))
                                  '(indentation
                                          indentation:tab
                                          indentation:space))
                                 wspstyl)))
  "An alist of major mode symbols and functions that return a value for
whitespace-style' to use if the current `major-mode' is derived from the key
one.")

(defun cq/pick-whitespace-inherited-constraints ()
  "Return a function that, when applied to the value of `whitespace-style' will
return a new value for that variable, suitable for the current major-mode"
  (let ((constraints *cq/trim-whitespace-inherited-constraints*)
        (result 'identity))
    (while constraints
      (let ((constraint (car constraints)))
        (cond ((derived-mode-p (car constraint))
               (setq result (cdr constraint))
               (setq constraints nil))
              (t
               (setq constraints (cdr constraints))))))
    result))

(defun cq/tailor-whitespace-style ()
  "Return a value for whitespace-style, tailoed to the currrent major mode per
`*cq/trim-whitespace-inherited-constraints*'"
  (let ((whitespace-style whitespace-style)
        (constraint (cq/pick-whitespace-inherited-constraints)))
    (funcall constraint whitespace-style)))

(defun cq/trim-whitespace ()
  "On saving, cleanup whitespace all over the buffer"
  (unless (memq major-mode *cq/trim-whitespace-excluded-modes*)
    (let ((whitespace-style (cq/tailor-whitespace-style)))
      (whitespace-cleanup)))
  t)

(provide 'cq-file-hooks)
;;;; end cq-file-hooks.el
