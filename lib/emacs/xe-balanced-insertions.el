;;; xemacs balanced insertions
;;; This replaces a much smarter version that used to work until around
;;; Emacs version 20.  It seems it never worked for Lucid/XEmacs, due
;;; to their more general implementation of character maps.

(defun insert-bookends (left right)
  "Insert strings LEFT and then RIGHT at point, then leave point
between them."
  (interactive)
  (insert left)
  (save-excursion
    (insert right)))

(defun globalize-bookends ()
  "Define global keys for selected bookend insertions.  I have chosen
those that are not likely to be defined especially by language editing 
modes."
  (interactive)

  ;; Here are the ones with identical left and right parts
  (global-set-key "\C-z\""
    '(lambda () (interactive) (insert-bookends "\"" "\"")))
  (global-set-key "\C-z'"
    '(lambda () (interactive) (insert-bookends "'" "'")))
  (global-set-key "\C-z`"
    '(lambda () (interactive) (insert-bookends "`" "`")))
  (global-set-key "\C-z*"
    '(lambda () (interactive) (insert-bookends "*" "*")))
  (global-set-key "\C-z_"
    '(lambda () (interactive) (insert-bookends "_" "_")))
  (global-set-key "\C-z-"
    '(lambda () (interactive) (insert-bookends "-" "-")))
  (global-set-key "\C-z+"
    '(lambda () (interactive) (insert-bookends "+" "+")))
  (global-set-key "\C-z|"
    '(lambda () (interactive) (insert-bookends "|" "|")))
  (global-set-key "\C-z/"
    '(lambda () (interactive) (insert-bookends "/" "/")))
  (global-set-key "\C-z\\"
    '(lambda () (interactive) (insert-bookends "\\" "\\")))
  (global-set-key "\C-z "
    '(lambda () (interactive) (insert-bookends " " " ")))
  (global-set-key "\C-z$"
    '(lambda () (interactive) (insert-bookends "$" "$")))
  (global-set-key "\C-z!"
    '(lambda () (interactive) (insert-bookends "!" "!")))
  (global-set-key "\C-z~"
    '(lambda () (interactive) (insert-bookends "~" "~")))
  (global-set-key "\C-z@"
    '(lambda () (interactive) (insert-bookends "@" "@")))
  (global-set-key "\C-z#"
    '(lambda () (interactive) (insert-bookends "#" "#")))
  (global-set-key "\C-z%"
    '(lambda () (interactive) (insert-bookends "%" "%")))
  (global-set-key "\C-z^"
    '(lambda () (interactive) (insert-bookends "^" "^")))
  (global-set-key "\C-z&"
    '(lambda () (interactive) (insert-bookends "&" "&")))
  (global-set-key "\C-z-"
    '(lambda () (interactive) (insert-bookends "-" "-")))
  (global-set-key "\C-z+"
    '(lambda () (interactive) (insert-bookends "+" "+")))
  (global-set-key "\C-z="
    '(lambda () (interactive) (insert-bookends "=" "=")))
  (global-set-key "\C-z:"
    '(lambda () (interactive) (insert-bookends ":" ":")))
  (global-set-key "\C-z?"
    '(lambda () (interactive) (insert-bookends "?" "?")))
  (global-set-key "\C-z."
    '(lambda () (interactive) (insert-bookends "." ".")))

  ;; Here are the non-trivial ones.
  (global-set-key "\C-z("
    '(lambda () (interactive) (insert-bookends "(" ")")))
  (global-set-key "\C-z{"
    '(lambda () (interactive) (insert-bookends "{" "}")))
  (global-set-key "\C-z["
    '(lambda () (interactive) (insert-bookends "[" "]")))
  (global-set-key "\C-z<"
    '(lambda () (interactive) (insert-bookends "<" ">")))
  (global-set-key "\C-zq"
    '(lambda () (interactive) (insert-bookends "`" "'")))
  (global-set-key "\C-zQ"
    '(lambda () (interactive) (insert-bookends "``" "''")))
  )

;;; xe-balanced-insertions
