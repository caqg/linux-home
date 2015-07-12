;;;;                                                        -*- Emacs-Lisp -*-
;;; Copyright (C) 2015 by Cesar A Quiroz, Ph.D.
;;; 3595 Granada Ave Unit 114 / Santa Clara, CA 95051 / USA
;;; All Rights Reserved Worldwide
;;; mailto:cesar.quiroz@gmail.com

(defun cq/minmod-flip (mode-symbol)
  "If the MODE_SYMBOL argument is true, turn off the associated minor mode.
Otherwise, turn the minor moe on."
  (interactive "S")
  (when (boundp mode-symbol)
    (let* ((current (symbol-value mode-symbol))
           (flipped (if current -1 1))
           (setter  (symbol-function mode-symbol)))
      (funcall setter flipped))))

;;;       (message "'%s before %s flipped %s after %s"
;;;               mode-symbol current flipped (symbol-value mode-symbol))

(defun cq/flip-scroll-bar-modes ()
  "Invert the status of scroll-bar-mode and horizontal-scroll-bar-mode"
  (interactive)
  (cq/minmod-flip 'scroll-bar-mode)
  (cq/minmod-flip 'horizontal-scroll-bar-mode))


;;; Menu entries


;;;; end minor-mode-utils.el
