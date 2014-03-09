;;;; cq-lisp-mode.el
;;; Customizations for Lisp Modes
;;;
(require 'cq-shell)

(defvar *global-functionals-or-typed*
    '(apply assoc-if assoc-if-not concatenate count-if count-if-not
      delete-if delete-if-not every find-if find-if-not funcall 
      (map . 2)
      mapc mapcan mapcar mapcon maphash mapl maplist
      member-if member-if-not merge notany notevery
      (nsubst-if . 2) (nsubst-if-not . 2)
      (nsubstitute-if . 2) (nsubstitute-if-not . 2)
      position-if position-if-not rassoc-if rassoc-if-not
      reduce remove-if remove-if-not some
      (subst-if . 2) (subst-if-not . 2)
      (substitute-if . 2) (substitute-if-not . 2))
  "List of [some] Common Lisp functions that take a function argument
or a type specifier argument early in their lambda-lists, and for
which I might use a non-standard indentation.  Each entry is either a
symbol (in whose case the spec used for indentation will be `1') or a
cons, whose `car' is the symbol to set and whose `cdr' is the spec to use.
See also `[un]set-questionable-indentation'.")

(defun set-questionable-indentation ()
  "Set the indent hooks of several Common Lisp functions in a
non-standard, but perhaps clearer way.  The affected functions take a
function or a type specifier `early' in their arglists, making it
desirable to consider all the arguments up to that one `special'.  See
the variables `*global-functionals-or-typed*'.  Undo these settings with
the function `unset-questionable-indentation'"
  (interactive)
  ;; Default: use a spec of 1
  (mapcar (function (lambda (symbol-or-cons)
                      (if (symbolp symbol-or-cons)
                          (put symbol-or-cons 'common-lisp-indent-hook 1)
                        (put (car symbol-or-cons)
                             'common-lisp-indent-hook (cdr symbol-or-cons)))))
    *global-functionals-or-typed*))

(defun unset-questionable-indentation ()
  "Undo the effect of `set-questionable-indentation' (q.v.)"
  (interactive)
  (mapcar (function (lambda (symbol-or-cons)
                      (if (symbolp symbol-or-cons)
                          (put symbol-or-cons 'common-lisp-indent-hook nil)
                        (put (car symbol-or-cons)
                             'common-lisp-indent-hook nil))))
    *global-functionals-or-typed*))

(defun cq-lisp-mode ()
  "Customizations common to all the lisp modes."
  (interactive)
  (auto-fill-mode 1)
  (lsetq
   blink-matching-paren    t
   indent-tabs-mode        nil
   shell-prompt-pattern    "^[^ 	]*>>* *" ;tailored to KCL
   fill-column             78)
  ;; getting more functions
  (autoload 'condify-sexp (concat emacslib "deuglify")
            "Change ifs into conds in the sexpr immediately after point"
            t nil)
  ;; adaptation for H. Weeks's lisp-mode
  (setq lisp-comment-indent-specification   (list comment-column t nil 0)
        lisp-electric-semicolon             t
        lisp-maximum-indent-struct-depth    5)
  ;; local bindings
  (set-balanced-insertions)
  (local-set-key "\C-zi"    'cq-both-in)
  (local-set-key "\C-zo"    'cq-both-out)
  (local-set-key "\C-zx"    'cq-extract-sexp)
  (local-set-key "\C-\M-u"  'cq-backward-up-list-or-string)
  (local-set-key "\C-\M-d"  'cq-down-list)
  (local-set-key "\C-z]"    'cq-close-defun)
  ;; (local-set-key "\C-c\C-i" 'indent-differently)
  ;; not clear they should be here!  there should be a specific
  ;; inferior-lisp-mode-hook
  ;; For AKCL's find-doc
  (when (and (not (memq major-mode
                        (list 'emacs-lisp-mode 'lisp-interaction-mode)))
             (or (not (boundp 'doc-file-name)) (null doc-file-name))
             (boundp '*thesis-doc-filename*) *thesis-doc-filename*
             (file-readable-p *thesis-doc-filename*))
    (visit-doc-file *thesis-doc-filename*))
  (when (eq major-mode 'inferior-lisp-mode)
    (cq-inferior-lisp-mode)))

(defun cq-emacs-lisp-mode ()
  "Customizations used for Emacs-Lisp only"
  (interactive)
  (cq-lisp-mode)
  (put 'define-abbrev-table 'emacs-lisp-indent-hook 1)
  (put 'defsetf 'emacs-lisp-indent-hook 2)
  (modify-syntax-entry ?\[ "\(\]" emacs-lisp-mode-syntax-table)
  (modify-syntax-entry ?\] "\)\[" emacs-lisp-mode-syntax-table))

(defun cq-lisp-interaction-mode ()
  "Customizations for Lisp Interaction."
  (interactive)
  (cq-lisp-mode))
;  (local-set-key "\C-j" (function (lambda (p)
;                                    (interactive "P")
;                                    (call-interactively
;                                     (if p
;                                         'cl-eval-print-last-sexp
;                                        'eval-print-last-sexp))))))
(defun cq-common-lisp-mode ()
  "Customizations for Common Lisp."
  (set-questionable-indentation)
  (put 'defsys:defsystem 'common-lisp-indent-hook
       '((1 2 quote) (0 t 2)))
  (put 'loop             'common-lisp-indent-hook
       '(lisp-indent-keyword-list ;; used to be a tagbody!
         nil                            ;quoted
         nil                            ;args-in-pairs
         t                              ;keyword-count, T means all
         t                              ;special-keyword-count
         nil                            ;special count 
         nil                            ;ignore-after-count
         ;; keywords of the loop macro that need special indentation
         "for" "with" "repeat" "named"
         "initially" "finally"
         "do" "doing"
         "collect" "collecting"
         "nconc" "nconcing"
         "append" "appending"
         "count" "counting"
         "sum" "summing"
         "maximize" "minimize"
         "while" "until"
         "always" "never" "thereis"
         "when" "if" "unless"))
  ;; (local-set-key "\C-z\C-l" 'resume-lisp)
  (local-set-key "\C-hd" 'find-doc))

;;; more structure editing commands

(defun cq-both-in (dot1 dot2)
  "Insert parentheses around the sexps containing the region.
A program has to pass two positions, DOT1 and DOT2
The left parenthesis goes before the sexp that BEGINS at or before DOT1,
the right one goes after the sexp that ENDS at or after DOT2
Most likely, what you really want is INSERT-PARENTHESES
See also WITHIN-DELIMITERS"
  (interactive "r")
  (if (> dot1 dot2)                     ;ensure order!
      (let ((d1 dot1)
            (d2 dot2))
        (setq dot1 d2 dot2 d1)))
  (save-excursion
    ;; right paren first, otherwise have to fix
    ;; dot2 after pushing "(" at dot1.
    (goto-char dot2)
    (backward-sexp 1)
    (forward-sexp 1)
    (insert "\)")
    ;; left paren -- dot1 is still dot1!
    (goto-char dot1)
    (forward-sexp 1)
    (backward-sexp 1)
    (insert "\(")))

(defun cq-both-out (dot)
  "Remove parentheses around the list enclosing DOT.
Common usage:  put the cursor at the beginning of the list you want,
mark that list and call this function.  BUG: it should know to operate
inside the region only"
  (interactive "d")
  (save-excursion
    (goto-char dot)
    (if (not (looking-at "("))
        (backward-up-list 1))           ;find the left parenthesis
    (let ((lpar-pos (dot)))
      (forward-list)
      (delete-char -1)
      (goto-char lpar-pos))             ;back to the left parenthesis
    (delete-char 1)))

(defun cq-extract-sexp (dot)
  "Take the s-expression at or after DOT out of the list enclosing it
The extracted sexp replaces the containing list, and is regrinded.
To extract a list from inside another, set point first to the open delimiter"
  (interactive "d")
  (goto-char dot)                       ;make sure we are there
  (let* ((sexp-end     (progn (forward-sexp 1)  (point)))
         (sexp-begin   (progn (backward-sexp 1) (point)))
         (sexp-string  (buffer-substring sexp-begin sexp-end))
         (list-begin   (progn (backward-up-list 1) (point)))
         (list-end     (progn (forward-sexp 1) (point))))
    (delete-region list-begin list-end)
    (save-excursion
      (insert sexp-string)
      (if (and (string-match "\\S $" sexp-string)
               (looking-at "\\s_\\|\\sw"))
          (insert " ")))
    (indent-sexp)))

;;; Posted by peck@sun.com (23 Feb 88)
;;;
;;; Fixes and cleanup, CQ (04 March 88)

(defvar inferior-lisp-editor "emacsclient"
  "*Editor to mention to the inferior lisp, in case it needs one ;-)")

(defvar *lisp-history-capacity* *shell-history-capacity*
  "Size of the inferior lisp interaction histories.")

(defun resume-lisp ()
  "Return to the *lisp* buffer.  Create a new one if needed.  If the
buffer exists, but the inferior-lisp lisp has exited, restart it."
  (interactive)
  (let* ((buffername        "*lisp*")
         (buffer            (get-buffer-create buffername))
         (proc              (get-buffer-process buffer))
         (status            (if proc (process-status proc)))
         ;; prepare to pop to the lisp window
         (pop-up-windows    t)
         (*shell-history-capacity* *lisp-history-capacity*))
    ;; arrange for server editing
    (if (not (and (boundp 'server-process)
                  server-process
                  (memq (process-status server-process) '(run stop))))
        (server-start))
    (cond ((memq status '(run stop
                          open          ;added by fi:
                          ))
           (pop-to-buffer buffer)
           (end-of-buffer))
          (t
           (switch-to-buffer buffer)
           (save-restriction
             (if (/= (point-max) 1)     ;first time around?
                 (newline)))
           (insert ";;;; " inferior-lisp-program "  "
                   (current-time-string) "\n")
           (run-lisp)))))

(defun resume-scheme ()
  "Return to the *scheme* buffer.  Create a new one if needed.  If the
buffer exists, but the inferior-scheme scheme has exited, restart it."
  (interactive)
  (let* ((buffername        "*scheme*")
         (buffer            (get-buffer-create buffername))
         (proc              (get-buffer-process buffer))
         (status            (if proc (process-status proc)))
         ;; prepare to pop to the scheme window
         (pop-up-windows    t))
    (cond ((memq status '(run stop
                          open          ;added by fi:
                          ))
           (pop-to-buffer buffer)
           (end-of-buffer))
          (t
           (switch-to-buffer buffer)
           (save-restriction
             (if (/= (point-max) 1)     ;first time around?
                 (newline)))
           (insert ";;;; Scheme " (current-time-string) "\n")
           (run-scheme (xscheme-default-command-line))))))

;;; The standard backward-up-list gives an error if the cursor is
;;; inside a string.  This function moves point to the beginning of the
;;; string and retries from there.  It is an error to reach top level
;;; when backing out of a string (this bounds the retries and catches
;;; a few ill-ground constructs).

(defun cq-backward-up-list (arg)
  "This is like backward-up-list (q.v.), except that it treats strings
as atoms, and skips them completely.  See also cq-down-list and
cq-backward-up-list-or-string."
  (interactive "p")
  (let* ((here (point))
         (top  (progn (beginning-of-defun) (point)))
         (parse) (delim))
    (setq parse (parse-partial-sexp top here))
    (cond ((setq delim (nth 3 parse))   ;inside a string
           (search-backward (char-to-string delim) top)
           (cq-backward-up-list arg))
          (t                            ;OK, just call the Emacs primitive
           (backward-up-list arg)))))

(defun cq-down-list (arg)
  "This is like down-list (q.v.), except that it treats strings
as atoms, and skips them completely.  See also cq-backward-up-list."
  (interactive "p")
  (let* ((here (point))
         (top  (progn (beginning-of-defun) (point)))
         (parse) (delim))
    (setq parse (parse-partial-sexp top here))
    (cond ((setq delim (nth 3 parse))   ;inside a string
           (search-backward (char-to-string delim) top)
           (cq-down-list arg))
          (t                            ;OK, just call the Emacs primitive
           (down-list arg)))))

;;; This is a more elaborate reimplementation of backward-up-list,
;;; that exits from lists or strings.  CQ-BACKWARD-UP-LIST just takes
;;; a string as an atom, CQ-BACKWARD-UP-LIST-OR-STRING considers the
;;; string delimiters as `lists' to exit from.

(defun out-of-string-maybe (arg)
  "If point is inside a string, and ARG is not zero,
   Then, if ARG is positive,
           Then
                Point moves to the initiating string quote,
                ARG-1 is returned
           Else (ARG is negative)
                Point moves beyond the terminating string quote,
                ARG+1 is returned
   Else
         ARG is returned."
  (interactive "p")
  (let* ((top  (save-excursion (beginning-of-defun) (point)))
         (bottom (save-excursion (end-of-defun) (point)))
         (in-string-p (nth 3 (parse-partial-sexp top (point)))))
    (when (and (/= arg 0) in-string-p)
      (cond ((> arg 0)
             (while in-string-p         ;make sure we are out of the string
               (search-backward (char-to-string in-string-p) top)
               (setq in-string-p (nth 3 (parse-partial-sexp top (point)))))
             (setq arg (- arg 1)))
            ((< arg 0)
             (while in-string-p
               (search-forward (char-to-string in-string-p) bottom)
               (forward-char 1)         ;move beyond the exit
               (setq in-string-p (nth 3 (parse-partial-sexp top (point)))))
             (setq arg (+ arg 1)))))
    arg))

(defun cq-backward-up-list-or-string (arg)
  "Like backward-up-list, but if point is inside a string, exiting the
string counts as one of the ARG jumps.  See also cq-backward-up-list.
An argument of C-u is understood as -1, not as 4."
  (interactive "p")
  (if (equal current-prefix-arg '(4))
      (setq arg -1))
  (backward-up-list (out-of-string-maybe arg)))

(defvar cq-stuff-alist nil
  "*Alist of (character left right) for cq-stuff.
Character cannot be '?'.")

(cond ((null cq-stuff-alist)
       (setq cq-stuff-alist
             (list (cons ?a (list "(apropos \""     "\")"))
                   (cons ?d (list "(describe "      ")"))
                   (cons ?i (list "(inspect "       ")"))
                   (cons ?l (list "(load \""        "\")"))
                   (cons ?s (list "(system \""      "\")"))))))

(defun cq-stuff-sexp ()
  "Stuff a given sexp, left and right parts come from cq-stuff-alist, q.v."
  (interactive)
  (let* ((entry (assoc last-command-char cq-stuff-alist))
         (left  (car (cdr entry)))
         (right (cadr (cdr entry))))
    (if (null entry)
        (if (not (eql last-command-char ?\?))
            (error "No stuffing for `%c'" last-command-char)
          (with-output-to-temp-buffer "*stuffings*"
            (let ((seen nil))
              (dolist (entry cq-stuff-alist)
                (terpri)
                (if (memq (car entry) seen)
                    nil                 ;just ignore
                  (push (car entry) seen)
                  (princ (format "%c produces %s" 
                                 (car entry) (concat (cadr entry)
                                                     "_"
                                                     (caddr entry)))))))))
      (balanced-insertion left right 0 (function forward-sexp)))))

(defun cq-inferior-lisp-mode ()
  "Set up stuff for inferior lisp mode.
This is just for Common Lisp inferiors, and runs at the end of cq-lisp-mode."
  (interactive)
  (setq truncate-partial-width-windows nil)
  (local-unset-key "\C-zs")
  (local-set-key "\C-zsa" 'cq-stuff-sexp)
  (local-set-key "\C-zsd" 'cq-stuff-sexp)
  (local-set-key "\C-zsi" 'cq-stuff-sexp)
  (local-set-key "\C-zsl" 'cq-stuff-sexp)
  (local-set-key "\C-zss" 'cq-stuff-sexp)
  (local-set-key "\C-zs?" 'cq-stuff-sexp)
  (local-set-key "\C-hd"  'find-doc))

;;; More stuff for Schelter's find-doc system.
(defun rebuild-doc ()
  "Goes and finishes fixing up the DOC file, and reloads it.
Run after you have done (rebuild-doc) in the KCL window."
  (interactive)
  (message "rebuilding %s..." *thesis-doc-filename*)
  (save-excursion
    (let ((require-final-newline t))
      (snarf-doc *thesis-doc-filename*)))
  (kill-buffer "DOC")
  (kill-buffer "DOC-keys.el")
  (visit-doc-file *thesis-doc-filename*)
  ;;(kill-buffer "-keys.el")
  (shell-command (format "/bin/rm -f %s-keys.el.*"
                         *thesis-doc-filename*))
  (message "rebuilding %s... done" *thesis-doc-filename*))

;;; Some stuff that is needed if one goes from CLtL to CLtL 2.

(fset 'function->ftype
   "(function †q•±¨ftyupe †
•‘†")


(defun cq-close-defun (where)
  "Try to close the top level s-expression ending at the position WHERE,
which is the value of point by default.  By 'closing' the s-exp we mean this: 
+ If inside a comment, break to the next line and reindent, and...
+ If inside a string, close the string, and...
+ If inside a nest of open parentheses, add enough closing parentheses to
  get the nesting back to zero.
This function does *not* look at right contexts.  Instead, you should use it
as if the point of insertion were the end of the buffer.  Useful when actually
at the end of the buffer, or when you know that the next expression is a top
level one.
"
  (interactive "d")
  (save-restriction
    (widen)                             ;see the entire buffer
    (let* ((parse	(parse-partial-sexp (point-min) where))
           (paren-depth (prog1 (car parse) (setq parse (cdddr parse))))
           (in-string   (prog1 (car parse) (setq parse (cdr parse))))
           (in-comment  (prog1 (car parse) (setq parse (cdr parse)))))
      (if in-comment
          (insert "\n"))
      (if in-string
          (insert "\""))
      (while (> paren-depth 0)
        (insert
         (save-excursion                ;should be safe
           (backward-up-list 1)
           ;; at this point, following char is an opening bracket,
           ;; find the matching closing bracket.
           ;; UGLY---look in "syntax.c":describe-syntax for this.
           (logand 255 (lsh (aref (syntax-table) (following-char)) -8))))
        (setq paren-depth (- paren-depth 1)))
      (lisp-indent-line))))

;;; End of cq-lisp-mode
