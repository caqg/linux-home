;;;; -*- Emacs-Lisp -*-
;;; 
;;; This module helps structured insertion of paired textual elements.
;;; The two critical functions are balanced-insertion and
;;; set-balanced-insertions.  The rest are convenient utilities.

;;; 2004-05-15.
;;; After a long hiatus I had to fix the within-delimiters behavior.
;;; It has been broken since the equivalence of characters and
;;; keystrokes was lost, due to the appearance of events in XEmacs.
;;; The old version is kept, in case GNU Emacs still can run it.

;;; Sat Mar 18 22:24:58 1989 -- I decided to reimplement this facility via an
;;; association list.  This is easier to extend, and is cleaner to boot.  The
;;; idea comes from Zmacs.

;; (require 'cl)

(unless (fboundp 'event-to-character)
  (defun event-to-character (e)
    "Replacement function for event-to-character in GNU Emacs"
    e))

(defvar *balanced-delimiters-alist* nil
  "*Table of balanced delimiters
Each entry is a list, composed of 4 slots:
    TRIGGER:  a character \(i.e., small integer\)
    LEFT:     a string
    RIGHT:    a string
    SKIPPER:  a function
TRIGGER has the function within-delimiters \(q.v.\) bound to it.  The function
eventually uses the prefix argument to skip \(via SKIPPER\) a number of
syntactically useful forms \(words, sexps, sentences, ...\) between the places
where LEFT and RIGHT are inserted.  For instance, assume the value of
*balanced-delimiters-alist* were
    \(\(?~ \"~|\" \"|~\" \(function forward-word\)\)\)
then if you have within-delimiters bound to '~', then typing
    `M-4 ~'
with the cursor where the _ is:
    in _this short boring line of text
you should get
    in ~|this short boring line|~_ of text")


;; (defun test-stuff (num-prefix raw-prefix)
;;   "See the documentation of *balanced-delimiters-alist*"
;;   (interactive "p\nP")
;;   (let* ((keystrokes (this-command-keys))
;;          (len (length keystrokes))
;;          (lastchar   last-command-char))
;;     (message "num:%d raw:%s keys:%s firstkey:%c lastkey:%c lastchar:%c"
;;              num-prefix (prin1-to-string raw-prefix)
;;              keystrokes (elt keystrokes 0) (elt keystrokes (1- len))
;;              lastchar)))

(defun within-delimiters-by-chars (num-prefix raw-prefix)
  "Insert balanced delimiters
See the documentation of *balanced-delimiters-alist*
This function uses not only the value of the prefix argument, but its shape
too.  Any prefix entered via `C-u' \(as opposed to using `M-'\) will leave a
mark \(see balanced-insertion, the description of MARKIT for details\).
As a special case, `C-u' followed by the character this is bound to is
interpreted as a prefix argument of 0, not of 4.

You shouldn't bind this function to `C-u'"
  (interactive "p\nP")
  (let* ((keystrokes    (this-command-keys))
         (len           (length keystrokes))
         (firstchar     (elt keystrokes 0))
         (lastchar      last-command-event)
         (items         (cond ((and (consp raw-prefix)
                                    (= len 2))
                               1)
                              ((or (null raw-prefix)
                                   ;; \C-u not followed by an argument
                                   ;; defaults usually to 4, but we really 
                                   ;; want it to be 0.
                                   (and (= firstchar ?\C-u)
                                        (not (memq (elt keystrokes 1)
                                                   '(?1 ?2 ?3 ?4 ?5
                                                     ?6 ?7 ?8 ?9 ?0
                                                     ?-)))))
                               0)
                              (t
                               num-prefix)))
         (markit        (= firstchar ?\C-u))
         (entry         (assoc lastchar *balanced-delimiters-alist*))
         (left          (nth 1 entry))
         (right         (nth 2 entry))
         (skipper       (nth 3 entry)))
    ;;(debug nil keystrokes items firstchar lastchar)
    (cond ((null entry)
           (error "no entry for `%c' in *balanced-delimiters-alist*"
                  lastchar))
          (t
           (balanced-insertion left right items skipper markit)))))

(defun within-delimiters (num-prefix raw-prefix)
  "Insert balanced delimiters
See the documentation of *balanced-delimiters-alist*
This function uses not only the value of the prefix argument, but its shape
too.  Any prefix entered via `C-u' \(as opposed to using `M-'\) will leave a
mark \(see balanced-insertion, the description of MARKIT for details\).
As a special case, `C-u' followed by the character this is bound to is
interpreted as a prefix argument of 0, not of 4.

You shouldn't bind this function to `C-u'"
  (interactive "p\nP")
  (let* ((keystrokes    (this-command-keys))
         (len           (length keystrokes))
         (firstchar     (event-to-character (elt keystrokes 0)))
         (lastchar      (event-to-character last-command-event))
         (items         (cond ((and (consp raw-prefix)
                                    (= len 2))
                               1)
                              ((or (null raw-prefix)
                                   ;; \C-u not followed by an argument
                                   ;; defaults usually to 4, but we really 
                                   ;; want it to be 0.
                                   (and (= firstchar ?\C-u)
                                        (not (memq (elt keystrokes 1)
                                                   '(?1 ?2 ?3 ?4 ?5
                                                     ?6 ?7 ?8 ?9 ?0
                                                     ?-)))))
                               0)
                              (t
                               num-prefix)))
         (markit        (= firstchar ?\C-u))
         (entry         (assoc lastchar *balanced-delimiters-alist*))
         (left          (nth 1 entry))
         (right         (nth 2 entry))
         (skipper       (nth 3 entry)))
    ;;(debug nil keystrokes items firstchar lastchar)
    (cond ((null entry)
           (error "no entry for `%c' in *balanced-delimiters-alist*"
                  lastchar))
          (t
           (balanced-insertion left right items skipper markit)))))

(defun balanced-insertion (left right items skipper &optional markit)
  "Insert strings LEFT and RIGHT, skipping between them ITEMS items,
by calling the SKIPPER function on arg. ITEMS between the insertion of
LEFT and the insertion of RIGHT.  
Leave point immediately after LEFT, except if negative ITEMS have been 
used, when point is left after RIGHT. SKIPPER is usually forward-sexp.
If MARKIT is non-nil, then leave a new mark after RIGHT \(if ITEMS was
positive\), or before LEFT \(for ITEMS negative\)."
  (let* ((backward   (< items 0))
         (first      (if backward right left))
         (second     (if backward left right))
         ;; POINT-IF-BACKWARD remembers where to leave point after a
         ;; backwards motion.
         ;; FINAL-MARK remembers the desired final position for the
         ;; mark.
         point-if-backward
         final-mark)
    (if backward
        (save-excursion (insert first)
                        (setq point-if-backward (point-marker)))
      (insert first))
    (save-excursion
      (funcall skipper items)
      (cond (backward
             (if markit
                 (setq final-mark (point-marker)))
             (insert second))
            (t
             (insert second)
             (if markit
                 (setq final-mark (point-marker))))))
    ;; Fix point and mark.  Point is already in the right place for
    ;; forward motions.
    (if markit
        (push-mark (marker-position final-mark)))
    (if backward
        (goto-char (marker-position point-if-backward)))))

(defun define-auto-delimiters (trigger left right skipper)
  "Make an entry in *balanced-delimiters-alist* with the arguments 
TRIGGER (a character), LEFT, RIGHT (two strings) and SKIPPER
\(a function, like forward-word\)."
  (interactive)
  (setq *balanced-delimiters-alist*
        (cons (list trigger left right skipper)
              *balanced-delimiters-alist*)))

(defun undefine-auto-delimiters (trigger)
  "Side-effect *balanced-delimiters-alist* to remove all entries that use
TRIGGER \(a character\).  See the documentation of the functions
define-auto-delimiters and within-delimiters."
  (interactive)
  (setq *balanced-delimiters-alist*
        (delq (assoc trigger *balanced-delimiters-alist*)
              *balanced-delimiters-alist*)))

(when (null *balanced-delimiters-alist*)
  ;; If you define more delimiters, make sure to fix set-balanced-insertions
  ;; too.
  ;; CQ, 94/07/01 --- exception for version 19: M-( needs to be treated
  ;; as one character now
  ;; CQ, 94/07/14 --- so are ?M\-{, ?\M-*, ?\M-\". etc...
  (define-auto-delimiters ?\M-\( "\(" "\)" 'forward-sexp)
  (define-auto-delimiters ?\M-\{ "{" "}" 'forward-sexp)
  (define-auto-delimiters ?\M-* "*" "*" 'forward-sexp)
  (define-auto-delimiters ?\M-\" "\"" "\"" 'forward-sexp)
  ;;
  (define-auto-delimiters ?\( "\(" "\)" 'forward-sexp)
  (define-auto-delimiters ?\[ "\[" "\]" 'forward-sexp)
  (define-auto-delimiters ?\{ "\{" "\}" 'forward-sexp)
  (define-auto-delimiters ?! "!" "!" 'forward-sexp)
  (define-auto-delimiters ?@ "@" "@" 'forward-sexp)
  (define-auto-delimiters ?# "#" "#" 'forward-sexp)
  (define-auto-delimiters ?$ "$" "$" 'forward-sexp)
  (define-auto-delimiters ?% "%" "%" 'forward-sexp)
  (define-auto-delimiters ?^ "^" "^" 'forward-sexp)
  (define-auto-delimiters ?& "&" "&" 'forward-sexp)
  (define-auto-delimiters ?* "*" "*" 'forward-sexp)
  (define-auto-delimiters ?- "-" "-" 'forward-sexp)
  (define-auto-delimiters ?= "=" "=" 'forward-sexp)
  (define-auto-delimiters ?/ "/" "/" 'forward-sexp)
  (define-auto-delimiters ?\\ "\\" "\\" 'forward-sexp)
  (define-auto-delimiters ?` "`" "`" 'forward-sexp)
  (define-auto-delimiters ?_ "_" "_" 'forward-sexp)
  (define-auto-delimiters ?+ "+" "+" 'forward-sexp)
  (define-auto-delimiters ?| "|" "|" 'forward-sexp)
  (define-auto-delimiters ?~ "~" "~" 'forward-sexp)
  (define-auto-delimiters ?\" "\"" "\"" 'forward-sexp)
  (define-auto-delimiters ?' "'" "'" 'forward-sexp)
  (define-auto-delimiters ?. "." "." 'forward-sexp)
  (define-auto-delimiters ?  " " " " 'forward-sexp)
  (define-auto-delimiters ?< "<" ">" 'forward-sexp)
  (define-auto-delimiters ?q "`" "'" 'forward-sexp)
  (define-auto-delimiters ?Q "``" "''" 'forward-sexp))

(defun set-balanced-insertions ()
  "Bind the balanced insertions in the local keymap."
  (interactive)
  (local-set-key   "\C-z\("   'within-delimiters)
  (local-set-key   "\C-z\{"   'within-delimiters)
  (local-set-key   "\C-z\["   'within-delimiters)
  (local-set-key   "\C-z!"    'within-delimiters)
  (local-set-key   "\C-z@"    'within-delimiters)
  (local-set-key   "\C-z~"    'within-delimiters)
  (local-set-key   "\C-z^"    'within-delimiters)
  (local-set-key   "\C-z$"    'within-delimiters)
  (local-set-key   "\C-z#"    'within-delimiters)
  (local-set-key   "\C-z&"    'within-delimiters)
  (local-set-key   "\C-z%"    'within-delimiters)
  (local-set-key   "\C-z+"    'within-delimiters)
  (local-set-key   "\C-z="    'within-delimiters)
  (local-set-key   "\C-z\\"   'within-delimiters)
  (local-set-key   "\C-z-"    'within-delimiters)
  (local-set-key   "\C-z_"    'within-delimiters)
  (local-set-key   "\C-z."    'within-delimiters)  
  (local-set-key   "\C-z|"    'within-delimiters)  
  (local-set-key   "\C-z<"    'within-delimiters)
  (local-set-key   "\C-z*"    'within-delimiters)
  (local-set-key   "\C-z/"    'within-delimiters)
  (local-set-key   "\C-z'"    'within-delimiters)
  (local-set-key   "\C-z`"    'within-delimiters)
  (local-set-key   "\C-z\""   'within-delimiters)
  (local-set-key   "\C-z "    'within-delimiters)
  (local-set-key   "\C-zq"    'within-delimiters)
  (local-set-key   "\C-zQ"    'within-delimiters)
  )

(provide 'balanced-insertions)


;;; End of new-balanced-insertions
