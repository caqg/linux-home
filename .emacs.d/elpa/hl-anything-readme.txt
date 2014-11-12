Highlight things in a text file makes you search things easily. It is
fundamental and very helpful to everyone, enjoy!

Check website for details:
https://github.com/boyw165/hl-anything

* Highlight symbols with different colors.
  Note: The highlights are still visible even under current line highlight
  (`hl-line-mode' or `global-hl-line-mode' is enabled).
* Highlight selections with different colors.
* Highlight things in a highlighted thing.
* Highlight enclosing inward and outward parentheses.
* Select highlighted things smartly and search forwardly or backwardly.

Usage:
------
Add the following to your .emacs file:
(require 'hl-anything)

Toggle highlighting things at point:
  M-x `hl-highlight-thingatpt-local'

Remove all highlights:
  M-x `hl-unhighlight-all-local'

Search highlights:
  M-x `hl-find-thing-forwardly'
  M-x `hl-find-thing-backwardly'

Enable enclosing parenethese highlighting:
  M-x `hl-paren-mode'

Highlight things temporarily which means any action will delete the highlights.
 (hl-highlight-keywords-temporarily '(("hello" hl-symbol-face)))

TODO:
-----
* Implement `hl-highlight-thingatpt-global' to highlight things globally.
* Save highlights before Emacs closed in order to restore them after Emacs
  opened?
* Highlight Enclosing syntax in Emacs REGEX.
