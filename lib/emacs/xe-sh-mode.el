;;; Adaptations for XEmacs's shell mode.

(require 'sh-script "sh-script")

(defun cq-sh-indent-line (&optional reindent)
  "Without a prefix arg:
If not at the indentation, add a tab.  Else, indent the line under
the previous non-empty one (per sh-indent-line) or extend that
indentation to another tab stop.

With a '-' prefix arg:
Delete the indentation.

With any other prefix arg:
Delete all the indentation and then re-indent, which is useful if you have
extended the indentation more times than you wanted to."
  (interactive "P")
  (let* ((indentation (locate-indentation))
	 (at-indentation (first indentation))
	 (indentation-start (second indentation))
	 (indentation-end (third indentation)))
    (cond ((not reindent)
	   (if at-indentation
	       (sh-indent-line)
	     (insert "\t")))
	  ((eq reindent '-)
	   (delete-region indentation-start indentation-end))
	  (t
	   (delete-region indentation-start indentation-end)
	   (sh-indent-line)))))

(defun cq-sh-mode-hook()
  "Add to the hook run by sh-mode (XEmacs and derivatives)."
  (local-set-key "\C-i" 'cq-sh-indent-line)
  (font-lock-mode (and (< (buffer-size) font-lock-maximum-size) 1))
  (setq sh-indentation 8)
  (let ((sh-name (cond ((string-match "csh" (buffer-name))
			"/bin/csh")
		       ((string-match "login" (buffer-name))
			"/bin/csh")
		       (t
			"/bin/sh"))))
    (sh-set-shell sh-name)
    (auto-fill-mode 0)
;;    (cond ((string= sh-name "/bin/csh")
;;	   (auto-fill-mode 0))
;;	  (t
;;	   (auto-fill-mode 1)
;;	   (setq fill-column 78)))
    sh-name))

;;; end xe-sh-mode.el
