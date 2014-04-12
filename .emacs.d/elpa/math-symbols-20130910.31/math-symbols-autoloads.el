;;; math-symbols-autoloads.el --- automatically extracted autoloads
;;
;;; Code:


;;;### (autoloads (math-symbols-helm math-symbols-insert math-symbols-to-tex-unicode-region
;;;;;;  math-symbols-to-tex-region math-symbols-from-tex-region math-symbols-subscript-string
;;;;;;  math-symbols-subscript-region math-symbols-superscript-string
;;;;;;  math-symbols-superscript-region math-symbols-monospace-string
;;;;;;  math-symbols-monospace-region math-symbols-sans-serif-bold-italic-string
;;;;;;  math-symbols-sans-serif-bold-italic-region math-symbols-sans-serif-italic-string
;;;;;;  math-symbols-sans-serif-italic-region math-symbols-sans-serif-bold-string
;;;;;;  math-symbols-sans-serif-bold-region math-symbols-sans-serif-string
;;;;;;  math-symbols-sans-serif-region math-symbols-double-struck-string
;;;;;;  math-symbols-double-struck-region math-symbols-bold-fraktur-string
;;;;;;  math-symbols-bold-fraktur-region math-symbols-fraktur-string
;;;;;;  math-symbols-fraktur-region math-symbols-bold-script-string
;;;;;;  math-symbols-bold-script-region math-symbols-script-string
;;;;;;  math-symbols-script-region math-symbols-bold-italic-string
;;;;;;  math-symbols-bold-italic-region math-symbols-italic-string
;;;;;;  math-symbols-italic-region math-symbols-bold-string math-symbols-bold-region
;;;;;;  math-symbols-input-activate) "math-symbols" "math-symbols.el"
;;;;;;  (21320 59678 775127 335000))
;;; Generated autoloads from math-symbols.el

(autoload 'math-symbols-input-activate "math-symbols" "\
Activating Math Input method.

\(fn NAME)" nil nil)

(register-input-method "math-symbols-bold" "math" 'math-symbols-input-activate "mt")

(autoload 'math-symbols-bold-region "math-symbols" "\
Convert REGION to bold style.

\(fn FROM TO)" t nil)

(autoload 'math-symbols-bold-string "math-symbols" "\
Convert STRING to bold style.

\(fn STRING)" nil nil)

(register-input-method "math-symbols-italic" "math" 'math-symbols-input-activate "mt")

(autoload 'math-symbols-italic-region "math-symbols" "\
Convert REGION to italic style.

\(fn FROM TO)" t nil)

(autoload 'math-symbols-italic-string "math-symbols" "\
Convert STRING to italic style.

\(fn STRING)" nil nil)

(register-input-method "math-symbols-bold-italic" "math" 'math-symbols-input-activate "mt")

(autoload 'math-symbols-bold-italic-region "math-symbols" "\
Convert REGION to bold-italic style.

\(fn FROM TO)" t nil)

(autoload 'math-symbols-bold-italic-string "math-symbols" "\
Convert STRING to bold-italic style.

\(fn STRING)" nil nil)

(register-input-method "math-symbols-script" "math" 'math-symbols-input-activate "mt")

(autoload 'math-symbols-script-region "math-symbols" "\
Convert REGION to script style.

\(fn FROM TO)" t nil)

(autoload 'math-symbols-script-string "math-symbols" "\
Convert STRING to script style.

\(fn STRING)" nil nil)

(register-input-method "math-symbols-bold-script" "math" 'math-symbols-input-activate "mt")

(autoload 'math-symbols-bold-script-region "math-symbols" "\
Convert REGION to bold-script style.

\(fn FROM TO)" t nil)

(autoload 'math-symbols-bold-script-string "math-symbols" "\
Convert STRING to bold-script style.

\(fn STRING)" nil nil)

(register-input-method "math-symbols-fraktur" "math" 'math-symbols-input-activate "mt")

(autoload 'math-symbols-fraktur-region "math-symbols" "\
Convert REGION to fraktur style.

\(fn FROM TO)" t nil)

(autoload 'math-symbols-fraktur-string "math-symbols" "\
Convert STRING to fraktur style.

\(fn STRING)" nil nil)

(register-input-method "math-symbols-bold-fraktur" "math" 'math-symbols-input-activate "mt")

(autoload 'math-symbols-bold-fraktur-region "math-symbols" "\
Convert REGION to bold-fraktur style.

\(fn FROM TO)" t nil)

(autoload 'math-symbols-bold-fraktur-string "math-symbols" "\
Convert STRING to bold-fraktur style.

\(fn STRING)" nil nil)

(register-input-method "math-symbols-double-struck" "math" 'math-symbols-input-activate "mt")

(autoload 'math-symbols-double-struck-region "math-symbols" "\
Convert REGION to double-struck style.

\(fn FROM TO)" t nil)

(autoload 'math-symbols-double-struck-string "math-symbols" "\
Convert STRING to double-struck style.

\(fn STRING)" nil nil)

(register-input-method "math-symbols-sans-serif" "math" 'math-symbols-input-activate "mt")

(autoload 'math-symbols-sans-serif-region "math-symbols" "\
Convert REGION to sans-serif style.

\(fn FROM TO)" t nil)

(autoload 'math-symbols-sans-serif-string "math-symbols" "\
Convert STRING to sans-serif style.

\(fn STRING)" nil nil)

(register-input-method "math-symbols-sans-serif-bold" "math" 'math-symbols-input-activate "mt")

(autoload 'math-symbols-sans-serif-bold-region "math-symbols" "\
Convert REGION to sans-serif-bold style.

\(fn FROM TO)" t nil)

(autoload 'math-symbols-sans-serif-bold-string "math-symbols" "\
Convert STRING to sans-serif-bold style.

\(fn STRING)" nil nil)

(register-input-method "math-symbols-sans-serif-italic" "math" 'math-symbols-input-activate "mt")

(autoload 'math-symbols-sans-serif-italic-region "math-symbols" "\
Convert REGION to sans-serif-italic style.

\(fn FROM TO)" t nil)

(autoload 'math-symbols-sans-serif-italic-string "math-symbols" "\
Convert STRING to sans-serif-italic style.

\(fn STRING)" nil nil)

(register-input-method "math-symbols-sans-serif-bold-italic" "math" 'math-symbols-input-activate "mt")

(autoload 'math-symbols-sans-serif-bold-italic-region "math-symbols" "\
Convert REGION to sans-serif-bold-italic style.

\(fn FROM TO)" t nil)

(autoload 'math-symbols-sans-serif-bold-italic-string "math-symbols" "\
Convert STRING to sans-serif-bold-italic style.

\(fn STRING)" nil nil)

(register-input-method "math-symbols-monospace" "math" 'math-symbols-input-activate "mt")

(autoload 'math-symbols-monospace-region "math-symbols" "\
Convert REGION to monospace style.

\(fn FROM TO)" t nil)

(autoload 'math-symbols-monospace-string "math-symbols" "\
Convert STRING to monospace style.

\(fn STRING)" nil nil)

(register-input-method "math-symbols-superscript" "math" 'math-symbols-input-activate "mt")

(autoload 'math-symbols-superscript-region "math-symbols" "\
Convert REGION to superscript style.

\(fn FROM TO)" t nil)

(autoload 'math-symbols-superscript-string "math-symbols" "\
Convert STRING to superscript style.

\(fn STRING)" nil nil)

(register-input-method "math-symbols-subscript" "math" 'math-symbols-input-activate "mt")

(autoload 'math-symbols-subscript-region "math-symbols" "\
Convert REGION to subscript style.

\(fn FROM TO)" t nil)

(autoload 'math-symbols-subscript-string "math-symbols" "\
Convert STRING to subscript style.

\(fn STRING)" nil nil)

(register-input-method "math-symbols-tex" "math" 'math-symbols-input-activate "mt")

(autoload 'math-symbols-from-tex-region "math-symbols" "\
Convert TeX commands in REGION to math symbols.
For example, 'Phi' will be converted to '𝛷'.

\(fn FROM TO)" t nil)

(autoload 'math-symbols-to-tex-region "math-symbols" "\
Convert math symbols to TeX command in REGION.
For example, `𝒫' will be converted to `mathcal{P}'.  
Optional argument UNICODE specifies to use unicode-math package.

\(fn FROM TO &optional UNICODE)" t nil)

(autoload 'math-symbols-to-tex-unicode-region "math-symbols" "\


\(fn FROM TO)" t nil)

(autoload 'math-symbols-insert "math-symbols" "\
Interactively input math characters from symbols.

\(fn NAME)" t nil)

(autoload 'math-symbols-helm "math-symbols" "\


\(fn)" t nil)

;;;***

;;;### (autoloads nil nil ("math-symbols-pkg.el") (21320 59678 914297
;;;;;;  886000))

;;;***

(provide 'math-symbols-autoloads)
;; Local Variables:
;; version-control: never
;; no-byte-compile: t
;; no-update-autoloads: t
;; coding: utf-8
;; End:
;;; math-symbols-autoloads.el ends here
