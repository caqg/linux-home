;;;;                                                        -*- Emacs-Lisp -*-
;;; Copyright (C) 2015 by Cesar A Quiroz, Ph.D.
;;; 3595 Granada Ave Unit 114 / Santa Clara, CA 95051 / USA
;;; All Rights Reserved Worldwide
;;; mailto:cesar.quiroz@gmail.com

(require 'whitespace)

(defvar *cq/trim-whitespace-excluded-modes*
  (list 'fundamental-mode 'text-mode 'picture-mode 'markdown-mode)
  "A list of symbols, mode names, exempted by `cq/trim-whitespace'.")

(defun cq/trim-whitespace ()
  "On saving, delete trailing whitespace per line, and empty lines at end."
  (let ((delete-trailing-line t))
    (unless (memq major-mode *cq/trim-whitespace-excluded-modes*)
      ;; (delete-trailing-whitespace)
      (whitespace-cleanup)))
  t)


(provide 'cq-file-hooks)
;;;; end cq-file-hooks.el
