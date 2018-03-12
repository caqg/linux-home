;;; FACTORIAL
(defun factorial (n &optional (a 1))
  "Calculate N! * A (A defaults to 1)"
  (if (<= n 0)
      a
      (factorial (- n 1) (* a n))))
