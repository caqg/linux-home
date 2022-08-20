;;; bigint.el --- A simple bigint package for emacs

;; Copyright (C) 2011 Robert Lupton. 

;; Author: Robert Lupton <rhl@astro.princeton.edu>
;; Url: http://www.astro.princeton.edu/~rhl/skyserver/bigint.el
;; Version: 1.0.0
;; Keywords: bigint, math

;; Packaged for marmalade by Ralph Moritz <ralmoritz@gmail.com>

;; This file is not part of GNU Emacs.
;;
;; This is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 2, or (at your option)
;; any later version.

;; This is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING.  If not, write to the
;; Free Software Foundation, Inc., 59 Temple Place - Suite 330,
;; Boston, MA 02111-1307, USA.

;;; Commentary: 

;; A simple bigint package for emacs; doubtless calc could do all this, 
;; but it's enormous.

(provide 'bigint)

(defconst bigint-base 10000 "Default base to use; must be power of 10
or 65536 (which may be specified as \"hex\")")

;;
;; Make a new bigint
;;
(defun bigint-new (base vec &optional negative)
  "Make a new bigint; the car is the vector of values, followed by
the base and whether the number's negative"
  (if (integerp vec)
      (setq vec (make-vector 1 vec)))
  (cons vec (cons base negative)))

(defun bigint-vec (A) "Return a bigint A's vector" (car A))
(defun bigint-base (A) "Return a bigint A's base" (car (cdr A)))
(defun bigint-ge-zero (A) "Return t if bigint A's >= 0" (not (cdr (cdr A))))
;;
;; Convert from a string to a bigint
;;
(defun bigint-string-to-bigint (str &optional base)
  "Convert a string to a vector, each element of which is a digit
of that string to some base.  Base 65536 (used for logical operations)
may be specified as \"hex\""
  (if (not base) (setq base bigint-base))

  (if (stringp base)
      (if (or (string-equal base "HEX") (string-equal base "hex"))
	  (setq base 65536)
	(error "The only non-numeric base supported is \"hex\" == 65536")))

  (save-match-data
    (let ( (ndig (round (log10 base)))
	   (positive t)
	   vec )
      (if (string-match "^[ \t]*-" str)
	  (progn
	    (setq positive nil)
	    (setq str (substring str (match-end 0)))))
      (cond ((= base 65536)
	     (setq vec (bigint-string-to-short-vector str))
	     )
	    ((= base (expt 10 ndig))
	     (while (not (= (% (length str) ndig) 0))
	       (setq str (concat "0" str)))
	     (let* ( (len (length str))
		     (nel (/ len ndig))
		     (i -1) )
	       (setq vec (make-vector nel 0))
	       (while (> (length str) 0)
		 (aset vec (- nel (setq i (1+ i)) 1)
		       (string-to-int (substring str 0 ndig)))
		 (setq str (substring str ndig))))
	     (setq vec (bigint-new base vec)))
	    (t
	     (error (format "Unsupported base %d" base))
	     ))
      (bigint-set-negative vec positive))))

(defun bigint-int-to-bigint (i &optional base)
  "Convert an int I to a vector, each element of which is a digit (base 100)
of that string.  It doesn't handle leading signs"
  (bigint-string-to-bigint (format "%d" i) base))
;;
;; Here's the workhorse behind bigint-string-to-bigint
;;
(defun bigint-string-to-short-vector (str)
  "Convert a string to a vector of (16-bit, base 10) integers,
handling leading 0x as appropriate"
  (save-match-data
    (let ( (A nil) )
      (if (string-match "[ \t]*0[xX]" str)
	  (let ( len )
	    ;; Hex
	    (setq str (substring str (match-end 0)))
	    (setq len (length str))
	    (while (> len 4)
	      (setq A (vconcat A (make-vector 1 (string-to-int
						 (substring str (- len 4)) 16))))
	      (setq str (substring str 0 (- len 4)))
	      (setq len (length str)))
	    (setq A (vconcat A (make-vector 1 (string-to-int str 16)))))
	;; Base 10
	(let ( (X (bigint-string-to-bigint str))
	       (SHORT (bigint-int-to-bigint 65536))
	       QR R )
	  (while (not (bigint-eq-zero X))
	    (setq QR (bigint-divide X SHORT))
	    (setq X (nth 0 QR))		;quotient
	    (setq R (nth 1 QR))		;remainder
	    (setq A (vconcat A (make-vector 1 (bigint-to-int R)))))))
      (if (< (length A) 4)
	  (setq A (vconcat A (make-vector 1 0))))
      (bigint-new base A))))
;;
;; Convert from bigint to a string
;;
(defun bigint-to-string (X)
  "Convert a \"bigint\" number to a string"
  (let* ( (base (bigint-base X))
	  (positive (bigint-ge-zero X))
	  (X (bigint-vec X))
	  (ndig (round (log10 base)))
	  (str nil)
	  (i (1- (length X))) x )
    (cond ((= base 65536)
	   (while (>= i 0)
	     (setq x (elt X i))
	       (if (or str (not (= x 0)))
		   (setq str (cond (str (concat str (format "%04x" x)))
				   (t (format "%x" x)))))
	       (setq i (1- i)))
	   (if (not str) (setq str "0"))
	   (setq str (concat "0x" str)))
	  ((= base (expt 10 ndig))
	   (let ( (fmt (format "%%0%dd" ndig)) )
	     (while (>= i 0)
	       (setq x (elt X i))
	       (if (or str (not (= x 0)))
		   (setq str (cond (str (concat str (format fmt x)))
				   (t (format "%d" x)))))
	       
	       (setq i (1- i))))
	   (if (not str) (setq str "0")))
	  (t
	   (error (format "I don't know how to format base %d" base))))
    (if (not positive) (setq str (concat "-" str)))
    str))

(defun bigint-to-int (X)
  "Convert a \"bigint\" number to an int"
  (string-to-int (bigint-to-string X)))
;;
;; Begin operators
;;
(defun bigint-add (X Y)
  "Add X and Y, both represented as bigints"

  (if (not (= (bigint-base X) (bigint-base Y)))
      (error "Both bigints must have the same base"))

  (cond
   ((and (bigint-ge-zero X) (not (bigint-ge-zero Y)))
    (bigint-subtract X (bigint-set-positive Y)))
   ((and (not (bigint-ge-zero X)) (bigint-ge-zero Y))
    (bigint-subtract Y (bigint-set-positive X)))
   (t
    (let* ( (base (bigint-base X))
	    (positive (bigint-ge-zero X))
	    (X (bigint-vec X))
	    (Y (bigint-vec Y))
	    (xlen (length X)) (ylen (length Y))
	    (len (1+ (cond ((> xlen ylen) xlen) (t ylen))))
	    (A (make-vector len 0))
	    (i 0) x y a (carry 0) )
      (while (< i len)
	(setq x (cond ((< i xlen) (elt X i)) (t 0)))
	(setq y (cond ((< i ylen) (elt Y i)) (t 0)))
	(setq a (+ x y carry))
	
	(setq carry (/ a base))
	(setq a (% a base))
	
	(aset A i a)
	(setq i (1+ i)))
      (bigint-set-negative (bigint-new base A) positive)))))
   
(defun bigint-subtract (X Y)
  "Subtract Y from X, both represented as bigints."
  (if (not (= (bigint-base X) (bigint-base Y)))
      (error "Both bigints must have the same base"))
  
  (cond
   ((and (bigint-ge-zero X) (not (bigint-ge-zero Y)))
    (bigint-add X (bigint-set-positive Y)))
   ((and (not (bigint-ge-zero X)) (bigint-ge-zero Y))
    (bigint-set-negative (bigint-add (bigint-set-positive X) Y)))
   (t
    (let* ( (base (bigint-base X))
	    (positive (bigint-ge-zero X))
	    (X (bigint-vec X))  (xlen (length X))
	    (Y (bigint-vec Y))  (ylen (length Y))
	    (len (cond ((> xlen ylen) xlen) (t ylen)))
	    (A (make-vector len 0))
	    (i 0) x y a (borrow 0) )
      (while (< i len)
	(setq x (cond ((< i xlen) (elt X i)) (t 0)))
	(setq y (cond ((< i ylen) (elt Y i)) (t 0)))
	(setq a (- x y borrow))
	(if (>= a 0)
	    (setq borrow 0)
	  (setq borrow (- 0 (floor a base)))
	  (setq a (+ a (* borrow base))))
	(aset A i a)
	(setq i (1+ i)))
      (setq A (bigint-new base A))
      (if (not (= borrow 0))		; -ve after calculation
	  (let ( big )
	    (setq big (bigint-new base (make-vector (1+ len) 0)))
	    (aset (bigint-vec big) len 1)
	    (setq A (bigint-subtract big A))
	    (bigint-set-negative A)))
      (if (not positive)		; we need to switch sign
	  (bigint-set-negative A (not (bigint-ge-zero A))))
      A))))

(defun bigint-multiply (X Y)
  "Multiply X and Y, both represented as bigints"

  (if (not (= (bigint-base X) (bigint-base Y)))
      (error "Both bigints must have the same base"))

  (let* ( (base (bigint-base X))
	  (positive (or
		     (and (bigint-ge-zero X) (bigint-ge-zero Y))
		     (and (not (bigint-ge-zero X)) (not (bigint-ge-zero Y)))))
	  (X (bigint-vec X))  (xlen (length X))
	  (Y (bigint-vec Y))  (ylen (length Y))
  	  (len (+ xlen ylen))
	  (A (make-vector len 0))
	  (i 0) x y a )
    (while (< i len)
      (setq x (cond ((< i xlen) (elt X i)) (t 0)))
      (let ( (j 0) tmp (carry 0) )
	(while (and (<= j ylen) (< (+ i j) len))
	  (setq y (cond ((< j ylen) (elt Y j)) (t 0)))
	  (setq a (elt A (+ i j)))
	  
	  (setq tmp (+ (* x y) a carry))
	  (setq carry (/ tmp base))
	  (setq tmp (% tmp base))
	  
	  (aset A (+ i j) tmp)
	  (setq j (1+ j)))

      (setq i (1+ i))))
    (bigint-set-negative (bigint-new base A) positive)))

(defun bigint-divide (U V)
  "Divide U by V, both represented as bigints, returning the quotient and
remainder.

The algorithm and notation are stolen from Knuth, Section 4.3.1
"

  (if (not (= (bigint-base U) (bigint-base V)))
      (error "Both bigints must have the same base"))

  (let* ( (base (bigint-base U))
	  (U-sign (if (bigint-ge-zero U) +1 -1))
	  (V-sign (if (bigint-ge-zero V) +1 -1))
	  (U (bigint-vec U))
	  (V (bigint-vec V))
	  n m
	  Q
	  d
	  i j
	  carry
	  u v q r )

    (setq n (length V))			;number of digits in V
    (while (and (> n 0) (= (elt V (1- n)) 0)) ;remove `leading' zeroes
      (setq n (1- n)))
    
    (setq m (- (length U) n))		;U has m + n digits
    (setq Q (make-vector (1+ m) 0))
    ;;
    ;; Are we dividing by a single digit number?
    ;;
    (if (<= n 1)
	(progn
	  (setq v (elt V 0))
	  (if (= 0 v)
	      (error "Attempt to divide by 0"))
	  (setq carry 0)
	  (setq i m)	  
	  (while (>= i 0)
	    (setq u (+ (elt U i) (* carry base)))
	    (setq carry (% u v))
	    (aset Q i (/ u v))
	    (setq i (1- i)))
	  (setq R carry))
      ;; Step D1 (see Knuth)
      (setq d (/ base (+ (elt V (1- n)) 1)))
      (setq U (vconcat (copy-sequence U) [0])) ;we need an extra digit
      (setq V (copy-sequence V))

      (setq i 0)			;normalise U
      (setq carry 0)
      (while (< i (+ n m))
	(setq u (+ (* d (elt U i)) carry))
	(setq carry (/ u base))
	(setq u (- u (* carry base)))
	(aset U i u)
	(setq i (1+ i)))
      (aset U i carry)

      (setq i 0)			;normalise V
      (setq carry 0)
      (while (< i n)
	(setq v (+ (* d (elt V i)) carry))
	(setq carry (/ v base))
	(setq v (- v (* carry base)))
	(aset V i v)
	(setq i (1+ i)))
      (if (not (= 0 carry))
	  (error "Need to carry for V"))
      ;; Step D2
      (setq j m)
      (while (>= j 0)
	;; Step D3
	(setq
	 q (/ (+ (* base (elt U (+ j n))) (elt U (+ j n -1))) (elt V (- n 1))))
	(setq
	 r (% (+ (* base (elt U (+ j n))) (elt U (+ j n -1))) (elt V (- n 1))))
	
	(setq i 2)
	(while (>= i 0)
	  (if (or (= q base)
		  (> (* q (elt V (- n 2))) (+ (* base r) (elt U (+ j n -2)))))
	      (progn
		(setq q (1- q))
		(setq r (+ r (elt V (- n 1))))
		(if (not (< r base)) (setq i 0)))) ; no need to repeat test
	  (setq i (1- i)))
	;; Step D4
	(setq i 0)
	(setq carry 0)			;actually it's "borrow" here
	(while (<= i n)
	  (setq u (- (elt U (+ j i))
		     (* q (cond ((= i n) 0) (t (elt V i)))) carry))
	  (if (>= u 0)
	      (setq carry 0)
	    (setq carry (- 0 (floor u base)))
	    (setq u (+ u (* carry base))))
	  (aset U (+ j i) u)
	  (setq i (1+ i)))
	;; Step D5
	(aset Q j q)
	;; Step D6
	(if (not (= carry 0))
	    (progn
	      (aset Q j (1- q))
	      
	      (setq i 0)
	      (setq carry 0)
	      (while (<= i n)
		(setq u (+ (elt U (+ j i))
			   (cond ((not (= i n)) (elt V i)) (t 0)) carry))
		      
		(setq carry (/ u base))
		(setq u (- u (* carry base)))
		(aset U (+ j i) u)
		
		(setq i (1+ i)))))
	;; Step D7
	(setq j (1- j)))
    ;; Step D8
      (setq R (make-vector n 0))
      (setq i (1- n))
      (setq carry 0)
      (while (>= i 0)
	(setq u (+ (elt U i) (* base carry)))
	(setq carry (% u d))
	(aset R i (/ u d))
	(setq i (1- i))))

    (setq Q (bigint-new base Q (< (* U-sign V-sign) 0)))
    (setq R (bigint-new base R (< U-sign 0)))
    (list Q R)))
;;
;;
(defun bigint-eq-zero (X)
  "Is a bigint number X equal to zero?"
  (let* ( (base (bigint-base X))
	 (X (bigint-vec X))
	 (n (length X)) (i 0) )
    (while (< i n)
      (if (not (= (elt X i) 0))
	  (setq i (1+ n)))
      (setq i (1+ i)))
    (if (= i n) t nil)))

(defun bigint-set-negative (A &optional positive)
  "Set A to be negative (or positive if the optional argument is t)"
  (setcdr (cdr A) (not positive))
  A)

(defun bigint-set-positive (A)
  "Set A to be positive)"
  (setcdr (cdr A) nil)
  A)
;;
;; Logical operators.  Only work on base 65536 bignums
;;
(defun bigint-logand (X Y)
  "Return the logical AND of two bigints.

Signs are ignored, and both must be base 65536"
  (if (not (= (bigint-base X) (bigint-base Y)))
      (error "Both bigints must have the same base"))

  (let* ( (base (bigint-base X))
	  (X (bigint-vec X))  (xlen (length X))
	  (Y (bigint-vec Y))  (ylen (length Y))
	  A )
    (cond ((= base 65536)
	   (let* ( (xlen (length X)) (ylen (length Y))
		   (len (1+ (cond ((> xlen ylen) xlen) (t ylen))))
		   (i 0) x y )
	     (setq A (make-vector len 0))
	     (while (< i len)
	       (setq x (cond ((< i xlen) (elt X i)) (t 0)))
	       (setq y (cond ((< i ylen) (elt Y i)) (t 0)))
	       
	       (aset A i (logand x y))
	       (setq i (1+ i)))
	     ))
	  (t
	   (error (format "Unsupported base %d" base))
	   ))
    (bigint-new base A)))

(defun bigint-logior (X Y)
  "Return the logical OR of two bigints.

Signs are ignored, and both must be base 65536"
  (if (not (= (bigint-base X) (bigint-base Y)))
      (error "Both bigints must have the same base"))

  (let* ( (base (bigint-base X))
	  (X (bigint-vec X))  (xlen (length X))
	  (Y (bigint-vec Y))  (ylen (length Y))
	  A )
    (cond ((= base 65536)
	   (let* ( (xlen (length X)) (ylen (length Y))
		   (len (1+ (cond ((> xlen ylen) xlen) (t ylen))))
		   (i 0) x y )
	     (setq A (make-vector len 0))
	     (while (< i len)
	       (setq x (cond ((< i xlen) (elt X i)) (t 0)))
	       (setq y (cond ((< i ylen) (elt Y i)) (t 0)))
	       
	       (aset A i (logior x y))
	       (setq i (1+ i)))
	     ))
	  (t
	   (error (format "Unsupported base %d" base))
	   ))
    (bigint-new base A)))

(defun bigint-logxor (X Y)
  "Return the logical XOR of two bigints.

Signs are ignored, and both must be base 65536"
  (if (not (= (bigint-base X) (bigint-base Y)))
      (error "Both bigints must have the same base"))

  (let* ( (base (bigint-base X))
	  (X (bigint-vec X))  (xlen (length X))
	  (Y (bigint-vec Y))  (ylen (length Y))
	  A )
    (cond ((= base 65536)
	   (let* ( (xlen (length X)) (ylen (length Y))
		   (len (1+ (cond ((> xlen ylen) xlen) (t ylen))))
		   (i 0) x y )
	     (setq A (make-vector len 0))
	     (while (< i len)
	       (setq x (cond ((< i xlen) (elt X i)) (t 0)))
	       (setq y (cond ((< i ylen) (elt Y i)) (t 0)))
	       
	       (aset A i (logxor x y))
	       (setq i (1+ i)))
	     ))
	  (t
	   (error (format "Unsupported base %d" base))
	   ))
    (bigint-new base A)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Test code
;;
;; N.b. use a small value of bigint-base (10?) when testing the division code
;; as there's a low-probability branch
;;
(if nil
    (progn
      (let ( (val "17626546044934")	; == 0x0000100800040006
	     U V A )
	(setq U (bigint-string-to-bigint "0x0000100000040000" "hex"))
	(setq V (bigint-string-to-bigint val "hex"))
	(setq A (bigint-logand U V))
	(if (not (string-equal (bigint-to-string A) (bigint-to-string U)))
	    (error (concat "Failed to extract desired bits "
			   (bigint-to-string U) " from "
			   (bigint-to-string A)))))
      
      (let ( (niter 1000) (i 0) )
	(while (< (setq i (1+ i)) niter)
	  (let* ( (x (- (random 100000) (/ 100000 2)))
		  (y (- (random 1000) (/ 1000 2)))
		  (y (cond ((= y 0) (1+ y)) (t y))) ; don't divide by 0
		  (X (bigint-string-to-bigint (format "%d" x)))
		  (Y (bigint-string-to-bigint (format "%d" y)))
		  (rat (bigint-divide X Y))
		  (orig (bigint-add (bigint-multiply (nth 0 rat) Y)
				    (nth 1 rat)))
		  (diff (bigint-subtract X Y))
		  q r )
	    ;; Check division
	    (setq q (bigint-to-int (nth 0 rat)))
	    (setq r (bigint-to-int (nth 1 rat)))
	    ;;(message (format "%d %d/%d : %d %d" i x y q r)); (sleep-for 0.01)
	    (if (or (not (= (/ x y) q))
		    (not (= (% x y) r)))
		(error (format "%d != %d*%d + %d" x y q r)))
	    ;; Check multiplication/addition
	    (if (not (= (bigint-to-int orig) x))
		(error (format "%d != %d*%d + %d (orig)"
			       (bigint-to-int orig) y q r)))
	    ;; And subtraction
	    (if (not (= (bigint-to-int diff) (- x y)))
		(error
		 (format "%d != %d - %d" (bigint-to-int diff) x y)))
	    )))
      ))

;;; bigint.el ends here
