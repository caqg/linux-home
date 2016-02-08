;;; multishell-autoloads.el --- automatically extracted autoloads
;;
;;; Code:
(add-to-list 'load-path (directory-file-name (or (file-name-directory #$) (car load-path))))

;;;### (autoloads nil "multishell" "multishell.el" (22191 38875 675098
;;;;;;  556000))
;;; Generated autoloads from multishell.el

(autoload 'multishell-pop-to-shell "multishell" "\
Easily navigate to and within multiple shell buffers, local and remote.

Use a single `universal-argument' (\\[universal-argument]) to launch and choose between
nalternate shell buffers, and a doubled universal argument to also set your
choice as the ongoing default.  Append a path to a new shell name to launch
a shell in that directory, and use Emacs tramp syntax to launch a remote
shell. There is a shortcut to manage your list of current and
historical shells, collectively, using `multishell-list' - see below.

Customize-group `multishell' to set up a key binding and tweak behaviors.

Manage your collection of current and historical shells by
recursively invoking \\[multishell-pop-to-shell] at the
`multishell-pop-to-shell' universal argument prompts, eg:

  \\[universal-argument] \\[multishell-pop-to-shell] \\[multishell-pop-to-shell]

\(That will be just a few keys if you do the above
customization.) Hit ? in the listing buffer for editing commands.

==== Basic operation:

 - If the current buffer is shell-mode (or shell-mode derived)
   buffer then focus is moved to the process input point.

   (You can use a universal argument go to a different shell
   buffer when already in a buffer that has a process - see
   below.)

 - If not in a shell buffer (or with universal argument), go to a
   window that is already showing the (a) shell buffer, if any.

   In this case, the cursor is left in its prior position in the
   shell buffer. Repeating the command will then go to the
   process input point, per the first item in this list.

   We respect `pop-up-windows', so you can adjust it to set the
   other-buffer/same-buffer behavior.

 - Otherwise, start a new shell buffer, using the current
   directory as the working directory.

If a buffer with the resulting name exists and its shell process
was disconnected or otherwise stopped, it's resumed.

===== Universal arg to start and select between named shell buffers:

You can name alternate shell buffers to create or return to, by
prefixing your \\[multishell-pop-to-shell] invocation with single or double
`universal-argument', \\[universal-argument]:

 - With a single universal argument, prompt for the buffer name
   to use (without the asterisks that shell mode will put around
   the name), defaulting to 'shell'.

   Completion is available.

   This combination makes it easy to start and switch across
   multiple shell restarts.

 - A double universal argument will prompt for the name *and* set
   the default to that name, so the target shell becomes the
   primary.

   See `multishell-primary-name' for info about preserving the
   setting across emacs restarts.

 - Manage your collection of current and historical shells by
   recursively invoking \\[multishell-pop-to-shell] at either of the
   `multishell-pop-to-shell' universal argument prompts, or at any
   time via \\[multishell-list]. Hit ? in the listing buffer for
   editing commands.

===== Select starting directory and remote host:

The shell buffer name you give to the prompt for a universal arg
can include an appended path. That will be used for the startup
directory. You can use tramp remote syntax to specify a remote
shell. If there is an element after a final '/', that's used for
the buffer name. Otherwise, the host, domain, or path is used.

For example:

* '#root/sudo:root@localhost:/etc' for a buffer named \"*#root*\" with a
  root shell starting in /etc.

* '/ssh:example.net:' for a shell buffer in your homedir on example.net.
  The buffer will be named \"*example.net*\".

* '#ex/ssh:example.net|sudo:root@example.net:/var/log' for a root shell
  starting in /var/log on example.net named \"*#ex*\".

* 'interior/ssh:gateway.corp.com|ssh:interior.corp.com:' to go
  via gateway.corp.com to your homedir on interior.corp.com.  The
  buffer will be named \"*interior*\". You could append a sudo
  hop to the path, combining the previous example, and so on.

File visits from the shell, and many common emacs activities like
dired, will be on the host where the shell is running, in the
auspices of the target account, and relative to the current
directory.

You can change the startup path for a shell buffer by editing it
at the completion prompt. The new path will not take effect for
an already-running shell.

To remove a shell buffer's history entry, kill the buffer and
affirm removal of the entry when prompted.

===== Activate savehist to retain shell buffer names and paths across Emacs restarts:

To have emacs maintain your history of shell buffer names and paths,
customize the savehist group to activate savehist.

\(fn &optional ARG NAME HERE)" t nil)

;;;***

;;;### (autoloads nil "multishell-list" "multishell-list.el" (22191
;;;;;;  38875 667098 801000))
;;; Generated autoloads from multishell-list.el

(autoload 'multishell-list "multishell-list" "\
Edit your current and historic list of shell buffers.

Hit ? for a list of commands.

You can get to this shell listing manager by
recursively invoking \\[multishell-pop-to-shell] at either of the
`multishell-pop-to-shell' universal argument prompts.

\(fn)" t nil)

;;;***

;;;### (autoloads nil nil ("multishell-pkg.el") (22191 38875 707097
;;;;;;  575000))

;;;***

;; Local Variables:
;; version-control: never
;; no-byte-compile: t
;; no-update-autoloads: t
;; End:
;;; multishell-autoloads.el ends here
