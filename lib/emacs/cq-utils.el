;;; -*- Mode: Emacs-Lisp -*-
;;;
;;; Always-available utilities
;;;
;;; Some of these have become obsolete since the days of V15, but I haven't
;;; had the time to remove them.

(require 'cl)
(provide 'cq-utils)                     ;CQ 9 Oct 90 00:29:20 UT-04:00

;;;; Original version
;;;;
;;;; The annoying special purpose code all over makes me want to have
;;;; :before and :after methods instead.  Now (2005) I don't have guru
;;;; terminals anymore, and display-time does not run an external process
;;;; anyway.
;;;;
;;;;(defun cq-suspend-saving ()
;;;;  "Save all file-visiting buffers and suspend. CQ"
;;;;  (interactive)
;;;;  (let ((term-is-a-guru (let ((termname (getenv "TERM")))
;;;;                          (and (>= (length termname) 4)
;;;;                               (string= (substring termname 0 4) "guru"))))
;;;;        (time-and-mail  (and (boundp 'display-time-process)
;;;;                             (processp display-time-process)
;;;;                             display-time-process)))
;;;;    (save-some-buffers 'all)
;;;;    (if time-and-mail                   ;don't waste cycles on this
;;;;        (stop-process time-and-mail))
;;;;    (cond (term-is-a-guru
;;;;           (suspend-emacs "/usr/ucb/clear"))
;;;;          (t
;;;;           (suspend-emacs)))
;;;;    (if time-and-mail
;;;;        (continue-process time-and-mail))
;;;;    (if term-is-a-guru
;;;;        (recenter nil))))

(defun cq-suspend-saving ()
  "Save all file-visiting buffers and suspend. CQ"
  (interactive)
  (save-some-buffers 'all)
  (suspend-emacs))

(defun cq-iconify-saving ()
  "Save all file-visiting buffers and iconify. CQ
Use only under a windowing system"
  (interactive)
  (save-some-buffers 'all)
  (iconify-frame))

(defun cq-goto-match ()
  "Take cursor to the matching delimiter.  CQ
It checks first that the character cursor is 'on'
has the syntactic class of open or close parenthesis,
which is mode-dependent.  If so, jumps one list in
the right direction (may NOT be enough).  Else, just
returns."
  (interactive)
  (cond
   ((looking-at "\\s\(")        ;syntax class of '('
    (forward-list 1)
    (backward-char 1))
   ((looking-at "\\s\)")        ;syntax class of ')'
    (forward-char 1)
    (backward-list 1))))

;;;; A reminder of the mouse-bindings for the X system
;;;;
;(defvar x-mouse-chart-buffer "*X mouse bindings*"
;  "*Name of the buffer to display X-system mouse bindings.")
;(defvar x-mouse-chart-file (concat emacslib "x-mouse.chart")
;  "*Name of the file containing the X-mouse bindings chart.")
;(defvar x-tinyfont-name "6x10"
;  "*Filename of the tiny font.")
;(defvar x-smallfont-name "6x13"
;  "*Filename of the small font.")
;(defvar x-largefont-name "gachax-r-10"
;  "*Filename of the large font.")
;(defvar x-hugefont-name "8x13"
;  "*Filename of the huge font.")

;(defun x-mouse-chart (&rest ignore)
;  "Reminder of the bindings for the X-system mouse"
;  (interactive)
;  (let ((my-buffer (get-buffer-create x-mouse-chart-buffer))
;        (old-window (selected-window)))
;    (pop-to-buffer my-buffer)
;    (if buffer-read-only
;        (toggle-read-only))
;    (erase-buffer)
;    (insert-file x-mouse-chart-file)
;    (goto-char (point-min))
;    (if (not buffer-read-only)
;        (toggle-read-only))
;    (not-modified)
;    (shrink-window (- (window-height) 8))
;    (message "... done")
;    (select-window old-window)))

;(defun x-reconfig (ignore)
;  "Reconfigure Emacs's X-window"
;  (interactive)
;  (eval (x-popup-menu
;         (list (/ (screen-width) 2) (/ (screen-height) 2))
;         '("X Reconfiguration Menu"
;           ("Font Selection"
;            (" Tiny"   . (x-set-font x-tinyfont-name))
;            (" Small"  . (x-set-font x-smallfont-name))
;            (" Large"  . (x-set-font x-largefont-name))
;            (" Huge"   . (x-set-font x-hugefont-name)))
;           ("Other Features"
;            (" Flip Color"     x-flip-color)
;            (" Visible Bell"   . (x-set-bell t))
;            (" Noisy Bell" . (x-set-bell nil)))))))

;;;; Based on a contribution by 
;;;;;erlkonig@walt.cc.utexas.edu (Christopher North-Keys)

;(defun x-mouse-select-and-mark (arg)
;  "Select Emacs window mouse is on, and set mark at mouse position.
;Display cursor at that position for a second."
;  (if (x-mouse-select arg)
;      (let ((point-save (point)))
;        (unwind-protect
;            (progn (x-mouse-set-point arg)
;                   (push-mark nil nil)
;                   (sit-for 1))
;          (goto-char point-save)))))

;;; 

(defun cq-no-suspend ()
  "Tell the User that this Emacs shouldn't be suspended."
  (interactive)
  (save-some-buffers 'all)              ;good for X, else I might forget this
  (message "This Emacs shouldn't be suspended"))

(defun cq-kill-emacs-maybe (no-query)
  "Check with the user if he really wants to exit, do so if confirmed.
File-visiting buffers are always saved,
   to avoid this, use `M-x kill-emacs'
Giving any numeric argument, typically just `C-u', will inhibit querying
about processes left behind.  If the argument is given just as `C-u C-u', 
no querying at all is used."
  (interactive "p")
  ;; (declare (special cq-gnews-initialized-p))
  (save-some-buffers 'all)              ;good for X, else I might forget this
  (cond ((equal current-prefix-arg '(16))
         (quote (and (boundp 'cq-gnews-initialized-p) cq-gnews-initialized-p
		     (news-quit t)))
         (kill-emacs 1))
        ((y-or-n-p "Do you really want to exit this Emacs? ")
         (quote (and (boundp 'cq-gnews-initialized-p) cq-gnews-initialized-p
		     (news-quit t)))
         (kill-emacs 0))
        (t
         (message "OK, keep hacking, see if I care."))))

(defvar *next-shell-number* 0
  "Index maintained by cq-shell and cq-shell-other-window, to name new
shells when needed.")

(defun cq-shell (shell-no)
  "Return to the `*shell*' buffer, initiating a shell process if necessary.
Returning to a shell that was already running does not destroy the
event history, nor does it affect the shell's state.
The only argument (prefix, if interactive) names which shell should be
used.  So saying (cq-shell 7) creates or reuses a buffer *shell-7*.
Using a negative number causes an error.  Just numeric argument (i.e,
typing something like `C-u M-x cq-shell') indicates using a new number
for the next shell created.  The variable `*next-shell-number*' contains
the number to be used by the next shell.  No argument means using the name
`*shell*', as usual in Emacs Lisp.
See also `cq-shell-other-window.'"
  (interactive "p")
  (let* ((shellname        (cond ((null current-prefix-arg)
                                  "shell")
                                 ((listp current-prefix-arg)
                                  (prog1 (concat "shell-"
                                                 (prin1-to-string
                                                  *next-shell-number*))
                                    (setq *next-shell-number*
                                          (+ *next-shell-number* 1))))
                                 ((>= shell-no 0)
                                  (concat "shell-"
                                          (prin1-to-string shell-no)))
                                 (t
                                  (error "Negative shell number=%d."
                                         shell-no))))
         (buffername        (concat "*" shellname "*"))
         (buffer            (get-buffer-create buffername))
         (proc              (get-buffer-process buffer))
         (status            (if proc (process-status proc)))
         ;; prepare to pop to the shell window
         (pop-up-windows    t))
    (cond ((memq status '(run stop
                          open          ;added by fi:
                          ))
           (pop-to-buffer buffer)
           (goto-char (point-max)))
          (t
           (switch-to-buffer buffer)
           (cq-shell-primitive shellname)))))

(defun cq-shell-other-window (shell-no)
  "Return to the *shell* buffer, initiating a shell process if necessary.
Returning to a shell that was already running does not destroy the
event history, nor does it affect the shell's state. 
Always tries to use other window. See also `cq-shell.'"
  (interactive "p")
  (let* ((shellname        (cond ((null current-prefix-arg)
                                  "shell")
                                 ((listp current-prefix-arg)
                                  (prog1 (concat "shell-"
                                                 (prin1-to-string
                                                  *next-shell-number*))
                                    (setq *next-shell-number*
                                          (+ *next-shell-number* 1))))
                                 ((>= shell-no 0)
                                  (concat "shell-"
                                          (prin1-to-string shell-no)))
                                 (t
                                  (error "Negative shell number=%d."
                                         shell-no))))
         (buffername        (concat "*" shellname "*"))
         (buffer            (get-buffer-create buffername))
         (proc              (get-buffer-process buffer))
         (status            (if proc (process-status proc)))
         ;; prepare to pop to the shell window
         (pop-up-windows    t))
    (cond ((memq status '(run stop
                          open          ;added by fi:
                          ))
           (pop-to-buffer buffer 'other-window)
           (goto-char (point-max)))
          (t
           (switch-to-buffer-other-window buffer)
           (cq-shell-primitive shellname)))))

(defun cq-comint-shell-other-window ()
  "Return to the *shell* buffer, initiating a shell process if necessary.
Returning to a shell that was already running does not destroy the
event history, nor does it affect the shell's state. 
Always tries to use other window. "
  (interactive "")
  (let* ((shellname	"shell")
         (buffername    (concat "*" shellname "*"))
         (buffer        (get-buffer-create buffername))
         (proc          (get-buffer-process buffer))
         (status        (if proc (process-status proc)))
         ;; prepare to pop to the shell window
         (pop-up-windows    t))
    (cond ((memq status '(run stop open))
           (pop-to-buffer buffer 'other-window)
           (goto-char (point-max)))
          (t
           (shell)
           ;;(shell-mode)
           ))))

(defun cq-shell-primitive (shellname)
  "Run an inferior shell, with I/O through buffer named by SHELLNAME.
This is like the default function `shell', which see.  The buffer
actually created for SHELLNAME=foo is `*foo*'!
If buffer exists but shell process is not running, make new shell.
Program used comes from variable explicit-shell-file-name,
 or (if that is nil) from the ESHELL environment variable,
 or else from SHELL if there is no ESHELL.
If a file ~/.emacs_SHELLNAME exists, it is given as initial input
 (Note that this may lose due to a timing error if the shell
  discards input when it starts up.)
The buffer is put in shell-mode, giving commands for sending input
and controlling the subjobs of the shell.  See shell-mode.
See also variable shell-prompt-pattern.

The shell file name (sans directories) is used to make a symbol name
such as `explicit-csh-arguments'.  If that symbol is a variable,
its value is used as a list of arguments when invoking the shell.
Otherwise, one argument `-i' is passed to the shell.

Note that many people's .cshrc files unconditionally clear the prompt.
If yours does, you will probably want to change it."
;  (let* ((prog (or explicit-shell-file-name
;		   (getenv "ESHELL")
;		   (getenv "SHELL")
;		   "/bin/sh"))		     
;	 (name (file-name-nondirectory prog))
;         (startfile (concat "~/.emacs_" name))
;         (xargs-name (intern-soft (concat "explicit-" name "-args")))
;	 )
;    (cond (emacs18
;           (switch-to-buffer
;            (apply 'make-shell shellname prog
;                   (if (file-exists-p startfile) startfile)
;                   (if (and xargs-name (boundp xargs-name))
;                       (symbol-value xargs-name)
;                     '("-i")))))
;          (emacs19
;           (require 'shell)
;           (set-buffer (apply 'make-comint shellname prog
;                              (if (file-exists-p startfile) startfile)
;                              (if (and xargs-name (boundp xargs-name))
;                                  (symbol-value xargs-name)
;                                '("-i"))))
;           (shell-mode)))
    (shell-mode)
;    )
)


;;; From john@xanth.UUCP (John Owens), 1 Jul 87: The most frustrating
;;; lack of orthogonality in GNU Emacs for me has been the lack of a
;;; combination of find-file-read-only and find-file-other window.
;;; So - a simple elisp function to share with you all:

;;; 2005-09-21 17:48:23UT (cesar@cesar-xp): It is in XEmacs now.

;(defun find-file-read-only-other-window (filename)
;  "Like find-file-read-only, but does it in another window."
;  (interactive "FFind file read-only in other window: ")
;  (switch-to-buffer-other-window (find-file-noselect filename))
;  (setq buffer-read-only t))


;;; Replied: Sun, 27 Sep 87 20:24:18 -0400
;;; Replied: "smithln "
;;; Message-Id: <8709280019.AA02919@yed.cs.rochester.edu>
;;; From: smithln
;;; To: quiroz
;;; Subject: modified tags-find
;;; Date: Sun, 27 Sep 87 20:19:28 -0400
;;; Sender: smithln
;;; 
;;; Well, I think I have finally figured out what I wanted it to do - so
;;; now I do it - Here is a copy of it - maybe you will like it better as
;;; well - Neil

;;; 2005-09-21 17:50:56UT (cesar@cesar-xp):
;;; This doesn't work in XEmacs anymore.

;(defun tags-find-all ()
;  "Find all files in tags file."
;  (interactive)
;  (visit-tags-table-buffer)
;  (mapcar 'find-file (tag-table-files))
;  (list-buffers)
;  (switch-to-buffer "*Buffer List*")
;  (delete-other-windows))

;;; Slightly better reporting of the cursor position.  Replaces the
;;; standard binding for `C-x ='

(defun cq-what-cursor-position ()
  "Print info on cursor position (on screen and within buffer).
Gives the character under the cursor, both a conventional name (as
used in the Emacs docs) and an octal number, followed by the position
of point in buffer, the total size of the buffer, the relative
position of point, the x-position (= column in this line) of point and
the y-position of point (= what line point is in), indicating also the
values relative to the current restriction, if one is in effect, and
the maxima (for x, the end of the line; for y, the last line)."
  (interactive)
  (let* ((char         (following-char))
	 (beg          (point-min))
	 (end          (point-max))
         (pos          (point))
         (col          (current-column))
         (eol          (save-excursion (end-of-line) (current-column)))
	 (total        (buffer-size))
	 (percent      (if (> total 50000)
                           ;; Avoid overflow from multiplying by 100!
                           (/ (+ (/ total 200) (1- pos))
                              (max (/ total 100) 1))
                         (/ (+ (/ total 2) (* 100 (1- pos)))
                            (max total 1))))
         (restricted-p (or (/= beg 1) (/= end (1+ total))))
         (whatline     (save-restriction
                         (widen)
                         (save-excursion ; line-number-in-buffer
                           (beginning-of-line)
                           (1+ (count-lines 1 (point))))))
         (rline        (if restricted-p
                           (save-excursion ;line-number-in-restriction
                             (beginning-of-line)
                             (1+ (count-lines beg (point))))
                         whatline))
         (totlines     (save-restriction
                         (widen)
                         (count-lines (point-min) (point-max))))
         (rtotlines    (if restricted-p
                           (count-lines (point-min) (point-max))
                         totlines))
	 (hscroll      (if (= (window-hscroll) 0)
                           ""
                         (format " Hscroll=%d" (window-hscroll)))))
    (cond
     ((= pos end)
      (cond
       (restricted-p
        (message
         "point=%d/%d (%d%%) <%d - %d>  x=%d/%d y=%d/%d <%d/%d> %s"
         pos total percent beg end col eol
         rline rtotlines whatline totlines
         hscroll))
       (t
        (message
         "point=%d/%d (%d%%) x=%d/%d y=%d/%d %s"
         pos total percent col eol whatline totlines hscroll))))
     (t
      (cond
       (restricted-p
        (message
         "`%s' (0%o) point=%d/%d (%d%%) <%d - %d> x=%d/%d y=%d/%d <%d/%d> %s"
         (single-key-description char) char pos total percent
         beg end col eol
         rline rtotlines whatline totlines
         hscroll))
       (t
        (message
         "`%s' (0%o) point=%d/%d (%d%%) x=%d/%d y=%d/%d %s"
         (single-key-description char) char pos total percent
         col eol whatline totlines hscroll)))))))

;;; Yet another solution to the ^S/^Q problem in brain-dead connections
;;; (set-flow-control 1) [or any non-zero] sets input mode to CBREAK,
;;;                       flow controlled and with a translate table
;;;                       for C-\ and C-^. 
;;; (set-flow-control 0) sets input mode to interrupt driven, no flow
;;;                      control, no translate table.
;;;
;;; These ideas have been discussed in the net on and on.

(defvar set-flow-control-old-keyboard-translate-table
    nil
  "Used to shadow the translations before a switch.
Nil means that no switch has occurred; else it is a list, take the
car of the list for your purposes.")

(defun set-flow-control (flag)
  "Enable/Disable flow-control input.

Without prefix argument, sets CBREAK input and flow control and
maps \\C-\\ to \\C-s and \\C-^ to \\C-q.
With prefix argument, it sets input to interrupt driven, not flow
controlled, and with no translate table.
"
  (interactive "P")
  (cond (flag
         (set-input-mode t nil)
         (setq keyboard-translate-table
               (if set-flow-control-old-keyboard-translate-table
                   (car set-flow-control-old-keyboard-translate-table)
                 keyboard-translate-table)))
        (t
         (set-input-mode nil t)
         (setq set-flow-control-old-keyboard-translate-table
               keyboard-translate-table)
         (setq keyboard-translate-table
               (let ((temp (make-string 32 0)) ;32 ctrl chars in ASCII
                     (i    0))
                 ;; make a straight-thru table
                 (while (< i 32)
                   (aset temp i i)
                   (setq i (+ i 1)))
                 ;; swap the critters
                 (aset temp ?\C-^  ?\C-q)
                 (aset temp ?\C-\\ ?\C-s)
                 temp)))))

(defvar cq-switch-del-and-bs-old-keyboard-translate-table
    nil
  "Used to remember the keyboard translate table before switching
Nil means that we haven't touched the translations yet.  A list means that
the car of the list is the old translations table.")

(defun cq-switch-del-and-bs (flag)
  "Use BS to delete, and DEL to ask for help.
With argument, set the table from before the switch, if any."
  (interactive "P")
  (if flag
      (setq keyboard-translate-table
            (if cq-switch-del-and-bs-old-keyboard-translate-table
                (car cq-switch-del-and-bs-old-keyboard-translate-table)
              keyboard-translate-table))
    (if (null cq-switch-del-and-bs-old-keyboard-translate-table)
        (setq cq-switch-del-and-bs-old-keyboard-translate-table
              (list keyboard-translate-table)))
    (setq keyboard-translate-table
          (let ((temp (make-string 256 0))
                (i    0))
            ;; make a straight-thru table
            (while (< i 256)
              (aset temp i i)
              (setq i (+ i 1)))
            ;; swap the critters
            (aset temp ?\C-?    ?\C-h)
            (aset temp ?\C-h    ?\C-?)
            (aset temp ?\M-   ?\M-)
            (aset temp ?\M-   ?\M-)
            temp))))

(defun cq-save-modified-buffers ()
  "Save all modified buffers, no confirmation required.
See also save-some-buffers"
  (interactive)
  (save-some-buffers t))

;;; From: merlyn@intelob.intel.com (Randal L. Schwartz @ Stonehenge)
;;; Newsgroups: comp.emacs,gnu.emacs
;;; Subject: see-chars for GNU
;;; Message-ID: <4362@omepd.UUCP>
;;; Date: 1 May 89 21:51:11 GMT
;;; original by merlyn -- LastEditDate = "Mon Apr 10 15:45:46 1989"

(defun see-chars ()
  "Displays characters typed, terminated by a 3-second timeout."
  (interactive)
  (let ((chars "")
	(inhibit-quit t))
    (message "Enter characters, terminated by 3-second timeout...")
    (while (not (sit-for 3))
      (setq chars (concat chars (list (read-char)))
	    quit-flag nil))		; quit-flag maybe set by C-g
    (message "Characters entered: %s" (key-description chars))))

;;;; Some utility functions to call from the command line.

;;; first-window does a `C-x o' from the command line
(defun first-window ()
  "Go to window 1.  Useful from the command line."
  (interactive)
  (other-window 1))

;;; identify-in-minibuffer
(defun identify-in-minibuffer ()
  "Print a generic identification message."
  (interactive)
  (declare (special window-system-version))
  (let* ((login-name (user-login-name))
         (real-login (user-real-login-name))
         (full-name  (user-full-name))
         (sysname    (or (getenv "HOST")
                         (system-name)))
;         (systype    (or system-type
;                         "Unknown System"))
         (os         (if window-system
                         (if (and (boundp 'window-system-version)
				  window-system-version)
                             (format "%s %s%d" system-type
                                     window-system window-system-version)
                           (format "%s %s" system-type window-system))
                       system-type))
         (tty        (or (getenv "TTY")
                         "Some TTY"))
         (term       (or (getenv "TERM")
                         "Some Terminal?")))
    (if (null full-name)
        (setq full-name "Yourself, Whoever"))
    (if (null sysname)
        (setq sysname "Unnamed Machine"))
    (if (string= login-name real-login)
        (message "%s/%s@%s:%s(%s); %s emacs %s"
                 full-name login-name sysname tty term
		 os emacs-version)
      (message "%s (%s for %s)@%s:%s, (%s) %s emacs %s"
               full-name login-name real-login
               sysname tty term os emacs-version))))

;;; Avoid large unintended kills

(defvar safe-kill-region-threshold nil  ;why not?
  "*Maximum size of the region (in characters) that safe-kill-region will kill
without asking for confirmation.  Nil means never ask.")

(defun safe-kill-region (p1 p2)
  "Kill region between point and mark, ask for confirmation from the 
user when more than safe-kill-region-threshold (q.v.) characters are 
in the region.  Called from a program takes two arguments, point and mark, 
smallest first."
  (interactive "r")
  (let* ((size       (length (buffer-substring p1 p2)))
         (should     (or (null safe-kill-region-threshold)
                         (<= size safe-kill-region-threshold)
                         (yes-or-no-p
                          (format "%d chars in region, should I kill it? "
                                  size)))))
    (if should
        (kill-region p1 p2))))

;;; This function was requested by Neil

(defun flash-describe-function (function)
  "Flash the documentation of FUNCTION (a symbol that is fboundp)"
  (interactive (list (or (function-called-at-point)
                         (call-interactively
                          (function
                           (lambda (f) (interactive "aFunction? ") f))))))
  (let* ((docs          (or (documentation function)
                            "Not documented as a function."))
         (msg           (concat "\n" (make-string (1- (window-width)) ?-)
                                "\n" (prin1-to-string function) ":"
                                "\n" docs
                                "\n" (make-string (1- (window-width)) ?-)))
         (msg-height    (let ((h 0) (i 0) (l (length msg)))
                          (while (< i l)
                            (if (char-equal (aref msg i) ?\n)
                                (setq h (+ h 1)))
                            (setq i (+ i 1)))
                          h)))
    (if (>= msg-height (+ (window-height) 3)) ;is there room?
        (describe-function function)
      (save-excursion
        (end-of-line 1)
        (if (/= (point-min) (point-max))
            (recenter (- (/ (- (window-height) msg-height 1) 2) 1)))
        (momentary-string-display msg (point))
        (recenter (/ (window-height) 2))))))

;;; Obvious variation on the above

(defun flash-describe-variable (variable)
  "Flash the documentation of VARIABLE (a symbol that is boundp)"
  (interactive (list (let* ((v (variable-at-point))
                            (s (completing-read
                                (if v
                                    (format
                                     "Describe variable (default %s): " v)
                                  "Describe variable: ")
                                obarray 'boundp t)))
                       (if (equal s "") v (intern s)))))
  (let* ((docs       (substitute-command-keys
                      (or (documentation-property
                           variable 'variable-documentation)
                          "Not documented as a variable.")))
         (msg        (concat "\n" (make-string (1- (window-width)) ?-)
                             "\n" (prin1-to-string variable) ":"
                             "\n" docs
                             "\n" (make-string (1- (window-width)) ?-)))
         (msg-height (let ((h 0) (i 0) (l (length msg)))
                       (while (< i l)
                         (if (char-equal (aref msg i) ?\n)
                             (setq h (+ h 1)))
                         (setq i (+ i 1)))
                       h)))
    (if (>= msg-height (+ (window-height) 3)) ;is there room?
        (describe-variable variable)
      (save-excursion
        (end-of-line 1)
        (if (/= (point-min) (point-max))
            (recenter (- (/ (- (window-height) msg-height 1) 2) 1)))
        (momentary-string-display msg (point))
        (recenter (/ (window-height) 2))))))
 
;;; For other purposes

(defun cq-display-temporarily (string &optional perm-if-big delimiter)
  "(CQ-DISPLAY-TEMPORARILY STRING &optional PERM-IF-BIG DELIMITER)
If STRING can be displayed temporarily, complete, in the current buffer, then
do so.  Else, display it in the full screen, except if the second optional
argument is not nil, when the display occurs in a real buffer.  Perhaps there
should be an option of passing the string to a function to deal with
perm-if-big cases?

If the third argument, delimiter, is not nil, then it is character, used to
delimit the string (lines of such character are prepended and appended to the
string first)."
  (let ((string-length (length string)))
    (if delimiter
        (setq string (concat "\n" (make-string (1- (window-width)) delimiter)
                             (if (and (> string-length 0)
                                      (not (char-equal (aref string 0) ?\n)))
                                 "\n")
                             string
                             (if (or (= string-length 0)
                                     (not (char-equal
                                           (aref string (- string-length 1))
                                           ?\n)))
                                 "\n")
                             (make-string (1- (window-width)) delimiter))))
    (let ((string-height (let ((h 0) (i 0))
                           (while (< i string-length)
                             (if (char-equal (aref string i) ?\n)
                                 (setq h (+ h 1)))
                             (setq i (+ i 1)))
                           h)))
      (cond ((< string-height (+ (window-height) 3)) ;3=mode+top+bottom
             (save-excursion
               (end-of-line 1)
               (if (/= (point-min) (point-max))
                   (recenter (- (/ (- (window-height) string-height 1) 2) 1)))
               (momentary-string-display string (point))
               (recenter (/ (window-height) 2))))
            (perm-if-big
             (let* ((current-buffer     (current-buffer))
                    (new-buffer-name    (make-temp-name
                                         " *display-temporarily* "))
                    (new-buffer         (get-buffer-create new-buffer-name)))
               (switch-to-buffer-other-window new-buffer)
               (erase-buffer)
               (insert string)
               (goto-char 1)
               (pop-to-buffer current-buffer)
               (message "Displayed on permanent buffer \"%s\""
                        new-buffer-name)))
            (t
             (save-window-excursion
               (save-excursion
                 (delete-other-windows)
                 (end-of-line 1)
                 (if (/= (point-min) (point-max))
                     (recenter (- (/ (- (window-height) string-height 1)
                                      2)
                                  1)))
                 (momentary-string-display string (point))
                 (recenter (/ (window-height) 2)))))))))

(defun cq-revert-buffer (use-auto-save)
  "Like revert-buffer, but never asks for yes/no confirmation.
It still checks if the latest auto-save file is newer.
With argument, that check is omitted mercifully.  CQ."
  (interactive "P")
  (revert-buffer use-auto-save t)
  (message "buffer %s reverted" (buffer-name)))

(defun copy-region-as-kill-command (begin end)
  "Exactly like copy-region-as-kill (q.v.), but with more feedback"
  (interactive "r")
  (copy-region-as-kill begin end)
  (message "To kill buffer: %s"
	   (trim-string-to-fit (buffer-substring begin end)
			       (- (window-width)
				  (+ (length "To kill buffer: ")
				     1)))))

(defun attach-to-register (register begin end prepend-flag)
  "Add region to contents of REGISTER.  
Second and third arguments are the begin and end positions of the region to 
be attached.  Fourth argument (interactively, the prefix) is T if the
attachment is a prepend, else it is an append.
CQ"
  (interactive "cAttach to register: \nr\nP")
  (if prepend-flag
      (prepend-to-register register begin end nil)
    (append-to-register register begin end nil)))

(defun trim-string-to-fit (string width)
  "Fit the first and last parts of STRING to WIDTH characters.
If STRING fits in the given size, just return it.  Else, split it evenly so
that the first few and last few characters appear separated by ...
Newlines and tabs are made visible first."
  (let* ((string (make-tabs-visible string))
         (length (length string)))
    (if (<= length width)
        string
      (let ((half (/ (- width (length " ... ")) 2)))
        (concat (substring string 0 half)
                " ... "
                (substring string (- half)))))))

(defun make-tabs-visible (string)
  "A copy of STRING, with tabs visible if ctl-arrow is not nil."
  ;;mapconcat is overkill here
  (mapconcat (function (lambda (c)
                         (cond ((and ctl-arrow (eql c ?\t))
                                "^I")
                               (t
                                (char-to-string c)))))
             string
             ""))

(defun force-recenter ()
  "(recenter '(0))"
  (interactive)
  (recenter '(0)))

(defun cq-goto-line (pfx)
  "(cq-goto-line PFX)
Go to line PFX.  Interactive, the raw prefix is inspected.  
If none or '-, go to the beginning of the file.  If \\C-u, go to the end.
Else, go to the line with that number.  This is like CCA's Emacs.
This function pushes the mark before moving!"
  (interactive "p")
  (cond ((or (null current-prefix-arg)
             (eq current-prefix-arg '-))
         ;; (beginning-of-buffer) --2014-01-05 03:15:39UT (cesar@cesar-u64)
         (goto-char (point-min)))
        ((equal current-prefix-arg (list 4))
         (goto-char (point-max)))
        (t
         (push-mark (point))
         ;; (goto-line pfx) --2014-01-05 03:12:31UT (cesar@cesar-u64)
         (goto-char (point-min))
         (forward-line (1- pfx)))))

(defun cq-timestamp (pfx)
  "Insert a time stamp at point.  Pushes mark before the time stamp.
If *timestamp-program* is bound, it is a program and arguments to be run
by shell-command (q.v.) to obtain the time stamp.  
Else the value (current-time-string) is used."
  (interactive "p")                     ;30 Aug 90 00:36:51 UT-04:00
  (cond ((and (boundp '*timestamp-program*) *timestamp-program*)
         (shell-command (concat *timestamp-program*
                                (if current-prefix-arg "-s" ""))
                        t)
         (exchange-point-and-mark))
        (t
         (push-mark (point) t)
         (insert (current-time-string)))))

;;; Like our good friend in MH-E, only a macro.

(defmacro lsetq (&rest body)            ;CQ 9 Oct 90 00:22:00 UT-04:00
  "(LSETQ [SYMBOL VALUE] ...)                                       [macro]
Each SYMBOL is made a local variable (buffer-specific) and it is then set to
the corresponding VALUE.  See also the mh-e function make-local-vars.
Returns the list of SYMBOLS actually seen."
  (let ((lhs ((lambda (list)
                (let (result)
                  (while list
                    (setq result (cons (car list) result))
                    (setq list (cddr list)))
                  (nreverse result)))   ;could spare that nreverse
              body)))
    (list 'progn
          (list 'mapcar (list 'function 'make-local-variable)
                (list 'quote lhs))
          (cons 'setq body)
          (list 'quote lhs))))

;;; From: sk@thp.uni-koeln.de
;;; Newsgroups: gnu.emacs.sources
;;; Subject: double-line
;;; Message-ID: <9011230958.AA02980@sun0.thp.Uni-Koeln.DE>
;;; Date: 23 Nov 90 09:58:10 GMT
;;; 
;;; It is amazing how often the following little function comes in handy:

;;; (define-key ctl-x-map "\"" 'double-line) ;; in .emacs

(defun double-line (arg)
  "Double this line.
With positive prefix arg, inserts ARG copies instead of just one.
With negative prefix arg, copies -ARG lines instead of just one."
  (interactive "p")
  (end-of-line)
  (if (< arg 0)
      (insert
       "\n"
       (buffer-substring
	(save-excursion (forward-line (1+ arg)) (point))
	(save-excursion (end-of-line) (point))))
    ;; else insert ARG copies:
    (let ((string (buffer-substring
		   (save-excursion (beginning-of-line) (point))
		   (point))))
      (while (>= (setq arg (1- arg)) 0)
	(insert "\n" string)))))

(defun cq-insert-buffer-file-name (which-buffer)
  "At point in the current buffer, insert the file name of the given buffer."
  (interactive "b")
  (let ((file-name (buffer-file-name (get-buffer which-buffer))))
    (cond (file-name
           ;; 2014-01-05 03:08:03UT (cesar@cesar-u64) obsolete (insert-string file-name)
           (insert file-name))
          (t
           (message "Buffer %s is not visiting a file." which-buffer)))))


;;; 2000-04-29 00:31:32UT
;;;	I found this convenient in the implementation of cq-sh-indent
(defun locate-indentation ()
  "Without moving the point, determine if 
1. Point is within the indentation (i.e., in the segment ^[ \t]*).
2. The position of the beginning of the line,
3. The position of the end of the indentation."
  (interactive)
  (save-excursion
    (let* ((at-indentation (progn (skip-chars-backward " \t")
				  (bolp)))
	   (indentation-start (progn (beginning-of-line)
				     (point)))
	   (indentation-end (progn (beginning-of-line)
				   (skip-chars-forward " \t")
				   (point))))
      (list at-indentation indentation-start indentation-end))))

(defun indent-buffer ( )
  "Indent the complete buffer.  If a narrowing restriction is set,
indent only that.  This is infinitely faster than using indent-region
interactively in XEmacs 20.4."
  (interactive)
  (indent-region (point-min) (point-max) nil ))

;;;

(defvar *any-old-hostname* nil
  "*A string that may or may not name this machine.  Do not access directly;
instead call get-any-hostname in code.  You can set this interactively, if our
guess was wrong.")

(defun get-any-hostname ()
  "Returns a string that could be a host name for this machine.
It depends on heuristic ideas, and so it is only good for banners, titles and
such.  Caches the result of its first call in *any-old-hostname*."
  (interactive)
  (setq *any-old-hostname* (or *any-old-hostname*
			       (getenv "HOST")
                               (getenv "USERDOMAIN")
			       mail-host-address
			       (delete*
				?\ ;squeeze spaces out
				(nsubstitute
				 ?\ ?\n ;space for newline
				 (shell-command-to-string "hostname"))))))

;;; End of cq-utils.el
