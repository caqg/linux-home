;;;; -*- Mode: Emacs-Lisp -*-  Customizations for MH-E
(if (not (and (boundp 'mh-letter-mode-map) mh-letter-mode-map))
    (load "mh-e"))
(if (not (boundp 'indentable-text-modes))
    (load "indented-submode"))

;;; Begin with the hooks.

(defun cq-mh-folder-mode ()
  "Sets MH-E's folder scanning options to my preferences. CQ"
  (interactive)
  (setq mh-use-mhl nil)
  (setq truncate-lines t)		;local to this buffer
  ;; fix this mess of a binding set
  (local-set-key	"b"	'mh-previous-page)
  (local-set-key	"g"	'mh-rescan-folder)
  (local-unset-key	"l")
  (local-set-key	"/"	'mh-search-folder)
  (local-set-key	"\M-s"	'mh-sort-folder)
  (local-set-key	"\M-G"	'mh-goto-msg)
  ;; for the interface with news
  (local-set-key	"\^Z\^Nf" 'mh-followup)
  (local-set-key	"\^Z\^Np" 'mh-postnews))

(defun cq-mh-letter-mode ()
  "Sets MH-E's letter writing mode to my preferences. CQ"
  (interactive)
  ;; make mh-letter an `indentable' mode
  (if (not (memq 'mh-letter-mode indentable-text-modes))
      (setq indentable-text-modes
	    (cons 'mh-letter-mode indentable-text-modes)))
  (indented-minor-mode 1)
  (auto-fill-mode 1)
  ;; set up internal preferences
  (setq fill-column 68)
  (make-local-vars 'version-control 'never)
  ;; fix local keymap
  (local-set-key "\es"      'center-line)
  (local-set-key "\eS"      'center-paragraph)
  ;; my own utilities
  (local-set-key "\e^"      'cq-mh-delete-indentation)
  (local-set-key "\eq"      'cq-mh-fill-paragraph)
  (local-set-key "\eQ"      'fill-paragraph)
  (local-set-key "\eg"      'cq-mh-fill-region)
  (local-set-key "\^O"      'cq-mh-open-line)
  (local-set-key "\^C\^C"   'cq-mh-send-letter)
  (local-set-key "\^C\^Fm"  'mh-to-message)
  (local-set-key "\^C\^FM"  'mh-insert-pom)
  (local-set-key "\^C\^FF"  'cq-mh-provide-Fcc-field)
  (local-set-key "\^C\^Fh"  'cq-mh-move-to-header-field)
  (local-set-key "\^C\^FR"  'cq-mh-field-return-receipt-to)
  (local-set-key "\^C\^Fr"  'cq-mh-field-reply-to)
  ;; more local keymap
  ;; (local-set-key "\C-i"     'indent-to-tab-stop)
  (local-set-key "\C-i"     'self-insert-command)
  (local-set-key "\M-i"     'point-to-tab-stop)
  (local-set-key "\C-\M-i"  'tab-to-tab-stop)
  (set-balanced-insertions)
  ;; for the interface with news
  (local-set-key "\^C\^P"   'mh-inews)
  ;; done
  (mh-to-message))

(defun cq-mh-compose-letter (to subject cc)
  "Sets MH-E's compose letter hook to my preferences. CQ"
  (make-local-vars 'version-control 'never))

;;; This doesn't seem to be useful anymore.  CQ Wed Apr 19 16:30:40 EDT 1989

(defun cq-mh-inc-folder ()
  "Stuff to do after incorporating mail.
If display-time-process is running, change the mode line
to stop announcing this mail, without waiting first for
display-time-interval to expire.  Sending SIGALRM to the 
display-time-process should be more reliable."
  (cond ((and (boundp 'display-time-process) display-time-process
              (eq 'run (process-status display-time-process))
              (stringp display-time-string))
         (accept-process-output)        ;make sure this gets done
         (cond ((string-match "\\(.*\\) Mail" display-time-string)
                (setq display-time-string 
                      (substring display-time-string 
                                 (match-beginning 1) (match-end 1)))
                (sit-for 0))))))

;;; Wrappers for mh-rmail and mh-smail that set up the folder list

(defun cq-mh-rmail (&optional arg)
  "Calls mh-rmail (q.v.) after trying to make mh-folder-list non nil"
  (interactive)
  (if (null mh-folder-list)
      (reset-mh-folder-list))
  (mh-rmail arg))

(defun cq-mh-smail ()
  "Calls mh-smail (q.v.) after trying to make mh-folder-list non nil"
  (interactive)
  (if (null mh-folder-list)
      (reset-mh-folder-list))
  (mh-smail))

(defun cq-mh-smail-other-window ()
  "Calls mh-smail-other-window (q.v.) after trying to make mh-folder-list non
nil" 
  (interactive)
  (if (null mh-folder-list)
      (reset-mh-folder-list))
  (mh-smail-other-window))

;;; A gadget for mail.  Good for reporting obscure bugs.  I puts the p.o.m.
;;; in the message header.  Not very useful and somehow slow, so not enabled
;;; automatically.  `\C-c\C-fM' activates it in letter-mode.  (Not to
;;; confuse with `\C-c\C-fm', of course

(defvar *pom-field* "X-phase-of-the-moon:" "Field name for P.O.M.")
(defvar *pom-program* "pom" "Program to run to get P.O.M.")

(defun mh-insert-pom ()
  "Compute the phase of the moon and stick it in the header.
Presumably useful when reporting bugs."
  (interactive)
  (save-excursion
    (mh-insert-fields *pom-field* "Computing Phase of the Moon ...")
    (mh-position-on-field *pom-field* nil)
    (sit-for 0)
    (beginning-of-line)
    (search-forward *pom-field*)
    (kill-line)
    (insert-string " ")
    (shell-command *pom-program* 'insert-at-point)))

;;; Manipulations when in letter mode
(defvar mh-header-separator "^----\\|^[ \t]*$"
  "*Regexp that describes the first non-header line.")

(defun mh-to-message ()
  "Go to the beginning of the message text.
Pushes a new mark, if needed."
  (interactive)
  ;;RMS broke this on v19
  ;;(if (not (eq (point) (mark)))
  ;;    (push-mark (point)))
  (push-mark (point))
  (goto-char (point-min))
  (let ((header-end (re-search-forward mh-header-separator (point-max) t)))
    (if (null header-end)
        (error "No separator line to end header ...")
      (beginning-of-line)
      (next-line 1))))

(defun cq-mh-send-letter (arg)
  "If user agrees, send the current letter, as per mh-send-letter.
It first cleans up the header, unconditionally (see the function 
cq-mh-clean-up-header).  The meaning of the argument (prefix, if interactive)
is as in standard MH-E: giving an argument means to monitor delivery."
  (interactive "P")
  (cq-mh-clean-up-header)
  (if (y-or-n-p "Send letter? ")
      (mh-send-letter arg)
    (message "Letter not sent yet...")))

(defun cq-mh-clean-up-header ()
  "Eliminate unsightly fields from the header.
Currently, only empty fields are eliminated."
  (interactive)
  (save-excursion
    (goto-char (point-min))
    (let ((header-end (re-search-forward mh-header-separator (point-max) t)))
      (if (null header-end)
          (error "No separator line to end header ...")
        (narrow-to-region (point-min) (point))
        (goto-char (point-min))
        (delete-matching-lines "^\\w*:[ \t]*$")
        (widen)))))

(defun cq-mh-fill-paragraph (justify)
  "Fill (and justify, if prefix arg given) the current paragraph.
If the line point is on begins with the value of mh-ins-buf-prefix (q.v.),
use that value as the fill-prefix for the duration of this operation."
  (interactive "P")
  (let ((fill-prefix (save-excursion
                       (beginning-of-line)
                       (if (looking-at mh-ins-buf-prefix)
                           mh-ins-buf-prefix
                         nil))))
    (fill-paragraph justify)))

(defun cq-mh-fill-region (p1 p2 justify)
  "Fill (and justify, if prefix arg. (third from code) given) each paragraph
in the region.  If the line point is on begins with the value of
mh-ins-buf-prefix (q.v.), use that value as the fill-prefix for the
duration of this operation."
  (interactive "r\nP")
  (let ((fill-prefix (save-excursion
                       (beginning-of-line)
                       (if (looking-at mh-ins-buf-prefix)
                           mh-ins-buf-prefix
                         nil))))
    (fill-region p1 p2 justify)))

(defun cq-mh-open-line (arg)
  "If the current line begins with the value of mh-ins-buf-prefix, do magic.
Else is just open-line.  The magic is this: the current line is broken at
point.  Ellipses are added to both lines so created, and three new empty lines
are inserted.  Point is left at the beginning of the middle line, and both
surrounding paragraphs are refilled, as per cq-mh-fill-paragraph.
There is more to this.  If the current line begins with mh-ins-buf-prefix, but
it is otherwise empty (contains only optional white space), then no ellipses
are added anywhere, and some vertical room is opened."
  (interactive "p")
  (let* ((fill-prefix (save-excursion
                       (beginning-of-line)
                       (if (looking-at mh-ins-buf-prefix)
                           mh-ins-buf-prefix
                         nil))))
    (if (or (not fill-prefix)
            (and (bolp) (not (bobp))    ;painful boundary conditions
                 (save-excursion
                   (forward-line -1)
                   (not (looking-at mh-ins-buf-prefix)))))
        (open-line arg)
      (if (looking-at mh-ins-buf-prefix)
          (forward-char (length mh-ins-buf-prefix)))
      (cond ((save-excursion
               (beginning-of-line)
               (forward-char (length mh-ins-buf-prefix))
               (looking-at "[ 	]*$"))  ;empty line
             (beginning-of-line)
             (kill-line)
             (open-line 2)
             (forward-line 1))
            (t                          ;need to add ellipses, etc.
             (let (middle)
               (save-excursion
                 (insert "...\n\n")
                 (setq middle (point-marker))
                 (insert "\n\n" mh-ins-buf-prefix)
                 (insert "...")
                 (fill-paragraph nil))
               (fill-paragraph nil)
               (goto-char middle)))))))

(defun cq-mh-delete-indentation (&optional arg)
  "Like delete-indentation (q.v.), but magic with respect to fill prefixes.
The optional argument is taken from the prefix argument, when interactive.
If nil, then if the current line starts with the value of mh-ins-buf-prefix,
then that string is removed, and delete-indentation is called.  If the prefix
argument is non-nil, first we move to the next line, then we act as if no
argument had been given."
  (interactive "*P")
  (cond (arg
         (forward-line 1)
         (cq-mh-delete-indentation))
        (t                              ;(null arg)
         (beginning-of-line)
         (if (looking-at mh-ins-buf-prefix)
             (delete-char (length mh-ins-buf-prefix)))
         (delete-indentation))))

;;; A hack to get a decent buffer when invoking EMACS from the whatnowproc.
;;; This mode is entered due to the fact that the 'Emacs:' header field
;;; happens to come first in the replcomps/components skeleton files.
(defun submh-mode ()
  "Same as Indented-Text (q.v.) mode, with the fill-column at 68. CQ"
  (interactive)
  ;; (indented-text-mode)
  (auto-fill-mode 1)
  (setq fill-column 68)
  (make-local-vars 'version-control 'never)
  (local-set-key "\^C\^C" 'save-buffers-kill-emacs)
  (local-set-key "\^Cy" 'mh-cq-grab-message)
  (local-set-key "\^C\^Fm" 'mh-to-message)
  (local-set-key "\^C\^Fh" 'mh-to-header-field)
  (local-set-key "\^I"  'self-insert-command)
  (setq mode-name "sub MH")
  (setq major-mode 'submh-mode))    

;;; This function supports the insertion of the current message, when
;;; Emacs is invoked by MH.

(defvar mh-cq-citation-prefix "| "
  "*Prefix for each line of the cited message.")

(defun mh-cq-grab-message ()
  "Quote after point the contents of the message being replied to."
  (interactive)
  (save-excursion
    (save-restriction
      (insert-file (getenv "editalt"))
      (narrow-to-region (point) (mark))
      (replace-regexp "^" mh-cq-citation-prefix)
      (widen))))

;;; The following are intended for Pnews and Rnmail, essentially

(defvar re-end-of-header "^[ \t]*$" "Regexp designating end of header")

(defun mh-to-header-field ()
  "Jump to a header field, after marking current position"
  (interactive)
  (let ((name (read-no-blanks-input "What field? " "")))
    (if (not (string= (substring name -1) ":"))
        (setq name (concat name ":")))
    (let* ((end-of-header)
           (uname (upcase name))
           (lname (downcase  name))
           (cname (capitalize name))
           (regexp (concat "^" cname "\\|^" lname "\\|^" uname)))
      ;; look for the end of the header
      (push-mark (point))
      (goto-char (point-min))
      (if (re-search-forward re-end-of-header (point-max) 'to-end)
          (setq end-of-header (progn (beginning-of-line) (point)))
        ;; All the file seems to be a header ...
        (message "All the file seems to be a header ...")
        (setq end-of-header (progn (next-line 1) (point))))
      ;; find old header field
      (goto-char (point-min))
      (if (re-search-forward regexp end-of-header 'to-end)
          ;; found, leave a space after the :
          (if (looking-at " ")
              (forward-char 1)
            (insert " "))
        ;; not found, create one
        (insert (capitalize name) " \n")
        (previous-line 1)
        (end-of-line)))))

;;; The News Interface
;;; 
;;; The purpose of these functions is to smooth the relations between
;;; Emacs and Rn, by reusing the machinery already provided by MH-E.
;;; Reply and Follow-up commands send messages to my inbox (see script
;;; ~/cmd/rn-mh for details), the final disposition of these messages
;;; is handled my MH-E.
(defvar mh-postnews-skel "~/.mh-e.news.skel"
  "*File to use as a template when composing a News article.")
(defvar mh-news-default-subject ""
  "*Default \"Subject:\" field to use when user is a moron.")
(defvar mh-news-default-newsgroups "junk"
  "*Default list of newsgroups (actually, comma-separated string),
to use when user is a moron.")
(defvar mh-news-buffer "*news-composition*"
  "*Name of the buffer used to compose news")
(defvar mh-news-inews-output "*inews-output*"
  "*Name of the buffer used to grab the output of inews.")
(defvar mh-news-article-map nil
  "Mode map for the RN-MH-EMACS interface")
(defvar mh-news-default-distribution "local"
  "*Distribution restriction that applies by default.")
(defvar mh-news-known-distributions
    '(("local") ("cs") ("gnu") ("alt") 
      ("wny") ("ny") ("ont") ("us") ("na") ("world"))
  "*Alist of known possible distributions.")

(cond
 ((null mh-news-article-map)
  (setq mh-news-article-map (make-keymap))
  (define-key mh-news-article-map "\^C\^C"  'mh-inews)
  (define-key mh-news-article-map "\^C\^Fb" 'mh-to-field)
  (define-key mh-news-article-map "\^C\^Fc" 'mh-to-field)
  (define-key mh-news-article-map "\^C\^Ff" 'mh-to-field)
  (define-key mh-news-article-map "\^C\^Fs" 'mh-to-field)
  (define-key mh-news-article-map "\^C\^Ft" 'mh-to-field)
  (define-key mh-news-article-map "\^C\^I"  'mh-insert-letter)
  (define-key mh-news-article-map "\^C\^Q"  'mh-fully-kill-draft)
  (define-key mh-news-article-map "\^C\^W"  'mh-check-whom)
  (define-key mh-news-article-map "\^C\^Y"  'mh-insert-cur-msg)
  (define-key mh-news-article-map "\^C\^Fm" 'mh-to-message)
  (define-key mh-news-article-map "\^C\^FM" 'mh-insert-pom)
  (define-key mh-news-article-map "\^I"     'indent-to-tab-stop)
  (define-key mh-news-article-map "\^C\^P"  'mh-inews)
  (define-key mh-news-article-map "\es"     'center-line)
  (define-key mh-news-article-map "\eS"     'center-paragraph)))

(defun mh-postnews ()
  "Compose and Post a News article."
  (interactive)
  (let ((target-buffer (get-buffer-create mh-news-buffer)))
    (switch-to-buffer target-buffer)
    (mh-letter-mode)
    (use-local-map mh-news-article-map)
    (make-local-vars 'version-control 'never)
    (delete-region (point-min) (point-max))
    (insert-file mh-postnews-skel)
    (let ((newsgroups   (read-string "Newsgroups: "
                                     mh-news-default-newsgroups))
          (distribution (completing-read "Distribution: "
                                         mh-news-known-distributions
                                         nil
                                         nil
                                         mh-news-default-distribution))
          (subject      (read-string "Subject: " mh-news-default-subject)))
      (if (not (assoc distribution mh-news-known-distributions))
          (setq mh-news-known-distributions
                (cons (cons distribution nil) mh-news-known-distributions)))
      (cq-mh-move-to-header-field "Newsgroups"   newsgroups   t)
      (cq-mh-move-to-header-field "Distribution" distribution t)
      (cq-mh-move-to-header-field "Subject"      subject      t))
    (mh-process-news-article)))

(defun mh-followup ()
  "Reply to a news article by following-up to it.  Use RN's header message!"
  (interactive)
  (let ((current-msg (mh-msg-filename (mh-get-msg-num t)))
        (target-buffer (get-buffer-create mh-news-buffer)))
    (switch-to-buffer target-buffer)
    (mh-letter-mode)
    (make-local-vars 'version-control 'never)
    (delete-region (point-min)(point-max))
    (insert-file current-msg)
    (mh-process-news-article)))

(defun mh-process-news-article ()
  "Handles a properly initialized news article buffer."
  ;; no way to send mail from here ...
  (set-balanced-insertions)
  (mh-to-message)
  (end-of-line 1)
  (message "Composing a News Article ..."))

(defun mh-inews (in-bg)
  "Send current buffer to inews.
Asks the user for confirmation.  With a prefix argument, it runs detached (in
the background), which restores you your Emacs faster, but makes it hard to
figure out if the posting succeeded."
  (interactive "P")
  (if (not (y-or-n-p "Post article? "))
      (message "Article not posted yet...")
    (let ((subject    (mh-get-field "Subject:"))
          (newsgroups (mh-get-field "Newsgroups:")))
      (if (string= subject "")
          (setq subject mh-news-default-subject))
      (if (string= newsgroups "")
          (setq newsgroups mh-news-default-newsgroups))
      ;; ensure final newline
      (save-excursion
        (goto-char (point-max))
        (if (not (looking-at "\n"))
            (insert "\n")))
      (cond (in-bg
             (message "Posting to %s ..." newsgroups)
             (shell-command-on-region
              (point-min) (point-max)
              ;;(concat news-inews-program " -h -t "
            ;;        (shell-quote-string subject)
              ;;        " -n " newsgroups " &")
              (concat news-inews-program " -h &"
                      ;; " -n '" newsgroups "' &"
                      )
              nil)
             (message "Posting to %s pushed to background." newsgroups))
            (t
             (message "Posting to %s ..." newsgroups)
             (let ((here   (current-buffer))
                   (output (get-buffer-create mh-news-inews-output)))
               (set-buffer output)
               (erase-buffer)
               (set-buffer here)
               (call-process-region (point-min) (point-max)
                                    news-inews-program
                                    nil output t
                                    "-h"
                                    ;; "-t" (shell-quote-string subject)
                                    ;; "-n '" newsgroups "'"
                                    )
               ;; Check if successful
               (set-buffer output)
               (if (not (string=
                         (buffer-substring (point-min) (point-max)) ""))
                   (display-buffer output))
               (set-buffer here))
             (message "Posting to %s ... done" newsgroups))))))

(defun shell-quote-string (string)
  "Quote the STRING so shell commands and scripts see it as one
argument.  A (potentially new) string is returned"
  (let ((strong-quote "'")              ;enough to stop nonsense, once
        (quoted-strong-quote "\\'"))
    (concat strong-quote
            (prog1                      ;hack until the \\ problem
                string                  ; is solved.
                (mapconcat (function (lambda (c)
                                   (let ((sc (char-to-string c)))
                                     (if (string-equal sc strong-quote)
                                         quoted-strong-quote
                                       sc))))
                       string ""))
            strong-quote)))

;;; Newer versions of MH-E don't let me say
;;;   "emacs -f mh-rmail -f mh-rescan-folder"
;;; as I used to.  So cq-inbox is provided for this purpose.

(defvar mh-folder-list-filename nil
  "*Name of the file that, when loaded, will reset mh-folder-list")

(defun cq-inbox ()
  "Get new mail.
Also sets the variable mh-folder-list, if nil.
Good from the command line: emacs -f cq-inbox"
  (interactive)
  (cond ((and (boundp 'display-time-process)
              display-time-process
              (eq 'run (process-status display-time-process)))
         (accept-process-output)))
  (if (null mh-folder-list)
      (reset-mh-folder-list))
  (mh-rmail)
  ;;(mh-rescan-folder "all")
  )

(defun reset-mh-folder-list (&optional nihil)
  "Load the file named by mh-folder-list-filename, so updating the
mh-folder-list.  The optional argument (prefix if interactive) controls
whether the list is just set to nil.  If the file version is not readable, for
any reason, the folder list is left alone."
  (interactive "P")
  (cond (nihil
         (setq mh-folder-list nil))
        (t
         (if (null mh-folder-list-filename)
             (setq mh-folder-list-filename
                   (or (getenv "MHFOLDERLIST")
                       (expand-file-name "~/.mh-folder-list.el"))))
         (if (file-readable-p mh-folder-list-filename)
             (load-file mh-folder-list-filename)))))

(defvar cq-mh-default-reply-to (user-login-name)
  ;; Some mailers don't quite understand rfc822, so this:
  ;; "Cesar A. Quiroz <quiroz@cs.rochester.edu>" causes them to send messages
  ;; to "Cesar", "A.", "Quiroz", and "<quiroz@cs.rochester.edu>".  Blah.
  "*Address to use as default return.")

(defun cq-mh-move-to-header-field (fieldname default &optional force)
  "Inserts a new field in the header, name given by FIELDNAME.  If the
field does not exist, it is given a value of DEFAULT, else point
is simply positioned at the end of the line containing the field (and
the mark is set to where point was before).  If the third argument is non-nil,
the default is inserted anyway.

A new mark is pushed (if needed) to remember where we were in the message."
  (interactive "sField Name? \nsDefault Value? ")
  ;;v19: broken
  ;;(if (not (eq (point) (mark)))
  ;;    (push-mark (point)))
  (push-mark (point))
  (if (and (not force) (mh-position-on-field fieldname t))
      nil
    (mh-insert-fields (concat fieldname ":") default)
    (mh-position-on-field fieldname nil)))

(defun cq-mh-field-return-receipt-to ()
  "Inserts (or moves to) the Return-Receipt-To field."
  (interactive)
  (cq-mh-move-to-header-field "Return-Receipt-To" cq-mh-default-reply-to))

(defun cq-mh-field-reply-to ()
  "Inserts (or moves to) the Reply-To field."
  (interactive)
  (cq-mh-move-to-header-field "Reply-To" cq-mh-default-reply-to))

(defun cq-mh-provide-Fcc-field (can-create)
  "Provide a folder for Fcc, defaults to +inbox
The argument (the prefix, if interactive) is non-nil when the name of the
folder need not exist."
  (interactive "P")
  (cq-mh-move-to-header-field           ;insert forcefully a folder name
   "Fcc" (mh-prompt-for-folder "Fcc" "+inbox" can-create) t))

(defvar cq-mh-exec-from-command "/usr/ucb/from"
  "Program used to figure out what sort of mail has arrived, without
clearing the mail arrival notification.  `from' is usual.")

(defun cq-mh-exec-from ()
  "Run `from' and show its output in temp buffer.
See the variable cq-mh-exec-from-command."
  (interactive)
  (let ((from-output    (get-buffer-create " *from output*")))
    (cq-display-temporarily
     (save-excursion
      (set-buffer from-output)
      (erase-buffer)
      (shell-command cq-mh-exec-from-command 'insert-output)
      (buffer-string))
     t
     ?-)))

;;; Get folder name

(defun cq-get-mh-folder-name (&optional default has-to-exist-p)
  "(cq-get-mh-folder-name &optional default has-to-exist-p)
Get a folder name, completing against mh-folder-list
The first argument is a default name to offer, the second argument controls
whether the folder has to exist.  Nil indicates that the argument could not
exist; non-nil means that the name has to exist.  Non-nil, but non-t also,
indicates that RET doesn't exist if it performs a completion.
Both arguments are optional."
  (completing-read
   "Folder? " mh-folder-list nil has-to-exist-p (or default "+")))

;;; Temporary fix here
;;;-
;;;-(defun mh-yank-cur-msg ()
;;;-  "Insert the currently displayed message into the draft buffer.  Prefix each
;;;-non-blank line in the message with the string in mh-ins-buf-prefix.  If a
;;;-region is set in the message's buffer, then only the region will be inserted.
;;;-Otherwise, the entire message will be inserted if mh-yank-from-start-of-msg is
;;;-non-nil.   If this variable is nil, the portion of the message following the
;;;-point will be yanked.  If mh-delete-yanked-msg-window is non-nil, any window
;;;-displaying the yanked message will be deleted."
;;;-  (interactive)
;;;-  (if (and (boundp 'mh-sent-from-folder) mh-sent-from-folder mh-sent-from-msg)
;;;-      (let ((to-point (point))
;;;-	    (to-buffer (current-buffer)))
;;;-	(set-buffer mh-sent-from-folder)
;;;-	(if mh-delete-yanked-msg-window
;;;-	    (delete-windows-on mh-show-buffer))
;;;-	(set-buffer mh-show-buffer)	; Find displayed message
;;;-	(let ((mh-ins-str (cond ((mark)
;;;-				 (buffer-substring (point) (mark)))
;;;-				((eq 'body mh-yank-from-start-of-msg)
;;;-				 (buffer-substring
;;;-				  (save-excursion
;;;-                                    (goto-char (point-min))
;;;-				    (mh-goto-header-end 1)
;;;-				    (point))
;;;-				  (point-max)))
;;;-				(mh-yank-from-start-of-msg
;;;-				 (buffer-substring (point-min) (point-max)))
;;;-				(t
;;;-				 (buffer-substring (point) (point-max))))))
;;;-	  (set-buffer to-buffer)
;;;-	  (narrow-to-region to-point to-point)
;;;-	  (insert mh-ins-str)
;;;-	  (mh-insert-prefix-string mh-ins-buf-prefix)
;;;-	  (insert "\n")
;;;-	  (widen)))
;;;-      (error "There is no current message.")))

;;; End of cq-mh-e.el
