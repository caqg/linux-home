;;;;                                                        -*- Emacs-Lisp -*-
;;; Copyright (C) 2015 by Cesar A Quiroz, Ph.D.
;;; 3595 Granada Ave Unit 114 / Santa Clara, CA 95051 / USA
;;; All Rights Reserved Worldwide
;;; mailto:cesar.quiroz@gmail.com

(require 'cl-lib)
(require 'parenface)


(defun cq/adjust-paren-face-fg (which)
  "Set the paren-face :foreground according to the frame-background-mode (light,
dark), or to argument WHICH ('dark or 'light; else nothing
happens) if frame-background-mode is nil."
  (interactive)
  (let ((paren-face-fg (cl-case frame-background-mode
                         (light
                          paren-face-light)
                         (dark
                          paren-face-dark)
                         (t             ;if not set yet
                          (cl-case which
                            ('dark paren-face-dark)
                            ('light paren-face-light)
                            (t nil))))))
    (unless (null paren-face-fg)
      (set-face-attribute 'paren-face nil :foreground paren-face-fg))
    paren-face-fg))

(defun cq/disable-all-themes ()
  "Disable all the `custom-enabled-themes'"
  (interactive)
  (mapc
   #'(lambda (theme-symbol)
       (disable-theme theme-symbol))
   (cl-copy-list custom-enabled-themes))
  (unless custom-enabled-themes
    (enable-theme 'user)))





(provide 'cq-theme-utils)

;;;; end cq-theme-utils.el
