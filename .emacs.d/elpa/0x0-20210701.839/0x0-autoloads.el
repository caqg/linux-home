;;; 0x0-autoloads.el --- automatically extracted autoloads (do not edit)   -*- lexical-binding: t -*-
;; Generated by the `loaddefs-generate' function.

;; This file is part of GNU Emacs.

;;; Code:

(add-to-list 'load-path (directory-file-name
                         (or (file-name-directory #$) (car load-path))))



;;; Generated autoloads from 0x0.el

(autoload '0x0-upload-file "0x0" "\
Choose FILE and upload it to SERVER.

(fn SERVER FILE)" t)
(autoload '0x0-upload-text "0x0" "\
Upload full or region text from the current buffer to SERVER.

(fn SERVER)" t)
(autoload '0x0-upload-kill-ring "0x0" "\
Upload content from the \"kill-ring\" to SERVER.

(fn SERVER)" t)
(autoload '0x0-shorten-uri "0x0" "\
Shorten the given URI with SERVER.

(fn SERVER URI)" t)
(autoload '0x0-popup "0x0" "\
Create a new buffer, fill it with content, and upload it to SERVER later.

(fn SERVER)" t)
(autoload '0x0-dwim "0x0" "\
Try to guess what to upload to SERVER.

(fn SERVER)" t)
(register-definition-prefixes "0x0" '("0x0-"))

;;; End of scraped data

(provide '0x0-autoloads)

;; Local Variables:
;; version-control: never
;; no-byte-compile: t
;; no-update-autoloads: t
;; no-native-compile: t
;; coding: utf-8-emacs-unix
;; End:

;;; 0x0-autoloads.el ends here
