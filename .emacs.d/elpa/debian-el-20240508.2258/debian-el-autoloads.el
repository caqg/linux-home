;;; debian-el-autoloads.el --- automatically extracted autoloads (do not edit)   -*- lexical-binding: t -*-
;; Generated by the `loaddefs-generate' function.

;; This file is part of GNU Emacs.

;;; Code:

(add-to-list 'load-path (or (and load-file-name (directory-file-name (file-name-directory load-file-name))) (car load-path)))



;;; Generated autoloads from apt-sources.el

(autoload 'apt-sources-mode "apt-sources" "\
Major mode for editing apt's sources.list file.
Sets up command `font-lock-mode'.

\\{apt-sources-mode-map}" t)
(register-definition-prefixes "apt-sources" '("apt-sources-"))


;;; Generated autoloads from apt-utils.el

(autoload 'apt-utils-show-package "apt-utils" "\
Show information for a Debian package.
A selection of known packages is presented.  See `apt-utils-mode'
for more detailed help.  If NEW-SESSION is non-nil, generate a
new `apt-utils-mode' buffer.

(fn &optional NEW-SESSION)" t)
(autoload 'apt-utils-search "apt-utils" "\
Search Debian packages for regular expression.
To search for multiple patterns use a string like \"foo && bar\".
The regular expression used to split the
terms (`apt-utils-search-split-regexp') is customisable." t)
(register-definition-prefixes "apt-utils" '("apt-"))


;;; Generated autoloads from deb-view.el

(autoload 'deb-view-dired-view "deb-view" "\
View Debian package control and data files.
Press \"q\" in either window to kill both buffers
and return to the dired buffer. See deb-view." t)
(autoload 'deb-view "deb-view" "\
View Debian package DEBFILE's control and data files.
Press \"q\" in either window to kill both buffers.

In dired, press ^d on the dired line of the .deb file to view.
Or, execute: ESCAPE x deb-view RETURN, and enter the .deb file name
at the prompt.

(fn DEBFILE)" t)
(autoload 'deb-view-mode "deb-view" "\
View mode for Debian Archive Files." t)
(autoload 'deb-find "deb-view" "\
Search for deb files.
Use the method specified by the variable deb-find-method, and collect
output in a buffer.  See also the variable deb-find-directory.

This command uses a special history list, so you can
easily repeat a `deb-find' command." t)
(register-definition-prefixes "deb-view" '("deb"))


;;; Generated autoloads from debian-autoloads.el

(require 'debian-el)


;;; Generated autoloads from debian-bug.el

(autoload 'debian-bug-wnpp "debian-bug" "\
Submit a WNPP bug report to Debian.
Optional argument ACTION can be provided in programs.

(fn &optional ACTION)" t)
(autoload 'debian-bug-request-for-package "debian-bug" "\
Shortcut for `debian-bug-wnpp' with RFP action." t)
(autoload 'debian-bug-intent-to-package "debian-bug" "\
Shortcut for `debian-bug-wnpp' with ITP action (for Debian developers)." t)
(autoload 'debian-bug-web-bugs "debian-bug" "\
Browse the BTS for this package via `browse-url'.
With optional argument prefix ARCHIVED, display archived bugs.

(fn &optional ARCHIVED)" t)
(autoload 'debian-bug-web-developer-page "debian-bug" "\
Browse the web for this package's developer page." t)
(autoload 'debian-bug-web-bug "debian-bug" "\
Browse the BTS for BUG-NUMBER via `browse-url'.

(fn &optional BUG-NUMBER)" t)
(autoload 'emacs-bug-web-bug "debian-bug" "\
Browse the Emacs BTS for BUG-NUMBER via `browse-url'.

(fn &optional BUG-NUMBER)" t)
(autoload 'debian-bug-web-this-bug-under-mouse "debian-bug" "\
Browse the BTS via `browse-url' for the bug report number under mouse.
In a program, mouse location is in EVENT.

(fn EVENT)" t)
(autoload 'debian-bug-web-packages "debian-bug" "\
Search Debian web page for this package via `browse-url'." t)
(autoload 'debian-bug-web-package "debian-bug" "\
Search Debian web page in ARCHIVE for this package via `browse-url'.

(fn ARCHIVE)" t)
(autoload 'debian-bug-get-bug-as-file "debian-bug" "\
Read bug report #BUG-NUMBER as a regular file.

(fn &optional BUG-NUMBER)" t)
(autoload 'debian-bug-get-bug-as-email "debian-bug" "\
Read bug report #BUG-NUMBER via Email interface.

(fn &optional BUG-NUMBER)" t)
(autoload 'emacs-bug-get-bug-as-email "debian-bug" "\
Read Emacs bug report #BUG-NUMBER via Email interface.

(fn &optional BUG-NUMBER)" t)
(autoload 'debian-bug "debian-bug" "\
Submit a Debian bug report." t)
(register-definition-prefixes "debian-bug" '("debian-b" "report-debian-bug"))


;;; Generated autoloads from gnus-BTS.el

(register-definition-prefixes "gnus-BTS" '("gnus-dbts-"))


;;; Generated autoloads from preseed.el

(autoload 'preseed-mode "preseed" "\
Major mode for editing debian-installer preseed files colourfully." t)
(register-definition-prefixes "preseed" '("preseed-"))

;;; End of scraped data

(provide 'debian-el-autoloads)

;; Local Variables:
;; version-control: never
;; no-byte-compile: t
;; no-update-autoloads: t
;; no-native-compile: t
;; coding: utf-8-emacs-unix
;; End:

;;; debian-el-autoloads.el ends here