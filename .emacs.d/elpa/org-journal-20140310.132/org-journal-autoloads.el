;;; org-journal-autoloads.el --- automatically extracted autoloads
;;
;;; Code:


;;;### (autoloads (org-journal-previous-entry org-journal-next-entry
;;;;;;  org-journal-read-entry org-journal-new-date-entry org-journal-new-entry
;;;;;;  org-journal-file-pattern org-journal-dir) "org-journal" "org-journal.el"
;;;;;;  (21319 37250 19910 405000))
;;; Generated autoloads from org-journal.el

(defvar org-journal-dir "~/Documents/journal/" "\
Directory containing journal entries.
  Setting this will update auto-mode-alist using
  `(org-journal-update-auto-mode-alist)`")

(custom-autoload 'org-journal-dir "org-journal" nil)

(defvar org-journal-file-pattern "[0-9]\\{8\\}$" "\
Regex string for journal file names.
  This pattern is used to enable org-journal-mode for files in
  org-journal-dir and mark journal entries in the calendar.
  Setting this will update auto-mode-alist using
  `(org-journal-update-auto-mode-alist)`")

(custom-autoload 'org-journal-file-pattern "org-journal" nil)
 (autoload 'calendar "org-journal")

(eval-after-load "calendar" '(progn (define-key calendar-mode-map "j" 'org-journal-read-entry) (define-key calendar-mode-map "]" 'org-journal-next-entry) (define-key calendar-mode-map "[" 'org-journal-previous-entry) (define-key calendar-mode-map (kbd "i j") 'org-journal-new-date-entry)))

(global-set-key (kbd "C-c j") 'org-journal-new-entry)

(autoload 'org-journal-new-entry "org-journal" "\
Open today's journal file and start a new entry

\(fn)" t nil)

(autoload 'org-journal-new-date-entry "org-journal" "\
Open the journal for the date indicated by point and start a new entry.
If the date is not today, it won't be given a time.

\(fn ARG &optional EVENT)" t nil)

(autoload 'org-journal-read-entry "org-journal" "\
Open journal entry for selected date for viewing

\(fn ARG &optional EVENT)" t nil)

(autoload 'org-journal-next-entry "org-journal" "\
Go to the next date with a journal entry

\(fn)" t nil)

(autoload 'org-journal-previous-entry "org-journal" "\
Go to the previous date with a journal entry

\(fn)" t nil)

;;;***

;;;### (autoloads nil nil ("org-journal-pkg.el") (21319 37250 97750
;;;;;;  779000))

;;;***

(provide 'org-journal-autoloads)
;; Local Variables:
;; version-control: never
;; no-byte-compile: t
;; no-update-autoloads: t
;; coding: utf-8
;; End:
;;; org-journal-autoloads.el ends here
