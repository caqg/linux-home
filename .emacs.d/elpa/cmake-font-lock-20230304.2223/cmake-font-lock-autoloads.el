;;; cmake-font-lock-autoloads.el --- automatically extracted autoloads (do not edit)   -*- lexical-binding: t -*-
;; Generated by the `loaddefs-generate' function.

;; This file is part of GNU Emacs.

;;; Code:

(add-to-list 'load-path (or (and load-file-name (file-name-directory load-file-name)) (car load-path)))



;;; Generated autoloads from cmake-font-lock.el

(defvar cmake-font-lock-modes '(cmake-mode) "\
List of major modes this package should be activated for.

Set this to nil to disable automatic activation.")
(autoload 'cmake-font-lock-activate "cmake-font-lock" "\
Activate advanced CMake colorization.

To activate this every time a CMake file is opened, use the following:

    (add-hook 'cmake-mode-hook 'cmake-font-lock-activate)" t)
(add-hook 'change-major-mode-after-body-hook (lambda nil (when (apply #'derived-mode-p cmake-font-lock-modes) (cmake-font-lock-activate))))
(register-definition-prefixes "cmake-font-lock" '("cmake-font-lock-"))

;;; End of scraped data

(provide 'cmake-font-lock-autoloads)

;; Local Variables:
;; version-control: never
;; no-byte-compile: t
;; no-update-autoloads: t
;; no-native-compile: t
;; coding: utf-8-emacs-unix
;; End:

;;; cmake-font-lock-autoloads.el ends here
