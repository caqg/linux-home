;;;;                                                        -*- Emacs-Lisp -*-
;;; Copyright (C) 2014 by Cesar A Quiroz, Ph.D.
;;; 3595 Granada Ave Unit 114 / Santa Clara, CA 95051 / USA
;;; All Rights Reserved Worldwide
;;; mailto:cesar.quiroz@gmail.com

(defun cq/set-selective-display (p)
  "Same as invoking `set-selective-display' on the prefix argument, except when
invoked with a plain \\C-u.

In that case, the current line's left margin determines what
levels of indentation are hidden. As usual, undo by invoking
set-selective-display again."
  (interactive "P")
  (cond ((consp p)                       ;(4) is the raw form of \C-u
         (let* ((bol (progn
                       (move-beginning-of-line nil)
                       (point)))
                (margin (progn
                          (back-to-indentation)
                          (point)))
                (indentation (- margin bol)))
           (set-selective-display indentation)))
        (t
         (set-selective-display p))))




(provide 'cq-edit-utils)
;;;; end cq-edit-utils.el
