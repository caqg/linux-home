;;; debian-el-autoloads.el --- automatically extracted autoloads
;;
;;; Code:

(add-to-list 'load-path (directory-file-name
                         (or (file-name-directory #$) (car load-path))))


;;;### (autoloads nil "apt-sources" "apt-sources.el" (0 0 0 0))
;;; Generated autoloads from apt-sources.el

(autoload 'apt-sources-mode "apt-sources" "\
Major mode for editing apt's sources.list file.
Sets up command `font-lock-mode'.

\\{apt-sources-mode-map}" t nil)

(if (fboundp 'register-definition-prefixes) (register-definition-prefixes "apt-sources" '("apt-sources-")))

;;;***

;;;### (autoloads nil "apt-utils" "apt-utils.el" (0 0 0 0))
;;; Generated autoloads from apt-utils.el

(autoload 'apt-utils-show-package "apt-utils" "\
Show information for a Debian package.
A selection of known packages is presented.  See `apt-utils-mode'
for more detailed help.  If NEW-SESSION is non-nil, generate a
new `apt-utils-mode' buffer.

\(fn &optional NEW-SESSION)" t nil)

(autoload 'apt-utils-search "apt-utils" "\
Search Debian packages for regular expression.
To search for multiple patterns use a string like \"foo && bar\".
The regular expression used to split the
terms (`apt-utils-search-split-regexp') is customisable." t nil)

(if (fboundp 'register-definition-prefixes) (register-definition-prefixes "apt-utils" '("apt-")))

;;;***

;;;### (autoloads nil "deb-view" "deb-view.el" (0 0 0 0))
;;; Generated autoloads from deb-view.el

(autoload 'deb-view-dired-view "deb-view" "\
View Debian package control and data files.
Press \"q\" in either window to kill both buffers
and return to the dired buffer. See deb-view." t nil)

(autoload 'deb-view "deb-view" "\
View Debian package DEBFILE's control and data files.
Press \"q\" in either window to kill both buffers.

In dired, press ^d on the dired line of the .deb file to view.
Or, execute: ESCAPE x deb-view RETURN, and enter the .deb file name
at the prompt.

\(fn DEBFILE)" t nil)

(autoload 'deb-view-mode "deb-view" "\
View mode for Debian Archive Files." t nil)

(autoload 'deb-find "deb-view" "\
Search for deb files.
Use the method specified by the variable deb-find-method, and collect
output in a buffer.  See also the variable deb-find-directory.

This command uses a special history list, so you can
easily repeat a `deb-find' command." t nil)

(if (fboundp 'register-definition-prefixes) (register-definition-prefixes "deb-view" '("deb")))

;;;***

;;;### (autoloads nil "debian-autoloads" "debian-autoloads.el" (0
;;;;;;  0 0 0))
;;; Generated autoloads from debian-autoloads.el

(require 'debian-el)

;;;***

;;;### (autoloads nil "debian-bug" "debian-bug.el" (0 0 0 0))
;;; Generated autoloads from debian-bug.el

(autoload 'debian-bug-wnpp "debian-bug" "\
Submit a WNPP bug report to Debian.
Optional argument ACTION can be provided in programs.

\(fn &optional ACTION)" t nil)

(autoload 'debian-bug-request-for-package "debian-bug" "\
Shortcut for `debian-bug-wnpp' with RFP action." t nil)

(autoload 'debian-bug-intent-to-package "debian-bug" "\
Shortcut for `debian-bug-wnpp' with ITP action (for Debian developers)." t nil)

(autoload 'debian-bug-web-bugs "debian-bug" "\
Browse the BTS for this package via `browse-url'.
With optional argument prefix ARCHIVED, display archived bugs.

\(fn &optional ARCHIVED)" t nil)

(autoload 'debian-bug-web-developer-page "debian-bug" "\
Browse the web for this package's developer page." t nil)

(autoload 'debian-bug-web-bug "debian-bug" "\
Browse the BTS for BUG-NUMBER via `browse-url'.

\(fn &optional BUG-NUMBER)" t nil)

(autoload 'emacs-bug-web-bug "debian-bug" "\
Browse the Emacs BTS for BUG-NUMBER via `browse-url'.

\(fn &optional BUG-NUMBER)" t nil)

(autoload 'debian-bug-web-this-bug-under-mouse "debian-bug" "\
Browse the BTS via `browse-url' for the bug report number under mouse.
In a program, mouse location is in EVENT.

\(fn EVENT)" t nil)

(autoload 'debian-bug-web-packages "debian-bug" "\
Search Debian web page for this package via `browse-url'." t nil)

(autoload 'debian-bug-web-package "debian-bug" "\
Search Debian web page in ARCHIVE for this package via `browse-url'.

\(fn ARCHIVE)" t nil)

(autoload 'debian-bug-get-bug-as-file "debian-bug" "\
Read bug report #BUG-NUMBER as a regular file.

\(fn &optional BUG-NUMBER)" t nil)

(autoload 'debian-bug-get-bug-as-email "debian-bug" "\
Read bug report #BUG-NUMBER via Email interface.

\(fn &optional BUG-NUMBER)" t nil)

(autoload 'emacs-bug-get-bug-as-email "debian-bug" "\
Read Emacs bug report #BUG-NUMBER via Email interface.

\(fn &optional BUG-NUMBER)" t nil)

(autoload 'debian-bug "debian-bug" "\
Submit a Debian bug report." t nil)

(if (fboundp 'register-definition-prefixes) (register-definition-prefixes "debian-bug" '("debian-b" "report-debian-bug")))

;;;***

;;;### (autoloads nil "gnus-BTS" "gnus-BTS.el" (0 0 0 0))
;;; Generated autoloads from gnus-BTS.el

(if (fboundp 'register-definition-prefixes) (register-definition-prefixes "gnus-BTS" '("gnus-dbts-")))

;;;***

;;;### (autoloads nil "preseed" "preseed.el" (0 0 0 0))
;;; Generated autoloads from preseed.el

(autoload 'preseed-mode "preseed" "\
Major mode for editing debian-installer preseed files colourfully." t nil)

(if (fboundp 'register-definition-prefixes) (register-definition-prefixes "preseed" '("preseed-")))

;;;***

;;;### (autoloads nil nil ("debian-el-pkg.el" "debian-el.el") (0
;;;;;;  0 0 0))

;;;***

;; Local Variables:
;; version-control: never
;; no-byte-compile: t
;; no-update-autoloads: t
;; coding: utf-8
;; End:
;;; debian-el-autoloads.el ends here
