;;; Grammar compiler for the wisent LALR parser, integrating Wisi OpenToken output.
;;
;; Copyright (C) 2012, 2013, 2015 Free Software Foundation, Inc.
;;
;; Author: Stephen Leake <stephen_leake@member.fsf.org>
;;
;; This file is part of GNU Emacs.
;;
;; GNU Emacs is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.
;;
;; GNU Emacs is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs.  If not, see <http://www.gnu.org/licenses/>.
;;
;;; History: first experimental version Jan 2013
;;
;;; Context
;;
;; Semantic (info "(semantic)Top") provides an LALR(1) parser
;; wisent-parse. The grammar used is defined by the functions
;; semantic-grammar-create-package, which reads a bison-like source
;; file and produces corresponding elisp source, and
;; wisent-compile-grammar, which generates a parser table.
;;
;; However, the algorithm used in wisent-compile-grammar cannot cope
;; with the grammar for the Ada language, because it is not
;; LALR(1). So we provide a generalized LALR parser, which spawns
;; parallel LALR parsers at each conflict. Instead of also rewriting
;; the entire semantic grammar compiler, we use the OpenToken LALR
;; parser generator, which is easier to modify (it is written in Ada,
;; not Lisp).
;;
;; The Ada function Wisi.Generate reads the bison-like input and
;; produces corresponding elisp source code, similar to that
;; produced by semantic-grammar-create-package.
;;
;; wisi-compile-grammar (provided here) generate the automaton
;; structure required by wisi-parse, using functions from
;; wisent/comp.el
;;
;;;;

(require 'semantic/wisent/comp)

(defun wisi-compose-action (value symbol-array nonterms)
  (let ((symbol (intern-soft (format "%s:%d" (car value) (cdr value)) symbol-array))
	(prod (car (nth (cdr value) (cdr (assoc (car value) nonterms))))))
    (if symbol
	(list (car value) symbol (length prod))
      (error "%s not in symbol-array" symbol))))

(defun wisi-replace-actions (action symbol-array nonterms)
  "Replace semantic action symbol names in ACTION with list as defined in `wisi-compile-grammar'.
ACTION is the alist for one state from the grammar; NONTERMS is from the grammar.
Return the new alist."
  ;; result is (nonterm index action-symbol token-count)
  (let (result item)
    (while action
     (setq item (pop action))
     (cond
      ((or
	(memq (cdr item) '(error accept))
	(numberp (cdr item)))
       (push item result))

      ((listp (cdr item))
       (let ((value (cdr item)))
	 (cond
	  ((symbolp (car value))
	   ;; reduction
	   (push (cons (car item)
		       (wisi-compose-action value symbol-array nonterms))
		 result))

	  ((integerp (car value))
	   ;; shift/reduce conflict
	   (push (cons (car item)
		       (list (car value)
			     (wisi-compose-action (cadr value) symbol-array nonterms)))
		 result))

	  ((integerp (cadr value))
	   ;; reduce/shift conflict
	   (push (cons (car item)
		       (list (wisi-compose-action (car value) symbol-array nonterms)
			     (cadr value)))
		 result))

	  (t ;; reduce/reduce conflict
	   (push (cons (car item)
		       (list (wisi-compose-action (car value) symbol-array nonterms)
			     (wisi-compose-action (cadr value) symbol-array nonterms)))
		 result))
	  )))

      (t
       (error "unexpected '%s'; expected 'error, 'accept, numberp, stringp, listp" (cdr item)))
      ));; while/cond

   (reverse result)))

(defun wisi-semantic-action (r rcode tags rlhs)
  "Define an Elisp function for semantic action at rule R.
On entry RCODE[R] contains a vector [BODY N (NTERM I)] where BODY
is the body of the semantic action, N is the number of tokens in
the production, NTERM is the nonterminal the semantic action
belongs to, and I is the index of the production and associated
semantic action in the NTERM rule.  Returns the semantic action
symbol, which is interned in RCODE[0].

The semantic action function accepts one argument, the list of
tokens to be reduced. It returns nil; it is called for the user
side-effects only."
  ;; based on comp.el wisent-semantic-action
  (let* ((actn (aref rcode r))
	 (n    (aref actn 1))         ; number of tokens in production
	 (name (apply 'format "%s:%d" (aref actn 2)))
	 (form (aref actn 0))
	 (action-symbol (intern name (aref rcode 0))))

    (fset action-symbol
	  `(lambda (wisi-tokens)
	     (let* (($nterm ',(aref tags (aref rlhs r)))
		    ($1 nil));; wisent-parse-nonterminals defines a default body of $1 for empty actions
	       ,form
	       nil)))

    (list (car (aref actn 2)) action-symbol n)))

(defun wisi-compile-grammar (grammar)
  "Compile the LALR(1) GRAMMAR; return the automaton for wisi-parse.
GRAMMAR is a list TERMINALS NONTERMS ACTIONS GOTOS, where:

TERMINALS is a list of terminal token symbols.

NONTERMS is a list of productions; each production is a
list (nonterm (tokens action) ...) where `action' is any lisp form.

ACTIONS is an array indexed by parser state, of alists indexed by
terminal tokens. The value of each item in the alists is one of:

'error

'accept

integer - shift; gives new state

'(nonterm . index) - reduce by nonterm production index.

'(integer (nonterm . index)) - a shift/reduce conflict
'((nonterm . index) integer) - a reduce/shift conflict
'((nonterm . index) (nonterm . index)) - a reduce/reduce conflict

The first item in the alist must have the key 'default (not a
terminal token); it is used when no other item matches the
current token.

GOTOS is an array indexed by parser state, of alists giving the
new state after a reduce for each nonterminal legal in that
state.

The automaton is an array with 3 elements:

parser-actions is a copy of the input ACTIONS, with reduction
actions replaced by a list (nonterm action-symbol token-count),
where `nonterm' is a symbol from NONTERMS, and is the
non-terminal to reduce to, token-count is the number of tokens in
the reduction, action-symbol is nil if there is no user action,
or a symbol from semantic-actions (below).

gotos is a copy of GOTOS.

semantic-actions is an obarray containing functions that
implement the user action for each nonterminal; the function
names have the format nonterm:index."
  (let (nrules ptable rcode rlhs tags token-list var-list)
    (wisent-parse-grammar;; set global vars used by wisent-semantic-action
     (cons
      (nth 0 grammar);; TOKENS
      (cons nil ;; ASSOCS
	    (nth 1 grammar));; NONTERMS
      ))

    (aset rcode 0 (make-vector 13 0));; obarray for semantic actions

    ;; create semantic action functions, interned in rcode[0]
    (let* ((i 1))
      (while (<= i nrules)
	(wisi-semantic-action i rcode tags rlhs)
	(setq i (1+ i)))
      )

    ;; replace semantic actions in ACTIONS with symbols from symbol-array
    (let ((nactions (length (nth 2 grammar)))
	  (actions (nth 2 grammar))
	  (symbol-array (aref rcode 0))
	  (i 0))
      (while (< i nactions)
	(aset actions i
	      (wisi-replace-actions (aref actions i) symbol-array (nth 1 grammar)))
	(setq i (1+ i)))
      (vector
       actions
       (nth 3 grammar)
       symbol-array)
      )))

(provide 'wisi-compile)

;;;; end of file
