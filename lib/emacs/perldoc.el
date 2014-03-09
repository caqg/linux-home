;;; -*- Emacs-Lisp -*- 

(defvar *perldoc* "perldoc"
  "*Path (may be relative) to the perldoc executable, see M-x perldoc.")

(defvar *perldoc-flags* nil; "-t"
  "*Arguments given to perldoc (see M-x perldoc) ahead of the user-given ones.")

(defvar *perldoc-pager* nil; "col -b"
  "*Postprocessor to handle the output of M-x perldoc.")

(defun perldoc-quit (ignored)
  "Bury the current perldoc buffer.  Overrules the view-quit command, ignoring
its argument for compatibility."
  (interactive "P")
  (bury-buffer))

(defun perldoc (what &optional other-frame)
  "Runs perldoc with arguments from the string WHAT (interactive).
See also the variable *perldoc*, for the path to perldoc, the variable
*perldoc-flags* for the default flags (used ahead of this function's argument)
and the variable *perldoc-pager* for a postprocessor (set it to NIL if you do
not want postprocessing). 

The output is in a buffer named after WHAT, set to view-major-mode.  A second
optional argument controls whether to use a new frame.
		       
There are two ways to quit.  The recommended one is \\[perldoc-quit], which
makes it possible to return to view-mode browsing by re-selecting the buffer.
However, introducing this command has changed the view-mode-map; the standard
exit behavior can be obtained by \\[view-quit]."
  (interactive  "s$ perldoc \nP")
  (let* ((cmdline     (format "%s %s %s" *perldoc* (or *perldoc-flags* "") what))
	 (postproc    (if *perldoc-pager* (format " | %s" *perldoc-pager*) ""))
	 (name        (concat
		       "*" (mapconcat 'identity (split-string cmdline) " ") "*"))
	 (output      (get-buffer-create name))
	 (prev-buffer (current-buffer)))
    ;; bring up the display buffer, and operate on it directly
    (set-buffer output)
    (and buffer-read-only (toggle-read-only))
    (erase-buffer output)
    (shell-command (concat cmdline postproc) output)
    (set-buffer-modified-p nil output)
    (setq buffer-read-only t)
    ;; load the new text in the buffer.
    (view-major-mode prev-buffer (lambda (b) nil) 'clean-bs)
    (local-set-key "q" 'perldoc-quit)	; \C-c\C-c still handles 'view-quit
    ;; now show up the result, in this or another frame.
    (let ((w (get-buffer-window output)))
      (and w (delete-window w)))
    (if other-frame
	(switch-to-buffer-other-frame output)
      (switch-to-buffer output))
    (goto-char (point-min))))

;;; end perldoc.el
