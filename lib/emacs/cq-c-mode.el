;;;; -*- Mode: Emacs-Lisp -*-
;;;
;;; To do:  the support for C programs is uglily written.  Rewrite
;;; just about all of it to use decent Emacs Lisp.  C-main and friends
;;; are especially atrocious.

(require 'balanced-insertions)
(require 'cq-utils)                     ;because of lsetq
(require 'set-mode)

(defvar c-style-switch  nil
  "Symbol, name of function called from c{,++}-mode-hook to determine C style
parameters. Call only from C-mode buffers; NIL means no-op.")

(defun determine-c-style ()
  "Sets the local variable c-style-switch. CQ"
  (interactive)
  nil)

(defun cq-cc-mode-common-settings ()
  "Set variables of C-style"
  (require 'vc)
  (make-local-variable 'c-style-switch)
  (setq c-style-switch (determine-c-style))
  (if c-style-switch
      (funcall c-style-switch))

  ;; Set other preferences.  I have used my own macro, lsetq, back in the 80s,
  ;; when automatic localization was not invented yet.
  (lsetq abbrev-mode                     t
	 case-fold-search               nil
	 case-replace                   nil
	 c-tab-always-indent		nil
	 blink-matching-paren            t
	 comment-multi-line              t
	 comment-column                 40)
  (lsetq tab-stop-list '(8 16 20 24 32 40 48 56 64 72 80 88 96 104 112 120 128
			  136 144 152 160 168 176 184 192 200 208 216 224))

  ;; change the syntax table so that my abbrevs will work
  (modify-syntax-entry ?# "w")

  ;; want fill mode
  (auto-fill-mode 1)
  (set-fill-column 79)

  ;; some help from text modes
  ;; (local-set-key    "\M-s"	   'center-line)

  ;;(local-set-key    "\e\{"         'cq-insert-braces)
  (set-balanced-insertions)
  (local-set-key "\C-z{"   'cq-insert-braces)
  (local-set-key "\C-\M-u" 'cq-backward-up-list-or-string)
  (local-set-key "\C-\M-d" 'cq-down-list))

;;; retired settings
;;; (local-set-key    "\e\""         'within-delimiters)
;;; (local-unset-key  "\C-z\C-u")
;;; (local-set-key    "\C-z\C-ue"    'c-insert-exit)
;;; (local-set-key    "\C-z\C-uc"    'c68-catch)
;;; (local-set-key    "\C-z\C-uw"    'c68-when)


;;; Old doc from 80s/early 90s
;;; Random thoughts on C style:
;;; *   Keep close to K&R indentation.
;;; *   UPPERCASE means #defined
;;; *   Capitalized means typedef \(say ListPointer, not List_pointer)
;;; *   gCapitalized means extern global \(can use gArgument_count\)
;;; These have to be kept to 6-char significance!  That `g' is a pain.
;;; Alternative:  end the name in G.
;;; Obviously, `errno', `optind', etc..., are too late to change.
;;; Also, having module name prefixes makes it easy to avoid the gCap 
;;; convention and still have some semblance of order.
;;;
;;; 2006-12-24 20:03:25UT (cesar@bears06-01)
;;; I have a document from the early 90s, written at EXELE, with the ideas
;;; prevalent at the time.  Now I reserve CamelCase for named scopes (like
;;; namespaces and types) that are not functions themselves, and use
;;; underscored_names for variables (including data members) and functions.
;;; It would be easier to explain if I used camelCase for functions, and left
;;; the underscored_names for data--except that the Lisp background makes me
;;; think of functions and data as not that different.  Types (and namespaces,
;;; and templates thereof) feel more different and take a different case.

(defun cq-c-mode ()
  "Sets the C-mode environment.
SEE ALSO: c-bsd-style, c-cq-style, c-rms-style.
"
  (interactive)
  ;; Look at the .emacs for the modern hook.
  (cq-cc-mode-common-settings))

(defun cq-c++-mode ()
  "Sets the C++-mode environment."
  ;; Look at the .emacs for the modern hook.
  (cq-cc-mode-common-settings))

(defun cq-java-mode ()
  "Sets the java-mode environment.
See the documentation for cq-c-mode for some lexical conventions."
  (interactive)
  ;; Look at the .emacs for the modern hook.
  (cq-cc-mode-common-settings))

;;; Styles

(defun c-bsd-style ()
  "BSD style indentation, at 8 spaces"
  (interactive)
  (setq c-basic-offset 8))

(defun c-raj-style ()
  "Change the C style parameters to Raj Prakash's usage."
  (interactive)
  (setq c-basic-offset 4))

(defun c-rms-style ()
  "Change the C style parameters to Stallman's usage."
  (interactive)
  (setq c-basic-offset 2))


(defvar *c-comment-fill-prefix* " * "
  "*Comment fill prefix in C mode.")
(defvar *c-comment-major-section-fill-prefix* " @ "
  "*Comment fill prefix in C mode, used to name a major section.")
(defvar *c-comment-minor-section-fill-prefix* " - "
  "*Comment fill prefix in C mode, used to name a minor section.")
(defvar *c-comment-subsection-fill-prefix* " . "
  "*Comment fill prefix in C mode, used to name a subsection.")

(defun c-rcs-header (hfile ansi-p)
  "Insert an RCS header after point.  Argument HFILE is t when this
buffer is intended to produce a .h file.  Argument ANSI-P is t when this file
is intended for use with ANSI-C"
  (let (insert-point)
    (cond (hfile
           (insert "/*\n")
           (insert *c-comment-fill-prefix* "$" "Id$\n")
           (insert *c-comment-fill-prefix*) (newline)
           (insert *c-comment-major-section-fill-prefix*)
           (setq insert-point (point))      (newline)
           (insert *c-comment-fill-prefix*) (newline)
           (insert *c-comment-fill-prefix* "$" "Source$\n */\n"))
          (t
           (insert "#ifndef lint\n")
           (insert "static char gRCSid[]= /* RCS identification string */")
           (indent-for-comment) (end-of-line) (newline-and-indent)
           (insert "    \"$" "Id$\";\n")
           (insert "static char gRCSsrc[]= /* RCS source file */")
           (indent-for-comment) (end-of-line) (newline-and-indent)
           (insert "    \"$" "Source$\";\n")
           (insert "#endif\n\n")
           (insert "/*\n")
           (insert *c-comment-major-section-fill-prefix*)
           (setq insert-point (point))      (newline)
           (insert *c-comment-fill-prefix*) (newline)
           (insert " */\n")))
    (save-excursion
      (let ((fill-prefix *c-comment-fill-prefix*))
        (goto-char insert-point)
        (message "%s. %s."
                 "Edit your main comments"
                 "`M-C-c' returns from recursive edit")
        (recursive-edit)))))

(defun c-main-with-args (stdio-p ansi-p)
  "Make sure command-line arguments are available to the main program.
If STDIO-P is not nil, code to include stdio is inserted.
If ANSI-P is not nil, code is treated as for ANSI-C"
  (let ((getopt-p (y-or-n-p "Do you want to use getopt(3)? "))
        (exit-stats-p (y-or-n-p "Do you want standard exit codes defined? ")))
    (if (and getopt-p (not stdio-p))
        (insert "\n#include <stdio.h>\n"))
    (cond (exit-stats-p
           (insert "\n/* exit codes */"
                   "\n#define SUCCESS     0"
                   "\n#define FAILURE     1"
                   "\n#define BADCMDLN    2"
                   "\n#define BADOPTS     2 /* for compatibility only */")
           (indent-for-comment)(end-of-line)
           (insert "\n#define BADINPUT    3"
                   "\n#define IOERR       4"
                   "\n#define DISASTER    5"
                   "\n")))
    (insert "\n/* command line arguments */")
    (insert "\nint                 argcG; /* number of command arguments */")
    (indent-for-comment) (end-of-line)
    (insert
     "\nchar              **argvG; /* access to the command line */")
    (indent-for-comment) (end-of-line)
    (insert "\n\f\n")
    (insert "/*") (newline)
    (insert " - main(int argc, char **argv)") (newline)
    (insert " */") (newline)
    (push-mark (point))                 ;UGLY SIDE EFFECT
    (if ansi-p
        (insert "\nint\nmain(\tint argc, char **argv\t)")
      (insert "\nint\nmain(argc, argv)"
              "\nint             argc;"
              "\nchar           *argv[];"))
    (insert "\n{")
    (cond (getopt-p
           (insert "\n/* for getopt(3) */\n"
                   "extern char    *optarg;\n"
                   "extern int      optind;\n"
                   "extern int      opterr;\n"
                   "void            usage();")
           (insert "\nint             option; /* returned by getopt */")
           (indent-for-comment) (end-of-line)
           (insert "\nint             badopts = 0;\n")))
    (insert "\n/* make the command line globally available */"
            "\nargcG = argc;  argvG = argv;\n")
    (cond (getopt-p
           (insert "\n/* process the command line */\n"
                   "while ((option = getopt(argc, argv, \"?\")) != EOF) {\n"
                   "switch (option) {\n"
                   "case '':\n"
                   "break;\n"
                   "case '?':\n"
                   "default:\n"
                   "badopts += 1;\n"
                   "}\n"
                   "}\n"
                   "if (badopts) {\n"
                   "usage();\n"
                   "}\n"
                   "for (; optind < argc; ++optind) {\n"
                   "}\n")))
    (insert "\n}\n")))


(defun c68-catch ()
  "Builds a catch block.  Extra braces are used for indentation purposes."
  (interactive)
  (insert "catch {") 
  (save-excursion
    (reindent-then-newline-and-indent)
    (insert "}")         (reindent-then-newline-and-indent)
    (insert "onthrow {") (reindent-then-newline-and-indent)
    (insert "}")         (reindent-then-newline-and-indent)
    (insert "endcatch;") (reindent-then-newline-and-indent))
  (newline-and-indent))

(defun c68-when ()
  "Builds a when() clause.  Extra braces for indentation.  
Must be inside an onthrow."
  (interactive)
  (newline-and-indent)
  (insert "when (")
  (save-excursion
    (insert ") {") (newline-and-indent)
    (insert "}")   (c-indent-command)))

(defun cq-insert-braces ()
  "Insert a matching pair of braces and position cursor for code
insertion in C mode. CQ"
  (interactive)
  (cond ((bolp)
         (insert "{") (newline-and-indent)
         (save-excursion
           (insert "\n")
           (if (looking-at "[ \t]*$")
               (insert "}")
             (insert "}\n"))))
        (t
         (insert "{") (reindent-then-newline-and-indent)
         (save-excursion
           (insert "\n}")
           (reindent-then-newline-and-indent)
           ;; make sure no new blank lines are opened
           (beginning-of-line)
           (if (looking-at "[ \t]*$")
               (kill-line 1))))))

(defun c-insert-exit ()
  "Insert exit(); followed by /* NOTREACHED */"
  (interactive)
  (insert "exit(")
  (c-indent-command)
  (save-excursion
    (insert ");")
    (newline-and-indent)
    (insert "/* NOTREACHED */")))

;;; End of cq-c-mode.el
