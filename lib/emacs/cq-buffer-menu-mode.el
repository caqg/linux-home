;;;; -*- Mode: Emacs-Lisp -*-

(require 'cl)

(defun cq-buffer-menu ()
  "Customizations for buffer-menu-mode"
  (interactive)
  (local-set-key "."    'Buffer-menu-other-window)
  (local-set-key "\M-d" 'cq-nuke-temp-buffers))

(defun cq-nuke-temp-buffers (arg)
  "Offer to kill the temporary buffers.  With arg, just go and kill them.
DANGER!  This assumes a single-processor Emacs :-).  Make sure no one needs
the buffers your are killing.  You may have to save or rename a few buffers
before killing the rest.

A buffer is deemed temporary if its name begins with a space."
  (interactive "P")
  (get-buffer-create " *Temp Buffers*") ;so it is available for deletion
  (let* ((buffer-list (mapcar (function (lambda (b)
                                          (list b
                                                (buffer-name b)
                                                (buffer-file-name b)
                                                (buffer-modified-p b))))
                              (buffer-list)))
         (temp-buffers (mapcan (function (lambda (bs)
                                           (when (char-equal
                                                  (aref (second bs) 0)
                                                  ?\ )
                                             (list bs))))
                               (copy-list buffer-list))))
    (with-output-to-temp-buffer " *Temp Buffers*"
      (princ (format "%s\n%s\n"
                     "MF Name (File Visited, if any)"
                     "-- ----  ---- -------- -- ---"))
      (dolist (b temp-buffers)
        (let ((name         (second b))
              (file         (if (third b)  "*" " "))
              (modified-p   (if (fourth b) "*" " ")))
          (princ (format "%s%s %s %s\n" modified-p file name
                         (if (third b) (concat "(" (third b) ")") ""))))))
    (if arg
        (mapc (function (lambda (b) (kill-buffer (first b))))
              temp-buffers)
      (mapc (function (lambda (b)
                        (if (y-or-n-p (format "Kill buffer `%s'? "
                                              (second b)))
                            (kill-buffer (first b)))))
            temp-buffers))
    (message "")))

;;;; End of cq-buffer-menu-mode.el

