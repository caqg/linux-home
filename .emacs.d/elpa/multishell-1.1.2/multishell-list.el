;;; multishell-list.el --- tabulated-list-mode for multishell shell buffers

;; Copyright (C) 2016 Free Software Foundation, Inc. and Ken Manheimer

;; Author: Ken Manheimer <ken.manheimer@gmail.com>
;; Version: 1.1.2
;; Created: 2016 -- first public availability
;; Keywords: processes
;; URL: https://github.com/kenmanheimer/EmacsMultishell

;; See multishell.el for commentary, change log, etc.

(require 'tabulated-list)

(defun multishell-list-open-pop ()
  "Pop to current entry's shell, and refresh the listing buffer."
  (interactive)
  (let ((list-buffer (current-buffer)))
    (multishell-pop-to-shell nil (tabulated-list-get-id))
    (with-current-buffer list-buffer
      (revert-buffer))))
(defun multishell-list-open-as-default ()
  "Pop to current entry's shell, and set as the default shell."
  (interactive)
  (let ((list-buffer (current-buffer)))
    (message "%s <==" (multishell-name-from-entry (tabulated-list-get-id)))
    (multishell-pop-to-shell '(16) (tabulated-list-get-id))
    (with-current-buffer list-buffer
      (revert-buffer))))
(defun multishell-list-open-here ()
  "Switch to current entry's shell buffer."
  (interactive)
  (let ((list-buffer (current-buffer)))
    (multishell-pop-to-shell nil (tabulated-list-get-id) 'here)
    (with-current-buffer list-buffer
      ;; In case they use switch-to-buffer or whatever to return.
      (revert-buffer))))

(defun multishell-list-delete ()
  "Remove current shell entry, and prompt for buffer-removal if present.

\(We depend on intrinsic confirmation prompts for active buffers,
supplemented by our own when buffer is inactive.)"
  (interactive)
  (let* ((entry (tabulated-list-get-id))
         (name (multishell-name-from-entry entry))
         (name-bracketed (multishell-bracket name))
         (buffer (get-buffer name-bracketed)))
    (when (multishell-delete-history-name name)
      (and buffer
           ;; If the process is live, let shell-mode get confirmation:
           (or (comint-check-proc (current-buffer))
               (y-or-n-p (format "Kill buffer %s? " name-bracketed)))
           (kill-buffer name-bracketed)))
    (tabulated-list-delete-entry)))

(defun multishell-list-edit-entry ()
  "Edit the value of current shell entry."
  (interactive)
  (let* ((where (save-excursion (beginning-of-line) (point)))
         (entry (tabulated-list-get-id))
         (name (multishell-name-from-entry entry))
         (revised (multishell-read-unbracketed-entry
                   (format "Edit shell spec for %s: " name)
                   entry
                   'no-record))
         (revised-name (multishell-name-from-entry revised))
         buffer)
    (when (not (string= revised entry))
      (multishell-replace-entry entry revised)
      (when (and (not (string= name revised-name))
                 (setq buffer (get-buffer (multishell-bracket name))))
        (with-current-buffer buffer
          (rename-buffer (multishell-bracket revised-name))))
      (revert-buffer)
      (goto-char where))))

(defun multishell-list-clone-entry (&optional arg)
  "Create a new list entry based on editing the current one.

You will be left in the list at the entry, not yet launched.

Providing a universal argument will also open the new shell.

The already existing current entry is left untouched."
  (interactive "P")
  (let* ((prototype (tabulated-list-get-id))
         (name (multishell-name-from-entry prototype))
         (new (multishell-read-unbracketed-entry
               (format "Clone new shell spec from %s: " name)
               prototype
               'no-record))
         (new-name (multishell-name-from-entry new))
         (new-path (cadr (multishell-split-entry new))))
    (when (not (string= new prototype))
      (multishell-register-name-to-path new-name new-path)
      (revert-buffer)
      (goto-char (point-min))
      (re-search-forward (format "^ . \\b%s\\b"
                                 (regexp-quote new-name)))
      (beginning-of-line))))

(defun multishell-list-placeholder (value default)
  "Return VALUE if non-empty string, else DEFAULT."
  (if (or (not value) (string= value ""))
      default
    value))
(defconst multishell-list-active-buffer-flag "+")
(defconst multishell-list-inactive-buffer-flag ".")
(defconst multishell-list-absent-buffer-flag "x")

(defun multishell-list-entries ()
  "Generate multishell name/path-spec entries list for tabulated-list."
  (let ((recency 0))
    (mapcar #'(lambda (entry)
                (setq recency (1+ recency))
                (let* ((splat (multishell-split-entry entry))
                       (name (car splat))
                       (buffer (and name
                                    (get-buffer
                                     (multishell-bracket name))))
                       (status (cond ((not buffer)
                                      multishell-list-absent-buffer-flag)
                                     ((comint-check-proc buffer)
                                      multishell-list-active-buffer-flag)
                                     (t multishell-list-inactive-buffer-flag)))
                       (rest (cadr splat))
                       (dir (or (file-remote-p rest 'localname)
                                rest))
                       (hops (and (file-remote-p rest 'localname)
                                  (substring
                                   rest 0 (- (length rest) (length dir))))))
                  (when (not name)
                    (setq name (multishell-name-from-entry entry)))
                  (list entry
                        (vector (format "%d" recency)
                                status
                                name
                                (multishell-list-placeholder hops "-")
                                (multishell-list-placeholder dir "~")))))
            (multishell-all-entries))))

(defun compare-strings-as-numbers (a b)
  (let ((a (aref (cadr a) 0))
        (b (aref (cadr b) 0)))
    (> (string-to-number a) (string-to-number b))))

(defvar multishell-list-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd "c") 'multishell-list-clone-entry)
    (define-key map (kbd "d") 'multishell-list-delete)
    (define-key map (kbd "\C-k") 'multishell-list-delete)
    (define-key map (kbd "k") 'multishell-list-delete)
    (define-key map (kbd "e") 'multishell-list-edit-entry)
    (define-key map (kbd "o") 'multishell-list-open-pop)
    (define-key map (kbd " ") 'multishell-list-open-pop)
    (define-key map (kbd "O") 'multishell-list-open-as-default)
    (define-key map (kbd "RET") 'multishell-list-open-here)
    map))
(define-derived-mode multishell-list-mode
    tabulated-list-mode "Shells"
  "Major mode for listing current and historically registered shells.
\\{multishell-list-mode-map\}"
  (setq tabulated-list-format
        [;; (name width sort '(:right-align nil :pad-right nil))
         ("#" 0 compare-strings-as-numbers :pad-right 1)
         ("! " 1 t :pad-right 1)
         ("Name" 15 t)
         ("Hops" 30 t)
         ("Directory" 30 t)]
        tabulated-list-sort-key '("#" . t)
        tabulated-list-entries #'multishell-list-entries)
  (tabulated-list-init-header))

;;;###autoload
(defun multishell-list ()
  "Edit your current and historic list of shell buffers.

Hit ? for a list of commands.

You can get to this shell listing manager by
recursively invoking \\[multishell-pop-to-shell] at either of the
`multishell-pop-to-shell' universal argument prompts."
  (interactive)
  (let ((buffer (get-buffer-create "*Shells*")))
    (pop-to-buffer buffer)
    (multishell-list-mode)
    (tabulated-list-print)))

(provide 'multishell-list)
(require 'multishell)

;;; multishell-list.el ends here
