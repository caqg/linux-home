;;; tmux-mode.el --- Major mode for tmux configuration -*- lexical-binding: t; -*-
;;
;; Author: Noah Peart <noah.v.peart@gmail.com>
;; URL: https://github.com/nverno/tmux-mode
;; Package-Requires: ((emacs "26.1"))
;; Version: 0.1.0
;; Created: 18 October 2023
;; Keywords: languages tmux config
;;
;; This file is not part of GNU Emacs.
;;
;; This program is free software; you can redistribute it and/or
;; modify it under the terms of the GNU General Public License as
;; published by the Free Software Foundation; either version 3, or
;; (at your option) any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
;; General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this program; see the file COPYING.  If not, write to
;; the Free Software Foundation, Inc., 51 Franklin Street, Fifth
;; Floor, Boston, MA 02110-1301, USA.
;;
;;; Commentary:
;;
;; Major mode for tmux configuration files.
;;
;; Features:
;; - font-locking
;; - indentation
;; - completion-at-point
;; - eldoc
;;
;;; Code:

(eval-when-compile
  (require 'cl-lib)
  (require 'lisp-mode))                 ; let-when-compile
  
(defcustom tmux-mode-indent-level 2
  "Number of spaces for each indentation."
  :group 'tmux
  :type 'integer
  :safe 'integerp)

;;; Font-Locking

(defvar tmux-mode-command-usage)
(defvar tmux-mode-commands)
(defvar tmux-mode-set-options)

(let-when-compile
    ((opts
      '("other-pane-height" "set-titles-string" "window-status-activity-style"
        "default-size" "status-interval" "window-style" "status-left-style"
        "destroy-unattached" "status-right-style" "pane-border-format"
        "visual-silence" "copy-mode" "copy-mode-vi"
        "message-command-style" "pane-base-index" "status-bg" "history-file"
        "lock-command" "update-environment" "pane-border-status" "clock-mode-colour"
        "aggressive-resize" "status-format" "prefix" "automatic-rename"
        "other-pane-width" "automatic-rename-format" "base-index" "backspace"
        "status-fg" "window-active-style" "display-time" "message-style"
        "status-justify" "status-style" "alternate-screen" "history-limit"
        "pane-active-border-style" "escape-time" "default-shell"
        "window-status-separator" "monitor-bell" "bell-action" "buffer-limit"
        "main-pane-width" "window-status-format" "mode-keys" "default-terminal"
        "set-titles" "window-status-bell-style" "allow-rename" "status-left-length"
        "visual-bell" "display-panes-time" "window-status-current-style" "xterm-keys"
        "key-table" "pane-border-style" "focus-event"
        "focus-events" "window-status-last-style"
        "window-status-current-format" "remain-on-exit" "monitor-silence"
        "silence-action" "status-right" "status-position" "window-status-style"
        "word-separators" "exit-empty" "default-command" "renumber-windows"
        "status-left" "status-right-length" "status" "prefix2" "message-limit"
        "command-alias" "display-panes-active-colour" "synchronize-panes"
        "exit-unattached" "wrap-search" "status-keys" "activity-action" "repeat-time"
        "visual-activity" "display-panes-colour" "assume-paste-time" "set-clipboard"
        "detach-on-destroy" "window-size" "terminal-overrides" "main-pane-height"
        "mouse" "clock-mode-style" "mode-style" "monitor-activity" "user-keys"
        "lock-after-time" "status-utf8" "utf8"))
     (raw
      '((("set-buffer" "setb")
         "set-buffer (setb) [-a] [-b buffer-name] [-n new-buffer-name] data")
        (("show-options" "show")
         "show-options (show) [-gqsvw] [-t target-session|target-window] [option]")
        (("join-pane" "joinp")
         "join-pane (joinp) [-bdhv] [-p percentage|-l size] [-s src-pane] [-t dst-pane]")
        (("delete-buffer" "deleteb")
         "delete-buffer (deleteb) [-b buffer-name]")
        (("source-file" "source")
         "source-file (source) [-q] path")
        (("set-option" "set")
         "set-option (set) [-aFgosquw] [-t target-window] option [value]")
        (("detach-client" "detach")
         "detach-client (detach) [-aP] [-E shell-command] [-s target-session] [-t target-client]")
        (("unbind-key" "unbind")
         "unbind-key (unbind) [-an] [-T key-table] key")
        (("move-pane" "movep")
         "move-pane (movep) [-bdhv] [-p percentage|-l size] [-s src-pane] [-t dst-pane]")
        (("choose-buffer" nil)
         "choose-buffer [-N] [-F format] [-f filter] [-O sort-order] [-t target-pane]")
        (("list-panes" "lsp")
         "list-panes (lsp) [-as] [-F format] [-t target-window]")
        (("command-prompt" nil)
         "command-prompt [-1Ni] [-I inputs] [-p prompts] [-t target-client] [template]")
        (("lock-client" "lockc")
         "lock-client (lockc) [-t target-client]")
        (("set-window-option" "setw")
         "set-window-option (setw) [-aFgoqu] [-t target-window] option [value]")
        (("lock-session" "locks")
         "lock-session (locks) [-t target-session]")
        (("save-buffer" "saveb")
         "save-buffer (saveb) [-a] [-b buffer-name] path")
        (("list-clients" "lsc")
         "list-clients (lsc) [-F format] [-t target-session]")
        (("suspend-client" "suspendc")
         "suspend-client (suspendc) [-t target-client]")
        (("capture-pane" "capturep")
         "capture-pane (capturep) [-aCeJpPq] [-b buffer-name] [-E end-line] [-S start-line][-t target-pane]")
        (("select-window" "selectw")
         "select-window (selectw) [-lnpT] [-t target-window]")
        (("previous-window" "prev")
         "previous-window (prev) [-a] [-t target-session]")
        (("load-buffer" "loadb")
         "load-buffer (loadb) [-b buffer-name] path")
        (("if-shell" "if")
         "if-shell (if) [-bF] [-t target-pane] shell-command command [command]")
        (("kill-session" nil)
         "kill-session [-aC] [-t target-session]")
        (("switch-client" "switchc")
         "switch-client (switchc) [-Elnpr] [-c target-client] [-t target-session] [-T key-table]")
        (("display-message" "display")
         "display-message (display) [-p] [-c target-client] [-F format] [-t target-pane] [message]")
        (("clear-history" "clearhist")
         "clear-history (clearhist) [-t target-pane]")
        (("break-pane" "breakp")
         "break-pane (breakp) [-dP] [-F format] [-n window-name] [-s src-pane] [-t dst-window]")
        (("kill-pane" "killp")
         "kill-pane (killp) [-a] [-t target-pane]")
        (("pipe-pane" "pipep")
         "pipe-pane (pipep) [-o] [-t target-pane] [command]")
        (("wait-for" "wait")
         "wait-for (wait) [-L|-S|-U] channel")
        (("split-window" "splitw")
         "split-window (splitw) [-bdfhvP] [-c start-directory] [-F format] [-p percentage|-l size] [-t target-pane] [command]")
        (("run-shell" "run")
         "run-shell (run) [-b] [-t target-pane] shell-command")
        (("previous-layout" "prevl")
         "previous-layout (prevl) [-t target-window]")
        (("send-prefix" nil)
         "send-prefix [-2] [-t target-pane]")
        (("rename-window" "renamew")
         "rename-window (renamew) [-t target-window] new-name")
        (("has-session" "has")
         "has-session (has) [-t target-session]")
        (("choose-tree" nil)
         "choose-tree [-Nsw] [-F format] [-f filter] [-O sort-order] [-t target-pane]")
        (("show-window-options" "showw")
         "show-window-options (showw) [-gv] [-t target-window] [option]")
        (("set-environment" "setenv")
         "set-environment (setenv) [-gru] [-t target-session] name [value]")
        (("respawn-window" "respawnw")
         "respawn-window (respawnw) [-c start-directory] [-k] [-t target-window] [command]")
        (("select-pane" "selectp")
         "select-pane (selectp) [-DdegLlMmRU] [-P style] [-T title] [-t target-pane]")
        (("new-window" "neww")
         "new-window (neww) [-adkP] [-c start-directory] [-F format] [-n window-name] [-t target-window] [command]")
        (("list-buffers" "lsb")
         "list-buffers (lsb) [-F format]")
        (("lock-server" "lock")
         "lock-server (lock) ")
        (("find-window" "findw")
         "find-window (findw) [-CNT] [-t target-pane] match-string")
        (("show-buffer" "showb")
         "show-buffer (showb) [-b buffer-name]")
        (("new-session" "new")
         "new-session (new) [-AdDEP] [-c start-directory] [-F format] [-n window-name] [-s session-name] [-t target-session] [-x width] [-y height] [command]")
        (("send-keys" "send")
         "send-keys (send) [-lXRM] [-N repeat-count] [-t target-pane] key ...")
        (("attach-session" "attach")
         "attach-session (attach) [-dEr] [-c working-directory] [-t target-session]")
        (("start-server" "start")
         "start-server (start) ")
        (("show-environment" "showenv")
         "show-environment (showenv) [-gs] [-t target-session] [name]")
        (("kill-server" nil)
         "kill-server ")
        (("last-window" "last")
         "last-window (last) [-t target-session]")
        (("choose-client" nil)
         "choose-client [-N] [-F format] [-f filter] [-O sort-order] [-t target-pane]")
        (("copy-mode" nil)
         "copy-mode [-Mu] [-t target-pane]")
        (("list-sessions" "ls")
         "list-sessions (ls) [-F format]")
        (("list-windows" "lsw")
         "list-windows (lsw) [-a] [-F format] [-t target-session]")
        (("display-panes" "displayp")
         "display-panes (displayp) [-d duration] [-t target-client]")
        (("swap-window" "swapw")
         "swap-window (swapw) [-d] [-s src-window] [-t dst-window]")
        (("list-commands" "lscm")
         "list-commands (lscm) [-F format]")
        (("show-messages" "showmsgs")
         "show-messages (showmsgs) [-JT] [-t target-client]")
        (("rename-session" "rename")
         "rename-session (rename) [-t target-session] new-name")
        (("unlink-window" "unlinkw")
         "unlink-window (unlinkw) [-k] [-t target-window]")
        (("next-layout" "nextl")
         "next-layout (nextl) [-t target-window]")
        (("clock-mode" nil)
         "clock-mode [-t target-pane]")
        (("respawn-pane" "respawnp")
         "respawn-pane (respawnp) [-c start-directory] [-k] [-t target-pane] [command]")
        (("bind-key" "bind")
         "bind-key (bind) [-cnr] [-T key-table] key command [arguments]")
        (("swap-pane" "swapp")
         "swap-pane (swapp) [-dDU] [-s src-pane] [-t dst-pane]")
        (("set-hook" nil)
         "set-hook [-gu] [-t target-session] hook-name [command]")
        (("rotate-window" "rotatew")
         "rotate-window (rotatew) [-DU] [-t target-window]")
        (("list-keys" "lsk")
         "list-keys (lsk) [-T key-table]")
        (("move-window" "movew")
         "move-window (movew) [-dkr] [-s src-window] [-t dst-window]")
        (("next-window" "next")
         "next-window (next) [-a] [-t target-session]")
        (("confirm-before" "confirm")
         "confirm-before (confirm) [-p prompt] [-t target-client] command")
        (("link-window" "linkw")
         "link-window (linkw) [-dk] [-s src-window] [-t dst-window]")
        (("refresh-client" "refresh")
         "refresh-client (refresh) [-S] [-C size] [-t target-client]")
        (("paste-buffer" "pasteb")
         "paste-buffer (pasteb) [-dpr] [-s separator] [-b buffer-name] [-t target-pane]")
        (("show-hooks" nil)
         "show-hooks [-g] [-t target-session]")
        (("last-pane" "lastp")
         "last-pane (lastp) [-de] [-t target-window]")
        (("resize-pane" "resizep")
         "resize-pane (resizep) [-DLMRUZ] [-x width] [-y height] [-t target-pane] [adjustment]")
        (("kill-window" "killw")
         "kill-window (killw) [-a] [-t target-window]")
        (("select-layout" "selectl")
         "select-layout (selectl) [-nop] [-t target-window] [layout-name]")))
     (cmds (cl-loop for (kws . usage) in raw nconc (delq nil kws)))
     (usages
      (let ((ht (make-hash-table :test #'equal)))
        (cl-loop for (kws . usage) in raw
                 do (dolist (k kws) (puthash k usage ht)))
        ht)))

  (let ((opts (eval-when-compile opts))
        (cmds (eval-when-compile cmds))
        (usages (eval-when-compile usages))
        (cmds-re (eval-when-compile (regexp-opt cmds t)))
        (opts-re (eval-when-compile (regexp-opt opts t))))

    ;; save these for completion candidates / eldoc
    (defconst tmux-mode-set-options opts)
    (defconst tmux-mode-commands cmds)
    (defconst tmux-mode-command-usage usages)

    (defconst tmux-font-lock-keywords
      `(;; builtin commands / shortcuts
        (,(concat "\\_<" cmds-re "\\_>") (1 font-lock-keyword-face))
        ;; set/setw options
        (,(concat "\\_<" opts-re "\\_>") (1 font-lock-builtin-face))
        (,(rx bow "%" (or "if" "elif" "else" "endif" "hidden") eow)
         . font-lock-keyword-face)
        ;; flags
        (,(concat "\\_<-[-A-Za-z0-9]+\\_>") . font-lock-type-face)
        ;; @
        ("\\B\\(@[-_A-Za-z0-9]+\\)\\b" (1 font-lock-function-name-face))
        ;; EOL escapes
        ("\\(^\\|[^\\]\\)\\(\\\\\\\\\\)*\\(\\\\\\)$"
         (3 'font-lock-escape-face prepend))
        ("\\(\\\\\\);" (1 font-lock-negation-char-face))
        ;; constants
        (,(concat "\\_<" (regexp-opt '("on" "off" "true" "false") t) "\\_>")
         (1 font-lock-constant-face prepend))
        (,(rx bow (+ num) eow) . 'font-lock-number-face)
        ;; variables
        ("\\$\\({#?\\)?\\([[:alpha:]_][[:alnum:]_]*\\|[-#?@!]\\)"
         (2 'font-lock-variable-use-face prepend))
        ("#{\\(\\w+\\)}" (1 'font-lock-variable-use-face prepend))
        (,(rx bow (group (+ word)) (group "="))
         (1 font-lock-variable-name-face)
         (2 'font-lock-operator-face))
        ("#\\({[><=]=:\\)" (1 'font-lock-operator-face prepend))))))

;;; Syntax

(defvar tmux-mode-syntax-table
  (let ((tbl (make-syntax-table)))
    (modify-syntax-entry ?# "<" tbl)
    (modify-syntax-entry ?\n ">" tbl)
    (modify-syntax-entry ?\' "\"" tbl)
    (modify-syntax-entry ?_ "w" tbl)
    (modify-syntax-entry ?= "." tbl)
    (modify-syntax-entry ?@ "'" tbl)
    (modify-syntax-entry ?$ "'" tbl)
    tbl)
  "Syntax table for `tmux-mode'.")

(defun tmux-mode--syntax-propertize (start end)
  "Apply syntax properties to text between START and END."
  (goto-char start)
  (funcall
   (syntax-propertize-rules
    ("\\(#\\){[><=]=:\\(?:#{[^{}\\\n ]+}\\|[^{}\\\n ]*\\)*\\(}\\)"
     (1 "|") (2 "|")))
   (point) end))

(defun tmux-mode--font-lock-syntactic-face-function (state)
  "Syntactic face function for `font-lock-syntactic-face-function'.
STATE is a `parse-partial-sexp' state."
  (if-let ((q (nth 3 state)))
      (let ((startpos (nth 8 state)))
        (if (or (eq t q)
                (eq (char-after (1+ startpos)) ?#))
            'font-lock-doc-face
          font-lock-string-face))
    font-lock-comment-face))

;;; Indentation

(require 'smie)

(defconst tmux-mode-grammar
  (smie-prec2->grammar
   (smie-bnf->prec2
    '((exp)
      (cmd ("%if" cmd "%endif")
           ("%if" cmd "%else" cmd "%endif")
           ("%if" exp "%elif" exp "%else" exp "%endif")
           ("%if" exp "%elif" exp "%elif" exp "%else" exp "%endif")
           (exp "\\" exp)
           (exp "\n" exp)
           (exp)))
    '((assoc "\\" "\n"))))
  "Smie grammar for `tmux-mode'.")

(defun tmux-mode-smie-rules (kind token)
  "Indentation rules for `tmux-mode'.
See `smie-rules-function' for description of KIND and TOKEN."
  (pcase (cons kind token)
    (`(:elem . basic) tmux-mode-indent-level)
    (`(:elem . args))
    (`(:after . ,(or "%if" "%elif" "%else")) tmux-mode-indent-level)
    (`(:after . "\n")
     (if (smie-rule-parent-p "\\")
         (smie-rule-parent (- tmux-mode-indent-level))
       (smie-rule-parent)))
    (`(:after . "\\")
     (unless (smie-rule-parent-p "\\")
       tmux-mode-indent-level))
    (`(:list-intro . ,(or "" "\n" "%if" "%else" "%elif")) t)
    (`(:close-all . ,_) t)))

(defun tmux-mode-backward-token ()
  "Function for `smie-backward-token-function' to find previous token."
  (let ((bol (line-beginning-position)))
    (forward-comment (- (point)))
    (cond
     ((< (point) bol)
      (cond
       ((tmux-mode--looking-back-at-continuation-p)
        (goto-char (1+ (match-beginning 0)))
        "\\")
       ((or (and (eq ?\} (char-before))
                 (get-text-property (1- (point)) 'syntax-table))
            (and (char-before)
                 (eq ?\" (char-syntax (char-before)))))
        (backward-sexp)
        (let ((tok (funcall #'smie-default-backward-token)))
          (pcase tok
            ((or "%if" "%elif" "%else") tok)
            (_ "\n"))))
       (t
        (skip-syntax-backward " ")
        (if (eq ?\" (ignore-errors (char-syntax (char-before)))) "\n"
          (let ((tok (funcall #'smie-default-backward-token)))
            (pcase tok
              ((or "" "%else" "%endif") tok)
              (_ "\n")))))))
     (t (funcall #'smie-default-backward-token)))))

(defun tmux-mode-forward-token ()
  "Function for `smie-forward-token-function' to find next token."
  (forward-comment (point-max))
  (cond
   ((looking-at-p "\\(?:\\\\\\\\\\)*\\\\\n")
    (forward-line 1) "\\")
   (t (funcall #'smie-default-forward-token))))

;; Like `sh-smie--looking-back-at-continuation-p' ignores commented
;; line-continuations
(defun tmux-mode--looking-back-at-continuation-p ()
  "Non-nil when previous line is escaped."
  (unless (nth 4 (syntax-ppss (and (not (bobp)) (bolp) (1- (point)))))
    (and (if (eq (char-before) ?\n) (progn (forward-char -1) t) (eolp))
         (looking-back "\\(?:^\\|[^\\]\\)\\(?:\\\\\\\\\\)*\\\\"
                       (line-beginning-position)))))

;;; Completion / eldoc

(defun tmux-mode-completion-at-point ()
  "Completion-at-point function for `tmux-mode'."
  (when-let ((bnds (bounds-of-thing-at-point 'symbol)))
    (and (eq ?w (char-syntax (car bnds)))
         (list (car bnds) (cdr bnds)
               (completion-table-with-cache
                (lambda (_string) (append tmux-mode-commands tmux-mode-set-options)))
               :exclusive 'no))))

(defun tmux-mode-current-command ()
  "Return current tmux command or nil if there is none."
  (let ((state (syntax-ppss)))
    (unless (nth 4 state)
      (save-excursion
        (when-let ((beg (nth 8 state)))
          (goto-char beg))
        (while (and
                (not (bobp))
                (let ((face (ignore-errors (get-char-property (point) 'face))))
                  (not (memq 'font-lock-keyword-face
                             (if (listp face) face (list face)))))
                (condition-case nil
                    (progn (backward-sexp 1) t)
                  (scan-error
                   (condition-case nil (progn (up-list -1 t t) t)
                     (scan-error nil))))))
        (thing-at-point 'symbol)))))

(defun tmux-mode-eldoc-function ()
  "Eldoc function for `tmux-mode'."
  (when-let ((s (tmux-mode-current-command)))
    (car (gethash s tmux-mode-command-usage))))

;;;###autoload
(define-derived-mode tmux-mode prog-mode "Tmux"
  "Major mode for tmux configuration files.

\\{tmux-mode-map}"
  :group 'tmux
  (setq-local comment-start "# ")
  (setq-local comment-end "")
  (setq-local comment-start-skip "#+ *")
  ;; (setq-local comment-add 1)
  (setq-local font-lock-defaults
              `( tmux-font-lock-keywords nil nil nil nil
                 (font-lock-syntactic-face-function
                  . ,#'tmux-mode--font-lock-syntactic-face-function)))
  (smie-setup tmux-mode-grammar #'tmux-mode-smie-rules
              :forward-token #'tmux-mode-forward-token
              :backward-token #'tmux-mode-backward-token)
  (add-hook 'completion-at-point-functions #'tmux-mode-completion-at-point nil t)
  (add-function :before-until (local 'eldoc-documentation-function)
                #'tmux-mode-eldoc-function)
  (setq-local syntax-propertize-function #'tmux-mode--syntax-propertize))

;;;###autoload
(add-to-list 'auto-mode-alist (cons "\\.?tmux\\.conf\\'" 'tmux-mode))

(provide 'tmux-mode)
;; Local Variables:
;; coding: utf-8
;; indent-tabs-mode: nil
;; End:
;;; tmux-mode.el ends here
