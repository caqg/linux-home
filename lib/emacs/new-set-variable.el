;;; Improvement on set-variable:  displays on demand the old value of the
;;; variable to be changed, so it can be edited in the minibuffer.

;;; To be applied later to simple.el

(defvar set-variable-displays-old-value nil
  "*When non-nil, the function set-variable (q.v.) displays in the minibuffer 
the old value of the variable to be set, so it can be edited instead of typed
afresh.

Some variables have values that don't fit in one line.  When that prevents you
from seeing the entire value, use \\[beginning-of-line] to move point back to
the beginning of the value, and perhaps use \\[enlarge-window] to see a larger
portion of the old value.")

(defun set-variable (var val)
  "Set VARIABLE to VALUE.  VALUE is a Lisp object.
When using this interactively, supply a Lisp expression for VALUE.
If you want VALUE to be a string, you must surround it with doublequotes.

If the variable set-variable-displays-old-value (q.v) is not nil, the old 
value is offered for editing in the minibuffer.  Calling this function with 
a prefix argument overrides the setting of set-variable-displays-old-value
for the duration of the call. (Useful if the old value is known to be
useless.)"
  (interactive
   (let* ((var (read-variable "Set variable: "))
	  (minibuffer-help-form
	   '(funcall myhelp))
	  (myhelp
	   (function
	    (lambda ()
	      (with-output-to-temp-buffer "*Help*"
		(prin1 var)
		(princ "\nDocumentation:\n")
		(princ (substring (documentation-property
                                   var 'variable-documentation)
				  1))
		(if (boundp var)
		    (let ((print-length 20))
		      (princ "\n\nCurrent value: ")
		      (prin1 (symbol-value var))))
		nil)))))
     (list var
	   (eval-minibuffer (format "Set %s to value: " var)
                            (if (and (if current-prefix-arg
                                         (not set-variable-displays-old-value)
                                       set-variable-displays-old-value)
                                     (boundp var))
                                (let ((print-length nil))
                                  (prin1-to-string (symbol-value var))))))))
  (set var val))
