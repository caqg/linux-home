;;; -*- Emacs-Lisp -*-
;;;
;;; This code tailors shell-mode.  Some of it is just an adaptation of
;;; the released shell.el. (CQ, 27 sep 87).

(provide 'cq-shell)
(require 'cl)
(require 'hists)

(defvar *shell-history-capacity* 32
  "*Number of events remembered by shell-mode buffer histories.")

(defvar *shell-min-length-remembered* 4
  "*Input events shorter than these many characters are not recorded.
Notice that grabbing something from the history already takes 2 or
more keystrokes, and the size of the history is limited.  Idea taken
from Neil Smithline's hacks to Csh.")

(defvar *shell-keep-repeated-top-events* nil
  "*Non-nil means to store events even if they are an exact match with
the currently top event in the history.  The default, nil, economizes
by not moving the ring when the top event is repeatedly used.")

(defvar *shell-help-for-copy-input* 
 "n or p - replace with next or previous
N or P - append next or previous
other  - leave as shown")

(defvar shell-mode-line
  '("" mode-line-modified "Emacs: %b"
    "   " default-directory  " - " global-mode-string
    " ---- "(-3 . "%p") " -%-")
  "Mode line used by shell mode buffers")

;;; completion code comes from denny@uunet.uu.net
(defvar shell-completions-window nil
  "If non-nil, completion window requires cleaning up.")

(defvar shell-token-pattern "[ \t\n()<>&|;]"
  "*Regexp used by shell name completion to mark path name boundaries.")
;;; code above by denny@uunet.uu.net
  
(defun cq-shell-mode ()
  "Setup for shell modes."
  (lsetq
   shell-history       (make-history *shell-history-capacity*)
   shell-prompt-pattern "^[#$>%@:] *"
   mode-line-format     shell-mode-line)
  (setq shell-pushd-regexp "pushd\\|+"
        shell-popd-regexp  "popd\\|-"
        ;;shell-cd-regexp has some bug.  use `cd' always.
        shell-cd-regexp    "chdir\\|cd\\|=")
  (set-balanced-insertions)
  (local-set-key "\C-j"     'cq-shell-send-input)
  (local-set-key "\C-m"     'cq-shell-send-input)
  (local-set-key "\C-c\C-i" 'shell-file-name-completion)
  (local-set-key "\C-[\C-[" 'shell-file-name-completion)
  (local-set-key "\C-c\C-k" 'kill-all-output-from-shell)
  (local-set-key "\C-c\C-n" 'shell-next-command)
  (local-set-key "\C-c\C-p" 'shell-prev-command)
  (local-set-key "\C-c\C-y" 'cq-copy-last-shell-input))

;;; History mechanism implemented by CQ, based on original shell.el
;;; (the version of marick@gswd-vms.arpa)
(defun cq-shell-send-input ()
  "Send input to subshell.
At end of buffer, sends all text after last output
as input to the subshell, including a newline inserted at the end.
When not at end, copies current line to the end of the buffer and sends it,
after first attempting to discard any prompt at the beginning of the line
by matching the regexp that is the value of shell-prompt-pattern if possible.
This regexp should start with \"^\".

This version record events in the variable shell-history. (CQ 27 sep 87)"
  (interactive)
  (end-of-line)
  (if (eobp)
      (progn
        (move-marker last-input-start
                     (process-mark (get-buffer-process (current-buffer))))
        (insert ?\n)
        (move-marker last-input-end (point)))
    (beginning-of-line)
    (re-search-forward shell-prompt-pattern nil t)
    (let ((copy (buffer-substring (point)
				  (progn (forward-line 1) (point)))))
      (goto-char (point-max))
      (move-marker last-input-start (point))
      (insert copy)
      (move-marker last-input-end (point))))
  ;; Even if we get an error trying to hack the working directory,
  ;; still send the input to the subshell.
  (condition-case ()
      (save-excursion
        (goto-char last-input-start)
        (shell-set-directory))
    (error (funcall shell-set-directory-error-hook)))
  (let ((process (get-buffer-process (current-buffer)))
        (this-event (buffer-substring last-input-start (- last-input-end 1))))
    (shell-store-event shell-history this-event)
    (process-send-region process last-input-start last-input-end)
    (set-marker (process-mark process) (point))
    (shell-completion-cleanup)))

(defun shell-store-event (history event)
  "(SHELL-STORE-EVENT HISTORY EVENT)
Install EVENT as the most current event in HISTORY, unless it is trivial
\(i.e., less than *shell-min-length-remembered* characters), or it is
a repeated top event (it coincides exactly with the most recent event
inserted in the history) and the user has kept the variable
*shell-keep-repeated-top-events* set to nil."
  (if (and (>= (length event) *shell-min-length-remembered*)
           (or *shell-keep-repeated-top-events*
               (= (history-occupancy history) 0)
               (not (string= event (history-retrieve-current history)))))
      (history-store history event)))

(defun cq-copy-last-shell-input ()
  "Copy previous shell input, sans newline, and insert at end of
buffer.  Gives the user the opportunity to insert previous or later
events in shell-history (q.v.), depress your help-char at the question
if you need help.  Usually, answering anything but one of 'n', 'p',
'N' or 'P' accepts the input.  The lowercase versions replace the
current input by your selection, the uppercase versions append to the
current candidate the selected events.  (CQ 27 sep 87)."
  (interactive)
  (let ((where (point)))                ;used for replacements and insertions
    ;; (goto-char where) -- `where' used to be (point-max)
    (insert (history-retrieve-current shell-history))
    (do ((location (- (history-here shell-history) 1))
         (capacity (history-capacity shell-history))
         (help-form *shell-help-for-copy-input*)
         (response nil))
        ((eql response ?y))             ;mapped by the default case below
      (message "Right? [default is yes; else n,p,N,P]: ")
      (setf response (read-char))
      (case response
        ((?n)                           ;replace with next
         (delete-region where (point))
         (incf location)
         (insert (history-retrieve shell-history location)))
        ((?p)                           ;replace with previous
         (delete-region where (point))
         (decf location)
         (insert (history-retrieve shell-history location)))
        ((?N)                           ;append next
         (incf location)
         (insert (history-retrieve shell-history location)))
        ((?P)                           ;append previous
         (decf location)
         (insert (history-retrieve shell-history location)))
        (t                              ;terminate iterations
         ;; The idea here is to put back in the command stream the
         ;; character that made us break the queries.  Perhaps some
         ;; keystroke should be kept for just breaking with no further
         ;; action.
         (setf unread-command-char response
               response            ?y))))))

;;; completion code comes from denny@uunet.uu.net
(defun shell-file-name-completion ()
  "Perform file name completion in shell mode"
  (interactive)
  (let ((shell-expand-string nil)
	(shell-expand-begin nil)
	(shell-expand-end nil)
	(shell-expand-dir nil)
	(shell-expand-file nil)
	(shell-expand-completion nil))

    ;; look back
    (re-search-backward shell-token-pattern nil t)
    (forward-char)
    (setq shell-expand-begin (point))
    ;; look ahead
    (if (re-search-forward shell-token-pattern nil 0) (backward-char))
    (setq shell-expand-end (point))

    ;; the name requiring expansion
    (setq shell-expand-string
	  (buffer-substring shell-expand-begin shell-expand-end))
    ;; directory part of name
    (setq shell-expand-dir
	  (or (file-name-directory shell-expand-string) default-directory))
    ;; file part of name
    (setq shell-expand-file
	  (file-name-nondirectory shell-expand-string))
    
    ;; do the expansion
    (setq shell-expand-completion
	  (file-name-completion shell-expand-file shell-expand-dir))
    ;; display the results
    (if (eq shell-expand-completion t) (message "Sole completion")
      (if (eq shell-expand-completion nil) (message "No match")
	(if (equal shell-expand-completion shell-expand-file)
	    (progn
	      (if shell-completions-window nil
		(setq shell-completions-window
		      (current-window-configuration)))
	      (message "Making completion list...")
	      (with-output-to-temp-buffer " *Completions*"
		(display-completion-list
		 (sort (file-name-all-completions
			shell-expand-completion shell-expand-dir)
		       'string-lessp)))
	      (message ""))
	  ;; put in the expansion
	  (search-backward shell-expand-file)
	  (replace-match shell-expand-completion t t))))))
  

(defun shell-completion-cleanup ()
  "Clean up windows after shell file name completion."
  (interactive)
  (if shell-completions-window
      (save-excursion
	(set-window-configuration shell-completions-window)
	(setq shell-completions-window nil))))
;;; end of completion code by denny@uunet.uu.net
;;; code for motion-deletion by command input/output
;;; also by denny@uunet.uu.net
(defun kill-all-output-from-shell ()
  "Kill shell buffer above current prompt."
  (interactive)
  (goto-char (point-max))
  (re-search-backward shell-prompt-pattern nil t)
  (kill-region (point-min) (point))
  (goto-char (point-max)))

(defun shell-next-command ()
  "Search for the next command in a shell."
  (interactive)
  (re-search-forward shell-prompt-pattern nil t))

(defun shell-prev-command ()
  "Search for the previous command in a shell."
  (interactive)
  (beginning-of-line)
  (re-search-backward shell-prompt-pattern nil t)
  (re-search-forward shell-prompt-pattern nil t))

;;; end of code by denny@uunet.uu.net

;;; A variation on lisp-send-defun that permits using a temporary
;;; directory different from /tmp.

(defvar inferior-lisp-tmp-directory "/tmp"
  "*Directory where lisp-send-defun can create temporary files.  Name
must not end in a slash!")

(defvar inferior-lisp-load-in-package-template
    "(let ((package (package-name *package*)))
       (in-package %s) 
       (load \"%s\" :verbose nil :print t)
       (in-package package)
       (values))
"
  "*Format template that shows how to assemble the load command that preserves
packages.  It should contain two string (%s) format effectors: the first gets
replaced with a form guaranteed to name a package, the second is the filename
from which the load will occur.  Supersedes inferior-lisp-load-command")

(defun lisp-send-defun (display-flag)
  "Send the current defun to the Lisp process made by `M-x run-lisp'.
With argument, force redisplay and scrolling of the *lisp* buffer.
Variable `inferior-lisp-load-in-package-template'
    controls formatting of the `load' form that is sent to the Lisp process.
Variable `inferior-lisp-tmp-directory'
    controls where to create temporary files."
  (interactive "P")
  (or (get-process "lisp")
      (error "No current lisp process"))
  (save-excursion
    (end-of-defun)
    (let* ((end          (point))
           (in-package   (save-excursion
                           (let ((case-fold-search t))
                             (if (not (re-search-backward "^(in-package"
                                                          (point-min)
                                                          t))
                                 "(package-name *package*)"
                               (format "%s"
                                       (buffer-substring
                                        (progn (down-list 1)
                                               (forward-sexp 2)
                                               (backward-sexp 1)
                                               (point))
                                        (progn (forward-sexp 1)
                                               (point))))))))
           (package-name (if (string= in-package "(package-name *package*)")
                             "current package"
                           (format "package %s" in-package)))
           (filename     (format "%s/emlisp%d" inferior-lisp-tmp-directory
                                 (process-id (get-process "lisp"))))
           (command      (format inferior-lisp-load-in-package-template
                                 in-package
                                 filename)))
      (beginning-of-defun)
      (write-region (point) end filename nil 'nomessage)
      (message "loading #P\"%s\" in %s..." filename package-name)
      (process-send-string "lisp" command)
      (message "loading #P\"%s\" in %s... done" filename package-name))
    (if display-flag
        (let* ((process (get-process "lisp"))
               (buffer (process-buffer process))
               (w (or (get-buffer-window buffer) (display-buffer buffer)))
               (height (window-height w))
               (end))
          (save-excursion
            (set-buffer buffer)
            (setq end (point-max))
            (while (progn
                     (accept-process-output process)
                     (goto-char (point-max))
                     (beginning-of-line)
                     (or (= (point-max) end)
                         (not (looking-at inferior-lisp-prompt)))))
            (setq end (point-max))
            (vertical-motion (- 4 height))
            (set-window-start w (point)))
          (set-window-point w end)))))

;;; Emergency patch to shell-set-directory. YICK.

(defun shell-set-directory ()
  (cond ((and (looking-at shell-popd-regexp)
	      (memq (char-after (match-end 0)) '(?\; ?\n)))
	 (if shell-directory-stack
	     (progn
	       (cd (car shell-directory-stack))
	       (setq shell-directory-stack (cdr shell-directory-stack)))))
	((looking-at shell-pushd-regexp)
	 (cond ((memq (char-after (match-end 0)) '(?\; ?\n))
		(if shell-directory-stack
		    (let ((old default-directory))
		      (cd (car shell-directory-stack))
		      (setq shell-directory-stack
			    (cons old (cdr shell-directory-stack))))))
	       ((memq (char-after (match-end 0)) '(?\  ?\t))
		(let (dir)
		  (skip-chars-forward "^ ")
		  (skip-chars-forward " \t")
		  (if (file-directory-p
			(setq dir
			      (expand-file-name
				(substitute-in-file-name
				  (buffer-substring
				    (point)
				    (progn
				      (skip-chars-forward "^\n \t;")
				      (point)))))))
		      (progn
			(setq shell-directory-stack
			      (cons default-directory shell-directory-stack))
			(cd dir)))))))
	((looking-at shell-cd-regexp)
	 (cond ((memq (char-after (match-end 0)) '(?\; ?\n))
		(cd (getenv "HOME")))
	       ((memq (char-after (match-end 0)) '(?\  ?\t))
		(let (dir)
                  ;; (forward-char 3)  BOGON
                  (skip-chars-forward "^ \t")
		  (skip-chars-forward " \t")
		  (if (file-directory-p
			(setq dir
			      (expand-file-name
				(substitute-in-file-name
				  (buffer-substring
				    (point)
				    (progn
				      (skip-chars-forward "^\n \t;")
				      (point)))))))
		      (cd dir))))))))

(defvar *Mathematica-buffer-name*       "*Mathematica*")
(defvar *Mathematica-history-capacity*  128)
(defvar *Mathematica-executable*        "math")

(defun resume-math ()
  "Return to the Mathematica buffer.  Create a new one if needed.  If the
buffer exists, but the inferior-lisp lisp has exited, restart it."
  (interactive)
  (let* ((buffername        *Mathematica-buffer-name*)
         (buffer            (get-buffer-create buffername))
         (proc              (get-buffer-process buffer))
         (status            (if proc (process-status proc)))
         ;; prepare to pop to the lisp window
         (pop-up-windows    t)
         (*shell-history-capacity* *Mathematica-history-capacity*))
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
           (insert "Running " *Mathematica-executable* " on ")
           ;;(call-process "hostname" nil t nil)
           (insert (system-name))
           (insert " at "
                   (current-time-string)
                   "\nHi "
                   (user-full-name)
                   "!\n\n")
           (make-shell "Mathematica" *Mathematica-executable*)
           (make-variable-buffer-local 'shell-prompt-pattern)
           (setq shell-prompt-pattern "^\\(In\\|Out\\).*= ")
           (local-set-key "\C-i" 'self-insert-command)))))


;;;; end of cq-shell.el
