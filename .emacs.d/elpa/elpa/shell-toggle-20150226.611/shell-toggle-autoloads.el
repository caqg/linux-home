;;; shell-toggle-autoloads.el --- automatically extracted autoloads
;;
;;; Code:
(add-to-list 'load-path (or (file-name-directory #$) (car load-path)))

;;;### (autoloads nil "shell-toggle" "shell-toggle.el" (21749 23054
;;;;;;  945375 508000))
;;; Generated autoloads from shell-toggle.el

(autoload 'shell-toggle-cd "shell-toggle" "\
Call `shell-toggle' with a prefix argument.
See command `shell-toggle'.

\(fn)" t nil)

(autoload 'shell-toggle "shell-toggle" "\
Toggle between the shell buffer and whatever buffer you are editing.
With a prefix argument MAKE-CD also insert a \"cd DIR\" command
into the shell, where DIR is the directory of the current buffer.

Call twice in a row to get a full screen window for the shell buffer.

When called in the shell buffer returns you to the buffer you were editing
before calling this the first time.

Options: `shell-toggle-goto-eob'

\(fn MAKE-CD)" t nil)

;;;***

;; Local Variables:
;; version-control: never
;; no-byte-compile: t
;; no-update-autoloads: t
;; End:
;;; shell-toggle-autoloads.el ends here
