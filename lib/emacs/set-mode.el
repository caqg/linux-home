;;; -*- Mode: Emacs-Lisp -*-
;;;
;;; Set mode for current buffer, and possibly add a mode-setting line

(provide 'set-mode)

(defun set-mode (new-mode also-in-buffer) 

  "Change mode of current buffer to NEW-MODE (Either a mode name, as
in 'emacs-lisp' or a function that changes modes, as in
'emacs-lisp-mode').  The mode must be one already loaded or otherwise
known. If ALSO-IN-BUFFER is non-nil, create or fix the first line of
the buffer to be a mode-spec-line for the new mode.  Passing to this
function \"\" and T asks to create a mode-spec-line for the current
major-mode, without any other changes.  For interactive use,
also-in-buffer receives the raw prefix argument.

   If your first line contains a -*- field, the rest of the line WILL be 
lost upon changing modes this way."

  (interactive "sNew Mode? \nP")
  (setq new-mode (downcase new-mode))   ;win always
  (let  ((new-mode-name new-mode)
         (new-p (not (string= new-mode ""))))
    ;; fix the mode name
    (if new-p                           ;except if no change intended
        (let ((l (length new-mode-name)))
          (if (and (> l 5)
                   (string= (substring new-mode-name (- l 5)) "-mode"))
              (setq new-mode (substring new-mode 0 (- l 5)))
              (setq new-mode-name (concat new-mode-name "-mode"))))
        (setq new-mode-name (symbol-name major-mode)
              new-mode (substring new-mode-name
                                  0 (- (length new-mode-name) 5))))
    ;; now, change mode if needed
    (if new-p
        (cond ((fboundp (intern new-mode-name))
               (funcall (intern new-mode-name)))
              (t
               (error "%s? no such mode" new-mode-name))))
    ;; last, change mode-spec line
    (if also-in-buffer
        (save-excursion
          (save-restriction
            (goto-char (point-min))
            (let ((linend (end-of-line))
                  (sp (concat "-*- Mode: " (capitalize new-mode) " -*-")))
              (beginning-of-line)
              ;; position to insert new specs line
              (cond ((re-search-forward "-\\*-.*-\\*-" linend t)
                     (beginning-of-line)
                     (kill-line nil))
                    (t
                     (goto-char (point-min))
                     (open-line 1)))
              (if (and (boundp 'comment-start);comments exist
                       comment-start)
                  (progn
                    (indent-for-comment)
                    (if (string= comment-end "")
                        (insert-string  ;special case: can be repeated
                         comment-start comment-start comment-start " "))))
              (insert-string sp)
              (beginning-of-line)
              (delete-horizontal-space)))))))

;;; End of set-mode.el 
