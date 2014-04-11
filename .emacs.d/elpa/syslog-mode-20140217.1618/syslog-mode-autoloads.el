;;; syslog-mode-autoloads.el --- automatically extracted autoloads
;;
;;; Code:


;;;### (autoloads (syslog-mode syslog-filter-dates syslog-date-to-time
;;;;;;  syslog-datetime-regexp syslog-filter-lines) "syslog-mode"
;;;;;;  "syslog-mode.el" (21319 39403 627966 431000))
;;; Generated autoloads from syslog-mode.el

(defvar syslog-setup-on-load nil "\
*If not nil setup syslog mode on load by running syslog-add-hooks.")

(autoload 'syslog-filter-lines "syslog-mode" "\
Restrict buffer to lines matching regexp.
With prefix arg: remove lines matching regexp.

\(fn &optional ARG)" t nil)

(defvar syslog-datetime-regexp "^[a-z]\\{3\\} [0-9]\\{1,2\\} \\([0-9]\\{2\\}:\\)\\{2\\}[0-9]\\{2\\} " "\
A regular expression matching the date-time at the beginning of each line in the log file.")

(custom-autoload 'syslog-datetime-regexp "syslog-mode" t)

(autoload 'syslog-date-to-time "syslog-mode" "\
Convert DATE string to time.
If no year is present in the date then the current year is used.
If DATE can't be parsed then if SAFE is non-nil return nil otherwise throw an error.

\(fn DATE &optional SAFE)" nil nil)

(autoload 'syslog-filter-dates "syslog-mode" "\
Restrict buffer to lines between dates.
With prefix arg: remove lines between dates.

\(fn START END &optional ARG)" t nil)

(autoload 'syslog-mode "syslog-mode" "\
Major mode for working with system logs.

\\{syslog-mode-map}

\(fn)" t nil)

;;;***

;;;### (autoloads nil nil ("syslog-mode-pkg.el") (21319 39403 729206
;;;;;;  898000))

;;;***

(provide 'syslog-mode-autoloads)
;; Local Variables:
;; version-control: never
;; no-byte-compile: t
;; no-update-autoloads: t
;; coding: utf-8
;; End:
;;; syslog-mode-autoloads.el ends here
