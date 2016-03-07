;;;; -*- Emacs-Lisp -*-  Common Start-Up options

(defvar *cq/homedir*   (getenv "HOME")
  "${HOME}")
(defvar *cq/emacslib*  (concat *cq/homedir* "/lib/emacs/")
  "Pathname of my private library")
(setq load-path (append (list *cq/emacslib*) load-path (list ".")))

(put 'dired-find-alternate-file 'disabled nil)
(put 'eval-expression  'disabled          nil)
(put 'narrow-to-page   'disabled          nil)
(put 'narrow-to-region 'disabled          nil)
(put 'scroll-left      'disabled          nil)
(put 'set-goal-column  'disabled          nil)

(setq-default major-mode 'text-mode)    ;indented-text-mode is an alias

(defvar *timestamp-program* (concat (getenv "HOME") "/cmd/timestamp")
  "Program to produce a time stamp (see cq-timestamp).")

(setq tag-table-alist nil)



;;; Mode Hooks

(add-hook 'c-mode-hook                  'cq-c-mode)
(add-hook 'c++-mode-hook                'cq-c++-mode)
(add-hook 'java-mode-hook               'cq-java-mode)
(setq c-style-variables-are-local-p     t)

;; (setq font-lock-maximum-size 500000)    ;workaround for its use in the hooks below.

(add-hook 'awk-mode-hook
          #'(lambda ()
              (setq c-basic-offset 8)
              (setq indent-tabs-mode t)
              (auto-fill-mode 1)
              (hs-minor-mode 1)
              (font-lock-mode 1)))

(add-hook 'c-mode-common-hook
          #'(lambda ()
              (c-set-style "user")
              (setq c-basic-offset 8)
              (setq indent-tabs-mode t)
              (c-set-offset 'substatement-open 0)
              (c-set-offset 'inextern-lang 0)
              (c-set-offset 'inline-open 0)
              (c-set-offset 'arglist-intro '+)
              (c-set-offset 'arglist-close 0)
              ;; (local-set-key "\M-\C-a" 'c-beginning-of-defun)
              ;; (local-set-key "\M-\C-e" 'c-end-of-defun)
              (hs-minor-mode 1)
              (if (string-match "^GNU Emacs" (emacs-version))
                  (subword-mode 1)
                (c-subword-mode 1))
              (auto-fill-mode 1)
              (font-lock-mode 1)
              (when (derived-mode-p 'c-mode 'c++-mode 'java-mode)
                ;; bison mode is derived from c-mode, so it works
                (gtags-mode 1)
                (ggtags-mode -1))))

(add-hook 'c-mode-common-hook
          #'(lambda ()
              (form-feed-mode 1))
          t)

(add-hook 'c-mode-common-hook
          #'(lambda () "Treat PowerView differently than PowerAnalysys"
              (when (and buffer-file-name
                         (string-match "\/PowerView\/" buffer-file-name))
                (message "PowerView settings for \"%s\"" buffer-file-name)
                (setq c-basic-offset 4)
                (setq indent-tabs-mode nil)
                ))
          t)

(autoload 'cmake-font-lock-activate "cmake-font-lock" nil t)
(add-hook 'cmake-mode-hook 'cmake-font-lock-activate)

(add-hook 'c++-mode-hook
          #'(lambda ()
              (c-set-offset 'innamespace 0)))

(add-hook 'java-mode-hook
          #'(lambda ()
              (setq c-basic-offset 4)
              (setq indent-tabs-mode nil)))

(c-add-style "llvm.org"
             '((fill-column . 80)
               (c++-indent-level . 2)
               (c-basic-offset . 2)
               (indent-tabs-mode . nil)
               (c-offsets-alist . ((innamespace 0)))))

(add-hook 'c-mode-hook
          #'(lambda () "Treat as LLVM if \"llvm\" appears in the filename."
              (when (and buffer-file-name
                         (string-match "llvm" buffer-file-name))
                (message "LLVM settings for \"%s\"" buffer-file-name)
                (c-set-style "llvm.org")))
          t)

(add-hook 'c++-mode-hook
          #'(lambda () "Treat as LLVM if \"llvm\" appears in the filename."
              (when (and buffer-file-name
                         (string-match "llvm" buffer-file-name))
                (message "LLVM settings for \"%s\"" buffer-file-name)
                (c-set-style "llvm.org")))
          t)

(add-hook 'comint-mode-hook
          #'(lambda ( )
              (add-hook 'comint-output-filter-functions
                        'comint-strip-ctrl-m)
              (local-set-key "\C-z\C-n" 'comint-next-prompt)
              (local-set-key "\C-z\C-p" 'comint-previous-prompt)))

(add-hook 'compilation-mode-hook
          #'(lambda ()
              (font-lock-mode 1)))

(add-hook 'cperl-mode-hook
          #'(lambda ()
              (auto-fill-mode 1)
              (hs-minor-mode 1)
              (font-lock-mode 1)
              (setq cperl-tab-always-indent nil)))

(add-hook 'diff-mode-hook
          #'(lambda ()
              (font-lock-mode 1)))

(add-hook 'emacs-lisp-mode-hook
          #'(lambda ()
              (auto-fill-mode 1)
              (setq fill-column 79)
              (setq indent-tabs-mode nil)
              (hs-minor-mode 1)
              (font-lock-mode 1)
              (eldoc-mode 1)
              (require 'balanced-insertions)
              (set-balanced-insertions )
              (local-set-key "\C-zi"    'cq-both-in)
              (local-set-key "\C-zo"    'cq-both-out)
              (local-set-key "\C-zx"    'cq-extract-sexp)
              (local-set-key "\C-\M-u"  'cq-backward-up-list-or-string)
              (local-set-key "\C-\M-d"  'cq-down-list)
              (local-set-key "\C-c\C-v" 'view-mode)
              ;;(local-set-key "\C-z]"    'cq-close-defun)
              ))

(add-hook 'gtags-mode-hook
          #'(lambda ()
              ;; Use "\C-cg" as the common map
              (define-key gtags-mode-map "\C-cgh" 'gtags-display-browser)
              (define-key gtags-mode-map "\C-cg." 'gtags-find-tag-from-here)
              (define-key gtags-mode-map "\C-cgt" 'gtags-pop-stack)
              (define-key gtags-mode-map "\C-cgf" 'gtags-find-file)
              (define-key gtags-mode-map "\C-cgP" 'gtags-parse-file)
              (define-key gtags-mode-map "\C-cgg" 'gtags-find-with-grep)
              (define-key gtags-mode-map "\C-cgI" 'gtags-find-with-idutils)
              (define-key gtags-mode-map "\C-cgs" 'gtags-find-symbol)
              (define-key gtags-mode-map "\C-cgr" 'gtags-find-rtag)
              (define-key gtags-mode-map "\C-cgt" 'gtags-find-tag)
              (define-key gtags-mode-map "\C-cgR" 'gtags-visit-rootdir)
              (define-key gtags-mode-map "\C-x4g" 'gtags-find-tag-other-window)
              ))

(add-hook 'gtags-select-mode-hook
          #'(lambda ()
              (hl-line-mode 1)          ;minor mode
              (define-key gtags-select-mode-map "t" 'gtags-pop-stack)
              (define-key gtags-select-mode-map "\^?" 'scroll-down)
              (define-key gtags-select-mode-map " " 'scroll-up)
              (define-key gtags-select-mode-map "p" 'previous-line)
              (define-key gtags-select-mode-map "n" 'next-line)
              (define-key gtags-select-mode-map "\C-m" 'gtags-select-tag)
              (define-key gtags-select-mode-map "\C-o" 'gtags-select-tag-other-window)
              (if gtags-disable-pushy-mouse-mapping nil
                (define-key gtags-select-mode-map [mouse-2] 'gtags-select-tag-by-event))))


;;(setq inferior-lisp-program "clisp")
(add-hook 'ilisp-mode-hook
          #'(lambda () (setq lisp-no-popper t)))
(add-hook 'lisp-mode-hook               ;tailored for CLISP-HS
          #'(lambda ()
              ;; (require 'ilisp)
              (require 'slime)
              (require 'balanced-insertions)
              (set-balanced-insertions )
              (local-set-key "\C-zi"    'cq-both-in)
              (local-set-key "\C-zo"    'cq-both-out)
              (local-set-key "\C-zx"    'cq-extract-sexp)
              (local-set-key "\C-\M-u"  'cq-backward-up-list-or-string)
              (local-set-key "\C-\M-d"  'cq-down-list)
              (local-set-key "\C-c\C-v" 'view-mode)
              ;;(local-set-key "\C-z]"    'cq-close-defun)
              (auto-fill-mode 1)
              (hs-minor-mode 1)
              (font-lock-mode 1)
              (setq lisp-no-popper t)   ;this is smoother in Cygwin
              ;;(put 'if 'lisp-indent-function nil)
              (let* ((name (buffer-file-name (current-buffer)))
                     (ext (and name (file-name-extension name))))
                (if (and ext
                         (or (string= ext "emacs")
                             (string= ext "el")
                             (string= ext "elc")))
                    nil                 ;must be Emacs Lisp
                  (make-local-variable 'lisp-indent-function)
                  (setq lisp-indent-function 'common-lisp-indent-function))
                (put 'defclass 'lisp-indent-function 3)
                (put 'defgeneric 'lisp-indent-function 'defun)
                ;; (put 'defmethod 'lisp-indent-function 'defun)
                (put 'define-method-combination 'lisp-indent-function 2)
                (put 'generic-flet 'lisp-indent-function
                     (get 'flet 'lisp-indent-function))
                (put 'generic-labels 'lisp-indent-function
                     (get 'labels 'lisp-indent-function))
                (put 'generic-function 'lisp-indent-function
                     (get 'lambda 'lisp-indent-function))
                (put 'with-accessors 'lisp-indent-function 2)
                (put 'with-slots 'lisp-indent-function 2)
                (put 'with-added-methods 'lisp-indent-function 'defun))))
(setq common-lisp-hyperspec-root
      "http://www.lispworks.com/documentation/HyperSpec/")

(add-hook 'makefile-mode-hook
          #'(lambda ()
              (auto-fill-mode 0)
              (font-lock-mode 1)
              (local-set-key "\C-c\C-v" 'view-mode)))

(add-hook 'markdown-mode-hook
          #'(lambda ()
              (setq tab-width 8)
              (local-set-key "\C-c\C-v" 'view-mode)))

(add-hook 'pascal-mode-hook
          #'(lambda ()
              (auto-fill-mode 1)
              (font-lock-mode 1)
              (setq pascal-tab-always-indent nil)
              (local-set-key "\C-c\C-v" 'view-mode)))

(add-hook 'shell-mode-hook
          #'(lambda ()
              (auto-fill-mode 0)
              (lsetq shell-pushd-regexp "pushd\\|\\+")
              (lsetq shell-popd-regexp "popd\\|-")
              (setq shell-prompt-pattern "^[$%#] "
                    comint-prompt-regexp shell-prompt-pattern)))

(add-hook 'shell-mode-hook
          #'(lambda ()
              (make-local-variable 'mode-line-format)
              (setq mode-line-format
                    (list " %b(%s) %p (%l,%c) "
                          'default-directory
                          " "
                          '(:eval (cq/get-git-branch-mode-line-item))
                          ;; '(vc-mode vc-mode)
                          " "
                          'global-mode-string
                          " ("
                          'mode-name
                          'minor-mode-alist
                          ") %-")))
          t)

(add-hook 'sh-mode-hook
          #'(lambda ()
              (setq indent-tabs-mode t)
              (local-set-key "\C-c\C-v" 'view-mode)
              (require 'balanced-insertions)
              (set-balanced-insertions)
              (auto-fill-mode 1)        ;it is a prog-mode
              (font-lock-mode 1)))

(add-hook 'tcl-mode-hook
          #'(lambda ()
              (setq tcl-tab-always-indent nil)
              (tcl-auto-fill-mode 1)
              (local-set-key "\C-c\C-v" 'view-mode)
              (hs-minor-mode 1)
              (font-lock-mode 1)))
(setq tcl-application "tclsh"
      tcl-prompt-regexp "\(^> \)|\(^\\ \)")

(add-hook 'vhdl-mode-hook
          #'(lambda ()
              (auto-fill-mode 1)
              (font-lock-mode 1)
              (local-set-key "\C-c\C-v" 'view-mode)))

(add-hook 'xml-mode-hook
          #'(lambda ()
              (auto-fill-mode 1)
              (font-lock-mode 1)
              (local-set-key "\C-c\C-v" 'view-mode)))

(add-hook 'xrdb-mode-hook
          #'(lambda ()
              (auto-fill-mode 1)
              (font-lock-mode 1)))

;;; For FORTRAN mode
;; (add-hook 'fortran-mode-hook             'cq-fortran-mode)

;;; For Mod2 mode
;; (add-hook 'mod2-mode-hook                'cq-mod2-mode)

;; ;;; For Yacc mode
;; (add-hook 'yacc-mode-hook
;;           #'(lambda ()
;;               (font-lock-mode 1)
;;               (filladapt-mode 1)
;;               (gtags-mode 1)
;;               (ggtags-mode 1)))
;;; For Lisp modes
;;(setq inferior-lisp-program         "gcl")
;;(setq inferior-lisp-program         "clisp")
;; (setq inferior-lisp-program         "/usr/staff/bin/kcl")
;; (setq inferior-lisp-program         "/u/quiroz/bin.mc68020/kcl")
;;(setq inferior-lisp-program         "/u/quiroz/cmd/lispaway")
;;(setq inferior-lisp-program         "/u/quiroz/bin/Mach.sparc/akcl")
;;(setq inferior-lisp-program         "/usr/grads/bin/akcl")
;;(setq inferior-lisp-load-command
;;      "(progn (load \"%s\" :verbose nil :print t) (values))\n")
;;(setq inferior-lisp-tmp-directory   "/u/quiroz/tmp")
;;(setq inferior-lisp-editor          "emacsclient")
;; (setenv "KCL-EDITOR" inferior-lisp-editor)
;; (setq scheme-program-name "/u/quiroz/cmd/fastscheme")
;; for Schelter's find-doc
;;(defvar *thesis-doc-filename* "/u/quiroz/thesis/work/DOC")
;; (if (file-readable-p akcl-DOC) (visit-doc-file akcl-DOC))

;;; For Text modes
(add-hook 'text-mode-hook           'cq-text-mode)
(add-hook 'nroff-mode-hook          'cq-nroff-mode)
(add-hook 'edit-picture-hook        'cq-picture-mode)
(add-hook 'texinfo-mode-hook        'cq-texinfo-mode)
(add-hook 'TeX-mode-hook            'cq-tex-mode)
(add-hook 'LaTeX-mode-hook          'cq-latex-mode)
(add-hook 'LaTeX-mode-hook          'latex-extra-mode)
(setq TeX-default-mode              'latex-mode)

;;;; For MH-E
;;(setq load-path (cons (expand-file-name "~/lib/emacs/mh") load-path))
;;; hooks
;;(add-hook 'mh-compose-letter-hook        'cq-mh-compose-letter)
;;(add-hook 'mh-folder-mode-hook           'cq-mh-folder-mode)
;;(add-hook 'mh-inc-folder-hook            'cq-mh-inc-folder)
;;(add-hook 'mh-letter-mode-hook           'cq-mh-letter-mode)
;;; options

;;(setq mh-delete-yanked-msg-window   t)
;;(setq mh-ins-buf-prefix             "| ")
;;(setq mh-recursive-folders          t)
;;(setq mh-redist-full-contents       nil) ;otherwise dist fails in Rochester
;;(setq mh-yank-from-start-of-msg     'body) ;fix cq-mh-e.el in next release
;;(setq mhl-formfile t)
;;; my own stuff
;;(setq mh-cq-citation-prefix         "| ")
;;(setq mh-postnews-skel              "~/.mh-e.news.skel")
;;(setq mh-news-default-newsgroups    "cs.general")
;;(setq cq-mh-default-reply-to        "cesar.quiroz@gmail.com")

;;; For the Babyl mailer
;; (setq mail-archive-file-name        "~/mail/babyl/OUT")
;; (setq mail-self-blind               nil)
;; (setq mail-use-rfc822               t)
;; (setq rmail-delete-after-output     nil)
;; (setq rmail-file-name               "~/mail/babyl/RMAIL")

;;; For Prolog mode
(add-hook 'prolog-mode-hook              'cq-prolog-mode)

;;; Dired Extensions
(add-hook 'dired-mode-hook               'cq-dired-mode)
(add-hook 'dired-mode-hook
          #'(lambda ()
              (setq mode-line-format
                    (subst '(:eval (cq/get-git-branch-mode-line-item))
                           '(vc-mode vc-mode)
                           mode-line-format
                           :test #'equal))))

;;; Buffer-Menu Extensions
(add-hook 'buffer-menu-mode-hook         'cq-buffer-menu)

;;; Reingold's calendar and diary program
;;; The idea is to share the screen with MH-E on startup,
;;; as I start things usually this way:
;;;     emacs -f display-time -f cq-inbox -f calendar

;;; First off, don't spend too much time on this.
;; (setq view-diary-entries-initially      nil)
;; (setq mark-holidays-in-calendar         nil)
;; (setq mark-diary-entries-in-calendar    nil)
;; (setq diary-file                        "~/.diary")
;; (setq european-calendar-style           nil)
;; (setq calendar-date-display-form     '((format "%s-%02s-%02s" year month day)))
;; (setq calendar-week-start-day                1)
(autoload 'calendar "calendar" "" t nil)
(autoload 'diary    "diary"    "" t nil)
(autoload 'holidays "holidays" "" t nil)
(add-hook 'initial-calendar-window-hook
          #'(lambda ()
              (when (and ecb-minor-mode
                         (ecb-point-in-edit-window-number))
                ;; if no horizontal split then nothing
                ;; special to do
                (or (= (frame-width) (window-width))
                    (shrink-window (- (window-height) 9))))
              ))

;;; Other customizations
(setq safe-kill-region-threshold        5120)
;; (setq lpq-known-printers                '())



;;; Other hooks

(add-hook 'after-save-hook
          #'(lambda ()
              (save-excursion
                (save-restriction
                  (widen)
                  (goto-char (point-min))
                  (and (looking-at "^#!") ;magic number detector
                       (not (file-executable-p buffer-file-truename))
                       (set-file-modes buffer-file-truename
                                       (logior (file-modes buffer-file-truename)
                                               #o755)))))))



;;;
;;; Some global key bindings
;;;

;;;(global-unset-key "\C-x\C-l")           ;was downcase-region
;;;(global-unset-key "\C-x\C-u")           ;was upcase-region

(global-unset-key "\C-z")               ;make it user-specific (thanks Neil)

(global-set-key [(button4)]             'scroll-down-one)
(global-set-key [(button5)]             'scroll-up-one)
(global-set-key [(control button4)]     'backward-block-of-lines)
(global-set-key [(control button5)]     'forward-block-of-lines)
(global-set-key [(meta button4)]        'scroll-down-command)
(global-set-key [(meta button5)]        'scroll-up-command)

(global-set-key [(control -)] 'text-scale-decrease)
(global-set-key [(control +)] 'text-scale-increase)

(global-set-key "\C-^"              'call-last-kbd-macro)
;;+? (global-set-key "\M-\C-l"           'force-recenter)
;;+? (global-set-key "\eG"               'goto-line)
;;+? (global-set-key "\eK"               'kill-paragraph)
;;+? (global-set-key "\eT"               'transpose-sentences)
;;-? (global-set-key "\eo"               'indent-to-point)
;;+? (global-set-key "\e\^R"             'isearch-backward-regexp)
;;+? (global-set-key "\eR"               'replace-string)
;;+? (global-set-key "\ew"               'copy-region-as-kill-command)
;; (global-set-key [ ?\C-c ?\  ]       'set-mark-command)
(global-set-key "\C-c\C-v"          'view-mode)
(global-set-key "\^Z\^C"            'compile)
(global-set-key "\^Z\^K"            'kill-compilation)
(global-set-key "\^Z\^N"            'next-error)
(global-set-key "\^Z\^R"            'recompile)
(global-set-key "\^Z\^Z"            'suspend-frame)
;;(global-set-key "\^X\^C"            'cq-kill-emacs-maybe)
;;+? (global-set-key "\^X,"              'attach-to-register)
;;+? (global-set-key "\^XR"              'replace-regexp)
;;+? (global-set-key "\^X%"              'query-replace-regexp)
;;+? (global-set-key "\^X="              'cq-what-cursor-position)
;;+? (global-set-key "\^XB"              'list-buffers)
(global-set-key "\^X\^B"            'buffer-menu);was electric-buffer-list
(global-set-key "\^Zv"              'shrink-window)
;;+? (global-set-key "\^Z|"              'goto-column)
(global-set-key "\^X\""             'double-line)
(global-set-key "\^X\^L"            'inferior-lisp)
(global-set-key "\^X\^N"            'set-goal-column)
;;(global-set-key "\^X4!"             'cq-comint-shell-other-window)
;;(global-set-key "\^X4!"             'cq-multi-shell-other-window)
;;(global-set-key "\^X!"              'cq-multi-shell)
;;(global-set-key "\^X!"              'shell)
(global-set-key "\^W"               'safe-kill-region)
(global-set-key "\^Z\^F"            'cq-revert-buffer)
(global-set-key "\^Zb"              'cq-insert-buffer-file-name)
(global-set-key "\^Zg"              'cq-goto-line)
(global-set-key "\^Zt"              'cq-timestamp)
(global-set-key "\C-xr>"            'append-to-register)
(global-set-key "\C-xr<"            'prepend-to-register)
;;+? (global-set-key "\^Z\et"            'transpose-paragraphs)
;;+? (global-set-key "\^Z\e@"            'mark-end-of-sentence)
;;+? (global-set-key "\^Z\ef"            'forward-sentence)
;;+? (global-set-key "\^Z\e\^?"          'backward-delete-paragraph)
;;+? (global-set-key "\^Z\^Z"            'cq-suspend-saving)
(global-set-key "\^Zm"              'vm-compose-mail)
(global-set-key "\^Zr"              'vm)

(define-key help-map "\C-f"         'flash-describe-function)
(define-key help-map "\C-v"         'flash-describe-variable)

;;; For electric-minibuffer
(define-key minibuffer-local-completion-map "\en"
  'minibuffer-yank-next-completion)
(define-key minibuffer-local-completion-map "\ep"
  'minibuffer-yank-previous-completion)
(define-key minibuffer-local-must-match-map "\en"
  'minibuffer-yank-next-completion)
(define-key minibuffer-local-must-match-map "\ep"
  'minibuffer-yank-previous-completion)



;;; Functions to load on demand.

(let ((file (concat *cq/emacslib* "cq-c-mode")))
  (autoload 'cq-c-mode file "C mode settings" t nil)
  (autoload 'cq-c++-mode file "C++ mode settings" t nil)
  (autoload 'cq-java-mode file "Java mode settings" t nil)
  (autoload 'emacs-c-source-mode file "Use Emacs's C style." t nil)
  (autoload 'c-main    file "C main program builder" t nil)
  (autoload 'c-non-main file "C headers/library builder" t nil)
  (autoload 'c-extern-trick file "Disgusting hacks for .h externs" t nil)
  (autoload 'c68-catch file "Build a catch block" t nil)
  (autoload 'c68-when  file "Build a when clause" t nil)
  (autoload 'cq-insert-braces file "Insert a pair of matching braces." t nil))

(let ((file (concat *cq/emacslib* "cq-lisp-mode")))
  (autoload 'cq-lisp-mode file "Lisp Mode customizations" t nil)
  (autoload 'cq-emacs-lisp-mode file "Emacs-Lisp Mode customizations" t nil)
  (autoload 'cq-lisp-interaction-mode file "Lisp Interaction details" t nil)
  (autoload 'cq-common-lisp-mode file "Common Lisp interaction" t nil)
  (autoload 'resume-lisp file "Run or restart inferior lisp" t nil)
  (autoload 'resume-scheme file "Run or restart inferior scheme" t nil)
  ;;; structured editing
  (autoload 'cq-both-in file "Parenthesize the sexps in the region" t nil)
  (autoload 'cq-both-out file "Un-parenthesize the sexps in the region" t nil)
  (autoload 'cq-extract-sexp file
    "Sexp at or after point replaces its whole list" t nil)
  (autoload 'cq-close-defun file
    "Put enough delimiters to close the current defun" t nil)
  ;;; structured in-file navigation
  (autoload 'cq-backward-up-list file "Like \\C-M-u, strings are safe" t nil)
  (autoload 'cq-backward-up-list-or-string file
    "Exits up from lists or strings" t nil)
  (autoload 'cq-down-list file "Like \\C-M-d, doesn't fail on strings" t nil))

(let ((file (concat *cq/emacslib* "perldoc")))
  (autoload 'perldoc file "Run perldoc" t nil))

;;(let ((file (concat *cq/emacslib* "xe-balanced-insertions")))
;;  (autoload 'insert-bookends file "" t nil)
;;  (autoload 'globalize-bookends file "" t nil))
;;(globalize-bookends)

(let ((file (concat *cq/emacslib* "cq-text-modes")))
  (autoload 'cq-text-mode file  "Text mode with auto-fill" t nil)
  (autoload 'cq-nroff-mode file "Nroff mode with indentation" t nil)
  (autoload 'cq-next-tab file   "Move to next tab stop" t nil)
  (autoload 'cq-picture-mode file "Picture mode settings" t nil)
  (autoload 'cq-texinfo-mode file "To edit TeXinfo files" t nil)
  (autoload 'cq-tex-mode file   "TeX mode settings" t nil)
  (autoload 'cq-latex-mode file "LaTeX mode settings" t nil))
(autoload   'new-latex-document "latex-mode" "Start a LaTeX paper" t nil)

(let ((file (concat *cq/emacslib* "pic-mode")))
  (autoload 'pic-mode file "Mode for pic input" t nil))

;;;(let ((file (concat *cq/emacslib* "cq-babyl")))
;;;  (autoload 'cq-mail-mode         file "Set Mail mode" t nil)
;;;  (autoload 'cq-mail-setup        file "Affect formatting of a message" t nil)
;;;  (autoload 'cq-rmail-mode        file "Set Rmail mode" t nil)
;;;  (autoload 'cq-rmail-summary-mode file "Set Rmail Summary mode" t nil))



(let ((file (concat *cq/emacslib* "cq-multi-shell")))
  (autoload 'cq-multi-shell file "Handle multiple shell buffers" t nil)
  (autoload 'cq-multi-shell-other-window file
    "Start or pop a shell in another buffer" t nil))

(let ((file (concat *cq/emacslib* "cq-utils")))
  (autoload 'double-line file "neato" t nil)
  (autoload 'cq-suspend-saving file "Suspend and save all buffers" t nil)
  (autoload 'cq-iconify-saving file "Iconify and save all buffers" t nil)
  (autoload 'cq-goto-match file "Take cursor to matching delimiter" t nil)
  (autoload 'x-mouse-chart file "Reminder of X-mouse bindings" t nil)
  (autoload 'x-reconfig    file "Reconfigure X window." t nil)
  (autoload 'x-mouse-select-and-mark file
    "Select window, set mark where cursor landed" t nil)
  (autoload 'cq-no-suspend file "Do not suspend this EMACS" t nil)
  (autoload 'cq-kill-emacs-maybe file "Do not kill this EMACS recklessly"
    t nil)
  (autoload 'cq-shell file "Start/Restart a shell" t nil)
  (autoload 'cq-shell-other-window file "Shell in another window." t nil)
  (autoload 'cq-comint-shell-other-window file
    "Shell in another window." t nil)
  (autoload 'find-file-read-only-other-window file "Like ^X^R" t nil)
  (autoload 'tags-find-all file "Find all file in tags file." t nil)
  (autoload 'cq-what-cursor-position file "Report cursor position." t nil)
  (autoload 'set-flow-control file "Set/Reset flow controlled input." t nil)
  (autoload 'cq-switch-del-and-bs file "BS<->DEL" t nil)
  (autoload 'cq-save-modified-buffers file "Saved all modified buffers."
    t nil)
  (autoload 'see-chars file
    "Displays characters typed, terminated by a 3-second timeout."
    t nil)
  (autoload 'first-window file
    "Other-window implemented to be used from the command line."
    t nil)
  (autoload 'identify-in-minibuffer file
    "Verbose identification dump."
    t nil)
  (autoload 'safe-kill-region file
    "Kill region, ask for confirmation if too large." t nil)
  (autoload 'flash-describe-function file
    "Flash the documentation of FUNCTION (a symbol)" t nil)
  (autoload 'flash-describe-variable file
    "Flash the documentation of VARIABLE (a symbol)" t nil)
  (autoload 'cq-display-temporarily file
    "Temporary display of a string, if doable" t nil)
  (autoload 'cq-revert-buffer file "Like revert-buffer, but less chatty" t nil)
  (autoload 'copy-region-as-kill-command file
    "Chatty copy-region-as-kill" t nil)
  (autoload 'attach-to-register file
    "Either prepend or append to register" t nil)
  (autoload 'force-recenter file "(recenter '(0))" t nil)
  (autoload 'cq-goto-line file "Go to line given by the prefix, a la CCA"
    t nil)
  (autoload 'cq-timestamp file "Insert a time stamp at point" t nil)
  (autoload 'lsetq file "Setq variables after making them buffer-local" nil t)
  (autoload 'locate-indentation file "Find indentation extent for current line."
    nil t ))

;; (let ((file (concat *cq/emacslib* "cq-generic-code-mode")))
;;   (autoload 'cq-generic-code-mode file "Customize generic code mode" t nil)
;;   (autoload 'new-script file "Write a new executable script." t nil)
;;   (autoload 'cq-cakefile-mode file "Setup for cakefiles" t nil)
;;   (autoload 'cq-pic-mode file "Setup for pic input" t nil)
;;   (autoload 'cq-sun-assembler-mode file "Setup for sun-assembler" t nil)
;;   (autoload 'Mathematica-mode file "Edit Mathematica sources" t nil))

;;(let ((file (concat *cq/emacslib* "cq-comint")))
;;  (autoload 'cq-shell-mode file "Setup shell modes" t nil))

;;(let ((file (concat *cq/emacslib* "xe-sh-mode")))
;;  (autoload 'cq-sh-mode-hook file "Setup shell modes" t nil)
;;  (autoload 'cq-sh-indent-line file "Handle indentation" t nil)
;;  (add-hook 'sh-mode-hook 'cq-sh-mode-hook))

(let ((file (concat *cq/emacslib* "cq-dired-mode")))
  (autoload 'cq-dired-mode file "Customizations of DIRED mode" t nil))

(let ((file (concat *cq/emacslib* "cq-buffer-menu-mode")))
  (autoload 'cq-buffer-menu file "Customizations of BUFFER-MENU" t nil)
  (autoload 'cq-nuke-temp-buffers file "Kill the temporary buffers" t nil))

(let ((file (concat *cq/emacslib* "electric-minibuffer")))
  (autoload 'minibuffer-yank-next-completion file "M-n" t nil)
  (autoload 'minibuffer-yank-previous-completion file "M-p" t nil))

(let ((file (concat *cq/emacslib* "cq-lpr")))
  (autoload 'lprint-buffer file "Like print-buffer, but spools to -Plp." t nil)
  (autoload 'lprint-region file "Like print-region, but spools to -Plp." t nil)
  (autoload 'lpq file "Run lpq" t nil))

(let ((file (concat *cq/emacslib* "starweb")))
  (autoload 'starweb-mode file "Supports writing orders" t nil))

;;; Load Abbreviations.
(quietly-read-abbrev-file nil)



;; (setq display-time-string-forms
;;       '((format "%s-%02d-%02d "
;;                 year (string-to-number month) (string-to-number day))
;;      (format "%s:%s " 24-hours minutes)
;;      (if mail "Mail ")))
(defun cq/wrap-up-start ()
    (message "%s (%s) @ %s -- %s GCs %s in init"
             (user-full-name) (user-login-name) (system-name)
             gcs-done (emacs-init-time)))

;;;end .emacs-shared, loaded from ~/.emacs, ~/.xemacs/init.el
;;;end init-legacy.el, loaded from init.el
