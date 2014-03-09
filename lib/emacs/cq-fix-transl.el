(let ((the-map (cdr (assoc ?\8
                           (cddr (assoc ?\C-x
                                        (cdr
                                         key-translation-map)
                                        ))))))
  (define-key key-translation-map [f8] the-map))
(define-key key-translation-map [Compose] "?\C-z")
