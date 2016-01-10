# How to obtain _italic_, __bold__, ___bold italic___?

_Italic_ is `_italic_`.  
__Bold__ is `__bold__`.  
___Bold Italic___ is `___bold italic___`.

The last is a consequence of the above,
not a separate rule. (Produced `<strong><em>` around the test.)

Both asterisks and underscores can be used (matched). So `*__italic bold__*` (*__italic bold__*)
and `**_bold italic_**` (**_bold italic_**) also work, and amount to the same,
by swapping `<em><strong>` and `<strong><em>`.

