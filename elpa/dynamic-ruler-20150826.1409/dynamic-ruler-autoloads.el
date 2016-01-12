;;; dynamic-ruler-autoloads.el --- automatically extracted autoloads
;;
;;; Code:
(add-to-list 'load-path (directory-file-name (or (file-name-directory #$) (car load-path))))

;;;### (autoloads nil "dynamic-ruler" "dynamic-ruler.el" (22164 43833
;;;;;;  246236 680000))
;;; Generated autoloads from dynamic-ruler.el

(autoload 'dynamic-ruler "dynamic-ruler" "\
Temporarily display a horizontal ruler at `point'.
Press up and down, or `n' and `p', keys to move it around the
buffer.  Left and right, or `f' and `b', will change the origin
of the numbered scale.  Keys `a', `e' and `c' will change also
the origin of the numbered scale to the beginning, end and
center, respectively.  Numbers 0 to 9 will change the step
interval.  Press `q' to quit.

\(fn)" t nil)

(autoload 'dynamic-ruler-vertical "dynamic-ruler" "\
Temporarily display a vertical ruler in the `current-column'.
Press left and right, or `f' and `b', keys to move it around the
buffer.  Up and down, or `n' and `p', will change the origin of
the numbered scale.  Keys `a', `e' and `c' will change also the
origin of the numbered scale to the beginning, end and center,
respectively.  Numbers 0 to 9 will change the numbered scale and
the step interval.  Press `q' to quit.

\(fn)" t nil)

(autoload 'dynamic-ruler-temporary-invisible-change "dynamic-ruler" "\
Execute FORMS with a temporary `buffer-undo-list', undoing on return.
The changes you make within FORMS are undone before returning.
But more importantly, the buffer's `buffer-undo-list' is not affected.
This macro allows you to temporarily modify read-only buffers too.
Always return nil

\(fn &rest FORMS)" nil t)

;;;***

;; Local Variables:
;; version-control: never
;; no-byte-compile: t
;; no-update-autoloads: t
;; End:
;;; dynamic-ruler-autoloads.el ends here
