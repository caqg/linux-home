;;; -*- Mode: Emacs-Lisp -*-
;;;
;;; A definition of a minor mode that adds indentation to any of the
;;; (major) text modes.
;;;
;;; Cesar Quiroz @ UofR DoCSc -- Jan 1986
;;;                     revised  23 Oct 87
(provide 'indented-minor-mode)
(provide 'indented-submode)             ;ugly backward compatibility

;;; Eval-when would come in handy here
(make-variable-buffer-local 'already-indenting);toggles the mode
(set-default 'already-indenting nil)
(or (assq 'already-indenting minor-mode-alist)
    (setq minor-mode-alist
          (append minor-mode-alist
                  (list '(already-indenting " Indented")))))

;;; Indentable-text-modes offers a sanity check before doing things to
;;; the local keymap. 
(defvar indentable-text-modes
  '(text-mode nroff-mode plain-tex-mode latex-mode texinfo-mode
    outline-mode mail-mode mh-letter-mode)
  "*Major modes that admit an indentation minor mode.  Before setting
indented-minor, make sure the name of the major mode you are using is
here.")

(defun indented-minor-mode (arg)
  "Toggles text indentation as a minor mode.  This affects the
behavior of the TAB and the LFD keys in most text modes.  Setting
indented minor causes other modes to behave like indented-text-mode in
this respect.

With a positive argument, it sets indentation on for any of
the modes that appear in the list indentable-text-modes.
With a null argument, it toggles the activity of this minor mode.

This minor mode is available only in text-like modes, as remembered in
the variable indented-minor-mode (q.v.).  If you define a new mode
that might need indented-minor, make sure to do something like:

  (if (not (memq 'new-mode indentable-text-modes))
      (setq indentable-text-modes
            (cons 'new-mode indentable-text-modes)))

before calling indented-minor.  An error occurs if the current major
mode has not been registered first."
  (interactive "P")
  (setq already-indenting
        (if (null arg)
            (not already-indenting)
	  (> (prefix-numeric-value arg) 0)))
  (cond ((memq major-mode indentable-text-modes)
         (let ((local-kmap (current-local-map)))
           (make-local-variable 'indent-line-function)
           ;; now imitating indented-text-mode's map, if on
           (cond (already-indenting
                  (define-key local-kmap "\t" 'indent-relative)
                  (setq indent-line-function 'indent-relative-maybe))
                 (t
                  (define-key local-kmap "\t" 'tab-to-tab-stop)
                  (setq indent-line-function 'indent-to-left-margin)))))
        (t
         (setq already-indenting nil)   ;make sure nothing is wrong
         (error "%s isn't good for indented-minor." major-mode))))

;;; End of indented-submode.el
