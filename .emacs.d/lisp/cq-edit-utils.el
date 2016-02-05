;;;;                                                        -*- Emacs-Lisp -*-
;;; Copyright (C) 2014 by Cesar A Quiroz, Ph.D.
;;; 3595 Granada Ave Unit 114 / Santa Clara, CA 95051 / USA
;;; All Rights Reserved Worldwide
;;; mailto:cesar.quiroz@gmail.com

;;; There may be an emacs lisp function to do this already
(defun cq/region-width (p1 p2)
  "Visual distance between positions P1 and P2, if P1 is before P2. Else 0."
  (let ((pos (goto-char p1))
        (end (if (markerp p2) (marker-position p2) p2))
        (width 0))
    (while (< pos end)
      (let ((char (char-after pos)))
        (cond ((char-equal char ?\n)    ;never from cq/set-selective-display
               (setq width 0))
              ((char-equal char ?\t)
               (setq width (+ width tab-width)))
              ((char-equal char ?\ )
               (setq width (1+ width)))
              (t                        ;never from cq/set-selective-display
               (setq width (1+ width)))))
      (setq pos (1+ pos)))
    width))

(defun cq/set-selective-display (p)
  "Same as invoking `set-selective-display' on the prefix argument, except when
invoked with a plain \\C-u.

In that case, the current line's left margin determines what
levels of indentation are hidden. As usual, undo by invoking
`set-selective-display` again."
  (interactive "P")
  (cond ((consp p)                       ;(4) is the raw form of \C-u
         (let* ((bol (progn (move-beginning-of-line nil) (point)))
                (margin (progn (back-to-indentation) (point)))
                (indentation (cq/region-width bol margin)))
           (set-selective-display indentation)))
        (t
         (set-selective-display p))))


(defun cq/desensitize-case-for-regexp (r1 r2)
  "Replace the region, replacing all 2-case characters x with [Xx]"
  (interactive "*^r")
  (insert
   (mapconcat
    #'(lambda (c)
        (let ((ucase (upcase c))
              (dcase (downcase c)))
          (if (string= ucase dcase)
              c
            (concat "[" ucase dcase "]"))))
    (split-string (delete-and-extract-region r1 r2) "")
    "")))



(provide 'cq-edit-utils)
;;;; end cq-edit-utils.el
