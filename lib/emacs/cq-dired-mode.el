;;;; -*- Mode: Emacs-Lisp -*-

(require 'dired)
(require 'cq-multi-shell)

(defvar dired-ignored-extensions nil
  "*Like completion-ignored-extensions, used by Dired to mask off files")

(defun cq-dired-shell-here ()
  "Run a shell on the current working directory--to be invoked from dired."
  (interactive)
  ;; TO DO: If a shell is already on that directory, pick it back.
  (cq-multi-shell '(new)))

(defun cq-dired-mode ()
  "Customizations of DIRED mode."
  ;; (when (and (string-match "^XEmacs" (emacs-version))
  ;;           (boundp 'emacs-major-version)
  ;;           (>= emacs-major-version 21)
  ;;           window-system)
  ;;   (local-set-key "\C-m" 'cq-dired-dwim))

  ;;(local-set-key "L" 'dired-load-file) ;not needed, now part of Dired
  ;;(local-set-key "i" 'dired-erase-ignored-extensions); insert subdir
  (local-set-key [(meta control m)] 'dired-make)
  (local-set-key [(control !)] 'cq-dired-shell-here)
  ;; currently good only for cygwin (local-set-key [(control m)] 'cq-dired-dwim)
  )

(defun dired-load-file ()
  "Load this file \(presumably it is Emacs code\)."
  (interactive)
  (let* ((buffer-read-only nil)
         (from-file (dired-get-filename)))
    (load-file from-file)))

;; Contributed by MAP@LCS.MIT.EDU from a suggestion of erik@mpx2.UUCP
(defun dired-delete-and-exit ()
  "Quit editing this directory."
  (interactive)
  (dired-do-deletions)
  (kill-buffer (current-buffer)))

;;; From: gudeman@arizona.edu (David Gudeman)
;;; Newsgroups: comp.emacs
;;; Subject: Re: Selective Dired
;;; Message-ID: <9226@megaron.arizona.edu>
;;; Date: 15 Feb 89 06:52:00 GMT
;;; Organization: U of Arizona CS Dept, Tucson

;;; Slightly modified by C. Quiroz, Thu Feb 16 23:46:11 EST 1989

(defun dired-erase-ignored-extensions ()
  "Remove all files that match completion-ignored-extensions.  If
dired-ignored-extensions is defined, then use that instead.

Use revert-buffer to see again the ignored files."
  (interactive)
  (let ((ls (if dired-ignored-extensions ;(boundp 'dired-ignored-extensions)
                dired-ignored-extensions
              completion-ignored-extensions))
        (buffer-read-only))
    (save-excursion
      (goto-char (point-min))
      (while ls
        (delete-matching-lines
         (concat (regexp-quote (car ls)) "[*|=/]?$"))
        (setq ls (cdr ls))))))

;;; Make and such commands

(defvar dired-make-command "make"
  "*Command to run to make a goal")

(defvar dired-make-command-output-buffer "*Make Output*"
  "*Name of the buffer where dired-make puts its output")

(defun dired-make (prefix)
  "Run make with this file as the goal.
With any prefix, try to guess which goal from the file name."
  (interactive "P")
  (let ((buffer-read-only nil)
        (file (dired-get-filename))
        (here (current-buffer))
        (outbuf (get-buffer-create dired-make-command-output-buffer)))
    ;; do we need to guess a goal?
    (when prefix
      ;;chop off suffix
      (let ((match-data (match-data)))
        (when (string-match "\\(.*\\)\\..*" file)
          (setf file (substring file (match-beginning 1) (match-end 1))))
        (store-match-data match-data)))
    ;; clear the output buffer
    (switch-to-buffer-other-window outbuf)
    (erase-buffer)
    (set-buffer here)
    ;; do the stuff
    (message "make %s ..." file)
    (call-process dired-make-command nil outbuf t file)
    (switch-to-buffer-other-window here)
    (revert-buffer)
    (message "make %s ... done" file)))

;;;

(defun cq-dired-cygstart ()
  "Open the current file with cygstart."
  (interactive)
  (call-process "cygstart" nil nil nil (dired-get-filename)))

(defvar *cq-dired-dwim-suffix-table*
  '(((lambda () (cq-dired-cygstart))
    ".jpg" ".jpeg" ".png" ".html" ".htm" ;Web browser
    ".doc" ".xls" ".ppt"                ;MS Office
    ".pdf"                              ;Acrobat Reader
    ".spp"                              ;XMLSpy
    ".zip"                              ;PKzip
    ))
  "List of lists; the car of each sublist is function to funcall if the
current dired filename has a suffix present in the cdr.  The sublists are
visited in order; a match near the front shadows any match beyond.")

(defun cq-dired-find-dwim-handler (extension)
  (let ((table *cq-dired-dwim-suffix-table*)
        (found nil)
        ;; file-name-extension returns "html"
        ;; dired-file-name-extension return ".html"
        ;; rather than checking what Emacs this is,
        ;; try both in a row.
        (dotted (concat "." extension)))
    (while (and table (not found))
      (if (or (member extension (cdar table)) (member dotted (cdar table)))
          (setq found (caar table)))
      (setq table (cdr table)))
    found))

(defun cq:dired-dwim-linux ()
  "Do the right thing with the current file."
  (interactive)
  (let ((filename (dired-get-filename nil t)))
    (if (null filename)
        nil
      )))

(defun cq-dired-dwim ()
  "Do the right thing with the current file.
See also *cq-dired-dwim-suffix-table*."
  (interactive)
  (let ((filename (dired-get-filename nil t)))
    (if (null filename)
        nil
      (let* ( ;; (extension (dired-file-name-extension filename))
             (extension (file-name-extension filename))
             (handler (cq-dired-find-dwim-handler extension)))
        (if handler
            (funcall handler)
          (dired-advertised-find-file))))))

;;;; end of cq-dired-mode.el
