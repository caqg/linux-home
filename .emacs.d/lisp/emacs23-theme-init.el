;;;;                                                        -*- Emacs-Lisp -*-
;;; Copyright (C) 2014 by Cesar A Quiroz, Ph.D.
;;; 3595 Granada Ave Unit 114 / Santa Clara, CA 95051 / USA
;;; All Rights Reserved Worldwide
;;; mailto:cesar.quiroz@gmail.com


;; (setq load-path (cons "~/.emacs.d/color-theme" load-path))
;; (setq load-path (cons "~/.emacs.d/color-theme-solarized" load-path))
(require 'color-theme)
(require 'color-theme-solarized)

;; compensate for the frame-background-mode setting
(defun set-color-theme-solarized (mode)
  "Switch to solarized-MODE, adjusting the frame-background-mode too."
  (interactive "Slight or dark? ")
  (unless (memq mode '(light dark))
    (error "Bad mode '%s, should be one of 'light or 'dark" mode))
  (let ((sym 'frame-background-mode))
    ;; (funcall (or (get sym 'custom-set) 'set) sym mode)
    ;; (set-frame-configuration cfc)
    ;; (color-theme-solarized mode)
    ;; (mapc 'frame-set-background-mode (frame-list))
    (set-frame-parameter nil 'background-mode mode)
    (color-theme-solarized)
    (adjust-paren-face-fg)))

(defun set-color-theme-solarized-light ()
  "Convenience invocation for (set-color-theme-solarized 'light)"
  (interactive)
  (set-color-theme-solarized 'light))

(defun set-color-theme-solarized-dark ()
  "Convenience invocation for (set-color-theme-solarized 'dark)"
  (interactive)
  (set-color-theme-solarized 'dark))

(defun set-color-theme-solarized-flip ()
  "Flip the background mode (from light or default to dark, and from dark to light."
  (interactive)
  (let* ((ofbm frame-background-mode)
         (nfbm (case ofbm
                 (light 'dark)
                 (dark 'light)
                 (otherwise 'dark))))
    (set-color-theme-solarized nfbm)))

;; (fset 'dark (symbol-function 'set-color-theme-solarized-dark))
;; (fset 'light (symbol-function 'set-color-theme-solarized-light))

(defvar menu-bar-solarized-menu (make-sparse-keymap "Light or Dark?"))
(define-key menu-bar-solarized-menu [solarized-light]
  '(menu-item "Light mode" set-color-theme-solarized-light
              :help "Set color theme to solarized, with light background"))
(define-key menu-bar-solarized-menu [solarized-dark]
  '(menu-item "Dark mode" set-color-theme-solarized-dark
              :help "Set color theme to solarized, with dark background"))
(define-key menu-bar-solarized-menu [solarized-flip]
  '(menu-item "Flip bg mode" set-color-theme-solarized-flip
              :help "Flip background mode between light and dark"))
(define-key menu-bar-options-menu [color-theme-background]
  (list 'menu-item "Light or Dark?" menu-bar-solarized-menu))

(global-set-key [f12] 'set-color-theme-solarized-flip)

(provide 'emacs23-theme-init)

;;;; end
