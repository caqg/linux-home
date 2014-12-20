leerzeichen is a minor mode to display whitespace characters. That's all it
does, and it imposes little overhead by using a buffer local display table
rather than the font-lock functionality.

More information: https://github.com/fgeller/leerzeichen.el/

(defgroup leerzeichen nil
  "Faces for highlighting whitespace characters."
  :group 'leerzeichen)

(defface leerzeichen '((t (:foreground "#b8b8b8")))
  "Face for `leerzeichen-mode'."
  :group 'leerzeichen)

(defvar leerzeichen-saved-buffer-display-table nil
  "Stored version of `buffer-display-table' before leerzeichen-mode was enabled.")

(defvar leerzeichen-line-feed-glyph (make-glyph-code ?$ 'leerzeichen))
(defvar leerzeichen-tab-glyph (make-glyph-code ?» 'leerzeichen))
(defvar leerzeichen-space-glyph (make-glyph-code ?· 'leerzeichen))

(defvar leerzeichen-display-table
  (let ((table (make-display-table)))
    (aset table ?\n `[,leerzeichen-line-feed-glyph ?\n])
    (aset table ?\t (vconcat `[,leerzeichen-tab-glyph] (make-vector (1- tab-width) ? )))
    (aset table ?\  `[,leerzeichen-space-glyph])
    table)
  "Display table to highlight whitespace characters.")

(define-minor-mode leerzeichen-mode
  "Minor mode to highlight whitespace characters by displaying them differently."
  nil "lz " nil
  (if leerzeichen-mode
      (leerzeichen-enable)
    (leerzeichen-disable)))

(defun leerzeichen-enable ()
  "Install's leerzeichens display table as (buffer local) `buffer-display-table'."
  (setq leerzeichen-saved-buffer-display-table buffer-display-table)
  (setq buffer-display-table leerzeichen-display-table))

(defun leerzeichen-disable ()
  "Resets `buffer-display-table' to state before leerzeichen was enabled."
  (setq buffer-display-table leerzeichen-saved-buffer-display-table))

(provide 'leerzeichen)

leerzeichen.el ends here
