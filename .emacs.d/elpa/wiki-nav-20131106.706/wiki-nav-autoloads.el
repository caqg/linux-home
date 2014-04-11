;;; wiki-nav-autoloads.el --- automatically extracted autoloads
;;
;;; Code:


;;;### (autoloads (wiki-nav-ido wiki-nav-find-any-previous-link wiki-nav-find-any-link
;;;;;;  global-wiki-nav-mode wiki-nav-mode wiki-nav-keyboard-action
;;;;;;  wiki-nav-mouse-action wiki-nav-default-multi-action wiki-nav-parsing
;;;;;;  wiki-nav-faces wiki-nav-keys wiki-nav) "wiki-nav" "wiki-nav.el"
;;;;;;  (21319 39606 951971 721000))
;;; Generated autoloads from wiki-nav.el

(let ((loads (get 'wiki-nav 'custom-loads))) (if (member '"wiki-nav" loads) nil (put 'wiki-nav 'custom-loads (cons '"wiki-nav" loads))))

(let ((loads (get 'wiki-nav-keys 'custom-loads))) (if (member '"wiki-nav" loads) nil (put 'wiki-nav-keys 'custom-loads (cons '"wiki-nav" loads))))

(let ((loads (get 'wiki-nav-faces 'custom-loads))) (if (member '"wiki-nav" loads) nil (put 'wiki-nav-faces 'custom-loads (cons '"wiki-nav" loads))))

(let ((loads (get 'wiki-nav-parsing 'custom-loads))) (if (member '"wiki-nav" loads) nil (put 'wiki-nav-parsing 'custom-loads (cons '"wiki-nav" loads))))

(autoload 'wiki-nav-default-multi-action "wiki-nav" "\
Dispatch the default double-click navigation action.

The link used is that identified by the position at EVENT, a
mouse event.

\(fn EVENT)" t nil)

(autoload 'wiki-nav-mouse-action "wiki-nav" "\
Dispatch the default action for the wiki-nav link at the mouse location.

Mouse location is defined by the mouse event EVENT.

\(fn EVENT)" t nil)

(autoload 'wiki-nav-keyboard-action "wiki-nav" "\
Dispatch the default navigation action for the wiki-nav link under the point.

\(fn)" t nil)

(autoload 'wiki-nav-mode "wiki-nav" "\
Turn on navigation by bracketed [[WikiStrings]] within a document.

When wiki-nav links are activated, clicking on a bracketed link
causes emacs to search the document for another link with text
matching the inner string.  If a match is found, the cursor is
moved to the location of the match.

If the string looks like it might be a URL (starts with
alphabetical characters followed by a colon), an external browser
will be spawned on the URL.  This behavior can be controlled by the
customizable variable `wiki-nav-external-link-pattern'.

If `multi-occur' is installed (standard with recent Emacs),
double-clicking a wiki-nav link will search for matching links in
all open file buffers.

If the link follows the form

   visit:/path/name:WikiString

Emacs will visit the named file, and search for the navigation
string there.  This behavior can be controlled by the customizable
variable `wiki-nav-visit-link-pattern'.

If the link follows the form

   func:FunctionName

the link will lead to the definition of the given function, as
defined by imenu. This behavior can be controlled by the
customizable variable `wiki-nav-function-link-pattern'.

If the link follows the form

   line:<digits>

the link will lead to the given line number.  This behavior can
be controlled by the customizable variable
`wiki-nav-line-number-link-pattern'.

The leading and trailing delimiters which define the navigation
links may be customized, as may the regular expressions that
match URLs and non-URL inner text.

With no argument, this command toggles the mode.  Non-null prefix
argument turns on the mode.  Null prefix argument turns off the
mode.

\(fn &optional ARG)" t nil)

(defvar global-wiki-nav-mode nil "\
Non-nil if Global-Wiki-Nav mode is enabled.
See the command `global-wiki-nav-mode' for a description of this minor mode.
Setting this variable directly does not take effect;
either customize it (see the info node `Easy Customization')
or call the function `global-wiki-nav-mode'.")

(custom-autoload 'global-wiki-nav-mode "wiki-nav" nil)

(autoload 'global-wiki-nav-mode "wiki-nav" "\
Toggle Wiki-Nav mode in all buffers.
With prefix ARG, enable Global-Wiki-Nav mode if ARG is positive;
otherwise, disable it.  If called from Lisp, enable the mode if
ARG is omitted or nil.

Wiki-Nav mode is enabled in all buffers where
`wiki-nav-maybe-turn-on' would do it.
See `wiki-nav-mode' for more information on Wiki-Nav mode.

\(fn &optional ARG)" t nil)

(autoload 'wiki-nav-find-any-link "wiki-nav" "\
Skip forward to the next defined wiki-nav link.

Automatically wraps past the end of the buffer.

With a negative prefix argument ARG, skip backward to the
previous defined wiki-nav link.

\(fn &optional ARG)" t nil)

(autoload 'wiki-nav-find-any-previous-link "wiki-nav" "\
Skip backward to the previous defined wiki-nav link.

Automatically wraps past the beginning of the buffer.

With a negative prefix argument ARG, skip backward to the
previous defined wiki-nav link.

\(fn)" t nil)

(autoload 'wiki-nav-ido "wiki-nav" "\
Navigate to wiki-nav strings using `ido-completing-read'.

With universal prefix ARG, navigate to wiki-nav strings in all
buffers.

\(fn ARG)" t nil)

;;;***

;;;### (autoloads nil nil ("wiki-nav-pkg.el") (21319 39607 38521
;;;;;;  394000))

;;;***

(provide 'wiki-nav-autoloads)
;; Local Variables:
;; version-control: never
;; no-byte-compile: t
;; no-update-autoloads: t
;; coding: utf-8
;; End:
;;; wiki-nav-autoloads.el ends here
