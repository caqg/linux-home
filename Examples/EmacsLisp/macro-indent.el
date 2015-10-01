(defmacro prog3 (first second the-one &rest body)
  "Evaluates to the result of the third form, even when there are more."
  (declare (indent 3))
  `(progn ,first ,second (prog1 ,the-one ,@body)))

(prog3
    1
    2
    3
  '(and beyond))
