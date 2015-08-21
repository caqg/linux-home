;;;;                                                        -*- Emacs-Lisp -*-
;;; Copyright (C) 2015 by Cesar A Quiroz, Ph.D.
;;; 3595 Granada Ave Unit 114 / Santa Clara, CA 95051 / USA
;;; All Rights Reserved Worldwide
;;; mailto:cesar.quiroz@gmail.com

(defcustom *cq/metadata-file-loaders-alist*
  (list (cons ".ede-cpproot.el"
              #'(lambda (f) (load-file f)))
        (cons "TAGS"
              #'(lambda (f) (visit-tags-table f)))
        (cons "cscope.out"
              #'(lambda (f) (cscope-set-initial-directory ".")))
        (cons "GTAGS"
              #'(lambda (f) (gtags-visit-rootdir))))
  "Map a base filename (e.g, \"TAGS\") to a s-exp which, when evaluated, loads
that file and any associated ones"
  :type 'alist)

(defun cq/load-ede-project-and-tags ()
  "Load .ede-cpproot.el, and other tag files, if present. The loaders are found
for each file name thru the map in `*cq/metadata-file-loaders-alist*'"
  (interactive)
  (mapc #'(lambda (e)
            (let* ((file-name (car e))
                   (loader-exp (cdr e))
                   (expanded-file-name (expand-file-name file-name)))
              ;; do the load if the file exists, be quiet otherwise
              (when (file-readable-p expanded-file-name)
                (funcall loader-exp expanded-file-name))))
        *cq/metadata-file-loaders-alist*))



(provide 'cq-cedet-ede-ecb-utils)
;;;; end cq-cedet-ede-ecb-utils.el
