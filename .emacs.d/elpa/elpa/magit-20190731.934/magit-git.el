;;; magit-git.el --- Git functionality  -*- lexical-binding: t -*-

;; Copyright (C) 2010-2019  The Magit Project Contributors
;;
;; You should have received a copy of the AUTHORS.md file which
;; lists all contributors.  If not, see http://magit.vc/authors.

;; Author: Jonas Bernoulli <jonas@bernoul.li>
;; Maintainer: Jonas Bernoulli <jonas@bernoul.li>

;; Magit is free software; you can redistribute it and/or modify it
;; under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.
;;
;; Magit is distributed in the hope that it will be useful, but WITHOUT
;; ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
;; or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public
;; License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with Magit.  If not, see http://www.gnu.org/licenses.

;;; Commentary:

;; This library implements wrappers for various Git plumbing commands.

;;; Code:

(require 'cl-lib)
(require 'dash)

(eval-when-compile
  (require 'subr-x))

(require 'magit-utils)
(require 'magit-section)

;; From `magit-branch'.
(defvar magit-branch-prefer-remote-upstream)
(defvar magit-published-branches)

;; From `magit-margin'.
(declare-function magit-maybe-make-margin-overlay "magit-margin" ())

;; From `magit-mode'.
(declare-function magit-get-mode-buffer "magit-mode"
                  (mode &optional value frame))
(declare-function magit-refresh "magit-mode" ())
(defvar magit-buffer-diff-args)
(defvar magit-buffer-file-name)
(defvar magit-buffer-log-args)
(defvar magit-buffer-log-files)
(defvar magit-buffer-refname)
(defvar magit-buffer-revision)

;; From `magit-process'.
(declare-function magit-call-git "magit-process" (&rest args))
(declare-function magit-process-buffer "magit-process" (&optional nodisplay))
(declare-function magit-process-file "magit-process" (&rest args))
(declare-function magit-process-insert-section "magit-process"
                  (pwd program args &optional errcode errlog))
(defvar magit-this-error)
(defvar magit-process-error-message-regexps)

;; From later in `magit-git'.
(defvar magit-tramp-process-environment nil)

(eval-when-compile
  (cl-pushnew 'number eieio--known-slot-names))

;;; Git implementations

(defvar magit-inhibit-libgit nil
  "Whether to inhibit the use of libgit.")

(defvar magit--libgit-available-p eieio-unbound
  "Whether libgit is available.
Use the function by the same name instead of this variable.")

(defun magit--libgit-available-p ()
  (if (eq magit--libgit-available-p eieio-unbound)
      (setq magit--libgit-available-p
            (and module-file-suffix
                 (let ((libgit (locate-library "libgit")))
                   (and libgit
                        (or (locate-library "libegit2")
                            (let ((load-path
                                   (cons (expand-file-name
                                          (convert-standard-filename "build")
                                          (file-name-directory libgit))
                                         load-path)))
                              (locate-library "libegit2")))))))
    magit--libgit-available-p))

(defun magit-gitimpl ()
  "Return the Git implementation used in this repository."
  (if (and (not magit-inhibit-libgit)
           (not (file-remote-p default-directory))
           (magit--libgit-available-p))
      'libgit
    'git))

;;; Options

;; For now this is shared between `magit-process' and `magit-git'.
(defgroup magit-process nil
  "Git and other external processes used by Magit."
  :group 'magit)

(defvar magit-git-environment
  (list (format "INSIDE_EMACS=%s,magit" emacs-version))
  "Prepended to `process-environment' while running git.")

(defcustom magit-git-output-coding-system
  (and (eq system-type 'windows-nt) 'utf-8)
  "Coding system for receiving output from Git.

If non-nil, the Git config value `i18n.logOutputEncoding' should
be set via `magit-git-global-arguments' to value consistent with
this."
  :package-version '(magit . "2.9.0")
  :group 'magit-process
  :type '(choice (coding-system :tag "Coding system to decode Git output")
                 (const :tag "Use system default" nil)))

(defvar magit-git-w32-path-hack nil
  "Alist of (EXE . (PATHENTRY)).
This specifies what additional PATH setting needs to be added to
the environment in order to run the non-wrapper git executables
successfully.")

(defcustom magit-git-executable
  ;; Git might be installed in a different location on a remote, so
  ;; it is better not to use the full path to the executable, except
  ;; on Window were we would otherwise end up using one one of the
  ;; wrappers "cmd/git.exe" or "cmd/git.cmd", which are much slower
  ;; than using "bin/git.exe" directly.
  (or (and (eq system-type 'windows-nt)
           (--when-let (executable-find "git")
             (ignore-errors
               ;; Git for Windows 2.x provides cygpath so we can
               ;; ask it for native paths.
               (let* ((core-exe
                       (car
                        (process-lines
                         it "-c"
                         "alias.X=!x() { which \"$1\" | cygpath -mf -; }; x"
                         "X" "git")))
                      (hack-entry (assoc core-exe magit-git-w32-path-hack))
                      ;; Running the libexec/git-core executable
                      ;; requires some extra PATH entries.
                      (path-hack
                       (list (concat "PATH="
                                     (car (process-lines
                                           it "-c"
                                           "alias.P=!cygpath -wp \"$PATH\""
                                           "P"))))))
                 ;; The defcustom STANDARD expression can be
                 ;; evaluated many times, so make sure it is
                 ;; idempotent.
                 (if hack-entry
                     (setcdr hack-entry path-hack)
                   (push (cons core-exe path-hack) magit-git-w32-path-hack))
                 core-exe))))
      "git")
  "The Git executable used by Magit."
  :group 'magit-process
  :type 'string)

(defcustom magit-git-global-arguments
  `("--no-pager" "--literal-pathspecs" "-c" "core.preloadindex=true"
    "-c" "log.showSignature=false"
    ,@(and (eq system-type 'windows-nt)
           (list "-c" "i18n.logOutputEncoding=UTF-8")))
  "Global Git arguments.

The arguments set here are used every time the git executable is
run as a subprocess.  They are placed right after the executable
itself and before the git command - as in `git HERE... COMMAND
REST'.  See the manpage `git(1)' for valid arguments.

Be careful what you add here, especially if you are using Tramp
to connect to servers with ancient Git versions.  Never remove
anything that is part of the default value, unless you really
know what you are doing.  And think very hard before adding
something; it will be used every time Magit runs Git for any
purpose."
  :package-version '(magit . "2.9.0")
  :group 'magit-git-arguments
  :group 'magit-process
  :type '(repeat string))

(defvar magit-git-debug nil
  "Whether to enable additional reporting of git errors.

Magit basically calls git for one of these two reasons: for
side-effects or to do something with its standard output.

When git is run for side-effects then its output, including error
messages, go into the process buffer which is shown when using \
\\<magit-status-mode-map>\\[magit-process].

When git's output is consumed in some way, then it would be too
expensive to also insert it into this buffer, but when this
option is non-nil and git returns with a non-zero exit status,
then at least its standard error is inserted into this buffer.

This is only intended for debugging purposes.  Do not enable this
permanently, that would negatively affect performance.")


(defcustom magit-prefer-remote-upstream nil
  "Whether to favor remote branches when reading the upstream branch.

This controls whether commands that read a branch from the user
and then set it as the upstream branch, offer a local or a remote
branch as default completion candidate, when they have the choice.

This affects all commands that use `magit-read-upstream-branch'
or `magit-read-starting-point', which includes most commands
that change the upstream and many that create new branches."
  :package-version '(magit . "2.4.2")
  :group 'magit-commands
  :type 'boolean)

(defcustom magit-list-refs-sortby nil
  "How to sort the ref collection in the prompt.

This affects commands that read a ref.  More specifically, it
controls the order of refs returned by `magit-list-refs', which
is called by functions like `magit-list-branch-names' to generate
the collection of refs.  By default, refs are sorted according to
their full refname (i.e., 'refs/...').

Any value accepted by the `--sort' flag of `git for-each-ref' can
be used.  For example, \"-creatordate\" places refs with more
recent committer or tagger dates earlier in the list.  A list of
strings can also be given in order to pass multiple sort keys to
`git for-each-ref'.

Note that, depending on the completion framework you use, this
may not be sufficient to change the order in which the refs are
displayed.  It only controls the order of the collection passed
to `magit-completing-read' or, for commands that support reading
multiple strings, `read-from-minibuffer'.  The completion
framework ultimately determines how the collection is displayed."
  :package-version '(magit . "2.11.0")
  :group 'magit-miscellanous
  :type '(choice string (repeat string)))

;;; Git

(defvar magit--refresh-cache nil)

(defmacro magit--with-refresh-cache (key &rest body)
  (declare (indent 1) (debug (form body)))
  (let ((k (cl-gensym)))
    `(if magit--refresh-cache
         (let ((,k ,key))
           (--if-let (assoc ,k (cdr magit--refresh-cache))
               (progn (cl-incf (caar magit--refresh-cache))
                      (cdr it))
             (cl-incf (cdar magit--refresh-cache))
             (let ((value ,(macroexp-progn body)))
               (push (cons ,k value)
                     (cdr magit--refresh-cache))
               value)))
       ,@body)))

(defvar magit-with-editor-envvar "GIT_EDITOR"
  "The environment variable exported by `magit-with-editor'.
Set this to \"GIT_SEQUENCE_EDITOR\" if you do not want to use
Emacs to edit commit messages but would like to do so to edit
rebase sequences.")

(defmacro magit-with-editor (&rest body)
  "Like `with-editor' but let-bind some more variables.
Also respect the value of `magit-with-editor-envvar'."
  (declare (indent 0) (debug (body)))
  `(let ((magit-process-popup-time -1)
         ;; The user may have customized `shell-file-name' to
         ;; something which results in `w32-shell-dos-semantics' nil
         ;; (which changes the quoting style used by
         ;; `shell-quote-argument'), but Git for Windows expects shell
         ;; quoting in the dos style.
         (shell-file-name (if (and (eq system-type 'windows-nt)
                                   ;; If we have Cygwin mount points,
                                   ;; the git flavor is cygwin, so dos
                                   ;; shell quoting is probably wrong.
                                   (not magit-cygwin-mount-points))
                              "cmdproxy"
                            shell-file-name)))
     (with-editor* magit-with-editor-envvar
       ,@body)))

(defun magit-process-git-arguments (args)
  "Prepare ARGS for a function that invokes Git.

Magit has many specialized functions for running Git; they all
pass arguments through this function before handing them to Git,
to do the following.

* Flatten ARGS, removing nil arguments.
* Prepend `magit-git-global-arguments' to ARGS.
* On w32 systems, encode to `w32-ansi-code-page'."
  (setq args (append magit-git-global-arguments (-flatten args)))
  (if (and (eq system-type 'windows-nt) (boundp 'w32-ansi-code-page))
      ;; On w32, the process arguments *must* be encoded in the
      ;; current code-page (see #3250).
      (mapcar (lambda (arg)
                (encode-coding-string
                 arg (intern (format "cp%d" w32-ansi-code-page))))
              args)
    args))

(defun magit-git-exit-code (&rest args)
  "Execute Git with ARGS, returning its exit code."
  (apply #'magit-process-file magit-git-executable nil nil nil
         (magit-process-git-arguments args)))

(defun magit-git-success (&rest args)
  "Execute Git with ARGS, returning t if its exit code is 0."
  (= (magit-git-exit-code args) 0))

(defun magit-git-failure (&rest args)
  "Execute Git with ARGS, returning t if its exit code is 1."
  (= (magit-git-exit-code args) 1))

(defun magit-git-string-p (&rest args)
  "Execute Git with ARGS, returning the first line of its output.
If the exit code isn't zero or if there is no output, then return
nil.  Neither of these results is considered an error; if that is
what you want, then use `magit-git-string-ng' instead.

This is an experimental replacement for `magit-git-string', and
still subject to major changes."
  (magit--with-refresh-cache (cons default-directory args)
    (with-temp-buffer
      (and (zerop (apply #'magit-process-file magit-git-executable nil t nil
                         (magit-process-git-arguments args)))
           (not (bobp))
           (progn
             (goto-char (point-min))
             (buffer-substring-no-properties (point) (line-end-position)))))))

(defun magit-git-string-ng (&rest args)
  "Execute Git with ARGS, returning the first line of its output.
If the exit code isn't zero or if there is no output, then that
is considered an error, but instead of actually signaling an
error, return nil.  Additionally the output is put in the process
buffer (creating it if necessary) and the error message is shown
in the status buffer (provided it exists).

This is an experimental replacement for `magit-git-string', and
still subject to major changes.  Also see `magit-git-string-p'."
  (magit--with-refresh-cache
      (list default-directory 'magit-git-string-ng args)
    (with-temp-buffer
      (let* ((args (magit-process-git-arguments args))
             (status (apply #'magit-process-file magit-git-executable
                            nil t nil args)))
        (if (zerop status)
            (and (not (bobp))
                 (progn
                   (goto-char (point-min))
                   (buffer-substring-no-properties
                    (point) (line-end-position))))
          (let ((buf (current-buffer)))
            (with-current-buffer (magit-process-buffer t)
              (magit-process-insert-section default-directory
                                            magit-git-executable args
                                            status buf)))
          (when-let ((status-buf (magit-get-mode-buffer 'magit-status-mode)))
            (let ((msg (magit--locate-error-message)))
              (with-current-buffer status-buf
                (setq magit-this-error msg))))
          nil)))))

(defun magit-git-str (&rest args)
  "Execute Git with ARGS, returning the first line of its output.
If there is no output, return nil.  If the output begins with a
newline, return an empty string.  Like `magit-git-string' but
ignore `magit-git-debug'."
  (setq args (-flatten args))
  (magit--with-refresh-cache (cons default-directory args)
    (with-temp-buffer
      (apply #'magit-process-file magit-git-executable nil (list t nil) nil
             (magit-process-git-arguments args))
      (unless (bobp)
        (goto-char (point-min))
        (buffer-substring-no-properties (point) (line-end-position))))))

(defun magit-git-output (&rest args)
  "Execute Git with ARGS, returning its output."
  (setq args (-flatten args))
  (magit--with-refresh-cache (cons default-directory args)
    (with-temp-buffer
      (apply #'magit-process-file magit-git-executable nil (list t nil) nil
             (magit-process-git-arguments args))
      (buffer-substring-no-properties (point-min) (point-max)))))

(define-error 'magit-invalid-git-boolean "Not a Git boolean")

(defun magit-git-true (&rest args)
  "Execute Git with ARGS, returning t if it prints \"true\".
If it prints \"false\", then return nil.  For any other output
signal `magit-invalid-git-boolean'."
  (pcase (magit-git-output args)
    ((or "true"  "true\n")  t)
    ((or "false" "false\n") nil)
    (output (signal 'magit-invalid-git-boolean output))))

(defun magit-git-false (&rest args)
  "Execute Git with ARGS, returning t if it prints \"false\".
If it prints \"true\", then return nil.  For any other output
signal `magit-invalid-git-boolean'."
  (pcase (magit-git-output args)
    ((or "true"  "true\n")  nil)
    ((or "false" "false\n") t)
    (output (signal 'magit-invalid-git-boolean output))))

(defun magit-git-insert (&rest args)
  "Execute Git with ARGS, inserting its output at point.
If Git exits with a non-zero exit status, then show a message and
add a section in the respective process buffer."
  (setq args (magit-process-git-arguments args))
  (if magit-git-debug
      (let (log)
        (unwind-protect
            (progn
              (setq log (make-temp-file "magit-stderr"))
              (delete-file log)
              (let ((exit (apply #'magit-process-file magit-git-executable
                                 nil (list t log) nil args)))
                (when (> exit 0)
                  (let ((msg "Git failed"))
                    (when (file-exists-p log)
                      (setq msg (with-temp-buffer
                                  (insert-file-contents log)
                                  (goto-char (point-max))
                                  (if (functionp magit-git-debug)
                                      (funcall magit-git-debug (buffer-string))
                                    (magit--locate-error-message))))
                      (let ((magit-git-debug nil))
                        (with-current-buffer (magit-process-buffer t)
                          (magit-process-insert-section default-directory
                                                        magit-git-executable
                                                        args exit log))))
                    (message "%s" msg)))
                exit))
          (ignore-errors (delete-file log))))
    (apply #'magit-process-file magit-git-executable
           nil (list t nil) nil args)))

(defun magit--locate-error-message ()
  (goto-char (point-max))
  (and (run-hook-wrapped 'magit-process-error-message-regexps
                         (lambda (re) (re-search-backward re nil t)))
       (match-string-no-properties 1)))

(defun magit-git-string (&rest args)
  "Execute Git with ARGS, returning the first line of its output.
If there is no output, return nil.  If the output begins with a
newline, return an empty string."
  (setq args (-flatten args))
  (magit--with-refresh-cache (cons default-directory args)
    (with-temp-buffer
      (apply #'magit-git-insert args)
      (unless (bobp)
        (goto-char (point-min))
        (buffer-substring-no-properties (point) (line-end-position))))))

(defun magit-git-lines (&rest args)
  "Execute Git with ARGS, returning its output as a list of lines.
Empty lines anywhere in the output are omitted.

If Git exits with a non-zero exit status, then report show a
message and add a section in the respective process buffer."
  (with-temp-buffer
    (apply #'magit-git-insert args)
    (split-string (buffer-string) "\n" t)))

(defun magit-git-items (&rest args)
  "Execute Git with ARGS, returning its null-separated output as a list.
Empty items anywhere in the output are omitted.

If Git exits with a non-zero exit status, then report show a
message and add a section in the respective process buffer."
  (with-temp-buffer
    (apply #'magit-git-insert args)
    (split-string (buffer-string) "\0" t)))

(defun magit-git-wash (washer &rest args)
  "Execute Git with ARGS, inserting washed output at point.
Actually first insert the raw output at point.  If there is no
output, call `magit-cancel-section'.  Otherwise temporarily narrow
the buffer to the inserted text, move to its beginning, and then
call function WASHER with ARGS as its sole argument."
  (declare (indent 1))
  (let ((beg (point)))
    (setq args (-flatten args))
    (magit-git-insert args)
    (if (= (point) beg)
        (magit-cancel-section)
      (unless (bolp)
        (insert "\n"))
      (save-restriction
        (narrow-to-region beg (point))
        (goto-char beg)
        (funcall washer args))
      (when (or (= (point) beg)
                (= (point) (1+ beg)))
        (magit-cancel-section))
      (magit-maybe-make-margin-overlay))))

(defun magit-git-version (&optional raw)
  (--when-let (let (magit-git-global-arguments)
                (ignore-errors (substring (magit-git-string "version") 12)))
    (if raw it (and (string-match "\\`\\([0-9]+\\(\\.[0-9]+\\)\\{1,2\\}\\)" it)
                    (match-string 1 it)))))

;;; Variables

(defun magit-config-get-from-cached-list (key)
  (gethash
   ;; `git config --list' downcases first and last components of the key.
   (--> key
        (replace-regexp-in-string "\\`[^.]+" #'downcase it t t)
        (replace-regexp-in-string "[^.]+\\'" #'downcase it t t))
   (magit--with-refresh-cache (cons (magit-toplevel) 'config)
     (let ((configs (make-hash-table :test 'equal)))
       (dolist (conf (magit-git-items "config" "--list" "-z"))
         (let* ((nl-pos (cl-position ?\n conf))
                (key (substring conf 0 nl-pos))
                (val (if nl-pos (substring conf (1+ nl-pos)) "")))
           (puthash key (nconc (gethash key configs) (list val)) configs)))
       configs))))

(defun magit-get (&rest keys)
  "Return the value of the Git variable specified by KEYS."
  (car (last (apply 'magit-get-all keys))))

(defun magit-get-all (&rest keys)
  "Return all values of the Git variable specified by KEYS."
  (let ((magit-git-debug nil)
        (arg (and (or (null (car keys))
                      (string-prefix-p "--" (car keys)))
                  (pop keys)))
        (key (mapconcat 'identity keys ".")))
    (if (and magit--refresh-cache (not arg))
        (magit-config-get-from-cached-list key)
      (magit-git-items "config" arg "-z" "--get-all" key))))

(defun magit-get-boolean (&rest keys)
  "Return the boolean value of the Git variable specified by KEYS."
  (let ((key (mapconcat 'identity keys ".")))
    (if magit--refresh-cache
        (equal "true" (car (last (magit-config-get-from-cached-list key))))
      (equal (magit-git-str "config" "--bool" key) "true"))))

(defun magit-set (value &rest keys)
  "Set the value of the Git variable specified by KEYS to VALUE."
  (let ((arg (and (or (null (car keys))
                      (string-prefix-p "--" (car keys)))
                  (pop keys)))
        (key (mapconcat 'identity keys ".")))
    (if value
        (magit-git-success "config" arg key value)
      (magit-git-success "config" arg "--unset" key))
    value))

(gv-define-setter magit-get (val &rest keys)
  `(magit-set ,val ,@keys))

(defun magit-set-all (values &rest keys)
  "Set all values of the Git variable specified by KEYS to VALUES."
  (let ((arg (and (or (null (car keys))
                      (string-prefix-p "--" (car keys)))
                  (pop keys)))
        (var (mapconcat 'identity keys ".")))
    (when (magit-get var)
      (magit-call-git "config" arg "--unset-all" var))
    (dolist (v values)
      (magit-call-git "config" arg "--add" var v))))

;;; Files

(defun magit--safe-default-directory (&optional file)
  (catch 'unsafe-default-dir
    (let ((dir (file-name-as-directory
                (expand-file-name (or file default-directory))))
          (previous nil))
      (while (not (magit-file-accessible-directory-p dir))
        (setq dir (file-name-directory (directory-file-name dir)))
        (when (equal dir previous)
          (throw 'unsafe-default-dir nil))
        (setq previous dir))
      dir)))

(defmacro magit--with-safe-default-directory (file &rest body)
  (declare (indent 1) (debug (form body)))
  `(when-let ((default-directory (magit--safe-default-directory ,file)))
     ,@body))

(defun magit-gitdir (&optional directory)
  "Return the absolute and resolved path of the .git directory.

If the `GIT_DIR' environment variable is define then return that.
Otherwise return the .git directory for DIRECTORY, or if that is
nil, then for `default-directory' instead.  If the directory is
not located inside a Git repository, then return nil."
  (let ((default-directory (or directory default-directory)))
    (magit-git-dir)))

(defun magit-git-dir (&optional path)
  "Return the absolute and resolved path of the .git directory.

If the `GIT_DIR' environment variable is define then return that.
Otherwise return the .git directory for `default-directory'.  If
the directory is not located inside a Git repository, then return
nil."
  (magit--with-refresh-cache (list default-directory 'magit-git-dir path)
    (magit--with-safe-default-directory nil
      (when-let ((dir (magit-rev-parse-safe "--git-dir")))
        (setq dir (file-name-as-directory (magit-expand-git-file-name dir)))
        (unless (file-remote-p dir)
          (setq dir (concat (file-remote-p default-directory) dir)))
        (if path (expand-file-name (convert-standard-filename path) dir) dir)))))

(defvar magit--separated-gitdirs nil)

(defun magit--record-separated-gitdir ()
  (let ((topdir (magit-toplevel))
        (gitdir (magit-git-dir)))
    ;; Kludge: git-annex converts submodule gitdirs to symlinks. See #3599.
    (when (file-symlink-p (directory-file-name gitdir))
      (setq gitdir (file-truename gitdir)))
    ;; We want to delete the entry for `topdir' here, rather than within
    ;; (unless ...), in case a `--separate-git-dir' repository was switched to
    ;; the standard structure (i.e., "topdir/.git/").
    (setq magit--separated-gitdirs (cl-delete topdir
                                              magit--separated-gitdirs
                                              :key #'car :test #'equal))
    (unless (equal (file-name-as-directory (expand-file-name ".git" topdir))
                   gitdir)
      (push (cons topdir gitdir) magit--separated-gitdirs))))

(defun magit-toplevel (&optional directory)
  "Return the absolute path to the toplevel of the current repository.

From within the working tree or control directory of a repository
return the absolute path to the toplevel directory of the working
tree.  As a special case, from within a bare repository return
the control directory instead.  When called outside a repository
then return nil.

When optional DIRECTORY is non-nil then return the toplevel for
that directory instead of the one for `default-directory'.

Try to respect the option `find-file-visit-truename', i.e.  when
the value of that option is nil, then avoid needlessly returning
the truename.  When a symlink to a sub-directory of the working
tree is involved, or when called from within a sub-directory of
the gitdir or from the toplevel of a gitdir, which itself is not
located within the working tree, then it is not possible to avoid
returning the truename."
  (magit--with-refresh-cache
      (cons (or directory default-directory) 'magit-toplevel)
    (magit--with-safe-default-directory directory
      (if-let ((topdir (magit-rev-parse-safe "--show-toplevel")))
          (let (updir)
            (setq topdir (magit-expand-git-file-name topdir))
            (if (and
                 ;; Always honor these settings.
                 (not find-file-visit-truename)
                 (not (getenv "GIT_WORK_TREE"))
                 ;; `--show-cdup' is the relative path to the toplevel
                 ;; from `(file-truename default-directory)'.  Here we
                 ;; pretend it is relative to `default-directory', and
                 ;; go to that directory.  Then we check whether
                 ;; `--show-toplevel' still returns the same value and
                 ;; whether `--show-cdup' now is the empty string.  If
                 ;; both is the case, then we are at the toplevel of
                 ;; the same working tree, but also avoided needlessly
                 ;; following any symlinks.
                 (progn
                   (setq updir (file-name-as-directory
                                (magit-rev-parse-safe "--show-cdup")))
                   (setq updir (if (file-name-absolute-p updir)
                                   (concat (file-remote-p default-directory) updir)
                                 (expand-file-name updir)))
                   (let ((default-directory updir))
                     (and (string-equal (magit-rev-parse-safe "--show-cdup") "")
                          (--when-let (magit-rev-parse-safe "--show-toplevel")
                            (string-equal (magit-expand-git-file-name it)
                                          topdir))))))
                updir
              (concat (file-remote-p default-directory)
                      (file-name-as-directory topdir))))
        (when-let ((gitdir (magit-rev-parse-safe "--git-dir")))
          (setq gitdir (file-name-as-directory
                        (if (file-name-absolute-p gitdir)
                            ;; We might have followed a symlink.
                            (concat (file-remote-p default-directory)
                                    (magit-expand-git-file-name gitdir))
                          (expand-file-name gitdir))))
          (if (magit-bare-repo-p)
              gitdir
            (let* ((link (expand-file-name "gitdir" gitdir))
                   (wtree (and (file-exists-p link)
                               (magit-file-line link))))
              (cond
               ((and wtree
                     ;; Ignore .git/gitdir files that result from a
                     ;; Git bug.  See #2364.
                     (not (equal wtree ".git")))
                ;; Return the linked working tree.
                (file-name-directory wtree))
               ;; The working directory may not be the parent directory of
               ;; .git if it was set up with `git init --separate-git-dir'.
               ;; See #2955.
               ((car (rassoc gitdir magit--separated-gitdirs)))
               (t
                ;; Step outside the control directory to enter the working tree.
                (file-name-directory (directory-file-name gitdir)))))))))))

(defmacro magit-with-toplevel (&rest body)
  (declare (indent defun) (debug (body)))
  (let ((toplevel (cl-gensym "toplevel")))
    `(let ((,toplevel (magit-toplevel)))
       (if ,toplevel
           (let ((default-directory ,toplevel))
             ,@body)
         (magit--not-inside-repository-error)))))

(define-error 'magit-outside-git-repo "Not inside Git repository")
(define-error 'magit-git-executable-not-found
  "Git executable cannot be found (see https://magit.vc/goto/e6a78ed2)")

(defun magit--not-inside-repository-error ()
  (if (executable-find magit-git-executable)
      (signal 'magit-outside-git-repo default-directory)
    (signal 'magit-git-executable-not-found magit-git-executable)))

(defun magit-inside-gitdir-p (&optioal noerror)
  "Return t if `default-directory' is below the repository directory.
If it is below the working directory, then return nil.
If it isn't below either, then signal an error unless NOERROR
is non-nil, in which case return nil."
  (and (magit--assert-default-directory noerror)
       ;; Below a repository directory that is not located below the
       ;; working directory "git rev-parse --is-inside-git-dir" prints
       ;; "false", which is wrong.
       (let ((gitdir (magit-git-dir)))
         (cond (gitdir (file-in-directory-p default-directory gitdir))
               (noerror nil)
               (t (signal 'magit-outside-git-repo default-directory))))))

(defun magit-inside-worktree-p (&optional noerror)
  "Return t if `default-directory' is below the working directory.
If it is below the repository directory, then return nil.
If it isn't below either, then signal an error unless NOERROR
is non-nil, in which case return nil."
  (and (magit--assert-default-directory noerror)
       (condition-case nil
           (magit-rev-parse-true "--is-inside-work-tree")
         (magit-invalid-git-boolean
          (and (not noerror)
               (signal 'magit-outside-git-repo default-directory))))))

(cl-defgeneric magit-bare-repo-p (&optional noerror)
  "Return t if the current repository is bare.
If it is non-bare, then return nil.  If `default-directory'
isn't below a Git repository, then signal an error unless
NOERROR is non-nil, in which case return nil."
  (and (magit--assert-default-directory noerror)
       (condition-case nil
           (magit-rev-parse-true "--is-bare-repository")
         (magit-invalid-git-boolean
          (and (not noerror)
               (signal 'magit-outside-git-repo default-directory))))))

(defun magit--assert-default-directory (&optional noerror)
  (or (file-directory-p default-directory)
      (and (not noerror)
           (let ((exists (file-exists-p default-directory)))
             (signal (if exists 'file-error 'file-missing)
                     (list "Running git in directory"
                           (if exists
                               "Not a directory"
                             "No such file or directory")
                           default-directory))))))

(defun magit-git-repo-p (directory &optional non-bare)
  "Return t if DIRECTORY is a Git repository.
When optional NON-BARE is non-nil also return nil if DIRECTORY is
a bare repository."
  (and (file-directory-p directory) ; Avoid archives, see #3397.
       (or (file-regular-p (expand-file-name ".git" directory))
           (file-directory-p (expand-file-name ".git" directory))
           (and (not non-bare)
                (file-regular-p (expand-file-name "HEAD" directory))
                (file-directory-p (expand-file-name "refs" directory))
                (file-directory-p (expand-file-name "objects" directory))))))

(defun magit-file-relative-name (&optional file tracked)
  "Return the path of FILE relative to the repository root.

If optional FILE is nil or omitted, return the relative path of
the file being visited in the current buffer, if any, else nil.
If the file is not inside a Git repository, then return nil.

If TRACKED is non-nil, return the path only if it matches a
tracked file."
  (unless file
    (with-current-buffer (or (buffer-base-buffer)
                             (current-buffer))
      (setq file (or magit-buffer-file-name buffer-file-name
                     (and (derived-mode-p 'dired-mode) default-directory)))))
  (when (and file (or (not tracked)
                      (magit-file-tracked-p (file-relative-name file))))
    (--when-let (magit-toplevel
                 (magit--safe-default-directory
                  (directory-file-name (file-name-directory file))))
      (file-relative-name file it))))

(defun magit-file-tracked-p (file)
  (magit-git-success "ls-files" "--error-unmatch" file))

(defun magit-list-files (&rest args)
  (apply #'magit-git-items "ls-files" "-z" "--full-name" args))

(defun magit-tracked-files ()
  (magit-list-files "--cached"))

(defun magit-untracked-files (&optional all files)
  (magit-list-files "--other" (unless all "--exclude-standard") "--" files))

(defun magit-unstaged-files (&optional nomodules files)
  (magit-git-items "diff-files" "-z" "--name-only"
                   (and nomodules "--ignore-submodules")
                   "--" files))

(defun magit-staged-files (&optional nomodules files)
  (magit-git-items "diff-index" "-z" "--name-only" "--cached"
                   (and nomodules "--ignore-submodules")
                   (magit-headish) "--" files))

(defun magit-binary-files (&rest args)
  (--mapcat (and (string-match "^-\t-\t\\(.+\\)" it)
                 (list (match-string 1 it)))
            (apply #'magit-git-items
                   "diff" "-z" "--numstat" "--ignore-submodules"
                   args)))

(defun magit-unmerged-files ()
  (magit-git-items "diff-files" "-z" "--name-only" "--diff-filter=U"))

(defun magit-ignored-files ()
  (magit-git-items "ls-files" "-z" "--others" "--ignored"
                   "--exclude-standard" "--directory"))

(defun magit-skip-worktree-files ()
  (--keep (and (and (= (aref it 0) ?S)
                    (substring it 2)))
          (magit-list-files "-t")))

(defun magit-assume-unchanged-files ()
  (--keep (and (and (memq (aref it 0) '(?h ?s ?m ?r ?c ?k))
                    (substring it 2)))
          (magit-list-files "-v")))

(defun magit-revision-files (rev)
  (magit-with-toplevel
    (magit-git-items "ls-tree" "-z" "-r" "--name-only" rev)))

(defun magit-changed-files (rev-or-range &optional other-rev)
  "Return list of files the have changed between two revisions.
If OTHER-REV is non-nil, REV-OR-RANGE should be a revision, not a
range.  Otherwise, it can be any revision or range accepted by
\"git diff\" (i.e., <rev>, <revA>..<revB>, or <revA>...<revB>)."
  (magit-with-toplevel
    (magit-git-items "diff" "-z" "--name-only" rev-or-range other-rev)))

(defun magit-renamed-files (revA revB)
  (--map (cons (nth 1 it) (nth 2 it))
         (-partition 3 (magit-git-items
                        "diff-tree" "-r" "--diff-filter=R" "-z" "-M"
                        revA revB))))

(defun magit-file-status (&rest args)
  (with-temp-buffer
    (save-excursion (magit-git-insert "status" "-z" args))
    (let ((pos (point)) status)
      (while (> (skip-chars-forward "[:print:]") 0)
        (let ((x (char-after     pos))
              (y (char-after (1+ pos)))
              (file (buffer-substring (+ pos 3) (point))))
          (forward-char)
          (if (memq x '(?R ?C))
              (progn
                (setq pos (point))
                (skip-chars-forward "[:print:]")
                (push (list file (buffer-substring pos (point)) x y) status)
                (forward-char))
            (push (list file nil x y) status)))
        (setq pos (point)))
      status)))

(defcustom magit-cygwin-mount-points
  (when (eq system-type 'windows-nt)
    (cl-sort (--map (if (string-match "^\\(.*\\) on \\(.*\\) type" it)
                        (cons (file-name-as-directory (match-string 2 it))
                              (file-name-as-directory (match-string 1 it)))
                      (lwarn '(magit) :error
                             "Failed to parse Cygwin mount: %S" it))
                    ;; If --exec-path is not a native Windows path,
                    ;; then we probably have a cygwin git.
                    (let ((process-environment
                           (append magit-git-environment process-environment)))
                      (and (not (string-match-p
                                 "\\`[a-zA-Z]:"
                                 (car (process-lines
                                       magit-git-executable "--exec-path"))))
                           (ignore-errors (process-lines "mount")))))
             #'> :key (pcase-lambda (`(,cyg . ,_win)) (length cyg))))
  "Alist of (CYGWIN . WIN32) directory names.
Sorted from longest to shortest CYGWIN name."
  :package-version '(magit . "2.3.0")
  :group 'magit-process
  :type '(alist :key-type string :value-type directory))

(defun magit-expand-git-file-name (filename)
  (unless (file-name-absolute-p filename)
    (setq filename (expand-file-name filename)))
  (-if-let ((cyg . win)
            (cl-assoc filename magit-cygwin-mount-points
                      :test (lambda (f cyg) (string-prefix-p cyg f))))
      (concat win (substring filename (length cyg)))
    filename))

(defun magit-convert-filename-for-git (filename)
  "Convert FILENAME so that it can be passed to git.
1. If it's a remote filename, then remove the remote part.
2. Deal with an `windows-nt' Emacs vs. Cygwin Git incompatibility."
  (if (file-name-absolute-p filename)
      (-if-let ((cyg . win)
                (cl-rassoc filename magit-cygwin-mount-points
                           :test (lambda (f win) (string-prefix-p win f))))
          (concat cyg (substring filename (length win)))
        (or (file-remote-p filename 'localname)
            filename))
    filename))

(defun magit-decode-git-path (path)
  (if (eq (aref path 0) ?\")
      (decode-coding-string (read path)
                            (or magit-git-output-coding-system
                                (car default-process-coding-system))
                            t)
    path))

(defun magit-file-at-point (&optional expand assert)
  (if-let ((file (magit-section-case
                   (file (oref it value))
                   (hunk (magit-section-parent-value it)))))
      (if expand
          (expand-file-name file (magit-toplevel))
        file)
    (when assert
      (user-error "No file at point"))))

(defun magit-current-file ()
  (or (magit-file-relative-name)
      (magit-file-at-point)
      (and (derived-mode-p 'magit-log-mode)
           (car magit-buffer-log-files))))

;;; Predicates

(defun magit-no-commit-p ()
  "Return t if there is no commit in the current Git repository."
  (not (magit-rev-verify "HEAD")))

(defun magit-merge-commit-p (commit)
  "Return t if COMMIT is a merge commit."
  (> (length (magit-commit-parents commit)) 1))

(defun magit-anything-staged-p (&optional ignore-submodules &rest files)
  "Return t if there are any staged changes.
If optional FILES is non-nil, then only changes to those files
are considered."
  (magit-git-failure "diff" "--quiet" "--cached"
                     (and ignore-submodules "--ignore-submodules")
                     "--" files))

(defun magit-anything-unstaged-p (&optional ignore-submodules &rest files)
  "Return t if there are any unstaged changes.
If optional FILES is non-nil, then only changes to those files
are considered."
  (magit-git-failure "diff" "--quiet"
                     (and ignore-submodules "--ignore-submodules")
                     "--" files))

(defun magit-anything-modified-p (&optional ignore-submodules &rest files)
  "Return t if there are any staged or unstaged changes.
If optional FILES is non-nil, then only changes to those files
are considered."
  (or (apply 'magit-anything-staged-p   ignore-submodules files)
      (apply 'magit-anything-unstaged-p ignore-submodules files)))

(defun magit-anything-unmerged-p (&rest files)
  "Return t if there are any merge conflicts.
If optional FILES is non-nil, then only conflicts in those files
are considered."
  (and (magit-git-string "ls-files" "--unmerged" files) t))

(defun magit-module-worktree-p (module)
  (magit-with-toplevel
    (file-exists-p (expand-file-name (expand-file-name ".git" module)))))

(defun magit-module-no-worktree-p (module)
  (not (magit-module-worktree-p module)))

(defun magit-ignore-submodules-p ()
  (cl-find-if (lambda (arg)
                (string-prefix-p "--ignore-submodules" arg))
              magit-buffer-diff-args))

;;; Revisions and References

(defun magit-rev-parse (&rest args)
  "Execute `git rev-parse ARGS', returning first line of output.
If there is no output, return nil."
  (apply #'magit-git-string "rev-parse" args))

(defun magit-rev-parse-safe (&rest args)
  "Execute `git rev-parse ARGS', returning first line of output.
If there is no output, return nil.  Like `magit-rev-parse' but
ignore `magit-git-debug'."
  (apply #'magit-git-str "rev-parse" args))

(defun magit-rev-parse-true (&rest args)
  "Execute `git rev-parse ARGS', returning t if it prints \"true\".
If it prints \"false\", then return nil.  For any other output
signal an error."
  (magit-git-true "rev-parse" args))

(defun magit-rev-parse-false (&rest args)
  "Execute `git rev-parse ARGS', returning t if it prints \"false\".
If it prints \"true\", then return nil.  For any other output
signal an error."
  (magit-git-false "rev-parse" args))

(defun magit-rev-parse-p (&rest args)
  "Execute `git rev-parse ARGS', returning t if it prints \"true\".
Return t if the first (and usually only) output line is the
string \"true\", otherwise return nil."
  (equal (magit-git-str "rev-parse" args) "true"))

(defun magit-rev-verify (rev)
  (magit-git-string-p "rev-parse" "--verify" rev))

(defun magit-commit-p (rev)
  "Return full hash for REV if it names an existing commit."
  (magit-rev-verify (concat rev "^{commit}")))

(defalias 'magit-rev-verify-commit 'magit-commit-p)

(defalias 'magit-rev-hash 'magit-commit-p)

(defun magit-rev-equal (a b)
  "Return t if there are no differences between the commits A and B."
  (magit-git-success "diff" "--quiet" a b))

(defun magit-rev-eq (a b)
  "Return t if A and B refer to the same commit."
  (let ((a (magit-commit-p a))
        (b (magit-commit-p b)))
    (and a b (equal a b))))

(defun magit-rev-ancestor-p (a b)
  "Return non-nil if commit A is an ancestor of commit B."
  (magit-git-success "merge-base" "--is-ancestor" a b))

(defun magit-rev-head-p (rev)
  (or (equal rev "HEAD")
      (and rev
           (not (string-match-p "\\.\\." rev))
           (equal (magit-rev-parse rev)
                  (magit-rev-parse "HEAD")))))

(defun magit-rev-author-p (rev)
  "Return t if the user is the author of REV.
More precisely return t if `user.name' is equal to the author
name of REV and/or `user.email' is equal to the author email
of REV."
  (or (equal (magit-get "user.name")  (magit-rev-format "%an" rev))
      (equal (magit-get "user.email") (magit-rev-format "%ae" rev))))

(defun magit-rev-name (rev &optional pattern not-anchored)
  "Return a symbolic name for REV using `git-name-rev'.

PATTERN can be used to limit the result to a matching ref.
Unless NOT-ANCHORED is non-nil, the beginning of the ref must
match PATTERN.

An anchored lookup is done using the arguments
\"--exclude=*/<PATTERN> --exclude=*/HEAD\" in addition to
\"--refs=<PATTERN>\", provided at least version v2.13 of Git is
used.  Older versions did not support the \"--exclude\" argument.
When \"--exclude\" cannot be used and `git-name-rev' returns a
ref that should have been excluded, then that is discarded and
this function returns nil instead.  This is unfortunate because
there might be other refs that do match.  To fix that, update
Git."
  (if (version< (magit-git-version) "2.13")
      (when-let
          ((ref (magit-git-string "name-rev" "--name-only" "--no-undefined"
                                  (and pattern (concat "--refs=" pattern))
                                  rev)))
        (if (and pattern
                 (string-match-p "\\`refs/[^/]+/\\*\\'" pattern))
            (let ((namespace (substring pattern 0 -1)))
              (and (not (or (string-suffix-p "HEAD" ref)
                            (and (string-match-p namespace ref)
                                 (not (magit-rev-verify
                                       (concat namespace ref))))))
                   ref))
          ref))
    (magit-git-string "name-rev" "--name-only" "--no-undefined"
                      (and pattern (concat "--refs=" pattern))
                      (and pattern
                           (not not-anchored)
                           (list "--exclude=*/HEAD"
                                 (concat "--exclude=*/" pattern)))
                      rev)))

(defun magit-rev-branch (rev)
  (--when-let (magit-rev-name rev "refs/heads/*")
    (unless (string-match-p "[~^]" it) it)))

(defun magit-get-shortname (rev)
  (let* ((fn (apply-partially 'magit-rev-name rev))
         (name (or (funcall fn "refs/tags/*")
                   (funcall fn "refs/heads/*")
                   (funcall fn "refs/remotes/*"))))
    (cond ((not name)
           (magit-rev-parse "--short" rev))
          ((string-match "^\\(?:tags\\|remotes\\)/\\(.+\\)" name)
           (if (magit-ref-ambiguous-p (match-string 1 name))
               name
             (match-string 1 name)))
          (t (magit-ref-maybe-qualify name)))))

(defun magit-name-branch (rev &optional lax)
  (or (magit-name-local-branch rev)
      (magit-name-remote-branch rev)
      (and lax (or (magit-name-local-branch rev t)
                   (magit-name-remote-branch rev t)))))

(defun magit-name-local-branch (rev &optional lax)
  (--when-let (magit-rev-name rev "refs/heads/*")
    (and (or lax (not (string-match-p "[~^]" it))) it)))

(defun magit-name-remote-branch (rev &optional lax)
  (--when-let (magit-rev-name rev "refs/remotes/*")
    (and (or lax (not (string-match-p "[~^]" it)))
         (substring it 8))))

(defun magit-name-tag (rev &optional lax)
  (--when-let (magit-rev-name rev "refs/tags/*")
    (and (or lax (not (string-match-p "[~^]" it)))
         (substring it 5))))

(defun magit-ref-abbrev (refname)
  "Return an unambigious abbreviation of REFNAME."
  (magit-rev-parse "--verify" "--abbrev-ref" refname))

(defun magit-ref-fullname (refname)
  "Return fully qualified refname for REFNAME.
If REFNAME is ambiguous, return nil."
  (magit-rev-parse "--verify" "--symbolic-full-name" refname))

(defun magit-ref-ambiguous-p (refname)
  (save-match-data
    (if (string-match "\\`\\([^^~]+\\)\\(.*\\)" refname)
        (not (magit-ref-fullname (match-string 1 refname)))
      (error "%S has an unrecognized format" refname))))

(defun magit-ref-maybe-qualify (refname &optional prefix)
  "If REFNAME is ambiguous, try to disambiguate it by prepend PREFIX to it.
Return an unambigious refname, either REFNAME or that prefixed
with PREFIX, nil otherwise.  If REFNAME has an offset suffix
such as \"~1\", then that is preserved.  If optional PREFIX is
nil, then use \"heads/\".  "
  (if (magit-ref-ambiguous-p refname)
      (let ((refname (concat (or prefix "heads/") refname)))
        (and (not (magit-ref-ambiguous-p refname)) refname))
    refname))

(defun magit-ref-exists-p (ref)
  (magit-git-success "show-ref" "--verify" ref))

(defun magit-ref-equal (a b)
  "Return t if the refnames A and B are `equal'.
A symbolic-ref pointing to some ref, is `equal' to that ref,
as are two symbolic-refs pointing to the same ref.  Refnames
may be abbreviated."
  (let ((a (magit-ref-fullname a))
        (b (magit-ref-fullname b)))
    (and a b (equal a b))))

(defun magit-ref-eq (a b)
  "Return t if the refnames A and B are `eq'.
A symbolic-ref is `eq' to itself, but not to the ref it points
to, or to some other symbolic-ref that points to the same ref."
  (let ((symbolic-a (magit-symbolic-ref-p a))
        (symbolic-b (magit-symbolic-ref-p b)))
    (or (and symbolic-a
             symbolic-b
             (equal a b))
        (and (not symbolic-a)
             (not symbolic-b)
             (magit-ref-equal a b)))))

(defun magit-headish ()
  "Return \"HEAD\" or if that doesn't exist the hash of the empty tree."
  (if (magit-no-commit-p)
      (magit-git-string "mktree")
    "HEAD"))

(defun magit-branch-at-point ()
  (magit-section-case
    (branch (oref it value))
    (commit (or (magit--painted-branch-at-point)
                (magit-name-branch (oref it value))))))

(defun magit--painted-branch-at-point (&optional type)
  (or (and (not (eq type 'remote))
           (memq (get-text-property (point) 'font-lock-face)
                 (list 'magit-branch-local
                       'magit-branch-current))
           (when-let ((branch (thing-at-point 'git-revision t)))
             (cdr (magit-split-branch-name branch))))
      (and (not (eq type 'local))
           (memq (get-text-property (point) 'font-lock-face)
                 (list 'magit-branch-remote
                       'magit-branch-remote-head))
           (thing-at-point 'git-revision t))))

(defun magit-local-branch-at-point ()
  (magit-section-case
    (branch (let ((branch (magit-ref-maybe-qualify (oref it value))))
              (when (member branch (magit-list-local-branch-names))
                branch)))
    (commit (or (magit--painted-branch-at-point 'local)
                (magit-name-local-branch (oref it value))))))

(defun magit-remote-branch-at-point ()
  (magit-section-case
    (branch (let ((branch (oref it value)))
              (when (member branch (magit-list-remote-branch-names))
                branch)))
    (commit (or (magit--painted-branch-at-point 'remote)
                (magit-name-remote-branch (oref it value))))))

(defun magit-commit-at-point ()
  (or (magit-section-value-if 'commit)
      (and (derived-mode-p 'magit-stash-mode
                           'magit-merge-preview-mode
                           'magit-revision-mode)
           magit-buffer-revision)))

(defun magit-branch-or-commit-at-point ()
  (or (and magit-buffer-file-name
           magit-buffer-refname)
      (magit-section-case
        (branch (magit-ref-maybe-qualify (oref it value)))
        (commit (or (magit--painted-branch-at-point)
                    (let ((rev (oref it value)))
                      (or (magit-name-branch rev) rev))))
        (tag (magit-ref-maybe-qualify (oref it value) "tags/"))
        (pullreq (or (and (fboundp 'forge--pullreq-branch)
                          (magit-branch-p
                           (forge--pullreq-branch (oref it value))))
                     (magit-ref-p (format "refs/pullreqs/%s"
                                          (oref (oref it value) number))))))
      (thing-at-point 'git-revision t)
      (and (derived-mode-p 'magit-stash-mode
                           'magit-merge-preview-mode
                           'magit-revision-mode)
           magit-buffer-revision)))

(defun magit-tag-at-point ()
  (magit-section-case
    (tag    (oref it value))
    (commit (magit-name-tag (oref it value)))))

(defun magit-stash-at-point ()
  (magit-section-value-if 'stash))

(defun magit-remote-at-point ()
  (magit-section-case
    (remote (oref it value))
    (branch (magit-section-parent-value it))))

(defun magit-module-at-point (&optional predicate)
  (when (magit-section-match 'magit-module-section)
    (let ((module (oref (magit-current-section) value)))
      (and (or (not predicate)
               (funcall predicate module))
           module))))

(defun magit-get-current-branch ()
  "Return the refname of the currently checked out branch.
Return nil if no branch is currently checked out."
  (magit-git-string "symbolic-ref" "--short" "HEAD"))

(defvar magit-get-previous-branch-timeout 0.5
  "Maximum time to spend in `magit-get-previous-branch'.
Given as a number of seconds.")

(defun magit-get-previous-branch ()
  "Return the refname of the previously checked out branch.
Return nil if no branch can be found in the `HEAD' reflog
which is different from the current branch and still exists.
The amount of time spent searching is limited by
`magit-get-previous-branch-timeout'."
  (let ((t0 (float-time))
        (current (magit-get-current-branch))
        (i 1) prev)
    (while (if (> (- (float-time) t0) magit-get-previous-branch-timeout)
               (setq prev nil) ;; Timed out.
             (and (setq prev (magit-rev-verify (format "@{-%i}" i)))
                  (or (not (setq prev (magit-rev-branch prev)))
                      (equal prev current))))
      (cl-incf i))
    prev))

(defun magit-set-upstream-branch (branch upstream)
  "Set UPSTREAM as the upstream of BRANCH.
If UPSTREAM is nil, then unset BRANCH's upstream.
Otherwise UPSTREAM has to be an existing branch."
  (if upstream
      (magit-call-git "branch" "--set-upstream-to" upstream branch)
    (magit-call-git "branch" "--unset-upstream" branch)))

(defun magit-get-upstream-ref (&optional branch)
  "Return the upstream branch of BRANCH as a fully qualified ref.
It BRANCH is nil, then return the upstream of the current branch,
if any, nil otherwise.  If the upstream is not configured, the
configured remote is an url, or the named branch does not exist,
then return nil.  I.e.  return an existing local or
remote-tracking branch ref."
  (when-let ((branch (or branch (magit-get-current-branch))))
    (magit-ref-fullname (concat branch "@{upstream}"))))

(defun magit-get-upstream-branch (&optional branch)
  "Return the name of the upstream branch of BRANCH.
It BRANCH is nil, then return the upstream of the current branch
if any, nil otherwise.  If the upstream is not configured, the
configured remote is an url, or the named branch does not exist,
then return nil.  I.e.  return the name of an existing local or
remote-tracking branch.  The returned string is colorized
according to the branch type."
  (when-let ((branch (or branch (magit-get-current-branch)))
             (upstream (magit-ref-abbrev (concat branch "@{upstream}"))))
    (magit--propertize-face
     upstream (if (equal (magit-get "branch" branch "remote") ".")
                  'magit-branch-local
                'magit-branch-remote))))

(defun magit-get-indirect-upstream-branch (branch &optional force)
  (let ((remote (magit-get "branch" branch "remote")))
    (and remote (not (equal remote "."))
         ;; The user has opted in...
         (or force
             (--some (if (magit-git-success "check-ref-format" "--branch" it)
                         (equal it branch)
                       (string-match-p it branch))
                     magit-branch-prefer-remote-upstream))
         ;; and local BRANCH tracks a remote branch...
         (let ((upstream (magit-get-upstream-branch branch)))
           ;; whose upstream...
           (and upstream
                ;; has the same name as BRANCH...
                (equal (substring upstream (1+ (length remote))) branch)
                ;; and can be fast-forwarded to BRANCH.
                (magit-rev-ancestor-p upstream branch)
                upstream)))))

(defun magit-get-upstream-remote (&optional branch allow-unnamed)
  (when-let ((branch (or branch (magit-get-current-branch)))
             (remote (magit-get "branch" branch "remote")))
    (and (not (equal remote "."))
         (cond ((member remote (magit-list-remotes))
                (magit--propertize-face remote 'magit-branch-remote))
               ((and allow-unnamed
                     (string-match-p "\\(\\`.\\{0,2\\}/\\|[:@]\\)" remote))
                (magit--propertize-face remote 'bold))))))

(defun magit-get-unnamed-upstream (&optional branch)
  (when-let ((branch (or branch (magit-get-current-branch)))
             (remote (magit-get "branch" branch "remote"))
             (merge  (magit-get "branch" branch "merge")))
    (and (magit--unnamed-upstream-p remote merge)
         (list (magit--propertize-face remote 'bold)
               (magit--propertize-face merge 'magit-branch-remote)))))

(defun magit--unnamed-upstream-p (remote merge)
  (and remote (string-match-p "\\(\\`\\.\\{0,2\\}/\\|[:@]\\)" remote)
       merge  (string-prefix-p "refs/" merge)))

(defun magit--valid-upstream-p (remote merge)
  (and (or (equal remote ".")
           (member remote (magit-list-remotes)))
       (string-prefix-p "refs/" merge)))

(defun magit-get-current-remote (&optional allow-unnamed)
  (or (magit-get-upstream-remote nil allow-unnamed)
      (when-let ((remotes (magit-list-remotes))
                 (remote (if (= (length remotes) 1)
                             (car remotes)
                           (car (member "origin" remotes)))))
        (magit--propertize-face remote 'magit-branch-remote))))

(defun magit-get-push-remote (&optional branch)
  (when-let ((remote
              (or (and (or branch (setq branch (magit-get-current-branch)))
                       (magit-get "branch" branch "pushRemote"))
                  (magit-get "remote.pushDefault"))))
    (magit--propertize-face remote 'magit-branch-remote)))

(defun magit-get-push-branch (&optional branch verify)
  (when-let ((branch (or branch (setq branch (magit-get-current-branch))))
             (remote (magit-get-push-remote branch))
             (target (concat remote "/" branch)))
    (and (or (not verify)
             (magit-rev-verify target))
         (magit--propertize-face target 'magit-branch-remote))))

(defun magit-get-@{push}-branch (&optional branch)
  (let ((ref (magit-rev-parse "--symbolic-full-name"
                              (concat branch "@{push}"))))
    (when (and ref (string-prefix-p "refs/remotes/" ref))
      (substring ref 13))))

(defun magit-get-remote (&optional branch)
  (when (or branch (setq branch (magit-get-current-branch)))
    (let ((remote (magit-get "branch" branch "remote")))
      (unless (equal remote ".")
        remote))))

(defun magit-get-some-remote (&optional branch)
  (or (magit-get-remote branch)
      (and (magit-branch-p "master")
           (magit-get-remote "master"))
      (let ((remotes (magit-list-remotes)))
        (or (car (member "origin" remotes))
            (car remotes)))))

(defun magit-branch-merged-p (branch &optional target)
  "Return non-nil if BRANCH is merged into its upstream and TARGET.

TARGET defaults to the current branch.  If `HEAD' is detached and
TARGET is nil, then always return nil.  As a special case, if
TARGET is t, then return non-nil if BRANCH is merged into any one
of the other local branches.

If, and only if, BRANCH has an upstream, then only return non-nil
if BRANCH is merged into both TARGET (as described above) as well
as into its upstream."
  (and (--if-let (and (magit-branch-p branch)
                      (magit-get-upstream-branch branch))
           (magit-git-success "merge-base" "--is-ancestor" branch it)
         t)
       (if (eq target t)
           (delete (magit-name-local-branch branch)
                   (magit-list-containing-branches branch))
         (--when-let (or target (magit-get-current-branch))
           (magit-git-success "merge-base" "--is-ancestor" branch it)))))

(defun magit-get-tracked (refname)
  "Return the remote branch tracked by the remote-tracking branch REFNAME.
The returned value has the form (REMOTE . REF), where REMOTE is
the name of a remote and REF is the ref local to the remote."
  (when-let ((ref (magit-ref-fullname refname)))
    (save-match-data
      (-some (lambda (line)
               (and (string-match "\
\\`remote\\.\\([^.]+\\)\\.fetch=\\+?\\([^:]+\\):\\(.+\\)" line)
                    (let ((rmt (match-string 1 line))
                          (src (match-string 2 line))
                          (dst (match-string 3 line)))
                      (and (string-match (format "\\`%s\\'"
                                                 (replace-regexp-in-string
                                                  "*" "\\(.+\\)" dst t t))
                                         ref)
                           (cons rmt (replace-regexp-in-string
                                      "*" (match-string 1 ref) src))))))
             (magit-git-lines "config" "--local" "--list")))))

(defun magit-split-branch-name (branch)
  (cond ((member branch (magit-list-local-branch-names))
         (cons "." branch))
        ((string-match "/" branch)
         (or (-some (lambda (remote)
                      (and (string-match (format "\\`\\(%s\\)/\\(.+\\)\\'" remote)
                                         branch)
                           (cons (match-string 1 branch)
                                 (match-string 2 branch))))
                    (magit-list-remotes))
             (error "Invalid branch name %s" branch)))))

(defun magit-get-current-tag (&optional rev with-distance)
  "Return the closest tag reachable from REV.

If optional REV is nil, then default to `HEAD'.
If optional WITH-DISTANCE is non-nil then return (TAG COMMITS),
if it is `dirty' return (TAG COMMIT DIRTY). COMMITS is the number
of commits in `HEAD' but not in TAG and DIRTY is t if there are
uncommitted changes, nil otherwise."
  (--when-let (magit-git-str "describe" "--long" "--tags"
                             (and (eq with-distance 'dirty) "--dirty") rev)
    (save-match-data
      (string-match
       "\\(.+\\)-\\(?:0[0-9]*\\|\\([0-9]+\\)\\)-g[0-9a-z]+\\(-dirty\\)?$" it)
      (if with-distance
          `(,(match-string 1 it)
            ,(string-to-number (or (match-string 2 it) "0"))
            ,@(and (match-string 3 it) (list t)))
        (match-string 1 it)))))

(defun magit-get-next-tag (&optional rev with-distance)
  "Return the closest tag from which REV is reachable.

If optional REV is nil, then default to `HEAD'.
If no such tag can be found or if the distance is 0 (in which
case it is the current tag, not the next), return nil instead.
If optional WITH-DISTANCE is non-nil, then return (TAG COMMITS)
where COMMITS is the number of commits in TAG but not in REV."
  (--when-let (magit-git-str "describe" "--contains" (or rev "HEAD"))
    (save-match-data
      (when (string-match "^[^^~]+" it)
        (setq it (match-string 0 it))
        (unless (equal it (magit-get-current-tag rev))
          (if with-distance
              (list it (car (magit-rev-diff-count it rev)))
            it))))))

(defvar magit-list-refs-namespaces
  '("refs/heads" "refs/remotes" "refs/tags" "refs/pull"))

(defun magit-list-refs (&optional namespaces format sortby)
  "Return list of references.

When NAMESPACES is non-nil, list refs from these namespaces
rather than those from `magit-list-refs-namespaces'.

FORMAT is passed to the `--format' flag of `git for-each-ref'
and defaults to \"%(refname)\".  If the format is \"%(refname)\"
or \"%(refname:short)\", then drop the symbolic-ref \"HEAD\".

SORTBY is a key or list of keys to pass to the `--sort' flag of
`git for-each-ref'.  When nil, use `magit-list-refs-sortby'"
  (unless format
    (setq format "%(refname)"))
  (let ((refs (magit-git-lines "for-each-ref"
                               (concat "--format=" format)
                               (--map (concat "--sort=" it)
                                      (pcase (or sortby magit-list-refs-sortby)
                                        ((and val (pred stringp)) (list val))
                                        ((and val (pred listp)) val)))
                               (or namespaces magit-list-refs-namespaces))))
    (if (member format '("%(refname)" "%(refname:short)"))
        (--remove (string-match-p "\\(\\`\\|/\\)HEAD\\'" it) refs)
      refs)))

(defun magit-list-branches ()
  (magit-list-refs (list "refs/heads" "refs/remotes")))

(defun magit-list-local-branches ()
  (magit-list-refs "refs/heads"))

(defun magit-list-remote-branches (&optional remote)
  (magit-list-refs (concat "refs/remotes/" remote)))

(defun magit-list-related-branches (relation &optional commit arg)
  (--remove (string-match-p "\\(\\`(HEAD\\|HEAD -> \\)" it)
            (--map (substring it 2)
                   (magit-git-lines "branch" arg relation commit))))

(defun magit-list-containing-branches (&optional commit arg)
  (magit-list-related-branches "--contains" commit arg))

(defun magit-list-publishing-branches (&optional commit)
  (--filter (magit-rev-ancestor-p commit it)
            magit-published-branches))

(defun magit-list-merged-branches (&optional commit arg)
  (magit-list-related-branches "--merged" commit arg))

(defun magit-list-unmerged-branches (&optional commit arg)
  (magit-list-related-branches "--no-merged" commit arg))

(defun magit-list-unmerged-to-upstream-branches ()
  (--filter (when-let ((upstream (magit-get-upstream-branch it)))
              (member it (magit-list-unmerged-branches upstream)))
            (magit-list-local-branch-names)))

(defun magit-list-branches-pointing-at (commit)
  (let ((re (format "\\`%s refs/\\(heads\\|remotes\\)/\\(.*\\)\\'"
                   (magit-rev-verify commit))))
    (--keep (and (string-match re it)
                 (let ((name (match-string 2 it)))
                   (and (not (string-suffix-p "HEAD" name))
                        name)))
            (magit-git-lines "show-ref"))))

(defun magit-list-refnames (&optional namespaces include-special)
  (nconc (magit-list-refs namespaces "%(refname:short)")
         (and include-special
              (magit-list-special-refnames))))

(defvar magit-special-refnames
  '("HEAD" "ORIG_HEAD" "FETCH_HEAD" "MERGE_HEAD" "CHERRY_PICK_HEAD"))

(defun magit-list-special-refnames ()
  (let ((gitdir (magit-gitdir)))
    (cl-mapcan (lambda (name)
                 (and (file-exists-p (expand-file-name name gitdir))
                      (list name)))
               magit-special-refnames)))

(defun magit-list-branch-names ()
  (magit-list-refnames (list "refs/heads" "refs/remotes")))

(defun magit-list-local-branch-names ()
  (magit-list-refnames "refs/heads"))

(defun magit-list-remote-branch-names (&optional remote relative)
  (if (and remote relative)
      (let ((regexp (format "^refs/remotes/%s/\\(.+\\)" remote)))
        (--mapcat (when (string-match regexp it)
                    (list (match-string 1 it)))
                  (magit-list-remote-branches remote)))
    (magit-list-refnames (concat "refs/remotes/" remote))))

(defun magit-format-refs (format &rest args)
  (let ((lines (magit-git-lines
                "for-each-ref" (concat "--format=" format)
                (or args (list "refs/heads" "refs/remotes" "refs/tags")))))
    (if (string-match-p "\f" format)
        (--map (split-string it "\f") lines)
      lines)))

(defun magit-list-remotes ()
  (magit-git-lines "remote"))

(defun magit-list-tags ()
  (magit-git-lines "tag"))

(defun magit-list-stashes (&optional format)
  (magit-git-lines "stash" "list" (concat "--format=" (or format "%gd"))))

(defun magit-list-active-notes-refs ()
  "Return notes refs according to `core.notesRef' and `notes.displayRef'."
  (magit-git-lines "for-each-ref" "--format=%(refname)"
                   (or (magit-get "core.notesRef") "refs/notes/commits")
                   (magit-get-all "notes.displayRef")))

(defun magit-list-notes-refnames ()
  (--map (substring it 6) (magit-list-refnames "refs/notes")))

(defun magit-remote-list-tags (remote)
  (--keep (and (not (string-match-p "\\^{}$" it))
               (substring it 51))
          (magit-git-lines "ls-remote" "--tags" remote)))

(defun magit-remote-list-branches (remote)
  (--keep (and (not (string-match-p "\\^{}$" it))
               (substring it 52))
          (magit-git-lines "ls-remote" "--heads" remote)))

(defun magit-remote-list-refs (remote)
  (--keep (and (not (string-match-p "\\^{}$" it))
               (substring it 41))
          (magit-git-lines "ls-remote" remote)))

(defun magit-list-module-paths ()
  (--mapcat (and (string-match "^160000 [0-9a-z]\\{40\\} 0\t\\(.+\\)$" it)
                 (list (match-string 1 it)))
            (magit-git-items "ls-files" "-z" "--stage")))

(defun magit-get-submodule-name (path)
  "Return the name of the submodule at PATH.
PATH has to be relative to the super-repository."
  (cadr (split-string
         (car (or (magit-git-items
                   "config" "-z"
                   "-f" (expand-file-name ".gitmodules" (magit-toplevel))
                   "--get-regexp" "^submodule\\..*\\.path$"
                   (concat "^" (regexp-quote (directory-file-name path)) "$"))
                  (error "No such submodule `%s'" path)))
         "\n")))

(defun magit-list-worktrees ()
  (let (worktrees worktree)
    (dolist (line (let ((magit-git-global-arguments
                         ;; KLUDGE At least in v2.8.3 this triggers a segfault.
                         (remove "--no-pager" magit-git-global-arguments)))
                    (magit-git-lines "worktree" "list" "--porcelain")))
      (cond ((string-prefix-p "worktree" line)
             (push (setq worktree (list (substring line 9) nil nil nil))
                   worktrees))
            ((string-equal line "bare")
             (let* ((default-directory (car worktree))
                    (wt (and (not (magit-get-boolean "core.bare"))
                             (magit-get "core.worktree"))))
               (if (and wt (file-exists-p (expand-file-name wt)))
                   (progn (setf (nth 0 worktree) (expand-file-name wt))
                          (setf (nth 2 worktree) (magit-rev-parse "HEAD"))
                          (setf (nth 3 worktree) (magit-get-current-branch)))
                 (setf (nth 1 worktree) t))))
            ((string-prefix-p "HEAD" line)
             (setf (nth 2 worktree) (substring line 5)))
            ((string-prefix-p "branch" line)
             (setf (nth 3 worktree) (substring line 18)))
            ((string-equal line "detached"))))
    (nreverse worktrees)))

(defun magit-symbolic-ref-p (name)
  (magit-git-success "symbolic-ref" "--quiet" name))

(defun magit-ref-p (rev)
  (or (car (member rev (magit-list-refs "refs/")))
      (car (member rev (magit-list-refnames "refs/")))))

(defun magit-branch-p (rev)
  (or (car (member rev (magit-list-branches)))
      (car (member rev (magit-list-branch-names)))))

(defun magit-local-branch-p (rev)
  (or (car (member rev (magit-list-local-branches)))
      (car (member rev (magit-list-local-branch-names)))))

(defun magit-remote-branch-p (rev)
  (or (car (member rev (magit-list-remote-branches)))
      (car (member rev (magit-list-remote-branch-names)))))

(defun magit-branch-set-face (branch)
  (magit--propertize-face branch (if (magit-local-branch-p branch)
                                     'magit-branch-local
                                   'magit-branch-remote)))

(defun magit-tag-p (rev)
  (car (member rev (magit-list-tags))))

(defun magit-remote-p (string)
  (car (member string (magit-list-remotes))))

(defun magit-rev-diff-count (a b)
  "Return the commits in A but not B and vice versa.
Return a list of two integers: (A>B B>A)."
  (mapcar 'string-to-number
          (split-string (magit-git-string "rev-list"
                                          "--count" "--left-right"
                                          (concat a "..." b))
                        "\t")))

(defun magit-abbrev-length ()
  (--if-let (magit-get "core.abbrev")
      (string-to-number it)
    ;; Guess the length git will be using based on an example
    ;; abbreviation.  Actually HEAD's abbreviation might be an
    ;; outlier, so use the shorter of the abbreviations for two
    ;; commits.  When a commit does not exist, then fall back
    ;; to the default of 7.  See #3034.
    (min (--if-let (magit-rev-parse "--short" "HEAD")  (length it) 7)
         (--if-let (magit-rev-parse "--short" "HEAD~") (length it) 7))))

(defun magit-abbrev-arg (&optional arg)
  (format "--%s=%d" (or arg "abbrev") (magit-abbrev-length)))

(defun magit-rev-abbrev (rev)
  (magit-rev-parse (magit-abbrev-arg "short") rev))

(defun magit-commit-children (commit &optional args)
  (mapcar #'car
          (--filter (member commit (cdr it))
                    (--map (split-string it " ")
                           (magit-git-lines
                            "log" "--format=%H %P"
                            (or args (list "--branches" "--tags" "--remotes"))
                            "--not" commit)))))

(defun magit-commit-parents (commit)
  (--when-let (magit-git-string "rev-list" "-1" "--parents" commit)
    (cdr (split-string it))))

(defun magit-patch-id (rev)
  (with-temp-buffer
    (magit-process-file
     shell-file-name nil '(t nil) nil shell-command-switch
     (let ((exec (shell-quote-argument magit-git-executable)))
       (format "%s diff-tree -u %s | %s patch-id" exec rev exec)))
    (car (split-string (buffer-string)))))

(defun magit-rev-format (format &optional rev args)
  (let ((str (magit-git-string "show" "--no-patch"
                               (concat "--format=" format) args
                               (if rev (concat rev "^{commit}") "HEAD") "--")))
    (unless (string-equal str "")
      str)))

(defun magit-rev-insert-format (format &optional rev args)
  (magit-git-insert "show" "--no-patch"
                    (concat "--format=" format) args
                    (if rev (concat rev "^{commit}") "HEAD") "--"))

(defun magit-format-rev-summary (rev)
  (--when-let (magit-rev-format "%h %s" rev)
    (string-match " " it)
    (magit--put-face 0 (match-beginning 0) 'magit-hash it)
    it))

(defvar magit-ref-namespaces
  '(("\\`HEAD\\'"                  . magit-head)
    ("\\`refs/tags/\\(.+\\)"       . magit-tag)
    ("\\`refs/heads/\\(.+\\)"      . magit-branch-local)
    ("\\`refs/remotes/\\(.+\\)"    . magit-branch-remote)
    ("\\`refs/bisect/\\(bad\\)"    . magit-bisect-bad)
    ("\\`refs/bisect/\\(skip.*\\)" . magit-bisect-skip)
    ("\\`refs/bisect/\\(good.*\\)" . magit-bisect-good)
    ("\\`refs/stash$"              . magit-refname-stash)
    ("\\`refs/wip/\\(.+\\)"        . magit-refname-wip)
    ("\\`refs/pullreqs/\\(.+\\)"   . magit-refname-pullreq)
    ("\\`\\(bad\\):"               . magit-bisect-bad)
    ("\\`\\(skip\\):"              . magit-bisect-skip)
    ("\\`\\(good\\):"              . magit-bisect-good)
    ("\\`\\(.+\\)"                 . magit-refname))
  "How refs are formatted for display.

Each entry controls how a certain type of ref is displayed, and
has the form (REGEXP . FACE).  REGEXP is a regular expression
used to match full refs.  The first entry whose REGEXP matches
the reference is used.

In log and revision buffers the first regexp submatch becomes the
\"label\" that represents the ref and is propertized with FONT.
In refs buffers the displayed text is controlled by other means
and this option only controls what face is used.")

(defun magit-format-ref-labels (string)
  (save-match-data
    (let ((regexp "\\(, \\|tag: \\|HEAD -> \\)")
          names)
      (if (and (derived-mode-p 'magit-log-mode)
               (member "--simplify-by-decoration" magit-buffer-log-args))
          (let ((branches (magit-list-local-branch-names))
                (re (format "^%s/.+" (regexp-opt (magit-list-remotes)))))
            (setq names
                  (--map (cond ((string-equal it "HEAD")     it)
                               ((string-prefix-p "refs/" it) it)
                               ((member it branches) (concat "refs/heads/" it))
                               ((string-match re it) (concat "refs/remotes/" it))
                               (t                    (concat "refs/" it)))
                         (split-string
                          (replace-regexp-in-string "tag: " "refs/tags/" string)
                          regexp t))))
        (setq names (split-string string regexp t)))
      (let (state head upstream tags branches remotes other combined)
        (dolist (ref names)
          (let* ((face (cdr (--first (string-match (car it) ref)
                                     magit-ref-namespaces)))
                 (name (magit--propertize-face
                        (or (match-string 1 ref) ref) face)))
            (cl-case face
              ((magit-bisect-bad magit-bisect-skip magit-bisect-good)
               (setq state name))
              (magit-head
               (setq head (magit--propertize-face "@" 'magit-head)))
              (magit-tag            (push name tags))
              (magit-branch-local   (push name branches))
              (magit-branch-remote  (push name remotes))
              (t                    (push name other)))))
        (setq remotes
              (-keep
               (lambda (name)
                 (if (string-match "\\`\\([^/]*\\)/\\(.*\\)\\'" name)
                     (let ((r (match-string 1 name))
                           (b (match-string 2 name)))
                       (and (not (equal b "HEAD"))
                            (if (equal (concat "refs/remotes/" name)
                                       (magit-git-string
                                        "symbolic-ref"
                                        (format "refs/remotes/%s/HEAD" r)))
                                (magit--propertize-face
                                 name 'magit-branch-remote-head)
                              name)))
                   name))
               remotes))
        (let* ((current (magit-get-current-branch))
               (target  (magit-get-upstream-branch current)))
          (dolist (name branches)
            (let ((push (car (member (magit-get-push-branch name) remotes))))
              (when push
                (setq remotes (delete push remotes))
                (string-match "^[^/]*/" push)
                (setq push (substring push 0 (match-end 0))))
              (cond
               ((equal name current)
                (setq head
                      (concat push
                              (magit--propertize-face
                               name 'magit-branch-current))))
               ((equal name target)
                (setq upstream
                      (concat push
                              (magit--propertize-face
                               name '(magit-branch-upstream
                                      magit-branch-local)))))
               (t
                (push (concat push name) combined)))))
          (when (and target (not upstream))
            (if (member target remotes)
                (progn
                  (add-face-text-property 0 (length target)
                                          'magit-branch-upstream nil target)
                  (setq upstream target)
                  (setq remotes  (delete target remotes)))
              (when-let ((target (car (member target combined))))
                (add-face-text-property 0 (length target)
                                        'magit-branch-upstream nil target)
                (setq upstream target)
                (setq combined (delete target combined))))))
        (mapconcat #'identity
                   (-flatten `(,state
                               ,head
                               ,upstream
                               ,@(nreverse tags)
                               ,@(nreverse combined)
                               ,@(nreverse remotes)
                               ,@other))
                   " ")))))

(defun magit-object-type (object)
  (magit-git-string "cat-file" "-t" object))

(defmacro magit-with-blob (commit file &rest body)
  (declare (indent 2)
           (debug (form form body)))
  `(with-temp-buffer
     (let ((buffer-file-name ,file))
       (save-excursion
         (magit-git-insert "cat-file" "-p"
                           (concat ,commit ":" buffer-file-name)))
       (decode-coding-inserted-region
        (point-min) (point-max) buffer-file-name t nil nil t)
       ,@body)))

(defmacro magit-with-temp-index (tree arg &rest body)
  (declare (indent 2) (debug (form form body)))
  (let ((file (cl-gensym "file")))
    `(let ((magit--refresh-cache nil)
           (,file (magit-convert-filename-for-git
                   (make-temp-name (magit-git-dir "index.magit.")))))
       (unwind-protect
           (magit-with-toplevel
             (--when-let ,tree
               (or (magit-git-success "read-tree" ,arg it
                                      (concat "--index-output=" ,file))
                   (error "Cannot read tree %s" it)))
             (if (file-remote-p default-directory)
                 (let ((magit-tramp-process-environment
                        (cons (concat "GIT_INDEX_FILE=" ,file)
                              magit-tramp-process-environment)))
                   ,@body)
               (let ((process-environment
                      (cons (concat "GIT_INDEX_FILE=" ,file)
                            process-environment)))
                 ,@body)))
         (ignore-errors
           (delete-file (concat (file-remote-p default-directory) ,file)))))))

(defun magit-commit-tree (message &optional tree &rest parents)
  (magit-git-string "commit-tree" "--no-gpg-sign" "-m" message
                    (--mapcat (list "-p" it) (delq nil parents))
                    (or tree
                        (magit-git-string "write-tree")
                        (error "Cannot write tree"))))

(defun magit-commit-worktree (message &optional arg &rest other-parents)
  (magit-with-temp-index "HEAD" arg
    (and (magit-update-files (magit-unstaged-files))
         (apply #'magit-commit-tree message nil "HEAD" other-parents))))

(defun magit-update-files (files)
  (magit-git-success "update-index" "--add" "--remove" "--" files))

(defun magit-update-ref (ref message rev &optional stashish)
  (let ((magit--refresh-cache nil))
    (or (if (not (version< (magit-git-version) "2.6.0"))
            (zerop (magit-call-git "update-ref" "--create-reflog"
                                   "-m" message ref rev
                                   (or (magit-rev-verify ref) "")))
          ;; `--create-reflog' didn't exist before v2.6.0
          (let ((oldrev  (magit-rev-verify ref))
                (logfile (magit-git-dir (concat "logs/" ref))))
            (unless (file-exists-p logfile)
              (when oldrev
                (magit-git-success "update-ref" "-d" ref oldrev))
              (make-directory (file-name-directory logfile) t)
              (with-temp-file logfile)
              (when (and oldrev (not stashish))
                (magit-git-success "update-ref" "-m" "enable reflog"
                                   ref oldrev ""))))
          (magit-git-success "update-ref" "-m" message ref rev
                             (or (magit-rev-verify ref) "")))
        (error "Cannot update %s with %s" ref rev))))

(defconst magit-range-re
  (concat "\\`\\([^ \t]*[^.]\\)?"       ; revA
          "\\(\\.\\.\\.?\\)"            ; range marker
          "\\([^.][^ \t]*\\)?\\'"))     ; revB

(defun magit-split-range (range)
  (and (string-match magit-range-re range)
       (let ((beg (or (match-string 1 range) "HEAD"))
             (end (or (match-string 3 range) "HEAD")))
         (cons (if (string-equal (match-string 2 range) "...")
                   (magit-git-string "merge-base" beg end)
                 beg)
               end))))

(defun magit-hash-range (range)
  (if (string-match magit-range-re range)
      (concat (magit-rev-hash (match-string 1 range))
              (match-string 2 range)
              (magit-rev-hash (match-string 3 range)))
    (magit-rev-hash range)))

(put 'git-revision 'thing-at-point 'magit-thingatpt--git-revision)
(defun magit-thingatpt--git-revision ()
  (--when-let
      (let ((c "\s\n\t~^:?*[\\"))
        (cl-letf (((get 'git-revision 'beginning-op)
                   (if (re-search-backward (format "[%s]" c) nil t)
                       (forward-char)
                     (goto-char (point-min))))
                  ((get 'git-revision 'end-op)
                   (lambda ()
                     (re-search-forward (format "\\=[^%s]*" c) nil t))))
          (bounds-of-thing-at-point 'git-revision)))
    (let ((text (buffer-substring-no-properties (car it) (cdr it))))
      (and (magit-commit-p text) text))))

;;; Completion

(defvar magit-revision-history nil)

(defun magit-read-branch (prompt &optional secondary-default)
  (magit-completing-read prompt (magit-list-branch-names)
                         nil t nil 'magit-revision-history
                         (or (magit-branch-at-point)
                             secondary-default
                             (magit-get-current-branch))))

(defun magit-read-branch-or-commit (prompt &optional secondary-default)
  (or (magit-completing-read prompt (magit-list-refnames nil t)
                             nil nil nil 'magit-revision-history
                             (or (magit-branch-or-commit-at-point)
                                 secondary-default
                                 (magit-get-current-branch)))
      (user-error "Nothing selected")))

(defun magit-read-range-or-commit (prompt &optional secondary-default)
  (magit-read-range
   prompt
   (or (--when-let (magit-region-values '(commit branch) t)
         (deactivate-mark)
         (concat (car (last it)) ".." (car it)))
       (magit-branch-or-commit-at-point)
       secondary-default
       (magit-get-current-branch))))

(defun magit-read-range (prompt &optional default)
  (magit-completing-read-multiple prompt
                                  (magit-list-refnames)
                                  "\\.\\.\\.?"
                                  default 'magit-revision-history))

(defun magit-read-remote-branch
    (prompt &optional remote default local-branch require-match)
  (let ((choice (magit-completing-read
                 prompt
                 (-union (and local-branch
                              (if remote
                                  (concat remote "/" local-branch)
                                (--map (concat it "/" local-branch)
                                       (magit-list-remotes))))
                         (magit-list-remote-branch-names remote t))
                 nil require-match nil 'magit-revision-history default)))
    (if (or remote (string-match "\\`\\([^/]+\\)/\\(.+\\)" choice))
        choice
      (user-error "`%s' doesn't have the form REMOTE/BRANCH" choice))))

(defun magit-read-refspec (prompt remote)
  (magit-completing-read prompt
                         (prog2 (message "Determining available refs...")
                             (magit-remote-list-refs remote)
                           (message "Determining available refs...done"))))

(defun magit-read-local-branch (prompt &optional secondary-default)
  (magit-completing-read prompt (magit-list-local-branch-names)
                         nil t nil 'magit-revision-history
                         (or (magit-local-branch-at-point)
                             secondary-default
                             (magit-get-current-branch))))

(defun magit-read-local-branch-or-commit (prompt)
  (let ((choices (nconc (magit-list-local-branch-names)
                        (magit-list-special-refnames)))
        (commit (magit-commit-at-point)))
    (when commit
      (push commit choices))
    (or (magit-completing-read prompt choices
                               nil nil nil 'magit-revision-history
                               (or (magit-local-branch-at-point) commit))
                     (user-error "Nothing selected"))))

(defun magit-read-local-branch-or-ref (prompt &optional secondary-default)
  (magit-completing-read prompt (nconc (magit-list-local-branch-names)
                                       (magit-list-refs "refs/"))
                         nil t nil 'magit-revision-history
                         (or (magit-local-branch-at-point)
                             secondary-default
                             (magit-get-current-branch))))

(defun magit-read-other-branch
    (prompt &optional exclude secondary-default no-require-match)
  (let* ((current (magit-get-current-branch))
         (atpoint (magit-branch-at-point))
         (exclude (or exclude current))
         (default (or (and (not (equal atpoint exclude)) atpoint)
                      (and (not (equal current exclude)) current)
                      secondary-default
                      (magit-get-previous-branch))))
    (magit-completing-read prompt (delete exclude (magit-list-branch-names))
                           nil (not no-require-match)
                           nil 'magit-revision-history default)))

(defun magit-read-other-branch-or-commit
    (prompt &optional exclude secondary-default)
  (let* ((current (magit-get-current-branch))
         (atpoint (magit-branch-or-commit-at-point))
         (exclude (or exclude current))
         (default (or (and (not (equal atpoint exclude))
                           (not (and (not current)
                                     (magit-rev-equal atpoint "HEAD")))
                           atpoint)
                      (and (not (equal current exclude)) current)
                      secondary-default
                      (magit-get-previous-branch))))
    (or (magit-completing-read prompt (delete exclude (magit-list-refnames))
                               nil nil nil 'magit-revision-history default)
        (user-error "Nothing selected"))))

(defun magit-read-other-local-branch
    (prompt &optional exclude secondary-default no-require-match)
  (let* ((current (magit-get-current-branch))
         (atpoint (magit-local-branch-at-point))
         (exclude (or exclude current))
         (default (or (and (not (equal atpoint exclude)) atpoint)
                      (and (not (equal current exclude)) current)
                      secondary-default
                      (magit-get-previous-branch))))
    (magit-completing-read prompt
                           (delete exclude (magit-list-local-branch-names))
                           nil (not no-require-match)
                           nil 'magit-revision-history default)))

(defun magit-read-branch-prefer-other (prompt)
  (let* ((current (magit-get-current-branch))
         (commit  (magit-commit-at-point))
         (atrev   (and commit (magit-list-branches-pointing-at commit)))
         (atpoint (magit--painted-branch-at-point)))
    (magit-completing-read prompt (magit-list-branch-names)
                           nil t nil 'magit-revision-history
                           (or (magit-section-value-if 'branch)
                               atpoint
                               (and (not (cdr atrev)) (car atrev))
                               (--first (not (equal it current)) atrev)
                               (magit-get-previous-branch)
                               (car atrev)))))

(defun magit-read-upstream-branch (&optional branch prompt)
  "Read the upstream for BRANCH using PROMPT.
If optional BRANCH is nil, then read the upstream for the
current branch, or raise an error if no branch is checked
out.  Only existing branches can be selected."
  (unless branch
    (setq branch (or (magit-get-current-branch)
                     (error "Need a branch to set its upstream"))))
  (let ((branches (delete branch (magit-list-branch-names))))
    (magit-completing-read
     (or prompt (format "Change upstream of %s to" branch))
     branches nil t nil 'magit-revision-history
     (or (let ((r (car (member (magit-remote-branch-at-point) branches)))
               (l (car (member (magit-local-branch-at-point) branches))))
           (if magit-prefer-remote-upstream (or r l) (or l r)))
         (let ((r (car (member "origin/master" branches)))
               (l (car (member "master" branches))))
           (if magit-prefer-remote-upstream (or r l) (or l r)))
         (car (member (magit-get-previous-branch) branches))))))

(defun magit-read-starting-point (prompt &optional branch default)
  (or (magit-completing-read
       (concat prompt
               (and branch
                    (if (bound-and-true-p ivy-mode)
                        ;; Ivy-mode strips faces from prompt.
                        (format  " `%s'" branch)
                      (concat " " (magit--propertize-face
                                   branch 'magit-branch-local))))
               " starting at")
       (nconc (list "HEAD")
              (magit-list-refnames)
              (directory-files (magit-git-dir) nil "_HEAD\\'"))
       nil nil nil 'magit-revision-history
       (or default (magit--default-starting-point)))
      (user-error "Nothing selected")))

(defun magit--default-starting-point ()
  (or (let ((r (magit-remote-branch-at-point))
            (l (magit-local-branch-at-point)))
        (if magit-prefer-remote-upstream (or r l) (or l r)))
      (magit-commit-at-point)
      (magit-stash-at-point)
      (magit-get-current-branch)))

(defun magit-read-tag (prompt &optional require-match)
  (magit-completing-read prompt (magit-list-tags) nil
                         require-match nil 'magit-revision-history
                         (magit-tag-at-point)))

(defun magit-read-stash (prompt)
  (let ((stashes (magit-list-stashes)))
    (magit-completing-read prompt stashes nil t nil nil
                           (magit-stash-at-point)
                           (car stashes))))

(defun magit-read-remote (prompt &optional default use-only)
  (let ((remotes (magit-list-remotes)))
    (if (and use-only (= (length remotes) 1))
        (car remotes)
      (magit-completing-read prompt remotes
                             nil t nil nil
                             (or default
                                 (magit-remote-at-point)
                                 (magit-get-remote))))))

(defun magit-read-remote-or-url (prompt &optional default)
  (magit-completing-read prompt
                         (nconc (magit-list-remotes)
                                (list "https://" "git://" "git@"))
                         nil nil nil nil
                         (or default
                             (magit-remote-at-point)
                             (magit-get-remote))))

(defun magit-read-module-path (prompt &optional predicate)
  (magit-completing-read prompt (magit-list-module-paths)
                         predicate t nil nil
                         (magit-module-at-point predicate)))

(defun magit-module-confirm (verb &optional predicate)
  (let (modules)
    (if current-prefix-arg
        (progn
          (setq modules (magit-list-module-paths))
          (when predicate
            (setq modules (-filter predicate modules)))
          (unless modules
            (if predicate
                (user-error "No modules satisfying %s available" predicate)
              (user-error "No modules available"))))
      (setq modules (magit-region-values 'magit-module-section))
      (when modules
        (when predicate
          (setq modules (-filter predicate modules)))
        (unless modules
          (user-error "No modules satisfying %s selected" predicate))))
    (if (> (length modules) 1)
        (magit-confirm t nil (format "%s %%i modules" verb) nil modules)
      (list (magit-read-module-path (format "%s module" verb) predicate)))))

;;; _
(provide 'magit-git)
;;; magit-git.el ends here
