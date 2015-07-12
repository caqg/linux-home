;;;;                                                        -*- Emacs-Lisp -*-
;;; Copyright (C) 2015 by Cesar A Quiroz, Ph.D.
;;; 3595 Granada Ave Unit 114 / Santa Clara, CA 95051 / USA
;;; All Rights Reserved Worldwide
;;; mailto:cesar.quiroz@gmail.com

(defun cq/minmod-flip (mode-symbol)
  "If the MODE_SYMBOL argument is true, turn off the associated minor mode.
Otherwise, turn the minor moe on."
  (interactive "S")
  (when (and (boundp mode-symbol) (booleanp (symbol-value mode-symbol)))
    (let* ((current (symbol-value mode-symbol))
           (flipped (if current -1 0))))
      (funcall (symbol-function mode-symbol)))))


;;;; end minor-mode-utils.el
