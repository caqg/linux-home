(cond ((and (eq window-system 'x) (> emacs-major-version 18))
       ;; Under X, and in Emacs 19 or better
       (if (fboundp 'scroll-bar-mode)
           (scroll-bar-mode -1))
       (if (fboundp 'menu-bar-mode)
           (menu-bar-mode -1))))
