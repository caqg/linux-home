;;;;                                                        -*- Emacs-Lisp -*-
;;; Copyright (C) 2015 by Cesar A Quiroz, Ph.D.
;;; 3595 Granada Ave Unit 114 / Santa Clara, CA 95051 / USA
;;; All Rights Reserved Worldwide
;;; mailto:cesar.quiroz@gmail.com

(defun cq/minmod-flip (mode-symbol)
  "If the MODE_SYMBOL argument is true, turn off the associated minor mode.
Otherwise, turn the minor mode on."
  (interactive "S")
  (when (boundp mode-symbol)
    (let* ((current (symbol-value mode-symbol))
           (flipped (if current -1 1))
           (setter  (symbol-function mode-symbol)))
      (funcall setter flipped))))

(defun cq/flip-scroll-bar-modes ()
  "Invert the status of scroll-bar-mode and horizontal-scroll-bar-mode"
  (interactive)
  (cq/minmod-flip 'scroll-bar-mode)
  (cq/minmod-flip 'horizontal-scroll-bar-mode))



(defvar *cq/current-directory-git-branch-cmd*
  "git branch 2>/dev/null | sed -n '/\\* \\(.*\\)/s// \\1/p'"
  "Command whose output is the git branch for the current directory")

(defun cq/get-current-directory-git-branch ()
  "Return the name of the current directory's Git branch, or an empty screen"
  (string-utils-trim-whitespace
   (shell-command-to-string
    *cq/current-directory-git-branch-cmd*)))

(defun cq/get-git-branch-mode-line-item ()
  "If the current directory is in a Git branch, return a suitable item for the
mode line, else an empty string"
  (let ((git-branch-name (cq/get-current-directory-git-branch)))
    (if (string= "" git-branch-name)
        ""
      (concat "Git:" git-branch-name))))



(provide 'cq-minor-mode-utils)
;;;; end cq-minor-mode-utils.el
