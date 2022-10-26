;;; -*- Emacs-Lisp -*- GNU Emacs Start-Up options

;;;       #####   ######  #       ######  #    #  #####     ##
;;;       #    #  #       #       #       ##   #  #    #   #  #
;;;       #    #  #####   #       #####   # #  #  #    #  #    #
;;;       #    #  #       #       #       #  # #  #    #  ######
;;;       #    #  #       #       #       #   ##  #    #  #    #
;;;       #####   ######  ######  ######  #    #  #####   #    #
;;;
;;;
;;;                       ######   ####    #####
;;;                       #       #          #
;;;                       #####    ####      #
;;;                       #            #     #
;;;                       #       #    #     #
;;;                       ######   ####      #
;;;
;;;   ##           #
;;;  #  #  #      #           ######  #    #    ##     ####    ####
;;;      ##      #            #       ##  ##   #  #   #    #  #
;;;             #             #####   # ## #  #    #  #        ####
;;;            #       ###    #       #    #  ######  #            #
;;;           #        ###    #       #    #  #    #  #    #  #    #
;;;          #         ###    ######  #    #  #    #   ####    ####
;;;


(message "cq: Initializing from ~/.emacs.d/init.el")
(message "cq: Initial GCs = %s" gcs-done)

;;; 2015-09-16 05:21:08UT (cesar@cesar-U64-14):
;;; 0.8 MB between gcs is too little nowadays
;;; hint at reddit from /u/bahblah
;;; https://www.reddit.com/r/emacs/comments/3kqt6e/2_easy_little_known_steps_to_speed_up_emacs_start/

(let ((file-name-handler-alist nil)
      (gc-cons-threshold (* 1024 1024 1024 2)))
  (require 'cl-lib)

  (load-file "~/.emacs.d/init-legacy.el")
  (message "cq: Done loading legacy init, GCs = %s" gcs-done)

  (add-to-list 'load-path "~/.emacs.d/lisp")
  (load-library "misc")
  (load-library "cq-workarounds")
  ;; (global-set-key [(meta z)] 'cq-zap-up-to-char)
  ;; stock or misc, not from workarounds:
  (global-set-key [(meta z)] 'zap-up-to-char)
  (global-set-key [(meta Z)] 'zap-to-char)

  (load-library "cq-emacs-lisp-utils")

  (load-library "cq-edit-utils")
  (global-set-key "\C-x$" 'cq/set-selective-display)

  (load-library "cq-file-hooks")
  (add-hook 'before-save-hook
            (lambda () ;; clean up source code; do nothing else
              (and
               (derived-mode-p 'prog-mode)
               (not (derived-mode-p 'makefile-mode))
               (cq/trim-whitespace))))

  (load-library "cq-minor-mode-utils")
  (global-set-key "\^Zs" 'cq/flip-scroll-bar-modes)

  (load-library "cq-cedet-ede-ecb-utils")
  (global-set-key "\^ZL" 'cq/load-ede-project-and-tags)

  (with-eval-after-load 'dired ;; was (add-hook 'dired-load-hook
    (lambda ()
      ;; Bind dired-x-find-file.
      (setq dired-x-hands-off-my-keys t)
      (load "dired-x")))

  (require 'ffap)
  (ffap-bindings)

  (filesets-init)

  (require 'slime-autoloads)
  ;;(slime-setup)
  (global-set-key "\C-cs" 'slime-selector)
  (add-hook 'slime-repl-mode-hook 'set-balanced-insertions)

  (which-function-mode   1)
  (pending-delete-mode   t)
  (electric-indent-mode -1)

  (require 'multishell)
  (global-set-key "\C-x!" 'multishell-pop-to-shell)

  (require 'magit)
  (global-set-key "\C-xg" 'magit-status)
  (global-set-key "\C-x\M-g" 'magit-dispatch)

  ;; Surely we haven't seen the last of perforce
  ;; (require 'p4)

  (require 'tramp)

  ;; Known to work at least since v23, again don't know if before.
  ;; (defun gamegrid-add-score-with-update-game-score-1( file target score ))

  ;; Optional cl-lib highlighting.
  (unless (> emacs-major-version 24)    ;obsolete before v24.4
    (require 'cl-lib-highlight)
    (cl-lib-highlight-initialize)
    (cl-lib-highlight-warn-cl-initialize))

  (require 'windmove)
  (global-set-key (kbd "C-c <right>") 'windmove-right)
  (global-set-key (kbd "C-c <left>")  'windmove-left)
  (global-set-key (kbd "C-c <up>")    'windmove-up)
  (global-set-key (kbd "C-c <down>")  'windmove-down)

  (require 'dired-x)
  (require 'dired-toggle-sudo)
  (define-key dired-mode-map (kbd "C-c C-s") 'dired-toggle-sudo)

  ;; (require 'xcscope)
  ;; (cscope-setup)

  ;; (require 'gtags)

  (require 'org-install)
  (add-to-list 'auto-mode-alist (cons "\\.org$" 'org-mode))
  (global-set-key "\C-ca" 'org-agenda)
  (global-set-key "\C-cb" 'org-iswitchb)
  (global-set-key "\C-cc" 'org-capture)
  (global-set-key "\C-cl" 'org-store-link)
  (setq org-todo-keywords
        '((sequence "TODO" "DOING" "PENDING" "|" "DONE" "DROPPED")))
  (setq org-log-done t)                 ; or '(done) instead of t
  (setq org-agenda-include-diary t)
  (add-hook 'org-mode-hook (lambda () (require 'vc)))
  (add-hook 'org-mode-hook 'turn-on-font-lock)

  (require 'remember)
  (setq org-directory "~/Notes")
  (setq org-default-notes-file (concat org-directory "/my-notes.org"))
  (define-key global-map "\C-cr" 'org-remember)

  (require 'cq-x-utils)
  (require 'cq-theme-utils)
  (require 'grep)
  (require 'paren)
  (require 'parenface)
  (require 'tabbar)
  (require 'time)

  (require 'string-utils)

  ;;(require 'hide-comnt)
  ;;(global-set-key (kbd "C-c @ ;") 'hide/show-comments-toggle)

  ;; tabbar (already initialized)
  (defadvice tabbar-add-tab (after cq/tabbar-add-tab-sorted
                                   (tabset object &optional append))
    "Present the tab bar tab sets in ascending order by buffer name."
    (let* ((tabs (tabbar-tabs tabset))
           (sorted (sort tabs (lambda (a b)
                                (string< (buffer-name (car a))
                                         (buffer-name (car b)))))))
      (set tabset sorted)))

  ;; Color them
  (when (and (window-system) (>= emacs-major-version 25))
    (load-theme 'solarized t t)
    (load-theme 'solarized-light t t)
    (load-theme 'solarized-dark t t)
    (require 'cq-solarized-theme-init))

  (require 'recentf)

  (require 'bison-mode)
  (require 'gdb-mi)

  (require 'semantic)
  (require 'semantic/decorate/mode)
  (require 'semantic/idle)
  (require 'semantic/mru-bookmark)
  (require 'semantic/sb)
  (require 'semantic/symref)

  (require 'ede)
  ;;(require 'ecb)                        ;last require, so at end of Tools menu

  (if window-system
      (ad-activate 'tabbar-add-tab 'compile-it))

  (setq-default ediff-auto-refine 'on)

  (defvar *cq/frame-background-mode* nil
    "Desired initial value for frame-background-mode (or just NIL).")
  (setq *cq/frame-background-mode*
        (let ((mybgshine (getenv "MYBGSHINE")))
          (when (and mybgshine (member mybgshine '("dark" "light")))
            (intern mybgshine))))
  (menu-bar-mode 1)
  (add-hook 'tty-setup-hook
            (lambda ()
              (tabbar-mode  -1)
              (when (or (getenv "WSL_DISTRO_NAME")
                        (string-equal (getenv "TERM") "xterm-256color"))
                (setq frame-background-mode *cq/frame-background-mode*)
                (mapc #'frame-set-background-mode (frame-list))
                (cq/adjust-paren-face-fg nil)
                (xterm-mouse-mode 1)
                (mouse-wheel-mode 1))))

  (when (memq window-system (list 'x 'w32))
    (set-default-xtitle))
  (when (display-color-p)
    (cq/adjust-paren-face-fg nil))
  (unless (display-graphic-p)
    (normal-erase-is-backspace-mode -1)))
(eval :force-gc-by-calling-eval)
(message "cq: In init.el, before custom-set-variables, GCs = %s" gcs-done)

;;;end ~/.emacs.d/init.el -- don't edit beyond


(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(Man-switches "-a")
 '(ada-skel-initial-string "")
 '(adaptive-fill-mode t)
 '(align-indent-before-aligning t)
 '(ansi-color-names-vector
   ["#073642" "#dc322f" "#859900" "#b58900" "#268bd2" "#d33682" "#2aa198" "#657b83"])
 '(auto-mode-case-fold nil)
 '(background-color "#202020")
 '(background-mode dark)
 '(backup-by-copying-when-linked t)
 '(beacon-mode nil)
 '(c++-font-lock-extra-types
   '("\\sw+_t" "FILE" "lconv" "tm" "va_list" "jmp_buf" "istream" "istreambuf" "ostream" "ostreambuf" "ifstream" "ofstream" "fstream" "strstream" "strstreambuf" "istrstream" "ostrstream" "ios" "string" "rope" "list" "slist" "deque" "vector" "bit_vector" "set" "multiset" "map" "multimap" "hash" "hash_set" "hash_multiset" "hash_map" "hash_multimap" "stack" "queue" "priority_queue" "type_info" "iterator" "const_iterator" "reverse_iterator" "const_reverse_iterator" "reference" "const_reference" "[[:upper:]]\\\\sw*[[:lower:]]\\\\sw"))
 '(c-tab-always-indent nil)
 '(calendar-date-style 'iso)
 '(calendar-intermonth-text
   '(propertize
     (format "%2d"
             (car
              (calendar-iso-from-absolute
               (calendar-absolute-from-gregorian
                (list month day year)))))
     'font-lock-face 'font-lock-function-name-face))
 '(calendar-mark-diary-entries-flag t)
 '(calendar-mark-holidays-flag t)
 '(calendar-week-start-day 1)
 '(case-fold-search t)
 '(column-number-mode t)
 '(compilation-message-face 'default)
 '(compilation-scroll-output t)
 '(compile-command "time -p make -j")
 '(completion-auto-help 'lazy)
 '(cscope-close-window-after-select t)
 '(cscope-option-do-not-update-database t)
 '(cscope-option-use-inverted-index t)
 '(cua-global-mark-cursor-color "#2aa198")
 '(cua-normal-cursor-color "#839496")
 '(cua-overwrite-cursor-color "#b58900")
 '(cua-read-only-cursor-color "#859900")
 '(current-language-environment "UTF-8")
 '(cursor-color "#cccccc")
 '(custom-safe-themes
   '("2809bcb77ad21312897b541134981282dc455ccd7c14d74cc333b6e549b824f3" "cb8d13429234ff2a8700da4db9bdf6b952c1b54b906a1aad2d0d98317c5b0224" "889a93331bc657c0f05a04b8665b78b3c94a12ca76771342cee27d6605abcd0e" "a8245b7cc985a0610d71f9852e9f2767ad1b852c2bdea6f4aadc12cce9c4d6d0" "4aee8551b53a43a883cb0b7f3255d6859d766b6c5e14bcb01bed572fcbef4328" "8db4b03b9ae654d4a57804286eb3e332725c84d7cdab38463cb6b97d5762ad26" "c69211d8567a0c5fa14b81c4cd08c4a458db7904c10d95f75d6ecd1b8baf19bd" "a53714de04cd4fdb92ed711ae479f6a1d7d5f093880bfd161467c3f589725453" "39dd7106e6387e0c45dfce8ed44351078f6acd29a345d8b22e7b8e54ac25bac4" "cab317d0125d7aab145bc7ee03a1e16804d5abdfa2aa8738198ac30dc5f7b569" "0c311fb22e6197daba9123f43da98f273d2bfaeeaeb653007ad1ee77f0003037" "e16a771a13a202ee6e276d06098bc77f008b73bbac4d526f160faa2d76c1dd0e" "d677ef584c6dfc0697901a44b885cc18e206f05114c8a3b7fde674fce6180879" "8aebf25556399b58091e533e455dd50a6a9cba958cc4ebb0aab175863c25b9a4" default))
 '(default-frame-alist '((width . 120) (height . 45)))
 '(default-input-method "latin-postfix")
 '(delete-old-versions t)
 '(delete-selection-mode t)
 '(describe-char-unidata-list
   '(name old-name general-category decomposition mirrored iso-10646-comment))
 '(desktop-save-mode nil)
 '(develock-auto-enable nil)
 '(diary-file "~/.diary")
 '(diff-switches "-du")
 '(dired-auto-revert-buffer t)
 '(dired-dwim-target t)
 '(dired-isearch-filenames 'dwim)
 '(dired-kept-versions 3)
 '(dired-listing-switches "-Alh --time-style=long-iso --group-directories-first")
 '(dired-recursive-copies 'always)
 '(dired-use-ls-dired t)
 '(dired-x-hands-off-my-keys nil)
 '(display-buffer-alist
   '(("^\\*shell"
      (display-buffer-reuse-window display-buffer-same-window)
      (nil))))
 '(display-time-24hr-format t)
 '(display-time-day-and-date t)
 '(display-time-default-load-average 0)
 '(display-time-format "%a %m‒%d %H:%M ")
 '(display-time-interval 30)
 '(display-time-mode t)
 '(dnd-open-file-other-window t)
 '(ecb-activate-before-layout-draw-hook
   '((lambda nil
       (modify-frame-parameters
        (selected-frame)
        '((fullscreen . maximized))))))
 '(ecb-activation-selects-ecb-frame-if-already-active t)
 '(ecb-auto-expand-tag-tree 'all)
 '(ecb-compile-window-height 0.2)
 '(ecb-compile-window-temporally-enlarge 'after-selection)
 '(ecb-compile-window-width 'edit-window)
 '(ecb-enlarged-compilation-window-max-height 'best)
 '(ecb-ignore-pop-up-frames 'always)
 '(ecb-layout-name "left-symboldef")
 '(ecb-new-ecb-frame t)
 '(ecb-options-version "2.50")
 '(ecb-scroll-other-window-scrolls-compile-window nil)
 '(ecb-show-sources-in-directories-buffer 'never)
 '(ecb-source-path
   '(("/home/cesar/work/linux-home" "Remote dots")
     ("/home/cesar/Projects/nmax_compiler" "Flex Logix SW compiler")
     ("/home/cesar/Projects/weight-generation-tool" "Flex Logix SW wgt")))
 '(ecb-tip-of-the-day nil)
 '(ecb-toggle-layout-sequence
   '("left-symboldef" "leftright-analyse" "leftright1" "left1"))
 '(ecb-version-check nil)
 '(ecb-windows-width 0.2)
 '(ede-project-directories nil)
 '(edebug-print-length nil)
 '(ediff-custom-diff-options "-U10")
 '(ediff-highlight-all-diffs nil)
 '(ediff-keep-variants nil)
 '(ediff-prefer-iconified-control-frame t)
 '(ediff-show-clashes-only t)
 '(ediff-split-window-function 'split-window-horizontally)
 '(ediff-use-toolbar-p nil)
 '(ediff-window-setup-function 'ediff-setup-windows-plain)
 '(enable-recursive-minibuffers t)
 '(explicit-shell-file-name "bash")
 '(fci-rule-color "#073642")
 '(fill-column 80)
 '(filladapt-turn-on-mode-hooks
   '(text-mode-hook awk-mode-hook lisp-mode-hook emacs-lisp-mode-hook perl-mode-hook))
 '(find-ls-option
   '("-exec ls -Dlb --time-style=long-iso --group-directories-first {} +" . "-Dlb --time-style=long-iso --group-directories-first"))
 '(focus-follows-mouse t)
 '(font-lock-maximum-size nil)
 '(foreground-color "#cccccc")
 '(frame-background-mode nil)
 '(garbage-collection-messages t)
 '(gc-cons-percentage 0.1)
 '(gc-cons-threshold 800000)
 '(gdb-enable-debug nil)
 '(gdb-many-windows t)
 '(gdb-max-frames 64)
 '(gdb-show-main t)
 '(gdb-speedbar-auto-raise t)
 '(gdb-stack-buffer-addresses t)
 '(gdb-use-separate-io-buffer t)
 '(ggtags-enable-navigation-keys nil)
 '(ggtags-global-treat-text t)
 '(global-ede-mode t)
 '(global-font-lock-mode t nil (font-lock))
 '(global-hl-line-mode nil)
 '(global-hl-line-sticky-flag nil)
 '(global-semantic-decoration-mode t)
 '(global-semantic-highlight-edits-mode t)
 '(global-semantic-highlight-func-mode t)
 '(global-semantic-idle-breadcrumbs-mode t nil (semantic/idle))
 '(global-semantic-idle-completions-mode t nil (semantic/idle))
 '(global-semantic-idle-local-symbol-highlight-mode t nil (semantic/idle))
 '(global-semantic-idle-scheduler-mode t)
 '(global-semantic-idle-summary-mode t)
 '(global-semantic-mru-bookmark-mode t)
 '(global-semanticdb-minor-mode t)
 '(gnutls-min-prime-bits 2048)
 '(gnutls-verify-error t)
 '(grep-command "grep -inHR -e ")
 '(grep-find-template
   "find . <X> -type f <F> -exec grep <C> -n -e <R> /dev/null {} +")
 '(grep-template "grep <X> <C> -n -e <R> <F>")
 '(highlight-changes-colors '("#d33682" "#6c71c4"))
 '(highlight-symbol-colors
   '("#98695021d64f" "#484f5a50ffff" "#9ae80000c352" "#00000000ffff" "#98695021d64f" "#9ae80000c352" "#484f5a50ffff"))
 '(highlight-symbol-foreground-color "#93a1a1")
 '(highlight-tail-colors
   '(("#073642" . 0)
     ("#5b7300" . 20)
     ("#007d76" . 30)
     ("#0061a8" . 50)
     ("#866300" . 60)
     ("#992700" . 70)
     ("#a00559" . 85)
     ("#073642" . 100)))
 '(hl-bg-colors
   '("#866300" "#992700" "#a7020a" "#a00559" "#243e9b" "#0061a8" "#007d76" "#5b7300"))
 '(hl-fg-colors
   '("#002b36" "#002b36" "#002b36" "#002b36" "#002b36" "#002b36" "#002b36" "#002b36"))
 '(hl-paren-colors '("#2aa198" "#b58900" "#268bd2" "#6c71c4" "#859900"))
 '(home-end-enable t)
 '(horizontal-scroll-bar-mode nil)
 '(indent-tabs-mode nil)
 '(indicate-buffer-boundaries 'left)
 '(indicate-empty-lines t)
 '(inferior-lisp-program "sbcl" t)
 '(inhibit-startup-echo-area-message "cesar")
 '(inhibit-startup-screen t)
 '(initial-scratch-message nil)
 '(isearch-allow-scroll t)
 '(line-move-visual nil)
 '(line-number-display-limit-width 512)
 '(list-directory-brief-switches "-ACF --group-directories-first ")
 '(list-directory-verbose-switches "-lgaF --time-style=long-iso  --group-directories-first")
 '(load-prefer-newer t t)
 '(ls-lisp-dirs-first t)
 '(ls-lisp-format-time-list '("%Y-%m-%d %H:%M" "%Y-%m-%d     "))
 '(lsp-ui-doc-border "#93a1a1")
 '(magit-diff-refine-hunk t)
 '(magit-log-margin '(t "%Y-%m-%d %H:%M " magit-log-margin-width t 18))
 '(magit-repository-directories '(("/work" . 2)))
 '(magit-save-repository-buffers 'dontask)
 '(magit-view-git-manual-method 'man)
 '(mail-archive-file-name "~/mail/babyl/OUT")
 '(mail-use-rfc822 t)
 '(mouse-autoselect-window -0.2)
 '(mouse-wheel-mode t nil (mwheel))
 '(mouse-yank-at-point nil)
 '(multishell-activate-command-key nil)
 '(multishell-command-key "\30!")
 '(network-security-level 'high)
 '(nrepl-message-colors
   '("#dc322f" "#cb4b16" "#b58900" "#5b7300" "#b3c34d" "#0061a8" "#2aa198" "#d33682" "#6c71c4"))
 '(nsm-save-host-names t)
 '(nxml-slash-auto-complete-flag t)
 '(org-agenda-restore-windows-after-quit t)
 '(org-catch-invisible-edits 'show)
 '(org-completion-use-ido t)
 '(org-export-backends
   '(ascii html icalendar latex man md org texinfo freemind groff))
 '(org-outline-path-complete-in-steps nil)
 '(org-pretty-entities t)
 '(org-startup-indented t)
 '(org-use-sub-superscripts '{})
 '(p4-check-empty-diffs t)
 '(package-archives
   '(("org" . "https://orgmode.org/elpa/")
     ("melpa" . "https://melpa.org/packages/")
     ("gnu" . "https://elpa.gnu.org/packages/")))
 '(package-selected-packages
   '(0blayout tramp-docker docker docstr docopt clhs ac-R ac-c-headers ac-emoji ac-etags ac-math ac-octave ac-python ac-slime ada-mode ada-ref-man aes aggressive-fill-paragraph all all-ext anaconda-mode ant anything-exuberant-ctags anything-git-files anything-git-grep anything-replace-string apt-utils ascii auto-complete-auctex auto-complete-c-headers auto-complete-exuberant-ctags auto-complete-pcmp autodisass-llvm-bitcode backtrace-mode beacon bigint bison-mode button-lock cedit charmap chess cider cl-format cl-lib-highlight clang-format cmake-font-lock cmake-mode cobol-mode codesearch common-lisp-snippets company-c-headers company-ess company-inf-ruby company-math company-quickhelp concurrent context-coloring cperl-mode csharp-mode csv-mode csv-nav ctable ctags ctags-update cuda-mode dash-functional debian-el dict-tree diff-hl diffview dircmp dired-hacks-utils dired-narrow dired-rsync dired-toggle-sudo docker-api docker-compose-mode dockerfile-mode dpkg-dev-el dropbox dts-mode dynamic-ruler ecb edebug-x ediprolog edit-at-point edit-list editorconfig-charset-extras editorconfig-custom-majormode editorconfig-domain-specific eldoc-cmake eldoc-eval eldoc-overlay elog epl ess-R-data-view ess-R-object-popup ess-smart-underscore f fasm-mode figlet fill-column-indicator flycheck flymake flymake-python-pyflakes fm form-feed ggtags gh ghub git gitattributes-mode gitconfig-mode gitignore-mode glsl-mode graphql gscholar-bibtex gtags gxref header2 heap hide-comnt hide-lines ht http-post-simple hydra indent-guide inf-ruby inline-docs interval-tree ipython itail j-mode javadoc-help javadoc-lookup jira json-mode json-reformat json-snatcher julia-mode kv latex-extra latex-preview-pane let-alist lexbind-mode lib-requires lisp-extra-font-lock list-utils llvm-mode log4e logito lv magit-filenotify magit-find-file magit-gh-pulls magit-gitflow magit-popup magit-tramp markdown-mode markdown-toc marshal math-symbol-lists memory-usage minimap mmt move-dup multi-term multishell name-this-color nasm-mode nav-flash ninja-mode noflet oauth oberon opencl-mode org-ac org-bullets org-cliplink org-context org-dashboard org-download org-jira org-journal org-make-toc org-mime org-pandoc org-plus-contrib orgtbl-show-header ov p4 pandoc-mode paredit paredit-everywhere paredit-menu path-headerline-mode pcache pcre2el pcsv peep-dired perl-completion perl-myvar pkg-info pod-mode pos-tip pp+ preproc-font-lock prolog px python-info python-mode python3-info pythonic quarter-plane queue quick-peek rainbow-mode relative-line-numbers ruby-electric ruby-end ruby-hash-syntax ruby-interpolation ruby-test-mode ruby-tools s-buffer sane-term sed-mode shell-command shell-here shell-toggle sicp slime slime-company sml-mode solarized-theme spark sparkline spinner srefactor ssh ssh-config-mode stream strie string-edit string-utils sudo-ext syntax-subword syslog-mode systemd systemtap-mode tNFA tabbar tablist tdd thing-cmds tramp-term tree-sitter tree-sitter-indent treepy trie undo-tree uniquify-files uuid vdiff vector-utils viewer vimrc-mode visible-mark vkill vlf wget wiki wiki-nav wisi xcscope xml-rpc yaml-mode yasnippet yaxception))
 '(prog-mode-hook '((lambda nil (form-feed-mode 1))))
 '(python-shell-interpreter "python")
 '(recentf-mode t)
 '(require-final-newline nil)
 '(rmail-file-name "~/mail/babyl/RMAIL")
 '(safe-local-variable-values '((ggtags-process-environment)))
 '(save-place-mode t)
 '(savehist-mode nil)
 '(scroll-bar-mode nil)
 '(scroll-conservatively 99)
 '(scroll-preserve-screen-position t)
 '(search-slow-window-lines 3)
 '(semantic-c-dependency-system-include-path
   '("/usr/include/c++/9" "/usr/include/x86_64-linux-gnu/c++/9" "/usr/include/c++/9/backward" "/usr/lib/gcc/x86_64-linux-gnu/9/include" "/usr/local/include" "/usr/lib/gcc/x86_64-linux-gnu/9/include-fixed" "/usr/include/x86_64-linux-gnu" "/usr/include" "/usr/include/libxml2"))
 '(semantic-decoration-styles
   '(("semantic-decoration-on-includes" . t)
     ("semantic-tag-boundary" . t)))
 '(semantic-default-submodes
   '(global-semantic-highlight-func-mode global-semantic-decoration-mode global-semantic-idle-completions-mode global-semantic-idle-scheduler-mode global-semanticdb-minor-mode global-semantic-idle-summary-mode global-semantic-mru-bookmark-mode))
 '(semantic-mode t)
 '(semantic-symref-auto-expand-results t)
 '(semantic-symref-results-summary-function 'semantic-format-tag-canonical-name)
 '(set-mark-command-repeat-pop t)
 '(sh-basic-offset 8)
 '(sh-indent-for-case-alt '+)
 '(sh-indent-for-case-label 0)
 '(sh-indentation 0)
 '(shell-popd-regexp "popd\\|-")
 '(shell-pushd-regexp "pushd\\|+")
 '(show-paren-mode t)
 '(show-paren-style 'parenthesis)
 '(show-trailing-whitespace nil)
 '(size-indication-mode t)
 '(slime-kill-without-query-p t)
 '(slime-net-coding-system 'utf-8-unix)
 '(smartrep-mode-line-active-bg (solarized-color-blend "#859900" "#073642" 0.2))
 '(solarized-distinct-fringe-background t)
 '(solarized-high-contrast-mode-line nil)
 '(speedbar-fetch-etags-command "/usr/bin/ctags -eR")
 '(speedbar-show-unknown-files t)
 '(spice-output-local "Gnucap")
 '(spice-simulator "Gnucap")
 '(spice-waveform-viewer "Gwave")
 '(tab-always-indent 'complete)
 '(tags-revert-without-query t)
 '(term-default-bg-color "#002b36")
 '(term-default-fg-color "#839496")
 '(text-mode-hook
   '(turn-on-auto-fill
     (lambda nil
       (form-feed-mode 1))
     cq-text-mode text-mode-hook-identify))
 '(tool-bar-mode nil)
 '(truncate-lines t)
 '(uniquify-buffer-name-style 'post-forward-angle-brackets nil (uniquify))
 '(uniquify-trailing-separator-p t)
 '(use-file-dialog t)
 '(user-full-name "César Quiroz")
 '(user-mail-address "cesar.quiroz@gmail.com")
 '(vc-annotate-background nil)
 '(vc-annotate-background-mode nil)
 '(vc-annotate-color-map
   '((20 . "#dc322f")
     (40 . "#ffffa21b0000")
     (60 . "#ffffd2170000")
     (80 . "#b58900")
     (100 . "#fffffffe0000")
     (120 . "#fffffffe0000")
     (140 . "#fffffffe0000")
     (160 . "#fffffffe0000")
     (180 . "#859900")
     (200 . "#dc61ffb77bfe")
     (220 . "#c516ffa79f16")
     (240 . "#a726ffaac017")
     (260 . "#7bfcffc6e035")
     (280 . "#2aa198")
     (300 . "#0000fffffffe")
     (320 . "#0000fffffffe")
     (340 . "#0000fffffffe")
     (360 . "#268bd2")))
 '(vc-annotate-very-old-color nil)
 '(vc-follow-symlinks t)
 '(verilog-highlight-grouping-keywords t)
 '(visible-bell t)
 '(warning-suppress-types '((emacs) (bytecomp)))
 '(wdired-allow-to-change-permissions t)
 '(wdired-use-dired-vertical-movement 'sometimes)
 '(weechat-color-list
   '(unspecified "#002b36" "#073642" "#a7020a" "#dc322f" "#5b7300" "#859900" "#866300" "#b58900" "#0061a8" "#268bd2" "#a00559" "#d33682" "#007d76" "#2aa198" "#839496" "#657b83"))
 '(whitespace-style
   '(face trailing tabs spaces lines-tail newline empty indentation space-after-tab space-before-tab space-mark tab-mark newline-mark))
 '(windmove-wrap-around t)
 '(x-gtk-show-hidden-files t)
 '(xref-marker-ring-length 32 t)
 '(xterm-color-names
   ["#073642" "#dc322f" "#859900" "#b58900" "#268bd2" "#d33682" "#2aa198" "#eee8d5"])
 '(xterm-color-names-bright
   ["#002b36" "#cb4b16" "#586e75" "#657b83" "#839496" "#6c71c4" "#93a1a1" "#fdf6e3"])
 '(yank-pop-change-selection t))
(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(default ((t (:family "Ubuntu Mono" :foundry "DAMA" :slant normal :weight normal :height 143 :width normal))))
 '(org-level-3 ((t (:inherit variable-pitch :foreground "#268bd2" :height 1.0))))
 '(org-level-4 ((t (:inherit variable-pitch :foreground "#b58900" :height 1.0))))
 '(region ((t (:inherit hightlight :extend t :background "color-235"))))
 '(tty-menu-disabled-face ((t (:background "color-242" :inverse-video t))))
 '(tty-menu-enabled-face ((t (:inverse-video t :weight bold))))
 '(tty-menu-selected-face ((t (:inverse-video t :underline t)))))
