;;;;                                                        -*- Emacs-Lisp -*-
;;; Copyright (C) 2015 by Cesar A Quiroz, Ph.D.
;;; 3595 Granada Ave Unit 114 / Santa Clara, CA 95051 / USA
;;; All Rights Reserved Worldwide
;;; mailto:cesar.quiroz@gmail.com

(require 'parenface)

(defun cq/enable-solarized (which)
  "Assuming solarized-theme is loaded, enable it.  WHICH should be 'dark or
'light"
  (unless (memq which '(dark light))
    (error "Wrong frame background mode %S, expected 'dark or 'light"
           which))
  (let* ((theme-name (concat "solarized-" (symbol-name which)))
         (theme-symbol (intern theme-name)))
    (enable-theme theme-symbol))
  (setq frame-background-mode which)
  (mapc 'frame-set-background-mode (frame-list))
  (adjust-paren-face-fg which)
  which)

(defun cq/enable-dark-solarized ()
  "Assuming solarized-theme is loaded, make it dark everywhere"
  (interactive)
  (cq/enable-solarized 'dark))

(defun cq/enable-light-solarized ()
  "Assuming solarized-theme is loaded, make it light everywhere"
  (interactive)
  (cq/enable-solarized 'light))

(defun cq/flip-solarized ()
  "Assuming solarized-theme is loaded, flip it between dark and light"
  (interactive)
  (cond ((eq frame-background-mode 'dark)
         (cq/enable-light-solarized))
        (t			;light or nil
         (cq/enable-dark-solarized))))


(defvar menu-bar-solarized-menu (make-sparse-keymap "Light or Dark?"))
(define-key menu-bar-solarized-menu [solarized-light]
  '(menu-item "Light mode" cq/enable-light-solarized
              :help "Set color theme to solarized, with light background"))
(define-key menu-bar-solarized-menu [solarized-dark]
  '(menu-item "Dark mode" cq/enable-dark-solarized
              :help "Set color theme to solarized, with dark background"))
(define-key menu-bar-solarized-menu [solarized-flip]
  '(menu-item "Flip bg mode" cq/flip-solarized
              :help "Flip background mode between light and dark"))
(define-key menu-bar-options-menu [color-theme-background]
  (list 'menu-item "Light or Dark?" menu-bar-solarized-menu))

(global-set-key [f12] 'cq/flip-solarized)

(provide 'emacs25-theme-init)

;;;; end
