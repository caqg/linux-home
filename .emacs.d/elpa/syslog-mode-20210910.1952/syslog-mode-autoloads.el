;;; syslog-mode-autoloads.el --- automatically extracted autoloads  -*- lexical-binding: t -*-
;;
;;; Code:

(add-to-list 'load-path (directory-file-name
                         (or (file-name-directory #$) (car load-path))))


;;;### (autoloads nil "syslog-mode" "syslog-mode.el" (0 0 0 0))
;;; Generated autoloads from syslog-mode.el

(defvar syslog-setup-on-load nil "\
*If not nil setup syslog mode on load by running syslog-add-hooks.")

(autoload 'syslog-view "syslog-mode" "\
Open a view of syslog files with optional filters and highlights applied.
When called interactively the user is prompted for a member of `syslog-views' and the
arguments are determined from the chosen member.
FILES can be either nil in which case the view is applied to the current log file, or
it can be the same as the first argument to `syslog-get-filenames' - a list of cons
cells whose cars are filenames and whose cdrs indicate how many logfiles to include.
LABEL indicates whether or not to label each line with the filename it came from.
RXSHOWSTART, RXSHOWEND and RXHIDESTART, RXHIDEEND are optional regexps which will be 
used to filter in/out blocks of buffer lines with `syslog-filter-lines'. 
STARTDATE and ENDDATE are optional dates used to filter the lines with `syslog-filter-dates'; 
they can be either date strings or time lists as returned by `syslog-date-to-time'.
HIGHLIGHTS is a list of cons cells whose cars are regexps and whose cdrs are faces to 
highlight those regexps with.

\(fn FILES &optional LABEL TREATMENTS RXSHOWSTART RXSHOWEND RXHIDESTART RXHIDEEND STARTDATE ENDDATE REMOVEDATES HIGHLIGHTS BUFNAME)" t nil)

(autoload 'syslog-filter-lines "syslog-mode" "\
Restrict buffer to blocks of text between matching regexps.
If the user only enters one regexp then just filter matching lines instead of blocks.
With prefix ARG: remove matching blocks.

\(fn &optional ARG)" t nil)

(defvar syslog-views nil "\
A list of views.
Each view is a list of:
 - a name for the view
 - a list of files to display; each item in the list is a cons cell whose car is the base log file, 
     and whose cdr is a number indicating how many previous log files of the same type to include.
     If nil then the view will be applied to the currently displayed file.
 - a boolean indicating whether or not to label each line with the filename
 - an optional list of functions to apply to transform the buffer before filtering & highlighting. 
     Each element is either:
     - a list whose car is a function and whose cdr is a list of arguments for the function. The arglist
       may contain the symbol 'interactive which means the value will be prompted for when the view is invoked.
     - a cons cell whose car is a regexp containing a match group, and whose cdr is either a replacement
       string, or a function that takes the text captured by that match group as its only arg, and returns 
       some text to replace it. This function/string will be used for replacing all matches in the buffer.
 - a regexp matching start lines of blocks to show
 - a regexp matching end lines of blocks to show (if blank then lines will be filtered instead of blocks)
 - a regexp matching start lines of blocks to hide
 - a regexp matching end lines of blocks to hide (if blank then lines will be hidden instead of blocks)
 - an optional start date for filtering lines with `syslog-filter-dates'
 - an optional end date for filtering lines with `syslog-filter-dates'
 - a boolean; if non-nil hide lines matching above dates, otherwise display only those lines
 - a list of highlighting info; each element is a cons cell whose car is a regexp to highlight and 
   whose cdr is a face to use for highlighting
 - an optional name to rename the buffer")

(custom-autoload 'syslog-views "syslog-mode" t)

(autoload 'syslog-date-to-time "syslog-mode" "\
Convert DATE string to time.
If no year is present in the date then the current year is used.
If DATE can't be parsed then if SAFE is non-nil return nil otherwise throw an error.

\(fn DATE &optional SAFE)" nil nil)

(autoload 'syslog-filter-dates "syslog-mode" "\
Restrict buffer to lines between times START and END (Emacs time lists).
With prefix ARG: remove lines between dates.
If either START or END are nil then treat them as the first/last time in the
buffer respectively.

\(fn START END &optional ARG)" t nil)

(autoload 'syslog-mode "syslog-mode" "\
Major mode for working with system logs, and strace output.

\\{syslog-mode-map}" t nil)

(register-definition-prefixes "syslog-mode" '("forward-syslog-token" "hi-lock-set-subpattern" "highlight-regexp-unique" "syslog-"))

;;;***

;;;### (autoloads nil nil ("strace_notes.el" "syslog-mode-pkg.el"
;;;;;;  "syslog_notes.el") (0 0 0 0))

;;;***

;; Local Variables:
;; version-control: never
;; no-byte-compile: t
;; no-update-autoloads: t
;; coding: utf-8
;; End:
;;; syslog-mode-autoloads.el ends here
