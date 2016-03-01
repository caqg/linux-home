;;;; -*- Emacs-Lisp -*- GNU Emacs Start-Up options

;;; 2015-09-16 05:21:08UT (cesar@cesar-U64-14):
;;; 0.8 MB between gcs is too little nowadays
;;; hint at reddit from /u/bahblah
;;; https://www.reddit.com/r/emacs/comments/3kqt6e/2_easy_little_known_steps_to_speed_up_emacs_start/
(setq gc-cons-threshold (* 1024 1024 16))

(let ((file-name-handler-alist nil)
      (gc-cons-threshold (* 1024 1024 128)))

  (load-file "~/.emacs.d/init-legacy.el")
  (message "Done loading legacy init")

  (load-library "cl-lib")
  (add-to-list 'load-path "~/.emacs.d/lisp")

  (load-library "cq-workarounds")
  (global-set-key [(meta z)] 'cq-zap-up-to-char)
  (global-set-key [(meta Z)] 'zap-to-char) ;stock, not workaround

  (load-library "cq-edit-utils")
  (global-set-key "\C-x$" 'cq/set-selective-display)

  (load-library "cq-file-hooks")
  (add-hook 'before-save-hook (lambda ()
                                ;; clean up source code, but nothing else
                                (when (and
                                       (derived-mode-p 'prog-mode)
                                       (not (derived-mode-p 'makefile-mode))
                                  (cq/trim-whitespace)))))

  (load-library "cq-minor-mode-utils")
  (global-set-key "\^Zs" 'cq/flip-scroll-bar-modes)

  (load-library "cq-cedet-ede-ecb-utils")
  (global-set-key "\^ZL" 'cq/load-ede-project-and-tags)

  (add-hook 'dired-load-hook
            (lambda ()
              ;; Bind dired-x-find-file.
              (setq dired-x-hands-off-my-keys nil)
              (load "dired-x")))

  (package-initialize)

  (filesets-init)

  (require 'slime-autoloads)
  (slime-setup '(slime-asdf
                 slime-banner
                 slime-editing-commands
                 slime-fancy
                 slime-fancy-inspector
                 ;;slime-highlight-edits
                 slime-mdot-fu
                 slime-mrepl
                 slime-references
                 slime-tramp
                 ;;slime-typeout-frame
                 ))
  (global-set-key "\C-cs" 'slime-selector)
  (add-hook 'slime-repl-mode-hook 'set-balanced-insertions)

  (which-function-mode 1)
  (pending-delete-mode t)
  (electric-indent-mode -1)

  (require 'multishell)

  (require 'magit)
  (global-set-key "\C-xg" 'magit-status)
  (global-set-key "\C-x\M-g" 'magit-dispatch-popup)
  (global-magit-file-mode 1)

  (require 'p4)

  (require 'tramp)

  ;; Known to work at least since v23, again don't know if before.
  ;; (defun gamegrid-add-score-with-update-game-score-1( file target score ))

  (require 'cl-lib-highlight)
  (cl-lib-highlight-initialize)
  (cl-lib-highlight-warn-cl-initialize)

  (require 'windmove)
  (global-set-key (kbd "C-c <right>") 'windmove-right)
  (global-set-key (kbd "C-c <left>")  'windmove-left)
  (global-set-key (kbd "C-c <up>")    'windmove-up)
  (global-set-key (kbd "C-c <down>")  'windmove-down)


  (require 'dired-x)
  (require 'dired-toggle-sudo)
  (define-key dired-mode-map (kbd "C-c C-s") 'dired-toggle-sudo)

  (require 'xcscope)
  (cscope-setup)

  (require 'gtags)

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
  (require 'grep)
  (require 'paren)
  (require 'parenface)
  (require 'tabbar)
  (require 'time)

  ;; tabbar (already initialized)
  (defadvice tabbar-add-tab (after cq/tabbar-add-tab-sorted
                                   (tabset object &optional append))
    "Present the tab bar tab sets in ascending order by buffer name."
    (let* ((tabs (tabbar-tabs tabset))
           (sorted (sort tabs (lambda (a b)
                                (string< (buffer-name (car a))
                                         (buffer-name (car b)))))))
      (set tabset sorted)))

  ;; Color theme
  (cond ((and (>= emacs-major-version 25) window-system)
         (load-theme 'solarized t t)
         (load-theme 'solarized-light t t)
         (load-theme 'solarized-dark t t)
         (require 'cq-solarized-theme-init)))

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
  (require 'ecb)                        ;last require, so at end of Tools menu
  (global-semantic-mru-bookmark-mode 1)

  (if window-system
      (ad-activate 'tabbar-add-tab 'compile-it))

  (setq-default ediff-auto-refine 'on)

  (when (memq window-system (list 'x 'w32))
    (set-default-xtitle))
  (when window-system
    (cq/adjust-paren-face-fg nil))

  (add-hook 'tty-setup-hook (lambda ()
                              (tabbar-mode -1)
                              (menu-bar-mode -1)))

  (unless window-system (normal-erase-is-backspace-mode 0)))

;;;end ~/.emacs.d/init.el -- don't edit beyond



(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(Man-switches "-a")
 '(adaptive-fill-mode t)
 '(align-indent-before-aligning t)
 '(auto-mode-case-fold nil)
 '(background-color "#202020")
 '(background-mode dark)
 '(backup-by-copying-when-linked t)
 '(beacon-mode nil)
 '(c++-font-lock-extra-types
   (quote
    ("\\sw+_t" "FILE" "lconv" "tm" "va_list" "jmp_buf" "istream" "istreambuf" "ostream" "ostreambuf" "ifstream" "ofstream" "fstream" "strstream" "strstreambuf" "istrstream" "ostrstream" "ios" "string" "rope" "list" "slist" "deque" "vector" "bit_vector" "set" "multiset" "map" "multimap" "hash" "hash_set" "hash_multiset" "hash_map" "hash_multimap" "stack" "queue" "priority_queue" "type_info" "iterator" "const_iterator" "reverse_iterator" "const_reverse_iterator" "reference" "const_reference" "[[:upper:]]\\\\sw*[[:lower:]]\\\\sw")))
 '(c-tab-always-indent nil)
 '(calendar-date-style (quote iso))
 '(calendar-mark-diary-entries-flag t)
 '(calendar-mark-holidays-flag t)
 '(calendar-week-start-day 1)
 '(case-fold-search t)
 '(column-number-mode t)
 '(compilation-scroll-output t)
 '(compile-command "time -p make -j8 BUILD=debug")
 '(completion-auto-help (quote lazy))
 '(cscope-close-window-after-select t)
 '(cscope-option-do-not-update-database t)
 '(cscope-option-use-inverted-index t)
 '(current-language-environment "UTF-8")
 '(cursor-color "#cccccc")
 '(custom-safe-themes
   (quote
    ("cb8d13429234ff2a8700da4db9bdf6b952c1b54b906a1aad2d0d98317c5b0224" "889a93331bc657c0f05a04b8665b78b3c94a12ca76771342cee27d6605abcd0e" "a8245b7cc985a0610d71f9852e9f2767ad1b852c2bdea6f4aadc12cce9c4d6d0" "4aee8551b53a43a883cb0b7f3255d6859d766b6c5e14bcb01bed572fcbef4328" "8db4b03b9ae654d4a57804286eb3e332725c84d7cdab38463cb6b97d5762ad26" "c69211d8567a0c5fa14b81c4cd08c4a458db7904c10d95f75d6ecd1b8baf19bd" "a53714de04cd4fdb92ed711ae479f6a1d7d5f093880bfd161467c3f589725453" "39dd7106e6387e0c45dfce8ed44351078f6acd29a345d8b22e7b8e54ac25bac4" "cab317d0125d7aab145bc7ee03a1e16804d5abdfa2aa8738198ac30dc5f7b569" "0c311fb22e6197daba9123f43da98f273d2bfaeeaeb653007ad1ee77f0003037" "e16a771a13a202ee6e276d06098bc77f008b73bbac4d526f160faa2d76c1dd0e" "d677ef584c6dfc0697901a44b885cc18e206f05114c8a3b7fde674fce6180879" "8aebf25556399b58091e533e455dd50a6a9cba958cc4ebb0aab175863c25b9a4" default)))
 '(default-frame-alist (quote ((width . 90) (height . 40))))
 '(default-input-method "latin-postfix")
 '(delete-old-versions t)
 '(delete-selection-mode t)
 '(describe-char-unidata-list
   (quote
    (name old-name general-category decomposition mirrored iso-10646-comment)))
 '(develock-auto-enable nil)
 '(diary-file "~/.diary")
 '(diff-switches "-du")
 '(dired-auto-revert-buffer t)
 '(dired-dwim-target t)
 '(dired-isearch-filenames (quote dwim))
 '(dired-kept-versions 3)
 '(dired-listing-switches "-Alh --time-style=long-iso --group-directories-first")
 '(dired-use-ls-dired t)
 '(dired-x-hands-off-my-keys nil)
 '(display-buffer-alist
   (quote
    (("^\\*shell"
      (display-buffer-reuse-window display-buffer-same-window)
      (nil)))))
 '(display-time-24hr-format t)
 '(display-time-day-and-date t)
 '(display-time-default-load-average 0)
 '(display-time-format "%a %m‒%d %H:%M ")
 '(display-time-interval 30)
 '(display-time-mode t)
 '(dnd-open-file-other-window t)
 '(ecb-activate-before-layout-draw-hook
   (quote
    ((lambda nil
       (modify-frame-parameters
        (selected-frame)
        (quote
         ((fullscreen . maximized))))))))
 '(ecb-activate-hook
   (quote
    (ecb-eshell-auto-activate-hook
     (lambda nil
       (scroll-bar-mode -1)
       (horizontal-scroll-bar-mode -1)
       (ecb-redraw-layout)))))
 '(ecb-activation-selects-ecb-frame-if-already-active t)
 '(ecb-auto-expand-tag-tree (quote all))
 '(ecb-compile-window-height 0.2)
 '(ecb-compile-window-temporally-enlarge (quote after-selection))
 '(ecb-compile-window-width (quote edit-window))
 '(ecb-enlarged-compilation-window-max-height (quote best))
 '(ecb-ignore-pop-up-frames (quote always))
 '(ecb-layout-name "leftright-analyse")
 '(ecb-new-ecb-frame t)
 '(ecb-options-version "2.40")
 '(ecb-scroll-other-window-scrolls-compile-window nil)
 '(ecb-show-sources-in-directories-buffer (quote never))
 '(ecb-source-path
   (quote
    (("/home/cesar" "Home")
     ("/work/Innergy/Software" "Software")
     ("/work/Innergy/Hardware" "Hardware")
     ("/" "/"))))
 '(ecb-tip-of-the-day nil)
 '(ecb-toggle-layout-sequence (quote ("leftright-analyse" "leftright1" "left1")))
 '(ecb-version-check nil)
 '(ecb-windows-width 0.2)
 '(ede-project-directories (quote ("/work/stable-linux")))
 '(ediff-custom-diff-options "-U10")
 '(ediff-highlight-all-diffs nil)
 '(ediff-keep-variants nil)
 '(ediff-prefer-iconified-control-frame t)
 '(ediff-show-clashes-only t)
 '(ediff-split-window-function (quote split-window-horizontally))
 '(ediff-use-toolbar-p nil)
 '(ediff-window-setup-function (quote ediff-setup-windows-plain))
 '(enable-recursive-minibuffers t)
 '(explicit-shell-file-name "bash")
 '(fill-column 78)
 '(filladapt-turn-on-mode-hooks
   (quote
    (text-mode-hook awk-mode-hook lisp-mode-hook emacs-lisp-mode-hook perl-mode-hook)))
 '(find-ls-option
   (quote
    ("-exec ls -Dlb --time-style=long-iso --group-directories-first {} +" . "-Dlb --time-style=long-iso --group-directories-first")))
 '(focus-follows-mouse t)
 '(font-lock-maximum-size nil)
 '(foreground-color "#cccccc")
 '(frame-background-mode nil)
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
 '(global-semantic-decoration-mode t)
 '(global-semantic-highlight-func-mode t)
 '(global-semantic-idle-completions-mode t nil (semantic/idle))
 '(global-semantic-idle-scheduler-mode t)
 '(global-semantic-idle-summary-mode t)
 '(global-semantic-mru-bookmark-mode t)
 '(grep-command "grep -inHR -e ")
 '(grep-find-template
   "find . <X> -type f <F> -exec grep <C> -n -e <R> /dev/null {} +")
 '(grep-template "grep <X> <C> -n -e <R> <F>")
 '(home-end-enable t)
 '(horizontal-scroll-bar-mode nil)
 '(indent-tabs-mode nil)
 '(indicate-buffer-boundaries (quote left))
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
 '(load-prefer-newer t)
 '(ls-lisp-dirs-first t)
 '(ls-lisp-format-time-list (quote ("%Y-%m-%d %H:%M" "%Y-%m-%d     ")))
 '(magit-diff-refine-hunk t)
 '(magit-repository-directories (quote ("/work")))
 '(magit-status-sections-hook
   (quote
    (magit-insert-status-headers magit-insert-repo-header magit-insert-remote-header magit-insert-user-header magit-insert-merge-log magit-insert-rebase-sequence magit-insert-am-sequence magit-insert-sequencer-sequence magit-insert-bisect-output magit-insert-bisect-rest magit-insert-bisect-log magit-insert-untracked-files magit-insert-unstaged-changes magit-insert-staged-changes magit-insert-stashes magit-insert-unpulled-commits magit-insert-unpushed-commits)))
 '(mail-archive-file-name "~/mail/babyl/OUT")
 '(mail-use-rfc822 t)
 '(menu-bar-mode nil)
 '(mouse-autoselect-window -0.2)
 '(mouse-wheel-mode t nil (mwheel))
 '(mouse-yank-at-point nil)
 '(multishell-activate-command-key t)
 '(multishell-command-key "!")
 '(normal-erase-is-backspace (quote maybe))
 '(nxml-slash-auto-complete-flag t)
 '(org-agenda-restore-windows-after-quit t)
 '(org-catch-invisible-edits (quote show))
 '(org-completion-use-ido t)
 '(org-export-backends
   (quote
    (ascii html icalendar latex man md org texinfo freemind groff)))
 '(org-outline-path-complete-in-steps nil)
 '(org-pretty-entities t)
 '(org-startup-indented t)
 '(org-use-sub-superscripts (quote {}))
 '(p4-check-empty-diffs t)
 '(package-archives
   (quote
    (("gnu" . "http://elpa.gnu.org/packages/")
     ("org" . "http://orgmode.org/elpa/")
     ("melpa" . "http://melpa.org/packages/")
     ("marmalade" . "http://marmalade-repo.org/packages/"))))
 '(package-selected-packages
   (quote
    (p4 srefactor ada-mode wisi seq ctags ctags-update auto-complete auto-complete-pcmp all async dash dired-hacks-utils ess git-commit heap hide-comnt hide-lines list-utils paredit queue s slime trie with-editor j-mode dts-mode magit magit-popup stream minimap memory-usage quarter-plane cmake-font-lock common-lisp-snippets dynamic-ruler figlet fill-column-indicator fm indent-guide itail json-mode json-reformat latex-extra latex-preview-pane lexbind-mode lisp-extra-font-lock multi-term name-this-color oberon org-magit sicp csv-mode let-alist multishell org-plus-contrib autodisass-llvm-bitcode llvm-mode magit-filenotify magit-find-file magit-gh-pulls magit-gitflow magit-tramp ac-R ac-etags ac-math ac-octave ac-python ac-slime anaconda-mode cl-lib-highlight clang-format beacon glsl-mode python3-info ac-emoji solarized-theme mmt fasm-mode edit-at-point org-dashboard ac-c-headers ada-ref-man aes aggressive-fill-paragraph aggressive-indent all-ext ant anything-exuberant-ctags anything-git-files anything-git-grep anything-replace-string apt-utils auctex auto-complete-auctex auto-complete-c-headers auto-complete-exuberant-ctags backtrace-mode bigint bison-mode cedit charmap cmake-mode codesearch company-c-headers company-ess company-inf-ruby company-math company-quickhelp cperl-mode csharp-mode csv-nav dict-tree dircmp dired-narrow dired-toggle-sudo ecb edebug-x ediprolog edit-list ess-R-data-view ess-R-object-popup ess-smart-underscore form-feed ggtags git gitattributes-mode gitconfig-mode gitignore-mode gscholar-bibtex gtags header2 ht http-post-simple hydra interval-tree ipython javadoc-help javadoc-lookup jira kv lib-requires markdown-toc move-dup nasm-mode org org-ac org-bullets org-cliplink org-context org-download org-jira org-journal org-mime org-pandoc orgtbl-show-header pandoc-mode paredit-everywhere paredit-menu path-headerline-mode pcsv peep-dired perl-completion perl-myvar pod-mode pos-tip pp+ preproc-font-lock prolog px python-info python-mode rainbow-mode relative-line-numbers ruby-electric ruby-end ruby-hash-syntax ruby-interpolation ruby-test-mode ruby-tools s-buffer sane-term shell-command shell-here shell-toggle slime-annot sml-mode sparkline ssh ssh-config-mode strie string-edit string-utils sudo-ext syntax-subword syslog-mode systemtap-mode tabbar tdd thing-cmds undo-tree uuid vector-utils viewer vimrc-mode vkill vlf wget wiki wiki-nav xcscope xml-rpc yaoddmuse)))
 '(prog-mode-hook (quote ((lambda nil (form-feed-mode 1)))))
 '(recentf-mode t)
 '(require-final-newline nil)
 '(rmail-file-name "~/mail/babyl/RMAIL")
 '(safe-local-variable-values (quote ((ggtags-process-environment))))
 '(scroll-bar-mode nil)
 '(scroll-conservatively 99)
 '(scroll-preserve-screen-position t)
 '(search-slow-window-lines 3)
 '(semantic-c-dependency-system-include-path
   (quote
    ("/usr/include/c++/5" "/usr/include/x86_64-linux-gnu/c++/5" "/usr/include/c++/5/backward" "/usr/lib/gcc/x86_64-linux-gnu/5/include" "/usr/local/include" "/usr/lib/gcc/x86_64-linux-gnu/5/include-fixed" "/usr/include/x86_64-linux-gnu" "/usr/include" "/usr/include/libxml2")))
 '(semantic-decoration-styles
   (quote
    (("semantic-decoration-on-includes" . t)
     ("semantic-decoration-on-protected-members")
     ("semantic-decoration-on-private-members")
     ("semantic-tag-boundary"))))
 '(semantic-default-submodes
   (quote
    (global-semantic-highlight-func-mode global-semantic-decoration-mode global-semantic-idle-completions-mode global-semantic-idle-scheduler-mode global-semanticdb-minor-mode global-semantic-idle-summary-mode global-semantic-mru-bookmark-mode)))
 '(semantic-mode t)
 '(semantic-symref-auto-expand-results t)
 '(semantic-symref-results-summary-function (quote semantic-format-tag-canonical-name))
 '(set-mark-command-repeat-pop t)
 '(sh-basic-offset 8)
 '(sh-indent-for-case-alt (quote +))
 '(sh-indent-for-case-label 0)
 '(sh-indentation 0)
 '(shell-popd-regexp "popd\\|-")
 '(shell-pushd-regexp "pushd\\|+")
 '(show-paren-mode t)
 '(show-paren-style (quote parenthesis))
 '(show-trailing-whitespace nil)
 '(size-indication-mode t)
 '(slime-kill-without-query-p t)
 '(slime-net-coding-system (quote utf-8-unix))
 '(speedbar-fetch-etags-command "/usr/bin/ctags -eR")
 '(speedbar-show-unknown-files t)
 '(spice-output-local "Gnucap")
 '(spice-simulator "Gnucap")
 '(spice-waveform-viewer "Gwave")
 '(tab-always-indent (quote complete))
 '(tabbar-mode t nil (tabbar))
 '(tabbar-mwheel-mode t nil (tabbar))
 '(text-mode-hook
   (quote
    (turn-on-auto-fill
     (lambda nil
       (form-feed-mode 1))
     cq-text-mode text-mode-hook-identify)))
 '(tool-bar-mode nil nil (tool-bar))
 '(truncate-lines t)
 '(uniquify-buffer-name-style (quote post-forward-angle-brackets) nil (uniquify))
 '(uniquify-trailing-separator-p t)
 '(use-file-dialog t)
 '(user-full-name "César Quiroz")
 '(user-mail-address "cesar.quiroz@gmail.com")
 '(visible-bell t)
 '(wdired-allow-to-change-permissions t)
 '(wdired-use-dired-vertical-movement (quote sometimes))
 '(whitespace-style
   (quote
    (face trailing tabs spaces lines-tail newline empty indentation space-after-tab space-before-tab space-mark tab-mark newline-mark)))
 '(windmove-wrap-around t)
 '(x-gtk-show-hidden-files t)
 '(yank-pop-change-selection t))
(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(default ((t (:family "Inconsolata" :foundry "unknown" :slant normal :weight normal :height 113 :width normal)))))
