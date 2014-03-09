;;; -*- Emacs-Lisp -*- 
;;; Copyright (C) 2006 by Cesar A Quiroz, Ph.D.
;;; 3500 Granada Ave Apt 348 / Santa Clara, CA 95051 / USA
;;; Released under the GPL.
;;; mailto:cesar.quiroz@gmail.com

(require 'cl)
(provide 'cq-multi-shell)		;2007-06-02 08:11:27UT (cesar@bears06-01)

(defvar *cq-next-shell-number* 0
  "* The number used by the next multi-shell buffer.  If 0, the buffer is
  named just *shell*, otherwise it is *shell-NUMBER*.")

(defun cq-make-shell-name (shell-number)
  "Returns the shell name corresponding to the given SHELL-NUMBER."
  (cond ((null shell-number)
	 (cq-make-shell-name 0))
        ((listp shell-number)
         (cq-make-next-shell-name))
	((integerp shell-number)
	 (assert (>= shell-number 0))
	 (format "*shell-%d*" shell-number))
	(t (error 'invalid-argument shell-number))))

(defun cq-make-next-shell-name ()
  "Return the next shell name, and commit to that choice.  Repeated calls
produce consecutive names."
  (let ((n *cq-next-shell-number*))
    (incf *cq-next-shell-number*)
    (cq-make-shell-name n)))

(defun cq-multi-shell (shell-number)
  "Handle multiple shell buffers.  An integer argument >= 0 selects or starts a
shell with the given name.  An null prefix argument is the same at (shell).  A
non-null prefix argument requests a new shell buffer, with the number chosen
by this code."
  (interactive "P")
  (cond ((null shell-number)		;delegate to the standard shell
	 (shell))
	((listp shell-number)		;make new shell
	 (shell (cq-make-next-shell-name)))
	((and (integerp shell-number) (>= shell-number 0)) ;select or new
	 (shell (cq-make-shell-name shell-number)))
	(t				;reserved for new development
	 (error 'invalid-argument shell-number))))

(defun cq-multi-shell-other-window (shell-number)
  "Like (cq-multi-shell SHELL-NUMBER), but selects a different window in the same
frame."
  (interactive "P")
  (let* ((shell-number (if (integerp shell-number)
                           shell-number
                         (prog1 *cq-next-shell-number*
                                (incf *cq-next-shell-number*))))
         (shell-buffer-name (cq-make-shell-name shell-number)))
    (switch-to-buffer-other-window shell-buffer-name)
    (cq-multi-shell shell-number)))

;;; cq-multi-shell.el
