Global minor-mode to print `__git_ps1` in mode-line.

This minor-mode will print current `git` status in Emacs mode-line as a
mode-name. Status text will be generated using `__git_ps1`, which is usually
defined in `"git-prompt.sh"`. By default, the text should be like
`"[GIT:master *]"`.


User Configuration Variables
----------------------------

* `git-ps1-mode-lighter-text-format`

  Format string for `git-ps1-mode` lighter (mode-name). By default it is set to
  `" [GIT:%s]"`.

* `git-ps1-mode-ps1-file-candidates-list`

  List of candidates that may contain `__git_ps1` definition.
  At the first invocation, `git-ps1-mode` searchs these files for `__git_ps1`
  definition, and set the first file to `git-ps1-mode-ps1-file`.

* `git-ps1-mode-showdirtystate`
* `git-ps1-mode-showstashstate`
* `git-ps1-mode-showuntrackedfiles`
* `git-ps1-mode-showupstream`

  Values for `GIT_PS1_SHOWDIRTYSTATE`, `GIT_PS1_SHOWSTASHSTATE`,
  `GIT_PS1_SHOWUNTERACKEDFILES` and `GIT_PS1_SHOWUPSTREAM` respectively.
  These variables configure output of `__git_ps1`: see document in
  "git-prompt.sh" file for details.
