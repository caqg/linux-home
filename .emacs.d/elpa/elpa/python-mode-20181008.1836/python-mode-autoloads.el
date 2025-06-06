;;; python-mode-autoloads.el --- automatically extracted autoloads
;;
;;; Code:

(add-to-list 'load-path (directory-file-name
                         (or (file-name-directory #$) (car load-path))))


;;;### (autoloads nil "python-mode" "python-mode.el" (0 0 0 0))
;;; Generated autoloads from python-mode.el

(autoload 'py-backward-class "python-mode" "\
Go to beginning of ‘class’ according to INDENT.

If already at beginning, go one ‘class’ backward.
Optional DECORATOR BOL

Return beginning of ‘class’ if successful, nil otherwise

\(fn &optional INDENT DECORATOR BOL)" t nil)

(autoload 'py-backward-def "python-mode" "\
Go to beginning of ‘def’ according to INDENT.

If already at beginning, go one ‘def’ backward.
Optional DECORATOR BOL

Return beginning of ‘def’ if successful, nil otherwise

\(fn &optional INDENT DECORATOR BOL)" t nil)

(autoload 'py-backward-def-or-class "python-mode" "\
Go to beginning of ‘def-or-class’ according to INDENT.

If already at beginning, go one ‘def-or-class’ backward.
Optional DECORATOR BOL

Return beginning of ‘def-or-class’ if successful, nil otherwise

\(fn &optional INDENT DECORATOR BOL)" t nil)

(autoload 'py-backward-class-bol "python-mode" "\
Go to beginning of ‘class’ according to INDENT, go to BOL.
Optional DECORATOR BOL

If already at beginning, go one ‘class’ backward.
Return beginning of ‘class’ if successful, nil otherwise

\(fn &optional INDENT DECORATOR)" t nil)

(autoload 'py-backward-def-bol "python-mode" "\
Go to beginning of ‘def’ according to INDENT, go to BOL.
Optional DECORATOR BOL

If already at beginning, go one ‘def’ backward.
Return beginning of ‘def’ if successful, nil otherwise

\(fn &optional INDENT DECORATOR)" t nil)

(autoload 'py-backward-def-or-class-bol "python-mode" "\
Go to beginning of ‘def-or-class’ according to INDENT, go to BOL.
Optional DECORATOR BOL

If already at beginning, go one ‘def-or-class’ backward.
Return beginning of ‘def-or-class’ if successful, nil otherwise

\(fn &optional INDENT DECORATOR)" t nil)

(autoload 'py-forward-class "python-mode" "\
Go to end of class.

Return end of class if successful, nil otherwise
Optional arg DECORATOR is used if form supports one
With optional BOL, go to beginning of line following match.

\(fn &optional ARG DECORATOR BOL)" t nil)

(autoload 'py-forward-def-or-class "python-mode" "\
Go to end of def-or-class.

Return end of def-or-class if successful, nil otherwise
Optional arg DECORATOR is used if form supports one
With optional BOL, go to beginning of line following match.

\(fn &optional ARG DECORATOR BOL)" t nil)

(autoload 'py-forward-def "python-mode" "\
Go to end of def.

Return end of def if successful, nil otherwise
Optional arg DECORATOR is used if form supports one
With optional BOL, go to beginning of line following match.

\(fn &optional ARG DECORATOR BOL)" t nil)

(autoload 'py-shell "python-mode" "\
Start a Python interpreter.

Interactively, \\[universal-argument] prompts for a new ‘buffer-name’.
  \\[universal-argument] 2 prompts for ‘py-python-command-args’.
  If ‘default-directory’ is a remote file name, it is also prompted
  to change if called with a prefix arg.
  Optional ARGPROMPT DEDICATED
  Optional string SHELL overrides default ‘py-shell-name’.
  Returns py-shell's ‘buffer-name’.
  BUFFER allows specifying a name, the Python process is connected to
  FAST process not in ‘comint-mode’ buffer
  EXCEPTION-BUFFER point to error
  Optional SPLIT see var ‘py-split-window-on-execute’
  Optional SWITCH see var ‘py-switch-buffers-on-execute-p’
  Optional INPUT-PROMPT permit command to set prompt
  Optional INTERNAL shell will be invisible for users

 \\[describe-mode] in the process buffer provides more info.

\(fn &optional ARGPROMPT DEDICATED SHELL BUFFER FAST EXCEPTION-BUFFER SPLIT SWITCH INTERNAL)" t nil)

(autoload 'ipython "python-mode" "\
Start an IPython interpreter.

Optional ARG \\[universal-argument] prompts for path to the interpreter.

\(fn &optional ARGPROMPT BUFFER FAST EXCEPTION-BUFFER SPLIT SWITCH)" t nil)

(autoload 'ipython2\.7 "python-mode" "\
Start an IPython2.7 interpreter.

Optional ARG \\[universal-argument] prompts for path to the interpreter.

\(fn &optional ARGPROMPT BUFFER FAST EXCEPTION-BUFFER SPLIT SWITCH)" t nil)

(autoload 'ipython3 "python-mode" "\
Start an IPython3 interpreter.

Optional ARG \\[universal-argument] prompts for path to the interpreter.

\(fn &optional ARGPROMPT BUFFER FAST EXCEPTION-BUFFER SPLIT SWITCH)" t nil)

(autoload 'jython "python-mode" "\
Start an Jython interpreter.

Optional ARG \\[universal-argument] prompts for path to the interpreter.

\(fn &optional ARGPROMPT BUFFER FAST EXCEPTION-BUFFER SPLIT SWITCH)" t nil)

(autoload 'python "python-mode" "\
Start an Python interpreter.

Optional ARG \\[universal-argument] prompts for path to the interpreter.

\(fn &optional ARGPROMPT BUFFER FAST EXCEPTION-BUFFER SPLIT SWITCH)" t nil)

(autoload 'python2 "python-mode" "\
Start an Python2 interpreter.

Optional ARG \\[universal-argument] prompts for path to the interpreter.

\(fn &optional ARGPROMPT BUFFER FAST EXCEPTION-BUFFER SPLIT SWITCH)" t nil)

(autoload 'python3 "python-mode" "\
Start an Python3 interpreter.

Optional ARG \\[universal-argument] prompts for path to the interpreter.

\(fn &optional ARGPROMPT BUFFER FAST EXCEPTION-BUFFER SPLIT SWITCH)" t nil)

(autoload 'py-auto-completion-mode "python-mode" "\
Run auto-completion

\(fn)" t nil)

(autoload 'python-mode "python-mode" "\
Major mode for editing Python files.

To submit a problem report, enter `\\[py-submit-bug-report]' from a
`python-mode' buffer.  Do `\\[py-describe-mode]' for detailed
documentation.  To see what version of `python-mode' you are running,
enter `\\[py-version]'.

This mode knows about Python indentation, tokens, comments and
continuation lines.  Paragraphs are separated by blank lines only.

COMMANDS

`py-shell'	Start an interactive Python interpreter in another window
`py-execute-statement'	Send statement at point to Python default interpreter
`py-backward-statement'	Go to the initial line of a simple statement

etc.

See available commands listed in files commands-python-mode at directory doc

VARIABLES

`py-indent-offset'	indentation increment
`py-shell-name'		shell command to invoke Python interpreter
`py-split-window-on-execute'		When non-nil split windows
`py-switch-buffers-on-execute-p'	When non-nil switch to the Python output buffer

See available customizations listed in files variables-python-mode at directory doc

\\{python-mode-map}

\(fn)" t nil)

(autoload 'py-python-shell-mode "python-mode" "\
Major mode for interacting with a Python process.
A Python process can be started with \\[py-shell].

You can send text to the Python process from other buffers
containing Python source.
 * \\[py-execute-region] sends the current region to the Python process.

Sets basic comint variables, see also versions-related stuff in `py-shell'.
\\{py-python-shell-mode-map}

\(fn)" t nil)

(autoload 'py-ipython-shell-mode "python-mode" "\
Major mode for interacting with a (I)Python process.
A Python process can be started with \\[py-shell].

You can send text to the (I)Python process from other buffers
containing Python source.
 * \\[py-execute-region] sends the current region to the Python process.

Sets basic comint variables, see also versions-related stuff in `py-shell'.
\\{py-ipython-shell-mode-map}

\(fn)" t nil)

(if (fboundp 'register-definition-prefixes) (register-definition-prefixes "python-mode" '("IPython" "Ipython" "Python" "autopair-mode" "druck" "durck" "empty-line-p" "eva" "ffap-alist" "flake8" "force-py-shell-name-p-o" "highlight-indent-active" "hs-hide-comments-when-hiding-all" "info-lookup-mode" "ios" "ipy" "iyp" "jython-" "pep8" "pios" "pps-emacs-version" "pst-here" "strip-chars-" "toggle-" "turn-o" "virtualenv-")))

;;;***

;;;### (autoloads nil nil ("python-mode-pkg.el") (0 0 0 0))

;;;***

;; Local Variables:
;; version-control: never
;; no-byte-compile: t
;; no-update-autoloads: t
;; coding: utf-8
;; End:
;;; python-mode-autoloads.el ends here
