;;;; -*- Emacs-Lisp -*-

;;; Minor utilities missed from XEmacs or some other emacs.

(defun zap-up-to-char (arg char)
  "Kill up to, but not including, ARG'th occurrence of CHAR.
Case is ignored if `case-fold-search' is non-nil in the current buffer.
Goes backward if ARG is negative; error if CHAR not found."
  (interactive "p\ncZap to char: ")
  (kill-region (point) (progn
                         (search-forward (char-to-string char) nil nil arg)
                         (goto-char (if (> arg 0) (1- (point)) (1+ (point))))
                         )))

;;; True workarounds (fixes for bugs in some Emacs still in use).

(when (and (= emacs-major-version 24)
           (< emacs-minor-version 4))
  (setq compilation-directory-matcher
        '("\\(?:Entering\\|Leavin\\(g\\)\\) directory [`']\\(.+\\)'$" (2 . 1))))


;;;; end
