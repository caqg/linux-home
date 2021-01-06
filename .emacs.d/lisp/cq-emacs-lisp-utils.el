;;;; -*- mode: emacs-lisp; lexical-binding: t -*-
;;; Copyright (C) 2021 by Cesar A Quiroz, Ph.D.
;;; 3595 Granada Ave Unit 114 / Santa Clara, CA 95051 / USA
;;; All Rights Reserved Worldwide
;;; mailto:cesar.quiroz@gmail.com

(defun cq/sort-package-selected-packages ()
  "Sort the symbol list package-selected-packages in increasing symbol-name.

The list is saved to the init file, along with other changes in this session."
  (interactive)
  (setq package-selected-packages
        (sort (copy-seq package-selected-packages) #'string-lessp))
  (put 'package-selected-packages
       'customized-value
       (list (custom-quote (symbol-value 'package-selected-packages))))
  (customize-save-customized)
  package-selected-packages)



(provide 'cq-emacs-lisp-utils)
;;;; end cq-emacs-lisp-utils.el
