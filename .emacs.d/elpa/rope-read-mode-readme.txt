** Usage

 Type M-x rope-read-mode in a buffer and wait until the
 transformation of the buffer has been performed.

 You can use:

 SPC/<backspace> to scroll a screen.
 v,<return>/V y to scroll one line.
 q to quit.
 g to refresh rope read for the current visible part of the buffer.
 ? open the help buffer.

 For convenience command rope-read-mode can be associated to a key
 sequence.  For example to activate or deactivate rope-read-mode by
 pressing scroll lock two times use the line

 (global-set-key (kbd "<Scroll_Lock> <Scroll_Lock>") 'rope-read-mode)

** Effect

 rope-read-mode reverses every other line in the visible part of a
 buffer.  When every other line has been reversed reading is like
 following a rope.

** Benefit

 - Find the next line easily.
   - In particular for long lines.
 - Have an alternative view on text.
 - Have fun.

** Price

 - Learn to easily read upside-down-lines.

** Links

 See elpa package spray for another alternative view mode.

** Development

*** Bugs

- rope-read-mode fails when truncated lines occur.

*** Features

- Make the transformation quicker.

*** Lentic Literate Style

This program is in literal style based on lentic-mode.  The
lentic-views are emacs lisp and Org.

A possible initialization of lentic is this:

(load-library "lentic-org")
(global-lentic-start-mode)

The el file is the source.  It is an emacs lisp file.

The el file fits to the lentic-mode, hopefully.  Use
lentic-mode-split-window-below to get a view on the program as Orgmode
file.

** Communication

Contact the author for feedback, bug reports, feature requests,
enhancements, ideas.
