This package implements useful features present in the
[ranger](http://ranger.nongnu.org/) file manager which are missing
in dired.

Multi-stage copy/pasting of files
---------------------------------

A feature present in most orthodox file managers is a "two-stage"
copy/paste process.  Roughly, the user first selects some files,
"copies" them into a clipboard and then pastes them to the target
location.  This workflow is missing in dired.

In dired, user first marks the files, then issues the
`dired-do-copy' command which prompts for the destination.  The
files are then copied there.  The `dired-dwim-target' option makes
this a bit friendlier---if two dired windows are opened, the other
one is automatically the default target.

With the multi-stage operations, you can gather files from
*multiple* dired buffers into a single "clipboard", then copy or
move all of them to the target location.  Another huge advantage is
that if the target dired buffer is already opened, switching to it
via ido or ibuffer is often faster than selecting the path.

Call `dired-ranger-copy' to add marked files (or the file under
point if no files are marked) to the "clipboard".  With non-nil
prefix argument, add the marked files to the current clipboard.

Past clipboards are stored in `dired-ranger-copy-ring' so you can
repeat the past pastes.

Call `dired-ranger-paste' or `dired-ranger-move' to copy or move
the files in the current clipboard to the current dired buffer.
With raw prefix argument (usually C-u), the clipboard is not
cleared, so you can repeat the copy operation in another dired
buffer.
