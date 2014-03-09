;;; -*- Emacs-Lisp -*-
;;;
;;; Utilities for X.  Developed originally for use with XEmacs.
;;;
;;; 2008-02-10 06:54:03UT (cesar@bears06-01)
;;; Minor adjustments to be compatible with Emacs 21 or later.
;;;
;;; 2009-04-05 05:44:11UT (caquiroz@vcs21044)
;;; Intel version for correct usage with Emacs 22 and XEmacs 21 latest releases.

(require 'cq-utils)

(defvar *default-frame-name*
  (if (string-match "^XEmacs" (version))
      "XEmacs@" "Emacs@"))

(defun xtitle-default-frame-title ()
  "Return a string suitable for a frame title.
This is the function to override if you want a different default."
  (let ((this-emacs-version (emacs-version)))
    (cond ((string-match "^GNU Emacs" this-emacs-version)
           (concat *default-frame-name* (get-any-hostname) " %b %f"))
          ((string-match "^XEmacs" this-emacs-version)
           (concat *default-frame-name* (get-any-hostname) " %b(%l,%c) %f")))))

(defun xtitle-default-icon-title ()
  "Return a string suitable for an icon title.
This is the function to override if you want a different default."
  (concat *default-frame-name* (get-any-hostname)))

(defun set-default-xtitle ()
  "Change the frame and icon titles to a user choice.  See the functions
xtitle-default-frame-title and xtitle-default-icon-title; override them to
change this default."
  (interactive)
  (setq frame-title-format (xtitle-default-frame-title) 
	frame-icon-title-format (xtitle-default-icon-title))
  t)
       
(defun set-xtitle (title arg)
  "Override the frame and icon titles with a string.
With a prefix, if 0 set both titles to the given string.
With a negative prefix, append the string to the default title,
With a positive prefix, prepend the string to the default title.
The prefix behavior is chosen so that the most common option, prepending, is
the easiest to request interactively.  See the function set-default-xtitle."
  (interactive "s\np")
  (if (not (numberp arg))
      (setq arg 0))
  (let ((frame-title )
	(icon-title))
    (cond ((> arg 0)
	   (setq frame-title (concat title (xtitle-default-frame-title))
		 icon-title (concat title (xtitle-default-icon-title))))
	  ((= arg 0)
	   (setq frame-title title
		 icon-title title))
	  ((< arg 0)
	   (setq frame-title (concat (xtitle-default-frame-title) title)
		 icon-title (concat (xtitle-default-icon-title) title))))
    (setq frame-title-format frame-title
	  frame-icon-title-format icon-title))
  t)


;;; left and top are chosen depending on the window manager; the default
;;; values work for Intel's fvwm2.  The values should make xwininfo claim that
;;; the window is at +0+0
(defvar *cq-max-frame-left* 	5 "*Location, pixels from the left edge")
(defvar *cq-max-frame-top*     21 "*Location, pixels from the top edge")

;;; width and height depend on the "theme"
(defvar *cq-max-frame-width*  152 "*Size, columns wide")
(defvar *cq-max-frame-height*  49 "*Size, rows tall")

(defun cq-maximize-x-frame ()
  "If XEmacs is running on an X display, make the current frame as large
as possible."
  (interactive)
  (let* ((current-frame (get-frame-for-buffer (current-buffer)))
         (current-device (frame-device current-frame))
         (current-device-type (device-type current-device))
         (current-device-metrics (device-system-metrics current-device)))
    (when (eq current-device-type 'x)
      (set-frame-properties current-frame
                          (list 'height *cq-max-frame-height*
                                'width  *cq-max-frame-width*
                                'left   *cq-max-frame-left*
                                'top    *cq-max-frame-top*)))))

(provide 'cq-x-utils)

;;;end cq-x-utils.el
