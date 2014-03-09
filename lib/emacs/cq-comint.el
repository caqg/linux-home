(defun cq-comint-mode ()
  "Setup for inferior processes based on comint"
  (local-set-key "\C-j" 'comint-send-input))

(defun cq-shell-mode ()
  "Setup for inferior shells"
  (local-set-key "\C-j" 'comint-send-input)
  (make-variable-buffer-local 'comint-prompt-regexp)
  (setq comint-prompt-regexp "^[#$%?>] "))

;;;; end of cq-comint.el
