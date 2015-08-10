;;; perl-myvar-autoloads.el --- automatically extracted autoloads
;;
;;; Code:


;;;### (autoloads (pmv-declare) "perl-myvar" "perl-myvar.el" (21339
;;;;;;  18655 652665 439000))
;;; Generated autoloads from perl-myvar.el

(autoload 'pmv-declare "perl-myvar" "\
Examine the current perl subroutine and insert a declaration.
Variables are considered 'declared' if they appear as:

     my($myvar);
     local($localvar);
or
     #global($globalvar);
     #ignore(%d);

Used but undeclared variables are inserted as a 'my' declaration.

If font-lock mode is active, the faces are used to do a better job.

\(fn)" t nil)

;;;***

;;;### (autoloads nil nil ("perl-myvar-pkg.el") (21339 18655 772357
;;;;;;  925000))

;;;***

(provide 'perl-myvar-autoloads)
;; Local Variables:
;; version-control: never
;; no-byte-compile: t
;; no-update-autoloads: t
;; coding: utf-8
;; End:
;;; perl-myvar-autoloads.el ends here
