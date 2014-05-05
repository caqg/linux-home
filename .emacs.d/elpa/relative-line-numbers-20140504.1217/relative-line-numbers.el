;;; relative-line-numbers.el --- Display relative line numbers on the margin  -*- lexical-binding: t -*-

;; Author: Fanael Linithien <fanael4@gmail.com>
;; URL: https://github.com/Fanael/relative-line-numbers
;; Version: 20140504.1217
;; X-Original-Version: 0.2.3
;; Package-Requires: ((emacs "24"))

;; This file is NOT part of GNU Emacs.

;; Copyright (c) 2014, Fanael Linithien
;; All rights reserved.
;;
;; Redistribution and use in source and binary forms, with or without
;; modification, are permitted provided that the following conditions are
;; met:
;;
;;   * Redistributions of source code must retain the above copyright
;;     notice, this list of conditions and the following disclaimer.
;;   * Redistributions in binary form must reproduce the above copyright
;;     notice, this list of conditions and the following disclaimer in the
;;     documentation and/or other materials provided with the distribution.
;;   * Neither the name of the copyright holder(s) nor the names of any
;;     contributors may be used to endorse or promote products derived from
;;     this software without specific prior written permission.
;;
;; THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS
;; IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED
;; TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
;; PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER
;; OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
;; EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
;; PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
;; PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
;; LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
;; NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
;; SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

;;; Code:

;; So we can use its face.
(require 'linum)

(defgroup relative-line-numbers nil
  "Show relative line numbers in the margin."
  :group 'convenience
  :prefix "relative-line-numbers-")

(defcustom relative-line-numbers-delay 0
  "The delay, in seconds, before updating the line numbers."
  :type 'number
  :group 'relative-line-numbers)

(defcustom relative-line-numbers-format #'relative-line-numbers-default-format
  "The function used to format the line numbers.
The function should take one integer argument: the line's distance, in
lines, from the current line, and return a string."
  :type 'function
  :group 'relative-line-numbers)

(defgroup relative-line-numbers-faces nil
  "Faces for displaying relative line numbers."
  :group 'relative-line-numbers
  :group 'faces)

(defface relative-line-numbers
  '((t :inherit linum))
  "Face for displaying relative line numbers."
  :group 'relative-line-numbers-faces)

(defface relative-line-numbers-current-line
  '((t :inherit relative-line-numbers))
  "Face for displaying the current line indicator."
  :group 'relative-line-numbers-faces)

(defvar relative-line-numbers--width 0
  "The current left margin width.")
(make-variable-buffer-local 'relative-line-numbers--width)

;;;###autoload
(define-minor-mode relative-line-numbers-mode
  "Display relative line numbers on the left margin.

Toggle Relative Line Numbers on or off.

With a prefix argument ARG, enable Relative Line Numbers mode if ARG
is positive, and disable it otherwise. If called from Lisp, enable the
mode if ARG is omitted or nil, and toggle it if ARG is `toggle'."
  :init-value nil
  :lighter ""
  :keymap nil
  (relative-line-numbers--off)
  (when relative-line-numbers-mode
    (relative-line-numbers--on)))

;;;###autoload
(define-globalized-minor-mode global-relative-line-numbers-mode
  relative-line-numbers-mode
  (lambda ()
    (unless (minibufferp)
      (relative-line-numbers-mode))))

(defun relative-line-numbers-default-format (offset)
  "The default formatting function.
Return the absolute value of OFFSET, converted to string."
  (number-to-string (abs offset)))

(defmacro relative-line-numbers--make-line-overlays (direction limit window)
  "Make the line number overlays for lines before or after point.
DIRECTION is either :forward or :backward.
LIMIT is the buffer position to end the operation when reached.
WINDOW is the window to show overlays in."
  (unless (memq direction '(:forward :backward))
    (error "Direction can be only :forward or :backward"))
  (let ((limitsym (make-symbol "limit"))
        (lineoffsetsym (make-symbol "lineoffset"))
        (windowsym (make-symbol "window")))
    `(let* ((,limitsym ,limit)
            (,lineoffsetsym 0)
            (,windowsym ,window))
       (while ,(if (eq direction :forward)
                   `(and (not (eobp)) (< (point) ,limitsym))
                 `(and (not (bobp)) (> (point) ,limitsym)))
         (forward-line ,(if (eq direction :forward) 1 -1))
         (setq ,lineoffsetsym
               (,(if (eq direction :forward)
                     '1+
                   '1-) ,lineoffsetsym))
         (relative-line-numbers--make-overlay
          (funcall relative-line-numbers-format ,lineoffsetsym)
          'relative-line-numbers
          ,windowsym)))))

(defun relative-line-numbers--update ()
  "Update line numbers in the visible portion of the current window."
  (let ((window (selected-window)))
    (relative-line-numbers--delete-window-overlays window)
    (save-excursion
      (let* ((inhibit-point-motion-hooks t)
             (pos (line-beginning-position))
             (start (window-start))
             (end (window-end nil t)))
        (setq relative-line-numbers--width (or (car (window-margins)) 0))
        (relative-line-numbers--make-line-overlays :forward end window)
        (goto-char pos)
        (relative-line-numbers--make-line-overlays :backward start window)
        (goto-char pos)
        (relative-line-numbers--make-overlay
         (funcall relative-line-numbers-format 0)
         'relative-line-numbers-current-line
         window)))))

(defun relative-line-numbers--update-from-timer (window)
  "Run the scheduled line number update in WINDOW."
  (when (window-live-p window)
    (with-selected-window window
      (when relative-line-numbers-mode
        (relative-line-numbers--update)))))

(defun relative-line-numbers--schedule-update ()
  "Schedule a line number update."
  (run-with-idle-timer relative-line-numbers-delay nil
                       #'relative-line-numbers--update-from-timer
                       (selected-window)))

(defun relative-line-numbers--is-scroll-bar-command (command)
  "Non-nil iff COMMAND is a scroll bar command."
  (memq command '(scroll-bar-toolkit-scroll
                  scroll-bar-drag
                  scroll-bar-scroll-up
                  scroll-bar-scroll-down)))

(defun relative-line-numbers--post-command-update ()
  "Update or schedule an update after a command."
  (cond
   ;; If it's a scroll bar command, always delay the update so that we
   ;; don't slow down scrolling.
   ((relative-line-numbers--is-scroll-bar-command this-command)
    (let ((relative-line-numbers-delay (max 0.05 relative-line-numbers-delay)))
      (relative-line-numbers--schedule-update)))
   ((= relative-line-numbers-delay 0)
    (relative-line-numbers--update))
   (t
    (relative-line-numbers--schedule-update))))

(defun relative-line-numbers--scroll (window _displaystart)
  "Schedule a line number update after scrolling."
  (with-selected-window window
    (relative-line-numbers--set-margin-width window)
    ;; If it's a scroll bar command, always delay the update so that we
    ;; don't slow down scrolling.
    (if (relative-line-numbers--is-scroll-bar-command last-command)
        (let ((relative-line-numbers-delay (max 0.001 relative-line-numbers-delay)))
          (relative-line-numbers--schedule-update))
      (relative-line-numbers--schedule-update))))

(defun relative-line-numbers--on ()
  "Set up `relative-line-numbers-mode'."
  (add-hook 'post-command-hook #'relative-line-numbers--post-command-update nil t)
  (add-hook 'window-configuration-change-hook #'relative-line-numbers--schedule-update nil t)
  (add-hook 'window-scroll-functions #'relative-line-numbers--scroll nil t)
  (add-hook 'change-major-mode-hook #'relative-line-numbers--off nil t)
  (relative-line-numbers--update))

(defun relative-line-numbers--off ()
  "Tear down `relative-line-numbers-mode'."
  (remove-hook 'post-command-hook #'relative-line-numbers--post-command-update t)
  (remove-hook 'window-configuration-change-hook #'relative-line-numbers--schedule-update t)
  (remove-hook 'window-scroll-functions #'relative-line-numbers--scroll t)
  (remove-hook 'change-major-mode-hook #'relative-line-numbers--off t)
  (relative-line-numbers--delete-overlays)
  (relative-line-numbers--set-current-buffer-margin)
  (kill-local-variable 'relative-line-numbers--width))

(defun relative-line-numbers--set-margin-width (window)
  "Set the left margin width to `relative-line-numbers--width'.
If `relative-line-numbers-mode' is off, hide the left margin."
  (set-window-margins window
                      (and relative-line-numbers-mode
                           relative-line-numbers--width)
                      (cdr (window-margins window))))

(defun relative-line-numbers--set-current-buffer-margin ()
  "Set the left margin width in all windows showing the current buffer."
  (dolist (window (get-buffer-window-list nil nil t))
    (relative-line-numbers--set-margin-width window)))

(defun relative-line-numbers--delete-window-overlays (window)
  "Delete all overlays belonging to WINDOW."
  (mapc #'delete-overlay (window-parameter window 'relative-line-numbers--used-overlays))
  (set-window-parameter window 'relative-line-numbers--used-overlays nil))

(defun relative-line-numbers--delete-overlays ()
  "Delete all used overlays."
  (dolist (window (get-buffer-window-list nil nil t))
    (relative-line-numbers--delete-window-overlays window)))

(defun relative-line-numbers--make-overlay (str face window)
  "Make a line number overlay at point.
STR is the string to display, FACE is the face to fontify the string
with, WINDOW is the window the show the overlay in.

This function changes the margin width if STR would not fit."
  (let ((strlen (length str)))
    (when (> strlen relative-line-numbers--width)
      (setq relative-line-numbers--width strlen)
      (relative-line-numbers--set-current-buffer-margin)))
  (let* ((pos (point))
         (overlay (make-overlay pos pos)))
    (overlay-put overlay 'window window)
    (overlay-put overlay 'before-string
                 (propertize " " 'display `((margin left-margin)
                                            ,(propertize str 'face face))))
    (push overlay (window-parameter window 'relative-line-numbers--used-overlays))))

(provide 'relative-line-numbers)
;;; relative-line-numbers.el ends here
