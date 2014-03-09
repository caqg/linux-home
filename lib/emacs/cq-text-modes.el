;;; -*- Mode: Emacs-Lisp -*-
;;;

(require 'balanced-insertions)
(provide 'cq-text-modes)

(defvar *cq-text-init-once* nil
  "Set this to non-nil if this has been initialized already.")

(defvar *cq-text-full-tab-list*
  '(8 16 24 32 40 48 56 64 72 80 88 96 104 112 120 128 132 140 148 156 160
      168 176))

(defvar *cq-text-half-tab-list*
  '(4 8 12 16 20 24 28 32 36 40 44 48 52 56 60 64 68 72 76
      80 84 88 92 96 100 104 108 112 116 120 124 128 132 136
      140 144 148 152 156 160 164 168 172 176 180))

(setq-default tab-stop-list *cq-text-full-tab-list*)

(eval-when (compile)
  (load-library "nroff-mode")           ;no provide for (require 'nroff-mode)
  (require 'picture))

(defun cq-text-mode ()
  "Sets text-mode to enable auto-fill and indented minors. CQ"
  (interactive)
  (setq truncate-lines t)		;local variable: for change-log.el
  (auto-fill-mode 1)
  (set-balanced-insertions)
  (setq indent-tabs-mode t)             ;change 94.07.14
  (local-set-key "\C-i" 'tab-to-tab-stop)
  (local-set-key "\M-i" 'indent-relative))

(defun cq-nroff-mode ()
  "Sets nroff-mode to be electric + indented. CQ"
  (interactive)
  (electric-nroff-mode 1)
  ;;(indented-minor-mode 1)
  ;; blink-matching is no use here (too many unbalanced parens)
  (setq blink-matching-paren nil)
  ;;VERY important!  use C-q TAB
  ;;if really needed. -me doesn't
  ;;like arbitrary tabs.
  (setq indent-tabs-mode nil)
  ;; make sure strings are considered sexps.
  ;; need a new syntax table, to avoid messing up
  ;; the fundamental mode table.
  (set-syntax-table (copy-syntax-table (syntax-table)))
  (modify-syntax-entry ?\" "\"" nil)
  ;; some more funcs and settings
  ;; (there should be a user-reserved keymap)
  (cq-nroff-local-set-keys)
  ;; fix paragraph delimiters
  (setq paragraph-separate  "^[.']\\|^[ \t\f]*$"
        paragraph-start     "^[.']\\|^[ \t\f]*$")
  ;; add my own delimiters -- see my 10pt-paper.me for definitions
  (make-local-variable 'nroff-brace-table)
  (setq nroff-brace-table
	(append (list
		 (cons ".G1" ".G2")     ;grap
		 (cons ".Cs" ".Ce")     ;in code font
		 (cons ".(C" ".)C")     ;display code
		 (cons ".Mi" ".Li")     ;More-Less Indentation
                 (cons ".St" ".Se")     ;StatementstarT-StatementEnd
                 (cons ".Pf" ".Pe")     ;ProoFstart-ProofEnd
		 (cons ".ba" ".ba 0")
		 (cons ".ie" ".el")
		 (cons ".am" "..")
		 (cons ".ig" ".."))
		nroff-brace-table))
  ;; deal with bib/refer files
  (let* ((filename      (buffer-file-name))
         (name-for-mode (if filename
                            (file-name-sans-versions
                             (file-name-nondirectory filename))
                          (buffer-name))))
    (cond ((or (string= name-for-mode "annotated")
               (string= name-for-mode "references"))
           (setq paragraph-separate  "^[ \t\f]*$"
                 paragraph-start     "^[.']\\|^[ \t\f]*$")
           (local-set-key "\M-\C-a" 'cq-bib-beginning-of-entry)
           (local-set-key "\M-\C-e" 'cq-bib-end-of-entry)
           (local-set-key "\M-\C-h" 'cq-bib-mark-entry)))))

(defun cq-nroff-local-set-keys ()
  "Set local keys as for nroff mode."
  (local-set-key "\e\""         'within-delimiters)
  (local-set-key "\C-j"         'cq-electric-nroff-newline)
  (set-balanced-insertions)
  (local-set-key "\C-z\C-ms"    'in-new-size)
  (local-set-key "\C-z\C-mf"    'in-new-font)
  (local-set-key "\C-z\C-m\C-f" 'in-code-font)
  (local-set-key "\C-z\C-m\C-i" 'in-italic-font)
  (local-set-key "\C-z\C-m\C-b" 'in-bold-font)
  (local-set-key "\C-z\C-m\C-x" 'in-bolditalic-font)
  (local-set-key "\C-z\C-m\C-r" 'in-roman-font)
  (local-set-key "\C-z\C-m^"    'in--me-superscript)
  (local-set-key "\C-z\C-m_"    'in--me-subscript)
  (local-set-key "\C-z\C-mu"    'in-up-then-down)
  (local-set-key "\C-z\C-md"    'in-down-then-up)
  (local-set-key "\C-z\C-mq"    'in--ms-quotes)
  ;; accents and such
  (local-set-key "\C-z\C-aa"    'in--me-acute-accent)
  (local-set-key "\C-z\C-ae"    'in--me-acute-accent)
  (local-set-key "\C-z\C-ai"    'in--me-acute-accent)
  (local-set-key "\C-z\C-ao"    'in--me-acute-accent)
  (local-set-key "\C-z\C-au"    'in--me-acute-accent)
  (local-set-key "\C-z\C-aA"    'in--me-acute-accent)
  (local-set-key "\C-z\C-aE"    'in--me-acute-accent)
  (local-set-key "\C-z\C-aI"    'in--me-acute-accent)
  (local-set-key "\C-z\C-aO"    'in--me-acute-accent)
  (local-set-key "\C-z\C-aU"    'in--me-acute-accent)
  (local-set-key "\C-z\C-^n"    'in--me-tilde-accent)
  (local-set-key "\C-z\C-uu"    'in--me-umlaut-accent)
  (local-set-key "\C-z\C-uU"    'in--me-umlaut-accent))

(defun forward-text-line (&optional cnt)
  "Go forward one nroff text line, skipping lines of nroff requests.
An argument is a repeat count; if negative, move backward."
  (interactive "p")
  (if (not cnt) (setq cnt 1))
  (while (and (> cnt 0) (not (eobp)))
    (forward-line 1)
    (while (and (not (eobp))
                (looking-at "[.']."))
      (forward-line 1))
    (setq cnt (- cnt 1)))
  (while (and (< cnt 0) (not (bobp)))
    (forward-line -1)
    (while (and (not (bobp))
		(looking-at "[.']."))
      (forward-line -1))
    (setq cnt (+ cnt 1)))
  cnt)

(defun cq-electric-nroff-newline (arg)
  "Insert newline for nroff mode; special if electric-nroff mode.
In electric-nroff-mode, if ending a line containing an nroff opening request,
automatically inserts the matching closing request after point.
Avoids opening extra blank lines."
  (interactive "P")
  (let ((completion (save-excursion
		      (beginning-of-line)
		      (and (null arg)
			   nroff-electric-mode
			   (<= (point) (- (point-max) 3))
			   (cdr (assoc (buffer-substring (point)
							 (+ 3 (point)))
				       nroff-brace-table)))))
        (needs-nl   (not (looking-at "[ \t]*$"))))
    (if (null completion)
	(newline (prefix-numeric-value arg))
      (save-excursion
	(insert "\n\n" completion (if needs-nl "\n" "")))
      (forward-char 1))))

(defun in-new-size (words)
  "Bracket temporary size change: \\s_\\s0.  With numeric argument,
bracket the next so many words."
  (interactive "p")
  (if (null current-prefix-arg) (setq words 0))
  (balanced-insertion "\\s" "\\s0" words 'forward-word 'mark))

(defun in-new-font (words)
  "Bracket temporary font change: \\f_\\fP.  With numeric argument,
bracket the next so many words."
  (interactive "p")
  (if (null current-prefix-arg) (setq words 0))
  (balanced-insertion "\\f" "\\fP" words 'forward-word 'mark))

(defun in-code-font (words)
  "Bracket temporary font change: \\f(\\*(Cf_\\fP.  With numeric argument,
bracket the next so many words."
  (interactive "p")
  (if (null current-prefix-arg) (setq words 0))
  (balanced-insertion "\\f\(\\*\(Cf" "\\fP" words 'forward-word 'mark))

(defun in-roman-font (words)
  "Bracket temporary font change: \\fR_\\fP.  With numeric argument,
bracket the next so many words."
  (interactive "p")
  (if (null current-prefix-arg) (setq words 0))
  (balanced-insertion "\\fR" "\\fP" words 'forward-word 'mark))

(defun in-italic-font (words)
  "Bracket temporary font change: \\fI_\\fP.  With numeric argument,
bracket the next so many words."
  (interactive "p")
  (if (null current-prefix-arg) (setq words 0))
  (balanced-insertion "\\fI" "\\fP" words 'forward-word 'mark))

(defun in-bold-font (words)
  "Bracket temporary font change: \\fB_\\fP.  With numeric argument,
bracket the next so many words."
  (interactive "p")
  (if (null current-prefix-arg) (setq words 0))
  (balanced-insertion "\\fB" "\\fP" words 'forward-word 'mark))

(defun in-bolditalic-font (words)
  "Bracket temporary font change: \\fX_\\fP.  With numeric argument,
bracket the next so many words."
  (interactive "p")
  (if (null current-prefix-arg) (setq words 0))
  (balanced-insertion "\\fX" "\\fP" words 'forward-word 'mark))

(defun in--me-superscript (words)
  "Put the next WORDS words in a superscript for -me."
  (interactive "p")
  (if (null current-prefix-arg) (setq words 0))
  (balanced-insertion "\\*[" "\\*]" words 'forward-word 'mark))

(defun in--me-subscript (words)
  "Put the next WORDS words in a subscript for -me."
  (interactive "p")
  (if (null current-prefix-arg) (setq words 0))
  (balanced-insertion "\\*<" "\\*>" words 'forward-word 'mark))

(defun in-up-then-down (words)
  "Put the next WORDS words in a nest of \\u-\\d, with compensation."
  (interactive "p")
  (if (null current-prefix-arg) (setq words 0))
  (balanced-insertion "\\u\\x'-0.25v'\\s-2" "\\s0\\d" words
                      'forward-word 'mark))


(defun in-down-then-up (words)
  "Put the next WORDS words in a nest of \\d-\\u, with compensation."
  (interactive "p")
  (if (null current-prefix-arg) (setq words 0))
  (balanced-insertion "\\d\\x'0.25v'\\s-2" "\\s0\\u" words
                      'forward-word 'mark))

(defun in--ms-quotes (words)
  "Put the next WORDS words in a nest of \\*Q \\*U, with compensation."
  (interactive "p")
  (if (null current-prefix-arg) (setq words 0))
  (balanced-insertion "\\*Q" "\\*U" words
                      'forward-word 'mark))

(defun in--me-accent (accent)
  "Put the last-command-char in the -me sequence for accenting with 
ACCENT."
  (insert "\\*(" last-command-char accent))

(defun in--me-acute-accent ()
  "Put last-command-char in the -me sequence for acute accent."
  (interactive)
  (in--me-accent ?'))

(defun in--me-tilde-accent ()
  "Put last-command-char in the -me sequence for tilde accent."
  (interactive)
  (insert last-command-char "\\*~"))

(defun in--me-umlaut-accent ()
  "Put last-command-char in the -me sequence for umlaut accent."
  (interactive)
  (in--me-accent ?:))

(defun cq-next-tab ()
  "Move cursor to next tab position. May use spaces. CQ"
  (interactive)
  (if indent-tabs-mode
      (insert "\t")                     ;user wants real tabs
    ;; else, user gets spaces
    (insert " ")
    (while (/= (% (current-column) tab-width) 0)
      (insert " "))))

(defun cq-tex-mode ()
  "TeX mode according to my taste.  CQ"
  (interactive)
  (set-balanced-insertions))

(defun cq-latex-mode ()
  "LaTeX mode according to my taste.  CQ"
  (interactive)
  (local-set-key "\C-zb" 'latex-bracket-region)
  (local-set-key "\C-ze" 'latex-delimit-environment)
  (setq *latex-template-dir* (concat emacslib "latex/")))

(defun cq-texinfo-mode ()
  "To edit TeXinfo files"
  (interactive)
  (set-balanced-insertions))

(defvar *latex-default-name* "paper" "*Name used for document if none given")
(defvar *latex-default-style* "article" "*Style used if none given.")
(defvar *latex-default-options* "" "*Default options used with the style.")
(defvar *latex-default-suffix* ".tex" "*String suffix for LaTeX filenames.")

(defvar *latex-template-dir* "./" "*Directory, where style templates live.")

(defun latex-delimit-environment (name)
  "Put the delimiters for environment NAME."
  (interactive "sEnvironment? ")
  (if (string= name "")
      (message "Ignoring command...")
    (if (not (looking-at "^"))
        (insert "\n"))
    (insert "\\begin{" name "}\n\n\\end{" name "}")
    (previous-line 1)))

(defun new-latex-document (name style options)
  "Create a new latex document, called NAME, of style STYLE and OPTIONS."
  (interactive "sName? \nsStyle? \nsOptions? ")
  (if (string= name "")
      (setq name *latex-default-name*))
  (if (string= style "")
      (setq style *latex-default-style*))
  (if (string= options "")
      (setq options *latex-default-options*))
  ;; determine the file name and the names of the optional templates
  (let ((fname (enforce-suffix name *latex-default-suffix*)))
    (pop-to-buffer (get-buffer-create fname))
    (erase-buffer)
    (latex-mode)
    (let* ((hname (concat *latex-template-dir* style ".head"))
           (bname (concat *latex-template-dir* style ".body")))
      (insert "% -*- Mode: LaTeX -*-\n")
      (insert "%**start of header\n")
      (insert "\\documentstyle" (if (string= options "")
                                    "{" (concat "[" options "]{"))
              style "}\n")
      (cond ((file-exists-p hname)
             (insert-file hname)
             (goto-char (mark))))
      (insert "%**end of header\n")
      (insert "\\begin{document}\n")
      (cond ((file-exists-p bname)
             (insert-file bname)
             (goto-char (mark))))
      (insert "\\end{document}\n")
      (insert "%% end of " fname "\n"))))

(defun enforce-suffix (name suffix)
  "If NAME doesn't end in SUFFIX, append it."
  (let* ((namelen (length name))
         (suffixlen (length suffix))
         (startup (- namelen suffixlen)))
    (if (or (< startup 0)
            (not (string= (substring name startup) suffix)))
        (concat name suffix)
      (copy-sequence name))))

(defun latex-bracket-region (r1 r2 header leankern)
  "Put around region (R1,R2) a TeX bracketing with HEADER at the
   beginning.  If fourth argument is \"\", include \\/ before the end."
  (interactive "r\nsHeader?[em] \nsDo we Lean At End?[t] ")
  (if (string= header "") (setq header "em"))
  (setq leankern (string= leankern ""))
  (goto-char r2)
  (if leankern (insert "\\/}") (insert "}"))
  (goto-char r1)
  (insert "{\\" header))

;;; Picture Mode
;;;
;;; I can never remember the commands that change direction, so I better use
;;; one command to query.

(defun cq-picture-mode ()
  "Picture mode settings. CQ"
  (setq indent-tabs-mode nil)
  (local-set-key "\^Cv"   'picture-movement-down)
  (local-set-key "\^C\^M" 'picture-query-direction))

(defvar picture-help-with-directions
    "One of r,l,u,d, n,s,e,w,ne,nw,se,sw

    r[ight], e[ast]   also in \\[picture-movement-right]
    l[eft],  w[est]   also in \\[picture-movement-left]
    u[p],    n[orth]  also in \\[picture-movement-up]
    d[own],  s[outh]  also in \\[picture-movement-down]

    n[orth]e[ast]     also in \\[picture-movement-ne]
    n[orth]w[est]     also in \\[picture-movement-nw]
    s[outh]e[ast]     also in \\[picture-movement-se]
    s[outh]w[est]     also in \\[picture-movement-sw]"
  "To display if the minibuffer requests help during direction selection.
The association of LEFT and EAST is conventional, although there is evidence
that proto-Indo-European identified RIGHT with SOUTH, contrary to modern
use.")

(defun picture-query-direction ()
  "Ask for a direction of motion, defaults to r[ight]"
  (interactive)
  (let* ((minibuffer-help-form (substitute-command-keys
                                picture-help-with-directions))
         (answer (read-from-minibuffer "Direction? " "r")))
    (cond ((or (string= answer "r")
               (string= answer "e"))
           (picture-movement-right))
          ((or (string= answer "d")
               (string= answer "s"))
           (picture-movement-down))
          ((or (string= answer "l")
               (string= answer "w"))
           (picture-movement-left))
          ((or (string= answer "u")
               (string= answer "n"))
           (picture-movement-up))
          ((string= answer "ne")
           (picture-movement-ne))
          ((string= answer "nw")
           (picture-movement-nw))
          ((string= answer "se")
           (picture-movement-se))
          ((string= answer "sw")
           (picture-movement-sw))
          (t
           (error "Wrong: %s" "One of r,l,u,d, n,s,e,w,ne,nw,se,sw")))))

;;; BIB motions

(defun cq-bib-beginning-of-entry ()
  "Move to the line following the last line of this entry"
  (interactive)
  (skip-chars-backward " \n\t\f" (point-min))
  (if (re-search-backward "^[ \t\f]*$" (point-min) 'to-top)
      (next-line 1)))

(defun cq-bib-end-of-entry ()
  "Move to the line following the last line of this entry"
  (interactive)
  (skip-chars-forward " \n\t\f" (point-max))
  (re-search-forward "^[ \t\f]*$" (point-max) 'to-bottom))

(defun cq-bib-mark-entry ()
  "Mark the bib entry at or after point.  Point is moved to the beginning of
the entry, mark is set at the end"
  (interactive)
  (cq-bib-end-of-entry)
  (push-mark)
  (cq-bib-beginning-of-entry))

;;; End of cq-text-modes.el
