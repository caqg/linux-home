;;; Customizations of code mode

(defun cq-generic-code-mode ()
  "Customize generic code mode to my liking."
  (interactive)
  ;; these are always useful, but may be bound to the wrong keys.
  (local-set-key "\M-i"     'point-to-tab-stop)
  (local-set-key "\C-\M-i"  'tab-to-tab-stop)
  ;; quotes appear often in such files as those in generic code mode
  ;; perhaps this syntax mode changes should be in generic-code-mode.el?
  (modify-syntax-entry ?'   "\"")
  (modify-syntax-entry ?`   "\"")
  (local-set-key "\C-\M-u"  'cq-backward-up-list-or-string)
  (local-set-key "\C-\M-d"  'cq-down-list)
  (set-balanced-insertions))

(defun new-script (name shell)
  "Create a new executable script, called NAME and running SHELL.
The shell name can be omitted, /bin/sh is assumed in that case.
The script name is mandatory, of course.  If that file exists, its
buffer is erased first.  The file is created with broad execute
permissions."
  (interactive "FScript Name? \nsShell Name?  [/bin/sh] ")
  (if (string= shell "") (setq shell "/bin/sh"))
  (setq name (expand-file-name name))
  (if (file-directory-p name)
      (error "%s is a directory." (prin1-to-string name)))
  (let ((file-existed (file-exists-p name))
        (buffer-existed (get-buffer  (file-name-nondirectory name))))
    (find-file name)
    (cond ((or file-existed buffer-existed)
           (if (yes-or-no-p "File already existed, want to erase it? ")
               (erase-buffer)
             (if (yes-or-no-p "Abort this function instead? ")
                 (error "User aborted action."))))))
  (unix-script-mode)
  (insert "#!" shell "\n\n")
  (insert "# $Id$\n# $Source$\n\n")
  (save-excursion
    (insert "\n\n"
            "# Emacs # local" " variables:\n";don't concatenate them yourself!
            "# Emacs # eval: "
            "(if (fboundp 'unix-script-mode) (unix-script-mode))\n"
            "# Emacs # end:\n"))
  (save-buffer)
  (call-process "/bin/chmod" nil nil nil "+x" name))

(defun cq-cakefile-mode ()
  "Setup for cakefiles."
  (abbrev-mode 1))

(defun cq-pic-mode ()
  "Setup for pic input"
  (set-scripts-syntax)
  (require 'cq-text-modes)
  (cq-nroff-local-set-keys))

(defun cq-sun-assembler-mode ()
  "Setup for Sun-Assembler"
  (abbrev-mode 1))

;;; Mathematica mode
(require 'generic-code-mode)

(defvar Mathematica-mode-hook nil)

(define-abbrev-table 'Mathematica-mode-abbrev-table ())

(defun Mathematica-mode ()
  "Major mode for editing Mathematica code.  
\\{Mathematica-mode-abbrev-table}"
  (interactive)
  (generic-code-mode)
  (setq mode-name "Code (Mathematica)")
  (make-local-variable 'comment-start)
  (setq comment-start "(* ")
  (make-local-variable 'comment-end)
  (setq comment-end " *)")
  (make-local-variable 'comment-column)
  (setq comment-column 32)
  (make-local-variable 'comment-start-skip)
  (setq comment-start-skip "(\\*+ *")
  (make-local-variable 'comment-indent-hook)
  (setq comment-indent-hook 'Mathematica-comment-indent)
  (setq comment-indent-hook 'c-comment-indent)
  (make-local-variable 'parse-sexp-ignore-comments)
  (setq parse-sexp-ignore-comments t)
  (run-hooks 'Mathematica-mode-hook))

(defun Mathematica-comment-indent ()
  (if (looking-at "^(\\*")
      0                                 ;Existing comment at bol stays there.
    (save-excursion
      (skip-chars-backward " \t")
      (max (1+ (current-column))	;Else indent at comment column
	   comment-column))))

;;; end of cq-generic-code-mode
