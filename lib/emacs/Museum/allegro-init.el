;;;; -*- Mode: Emacs-Lisp -*-
;;;;
;;;; Initializations for Allegro.  Taken from Brad, Wed Aug 29 22:10:01 1990

;; turn on superkeys in subprocess modes
;;
(setq-default fi:subprocess-enable-superkeys t)

;; the following causes fi:common-lisp to give the inferior Common
;; Lisp, by default, a command line argument of `+ipc':
;;
(setq fi:common-lisp-image-arguments '("+ipc"))

;; the following causes fi:common-lisp to invoke the image `cl', but
;; to ask for an image name when given a prefix argument:
;;
(setq fi:common-lisp-image-name
  '(lambda ()
    (let ((image "cl"))
      (if current-prefix-arg
	  (setq image
	    (read-file-name (format "cl image (default: %s): " image)
			    default-directory image nil)))
      (setq mode-line-buffer-identification
	(format "%s (%s)" (buffer-name) (file-name-nondirectory image)))
      image)))

;; This redefines `kill-emacs' so that transaction files in /tmp are
;; removed emacs is killed:
;;
(fset 'old-kill-emacs (symbol-function 'kill-emacs))
(defun kill-emacs (&optional arg)
  (interactive "P")
  (fi:remove-all-temporary-lisp-transaction-files)
  (old-kill-emacs arg))

(defun x-lisp-find-tag (arg)
  (x-mouse-set-point arg)
  (cond ((eq major-mode 'fi:common-lisp-mode) (fi:lisp-find-tag))
	(t (find-tag-other-window (find-tag-default)))))

(defun x-lisp-eval-defun (arg)
  (x-mouse-set-point arg)
  (cond ((memq major-mode '(fi:common-lisp-mode fi:franz-lisp-mode
			    fi:lisp-mode))
	 (fi:lisp-eval-defun nil))
	((eq major-mode 'fi:emacs-lisp-mode) (eval-defun))))

(defun x-lisp-arglist (arg)
  (x-mouse-set-point arg)
  (cond ((eq major-mode 'fi:common-lisp-mode) (fi:lisp-arglist))
	(t (describe-function (intern (find-tag-default))))))

;;;; End of allegro-init.el

