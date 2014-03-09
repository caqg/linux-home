;;; Make sure some printouts go to the line printer.

(defun lprint-buffer ()
  "Like print-buffer, but spools to -Plp"
  (interactive)
  (let ((lpr-switches (cons "-Plp" lpr-switches)))
    (print-buffer)))

(defun lprint-region (start end)
  "Like print-region, but spools to -Plp"
  (interactive "r")
  (let ((lpr-switches (cons "-Plp" lpr-switches)))
    (print-region start end)))

(defvar lpq-known-printers '("lp")
  "*Printers known to the spooler")
(defvar lpq-command "/usr/ucb/lpq"
  "*Command to run to get spooling queues.")
(defvar lpq-options '("-l")
  "*List of options (strings) to pass to lpq")
(defvar lpq-most-recent-printer ""
  "Default that changes over time")

(defun lpq (prefix &optional printer)
  "Runs lpq(1) if available.

First argument is the prefix argument.

Optional argument is a string, the name of a printer.
In the absence of the printer argument (and when running interactively), if
run with a command prefix, offers choice of printer from the list
lpq-known-printers.  Else it asks for the default printer.

The default printer is originally the default for lpq.  If you choose a
printer once, it will be used as a default thereafter.

See also vars lpq-command and lpq-options"
  (interactive "P")
  (cond ((null printer)
         (setq printer (if prefix
                           (completing-read
                            "Printer? "
                            (mapcar (function
                                     (lambda (p) (cons p nil)))
                                    (cons lpq-most-recent-printer
                                          lpq-known-printers))
                            nil
                            'must-match
                            lpq-most-recent-printer)
                         ""))
         (if prefix (setq lpq-most-recent-printer printer))))
  (let* ((pname   (if (string= printer "") "" (concat "-P" printer)))
         (current (current-buffer))
         (buffer  (get-buffer-create (concat "*lpq" pname "*")))
         (options lpq-options))
    (if (not (string= printer ""))
        (setq options (cons pname options)))
    (save-excursion
      (set-buffer buffer)
      (erase-buffer)
      (insert (current-time-string) "\n\n$ " lpq-command " ")
      (insert (mapconcat 'identity options " "))
      (insert "\n"))
    (apply 'call-process lpq-command nil buffer t options)
    (switch-to-buffer-other-window buffer)
    (pop-to-buffer current)))

;;;; End of cq-lpr.el
