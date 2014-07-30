;;; wisi.el --- Utilities for implementing an indentation/navigation engine using a generalized LALR parser
;;
;; Copyright (C) 2012 - 2014  Free Software Foundation, Inc.
;;
;; Author: Stephen Leake <stephen_leake@member.fsf.org>
;; Version: 1.0.5
;; package-requires: ((cl-lib "0.4") (emacs "24.2"))
;; URL: http://stephe-leake.org/emacs/ada-mode/emacs-ada-mode.html
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

;;; Commentary:

;;;; History: first experimental version Oct 2012
;;
;;;; indentation algorithm overview
;;
;; This design is inspired in part by experience writing a SMIE
;; indentation engine for Ada, and the wisent parser.
;;
;; The general approach to indenting a given token is to find the
;; start of the statement it is part of, or some other relevant point
;; in the statement, and indent relative to that.  So we need a parser
;; that lets us find statement indent points from arbitrary places in
;; the code.
;;
;; For example, the grammar for Ada as represented by the EBNF in LRM
;; Annex P is not LALR(1), so we use a generalized LALR(1) parser (see
;; wisi-parse, wisi-compile).
;;
;; The parser actions cache indentation and other information as text
;; properties of tokens in statements.
;;
;; An indentation engine moves text in the buffer, as does user
;; editing, so we can't rely on character positions remaining
;; constant.  So the parser actions use markers to store
;; positions.  Text properties also move with the text.
;;
;; The stored information includes a marker at each statement indent
;; point.  Thus, the indentation algorithm is: find the previous token
;; with cached information, and either indent from it, or fetch from
;; it the marker for a previous statement indent point, and indent
;; relative to that.
;;
;; Since we have a cache (the text properties), we need to consider
;; when to invalidate it.  Ideally, we invalidate only when a change to
;; the buffer would change the result of a parse that crosses that
;; change, or starts after that change.  Changes in whitespace
;; (indentation and newlines) do not affect an Ada parse.  Other
;; languages are sensitive to newlines (Bash for example) or
;; indentation (Python).  Adding comments does not change a parse,
;; unless code is commented out.  For now we invalidate the cache after
;; the edit point if the change involves anything other than
;; whitespace.
;;
;;;; comparison to the SMIE parser
;;
;; The central problem to be solved in building the SMIE parser is
;; grammar precedence conflicts; the general solution is refining
;; keywords so that each new keyword can be assigned a unique
;; precedence.  This means ad hoc code must be written to determine the
;; correct refinement for each language keyword from the surrounding
;; tokens.  In effect, for a complex language like Ada, the knowledge
;; of the language grammar is mostly embedded in the refinement code;
;; only a small amount is in the refined grammar.  Implementing a SMIE
;; parser for a new language involves the same amount of work as the
;; first language.
;;
;; Using a generalized LALR parser avoids that particular problem;
;; assuming the language is already defined by a grammar, it is only a
;; matter of a format change to teach the wisi parser the
;; language.  The problem in a wisi indentation engine is caching the
;; output of the parser in a useful way, since we can't start the
;; parser from arbitrary places in the code (as we can with the SMIE
;; parser). A second problem is determining when to invalidate the
;; cache.  But these problems are independent of the language being
;; parsed, so once we have one wisi indentation engine working,
;; adapting it to new languages should be quite simple.
;;
;; The SMIE parser does not find the start of each statement, only the
;; first language keyword in each statement; additional code must be
;; written to find the statement start and indent points.  The wisi
;; parser finds the statement start and indent points directly.
;;
;; In SMIE, it is best if each grammar rule is a complete statement,
;; so forward-sexp will traverse the entire statement.  If nested
;; non-terminals are used, forward-sexp may stop inside one of the
;; nested non-terminals.  This problem does not occur with the wisi
;; parser.
;;
;; A downside of the wisi parser is conflicts in the grammar; they can
;; be much more difficult to resolve than in the SMIE parser.  The
;; generalized parser helps by handling conflicts, but it does so by
;; running multiple parsers in parallel, persuing each choice in the
;; conflict.  If the conflict is due to a genuine ambiguity, both paths
;; will succeed, which causes the parse to fail, since it is not clear
;; which set of text properties to store.  Even if one branch
;; ultimately fails, running parallel parsers over large sections of
;; code is slow.  Finally, this approach can lead to exponential growth
;; in the number of parsers.  So grammar conflicts must still be
;; analyzed and minimized.
;;
;; In addition, the complete grammar must be specified; in smie, it is
;; often possible to specify a subset of the grammar.
;;
;;;; grammar compiler and parser
;;
;; Since we are using a generalized LALR(1) parser, we cannot use any
;; of the wisent grammar functions.  We use OpenToken wisi-generate
;; to compile BNF to Elisp source (similar to
;; semantic-grammar-create-package), and wisi-compile-grammar to
;; compile that to the parser table.
;;
;; Semantic provides a complex lexer, more complicated than we need
;; for indentation.  So we use the elisp lexer, which consists of
;; `forward-comment', `skip-syntax-forward', and `scan-sexp'.  We wrap
;; that in functions that return tokens in the form wisi-parse
;; expects.
;;
;;;; code style
;;
;; 'wisi' was originally short for "wisent indentation engine", but
;; now is just a name.
;;
;; not using lexical-binding because we support Emacs 23
;;
;;;;;

;;; Code:

(require 'cl-lib)
(require 'wisi-parse)

;; WORKAROUND: for some reason, this condition doesn't work in batch mode!
;; (when (and (= emacs-major-version 24)
;; 	   (= emacs-minor-version 2))
  (require 'wisi-compat-24.2)
;;)

;;;; lexer

(defvar-local wisi-class-list nil)
(defvar-local wisi-keyword-table nil)
(defvar-local wisi-punctuation-table nil)
(defvar-local wisi-punctuation-table-max-length 0)
(defvar-local wisi-string-double-term nil);; string delimited by double quotes
(defvar-local wisi-string-quote-escape-doubled nil
  "Non-nil if a string delimiter is escaped by doubling it (as in Ada).")
(defvar-local wisi-string-quote-escape nil
  "Cons '(delim . character) where 'character' escapes quotes in strings delimited by 'delim'.")
(defvar-local wisi-string-single-term nil) ;; string delimited by single quotes
(defvar-local wisi-symbol-term nil)

(defun wisi-forward-token (&optional text-only)
  "Move point forward across one token, skipping leading whitespace and comments.
Return the corresponding token, in a format determined by TEXT-ONLY:
TEXT-ONLY t:          text
TEXT-ONLY nil:        (token text start . end)
where:
`token' is a token symbol (not string) from `wisi-punctuation-table',
`wisi-keyword-table', `wisi-string-double-term', `wisi-string-double-term' or `wisi-symbol-term'.

`text' is the token text from the buffer

`start, end' are the character positions in the buffer of the start
and end of the token text.

If at end of buffer, returns `wisent-eoi-term'."
  (forward-comment (point-max))
  ;; skips leading whitespace, comment, trailing whitespace.

  (let ((start (point))
	;; (info "(elisp)Syntax Table Internals" "*info elisp syntax*")
	(syntax (syntax-class (syntax-after (point))))
	token-id token-text)
    (cond
     ((eobp)
      (setq token-text "")
      (setq token-id wisent-eoi-term))

     ((eq syntax 1)
      ;; punctuation. Find the longest matching string in wisi-punctuation-table
      (forward-char 1)
      (let ((next-point (point))
	    temp-text temp-id done)
	(while (not done)
	  (setq temp-text (buffer-substring-no-properties start (point)))
	  (setq temp-id (car (rassoc temp-text wisi-punctuation-table)))
	  (when temp-id
	    (setq token-text temp-text
		  token-id temp-id
		  next-point (point)))
	  (if (or
	       (eobp)
	       (= (- (point) start) wisi-punctuation-table-max-length))
	      (setq done t)
	    (forward-char 1))
	  )
	(goto-char next-point)))

     ((memq syntax '(4 5)) ;; open, close parenthesis
      (forward-char 1)
      (setq token-text (buffer-substring-no-properties start (point)))
      (setq token-id (symbol-value (intern-soft token-text wisi-keyword-table))))

     ((eq syntax 7)
      ;; string quote, either single or double. we assume point is before the start quote, not the end quote
      (let ((delim (char-after (point)))
	    (forward-sexp-function nil))
	(forward-sexp)
	;; point is now after the end quote; check for an escaped quote
	(while (or
		(and wisi-string-quote-escape-doubled
		     (eq (char-after (point)) delim))
		(and (eq delim (car wisi-string-quote-escape))
		     (eq (char-before (1- (point))) (cdr wisi-string-quote-escape))))
	  (forward-sexp))
	(setq token-text (buffer-substring-no-properties start (point)))
	(setq token-id (if (= delim ?\") wisi-string-double-term wisi-string-single-term))))

     (t ;; assuming word syntax
      (skip-syntax-forward "w_'")
      (setq token-text (buffer-substring-no-properties start (point)))
      (setq token-id
	    (or (symbol-value (intern-soft (downcase token-text) wisi-keyword-table))
		wisi-symbol-term)))
     );; cond

    (unless token-id
      (error (wisi-error-msg "unrecognized token '%s'" (buffer-substring-no-properties start (point)))))

    (if text-only
	token-text
      (cons token-id (cons token-text (cons start (point)))))
    ))

(defun wisi-backward-token ()
  "Move point backward across one token, skipping whitespace and comments.
Return (nil text start . end) - same structure as
wisi-forward-token, but does not look up symbol."
  (forward-comment (- (point)))
  ;; skips leading whitespace, comment, trailing whitespace.

  ;; (info "(elisp)Syntax Table Internals" "*info elisp syntax*")
  (let ((end (point))
	(syntax (syntax-class (syntax-after (1- (point))))))
    (cond
     ((bobp) nil)

     ((memq syntax '(4 5)) ;; open, close parenthesis
      (backward-char 1))

     ((eq syntax 7)
      ;; a string quote. we assume we are after the end quote, not the start quote
      (let ((forward-sexp-function nil))
	(forward-sexp -1)))

     (t
      (if (zerop (skip-syntax-backward "."))
	  (skip-syntax-backward "w_'")))
     )
    (cons nil (cons (buffer-substring-no-properties (point) end) (cons (point) end)))
    ))

;;;; token info cache
;;
;; the cache stores the results of parsing as text properties on
;; keywords, for use by the indention and motion engines.

(cl-defstruct
  (wisi-cache
   (:constructor wisi-cache-create)
   (:copier nil))
  nonterm;; nonterminal from parse (set by wisi-statement-action)

  token
  ;; terminal symbol from wisi-keyword-table or
  ;; wisi-punctuation-table, or lower-level nonterminal from parse
  ;; (set by wisi-statement-action)

  last ;; pos of last char in token, relative to first (0 indexed)

  class
  ;; arbitrary lisp symbol, used for indentation and navigation.
  ;; some classes are defined by wisi:
  ;;
  ;; 'block-middle - a block keyword (ie: if then else end), not at the start of a statement
  ;;
  ;; 'block-start - a block keyword at the start of a statement
  ;;
  ;; 'statement-start - the start of a statement
  ;;
  ;; 'open-paren
  ;;
  ;; others are language-specific

  containing
  ;; Marker at the containing keyword for this token.
  ;; A containing keyword is an indent point; the start of a
  ;; statement, or 'begin', 'then' or 'else' for a block of
  ;; statements, etc.
  ;; nil only for first token in buffer

  prev ;; marker at previous motion token in statement; nil if none
  next ;; marker at next motion token in statement; nil if none
  end ;; marker at token at end of current statement
  )

(defvar-local wisi-cache-max 0
  "Maximimum position in buffer where wisi token cache is valid.")

(defvar-local wisi-parse-table nil)

(defvar-local wisi-parse-failed nil
  "Non-nil when a recent parse has failed - cleared when parse succeeds.")

(defvar-local wisi-parse-try nil
  "Non-nil when parse is needed - cleared when parse succeeds.")

(defvar-local wisi-change-need-invalidate nil)

(defvar wisi-end-caches nil
  "List of buffer positions of caches in current statement that need wisi-cache-end set.")

(defun wisi-invalidate-cache()
  "Invalidate the wisi token cache for the current buffer.
Also invalidate the Emacs syntax cache."
  (interactive)
  (setq wisi-cache-max 0)
  (setq wisi-parse-try t)
  (setq wisi-end-caches nil)
  (syntax-ppss-flush-cache (point-min))
  (with-silent-modifications
    (remove-text-properties (point-min) (point-max) '(wisi-cache))))

(defun wisi-before-change (begin end)
  "For `before-change-functions'."
  ;; begin . end is range of text being deleted

  ;; If jit-lock-after-change is before wisi-after-change in
  ;; after-change-functions, it might use any invalid caches in the
  ;; inserted text.
  ;;
  ;; So we check for that here, and ensure it is after
  ;; wisi-after-change, which deletes the invalid caches
  (when (boundp 'jit-lock-mode)
    (when (memq 'wisi-after-change (memq 'jit-lock-after-change after-change-functions))
      (setq after-change-functions (delete 'wisi-after-change after-change-functions))
      (add-hook 'after-change-functions 'wisi-after-change nil t))
    )

  (save-excursion
    ;; don't invalidate parse for whitespace, string, or comment changes
    (let (;; (info "(elisp)Parser State")
	  (state (syntax-ppss begin)))
      ;; syntax-ppss has moved point to "begin".
      (cond
       ((or
	 (nth 3 state); in string
	 (nth 4 state)); in comment
	;; FIXME: check that entire range is in comment or string
	(setq wisi-change-need-invalidate nil))

       ((progn
	  (skip-syntax-forward " " end);; does not skip newline
	  (eq (point) end))
	(setq wisi-change-need-invalidate nil))

       (t (setq wisi-change-need-invalidate t))
       ))))

(defun wisi-after-change (begin end length)
  "For `after-change-functions'."
  ;; begin . end is range of text being inserted (may be empty)

  ;; (syntax-ppss-flush-cache begin) is in before-change-functions

  (cond
   (wisi-parse-failed
    ;; The parse was failing, probably due to bad syntax; this change
    ;; may have fixed it, so try reparse.
    (setq wisi-parse-try t)

    ;; remove 'wisi-cache on inserted text, which could have caches
    ;; from before the failed parse, and are in any case invalid.
    (with-silent-modifications
      (remove-text-properties begin end '(wisi-cache)))
    )

   ((>= wisi-cache-max begin)
    ;; The parse had succeeded past the start of the inserted
    ;; text.
    (save-excursion
      (let ((need-invalidate t)
	    ;; (info "(elisp)Parser State")
	    (state (syntax-ppss begin)))
	;; syntax-ppss has moved point to "begin".
	(cond
	 (wisi-change-need-invalidate
	  ;; wisi-before change determined the removed text alters the
	  ;; parse
	  nil)

	 ((or
	   (nth 3 state); in string
	   (nth 4 state)); in comment
	  ;; FIXME: insert newline in comment to create non-comment!?
	  ;; or paste a chunk of code
	  ;; => check that all of change region is comment or string
	  (setq need-invalidate nil)
	  ;; no caches to remove
	  )

	 ((progn
	    (skip-syntax-forward " " end);; does not skip newlines
	    (eq (point) end))
	  (setq need-invalidate nil))

	 (t nil)
	 )

	(if need-invalidate
	    ;; The inserted or deleted text could alter the parse;
	    ;; wisi-invalidate-cache removes all 'wisi-cache.
	    (wisi-invalidate-cache)

	  ;; else move cache-max by the net change length. We don't
	  ;; need to delete 'wisi-cache in the inserted text, because
	  ;; if there were any it would not pass the above.
	  (setq wisi-cache-max
		(+ wisi-cache-max (- end begin length))))
	)
      ))

   (t
    ;; parse never attempted, or only done to before BEGIN. Just
    ;; remove 'wisi-cache
    (with-silent-modifications
      (remove-text-properties begin end '(wisi-cache)))
    )
  ))

(defun wisi-get-cache (pos)
  "Return `wisi-cache' struct from the `wisi-cache' text property at POS.
If accessing cache at a marker for a token as set by `wisi-cache-tokens', POS must be (1- mark)."
  (get-text-property pos 'wisi-cache))

(defvar-local wisi-parse-error-msg nil)

(defun wisi-goto-error ()
  "Move point to position in last error message (if any)."
  (when (string-match ":\\([0-9]+\\):\\([0-9]+\\):" wisi-parse-error-msg)
    (let ((line (string-to-number (match-string 1 wisi-parse-error-msg)))
	  (col (string-to-number (match-string 2 wisi-parse-error-msg))))
      (goto-char (point-min))
      (forward-line (1- line))
      (forward-char col))))

(defun wisi-show-parse-error ()
  "Show last wisi-parse error."
  (interactive)
  (if wisi-parse-failed
      (progn
	(message wisi-parse-error-msg)
	(wisi-goto-error))
    (message "parse succeeded")))

(defun wisi-validate-cache (pos)
  "Ensure cached data is valid at least up to POS in current buffer."
  (let ((msg (format "wisi: parsing %s:%d ..." (buffer-name) (line-number-at-pos))))
    (when (and wisi-parse-try
	       (< wisi-cache-max pos))
      (when (> wisi-debug 0)
	(message msg))

      (setq wisi-parse-try nil)
      (setq wisi-parse-error-msg nil)
      (save-excursion
	(goto-char wisi-cache-max)
	(if (> wisi-debug 1)
	    ;; let debugger stop in wisi-parse
	    (progn
	      (wisi-parse wisi-parse-table 'wisi-forward-token)
	      (setq wisi-cache-max (point))
	      (setq wisi-parse-failed nil))
	  ;; else capture errors from bad syntax, so higher level functions can try to continue
	  (condition-case err
	      (progn
		(wisi-parse wisi-parse-table 'wisi-forward-token)
		(setq wisi-cache-max (point))
		(setq wisi-parse-failed nil))
	    (wisi-parse-error
	     (setq wisi-parse-failed t)
	     (setq wisi-parse-error-msg (cdr err)))
	    )))
      (if wisi-parse-error-msg
	  ;; error
	  (when (> wisi-debug 0)
	    (message "%s error" msg)
	    (wisi-goto-error)
	    (error wisi-parse-error-msg))
	;; no msg; success
	(when (> wisi-debug 0)
	  (message "%s done" msg)))
      )))

(defun wisi-get-containing-cache (cache)
  "Return cache from (wisi-cache-containing CACHE)."
  (let ((containing (wisi-cache-containing cache)))
    (and containing
	 (wisi-get-cache (1- containing)))))

(defun wisi-cache-text (cache)
  "Return property-less buffer substring designated by cache.
Point must be at cache."
  (buffer-substring-no-properties (point) (+ (point) (wisi-cache-last cache))))

;;;; parse actions

(defun wisi-set-end (start-mark end-mark)
  "Set END-MARK on all caches in `wisi-end-caches' in range START-MARK END-MARK,
delete from `wisi-end-caches'."
  (let ((i 0)
	pos cache)
    (while (< i (length wisi-end-caches))
      (setq pos (nth i wisi-end-caches))
      (setq cache (wisi-get-cache pos))

      (if (and (>= pos start-mark)
	       (<  pos end-mark))
	  (progn
	    (setf (wisi-cache-end cache) end-mark)
	    (setq wisi-end-caches (delq pos wisi-end-caches)))

	;; else not in range
	(setq i (1+ i)))
      )))

(defvar wisi-tokens nil)
;; keep byte-compiler happy; `wisi-tokens' is bound in action created
;; by wisi-semantic-action

(defun wisi-statement-action (&rest pairs)
  "Cache information in text properties of tokens.
Intended as a grammar non-terminal action.

PAIRS is of the form [TOKEN-NUMBER CLASS] ...  where TOKEN-NUMBER
is the (1 indexed) token number in the production, CLASS is the wisi class of
that token. Use in a grammar action as:
  (wisi-statement-action 1 'statement-start 7 'statement-end)"
  (save-excursion
    (let ((first-item t)
	  first-keyword-mark
	  (override-start nil))
      (while pairs
	(let* ((number (1- (pop pairs)))
	       (region (cddr (nth number wisi-tokens)));; wisi-tokens is let-bound in wisi-parse-reduce
	       (token (car (nth number wisi-tokens)))
	       (class (pop pairs))
	       (mark
		;; Marker one char into token, so indent-line-to
		;; inserts space before the mark, not after
		(when region (copy-marker (1+ (car region)))))
	       cache)

	  (unless (memq class wisi-class-list)
	    (error "%s not in wisi-class-list" class))

	  (if region
	      (progn
		(if (setq cache (wisi-get-cache (car region)))
		    ;; We are processing a previously set non-terminal; ie generic_formal_part in
		    ;;
		    ;; generic_package_declaration : generic_formal_part package_specification SEMICOLON
		    ;;    (wisi-statement-action 1 'block-start 2 'block-middle 3 'statement-end)
		    ;;
		    ;; or simple_statement in
		    ;;
		    ;; statement : label_opt simple_statement
		    ;;
		    ;; override nonterm, class and containing
		    (progn
		      (cl-case (wisi-cache-class cache)
			(block-start
			 (setf (wisi-cache-class cache)
			       (cond
				 ((eq override-start nil)
				  (cond
				   ((memq class '(block-start statement-start)) 'block-start)
				   (t 'block-middle)))

				 ((memq override-start '(block-start statement-start)) 'block-start)

				 (t (error "unexpected override-start"))
				 )))
			(t
			 (setf (wisi-cache-class cache) (or override-start class)))
			)
		      (setf (wisi-cache-nonterm cache) $nterm)
		      (setf (wisi-cache-containing cache) first-keyword-mark))

		  ;; else create new cache
		  (with-silent-modifications
		    (put-text-property
		     (car region)
		     (1+ (car region))
		     'wisi-cache
		     (wisi-cache-create
		      :nonterm    $nterm;; $nterm defined in wisi-semantic-action
		      :token      token
		      :last       (- (cdr region) (car region))
		      :class      (or override-start class)
		      :containing first-keyword-mark)
		     ))
		  (if wisi-end-caches
		      (push (car region) wisi-end-caches)
		    (setq wisi-end-caches (list (car region)))
		    ))

		(when first-item
		  (setq first-item nil)
		  (when (or override-start
			    ;; FIXME: why block-middle here?
			    (memq class '(block-middle block-start statement-start)))
		    (setq override-start nil)
		    (setq first-keyword-mark mark)))

		(when (eq class 'statement-end)
		  (wisi-set-end (1- first-keyword-mark) (copy-marker (1+ (car region)))))
		)

	    ;; region is nil when a production is empty; if the first
	    ;; token is a start, override the class on the next token.
	    (when (and first-item
		       (memq class '(block-middle block-start statement-start)))
	      (setq override-start class)))
	))
      )))

(defun wisi-containing-action (containing-token contained-token)
  "Set containing marks in all tokens in CONTAINED-TOKEN with null containing mark to marker pointing to CONTAINING-TOKEN.
If CONTAINING-TOKEN is empty, the next token number is used."
  ;; wisi-tokens is is bound in action created by wisi-semantic-action
  (let* ((containing-region (cddr (nth (1- containing-token) wisi-tokens)))
	 (contained-region (cddr (nth (1- contained-token) wisi-tokens))))

    (unless containing-region ;;
      (signal 'wisi-parse-error
	      (wisi-error-msg
	       "wisi-containing-action: containing-region '%s' is empty. grammar error; bad action"
	       (nth 1 (nth (1- containing-token) wisi-tokens)))))

    (unless (or (not contained-region) ;; contained-token is empty
		(wisi-get-cache (car containing-region)))
      (signal 'wisi-parse-error
	      (wisi-error-msg
	       "wisi-containing-action: containing-token '%s' has no cache. grammar error; missing action"
	       (nth 1 (nth (1- containing-token) wisi-tokens)))))

    (while (not containing-region)
      ;; containing-token is empty; use next
      (setq containing-region (cddr (nth containing-token wisi-tokens))))

    (when contained-region
      ;; nil when empty production, may not contain any caches
      (save-excursion
	(goto-char (cdr contained-region))
	(let ((cache (wisi-backward-cache))
	      (mark (copy-marker (1+ (car containing-region)))))
	  (while cache

	    ;; skip blocks that are already marked
	    (while (and (>= (point) (car contained-region))
			(markerp (wisi-cache-containing cache)))
	      (goto-char (1- (wisi-cache-containing cache)))
	      (setq cache (wisi-get-cache (point))))

	    (if (or (and (= (car containing-region) (car contained-region))
			 (<= (point) (car contained-region)))
		    (< (point) (car contained-region)))
		;; done
		(setq cache nil)

	      ;; else set mark, loop
	      (setf (wisi-cache-containing cache) mark)
	      (setq cache (wisi-backward-cache)))
	    ))))))

(defun wisi-motion-action (&rest token-numbers)
  "Set prev/next marks in all tokens given by TOKEN-NUMBERS.
Each TOKEN-NUMBERS is one of:

number: the token number; mark that token

list (number token_id):
list (number (token_id token_id)):
   mark all tokens with token_id in the nonterminal given by the number."
  (save-excursion
    (let (prev-keyword-mark
	  prev-cache
	  cache
	  mark)
      (while token-numbers
	(let ((token-number (pop token-numbers))
	      target-token
	      region)
	  (cond
	   ((numberp token-number)
	    (setq target-token nil)
	    (setq region (cddr (nth (1- token-number) wisi-tokens)))
	    (when region
	      (setq cache (wisi-get-cache (car region)))
	      (setq mark (copy-marker (1+ (car region))))

	      (when (and prev-keyword-mark
			 cache
			 (null (wisi-cache-prev cache)))
		(setf (wisi-cache-prev cache) prev-keyword-mark)
		(setf (wisi-cache-next prev-cache) mark))

	      (setq prev-keyword-mark mark)
	      (setq prev-cache cache)
	      ))

	   ((listp token-number)
	    ;; token-number may contain 0, 1, or more token_id; token_id may be a list
	    ;; the corresponding region may be empty
	    ;; there must have been a prev keyword
	    (setq target-token (cadr token-number))
	    (when (not (listp target-token))
	      (setq target-token (list target-token)))
	    (setq token-number (car token-number))
	    (setq region (cddr (nth (1- token-number) wisi-tokens)))
	    (when region ;; not an empty token
	      (goto-char (car region))
	      (while (wisi-forward-find-token target-token (cdr region) t)
		(setq cache (wisi-get-cache (point)))
		(setq mark (copy-marker (1+ (point))))

		(when (null (wisi-cache-prev cache))
		  (setf (wisi-cache-prev cache) prev-keyword-mark)
		  (setf (wisi-cache-next prev-cache) mark)
		  (setq prev-keyword-mark mark)
		  (setq prev-cache cache))

		(wisi-forward-token);; don't find same token again
		))
	      )

	   (t
	    (error "unexpected token-number %s" token-number))
	   )

	  ))
      )))

;;;; motion
(defun wisi-backward-cache ()
  "Move point backward to the beginning of the first token preceding point that has a cache.
Returns cache, or nil if at beginning of buffer."
  (let (cache pos)
    (setq pos (previous-single-property-change (point) 'wisi-cache))
    ;; There are three cases:
    ;;
    ;; 1) caches separated by non-cache chars: 'if ... then'
    ;;    pos is before 'f', cache is on 'i'
    ;;
    ;; 2) caches not separated: ');'
    ;;    pos is before ';', cache is on ';'
    ;;
    ;; 3) at bob; pos is nil
    ;;
    (if pos
	(progn
	  (setq cache (get-text-property pos 'wisi-cache))
	  (if cache
	      ;; case 2
	      (goto-char pos)
	    ;; case 1
	    (setq cache (get-text-property (1- pos) 'wisi-cache))
	    (goto-char (1- pos))))
      ;; at bob
      (goto-char (point-min))
      (setq cache nil))
    cache
    ))

(defun wisi-forward-cache ()
  "Move point forward to the beginning of the first token after point that has a cache.
Returns cache, or nil if at end of buffer."
  (let (cache pos)
    (when (get-text-property (point) 'wisi-cache)
      ;; on a cache; get past it
      (goto-char (1+ (point))))

    (setq cache (get-text-property (point) 'wisi-cache))
    (if cache
	nil

      (setq pos (next-single-property-change (point) 'wisi-cache))
      (if pos
	  (progn
	    (goto-char pos)
	    (setq cache (get-text-property pos 'wisi-cache)))
	;; at eob
	(goto-char (point-max))
	(setq cache nil))
      )
    cache
    ))

(defun wisi-forward-find-class (class limit)
  "Search forward for a token that has a cache with CLASS.
Return cache, or nil if at end of buffer.
If LIMIT (a buffer position) is reached, throw an error."
  (let ((cache (wisi-forward-cache)))
    (while (not (eq class (wisi-cache-class cache)))
      (setq cache (wisi-forward-cache))
      (when (>= (point) limit)
	(error "cache with class %s not found" class)))
    cache))

(defun wisi-forward-find-token (token limit &optional noerror)
  "Search forward for a token that has a cache with TOKEN.
If point is at a matching token, return that token.
TOKEN may be a list; stop on any cache that has a member of the list.
Return cache, or nil if at end of buffer.
If LIMIT (a buffer position) is reached, then if NOERROR is nil, throw an
error, if non-nil, return nil."
  (let ((token-list (cond
		     ((listp token) token)
		     (t (list token))))
	(cache (wisi-get-cache (point)))
	(done nil))
    (while (not (or done
		    (and cache
			 (memq (wisi-cache-token cache) token-list))))
      (setq cache (wisi-forward-cache))
      (when (>= (point) limit)
	(if noerror
	    (progn
	      (setq done t)
	      (setq cache nil))
	  (error "cache with token %s not found" token))))
    cache))

(defun wisi-forward-find-nonterm (nonterm limit)
  "Search forward for a token that has a cache with NONTERM.
NONTERM may be a list; stop on any cache that has a member of the list.
Return cache, or nil if at end of buffer.
If LIMIT (a buffer position) is reached, throw an error."
  (let ((nonterm-list (cond
		       ((listp nonterm) nonterm)
		       (t (list nonterm))))
	(cache (wisi-forward-cache)))
    (while (not (memq (wisi-cache-nonterm cache) nonterm-list))
      (setq cache (wisi-forward-cache))
      (when (>= (point) limit)
	(error "cache with nonterm %s not found" nonterm)))
    cache))

(defun wisi-goto-cache-next (cache)
  (goto-char (1- (wisi-cache-next cache)))
  (wisi-get-cache (point))
  )

(defun wisi-forward-statement-keyword ()
  "If not at a cached token, move forward to next
cache. Otherwise move to cache-next, or next cache if nil.
Return cache found."
  (wisi-validate-cache (point-max))
  (let ((cache (wisi-get-cache (point))))
    (if cache
	(let ((next (wisi-cache-next cache)))
	  (if next
	      (goto-char (1- next))
	    (wisi-forward-token)
	    (wisi-forward-cache)))
      (wisi-forward-cache))
    )
  (wisi-get-cache (point))
  )

(defun wisi-backward-statement-keyword ()
  "If not at a cached token, move backward to prev
cache. Otherwise move to cache-prev, or prev cache if nil."
  (wisi-validate-cache (point-max))
  (let ((cache (wisi-get-cache (point))))
    (if cache
	(let ((prev (wisi-cache-prev cache)))
	  (if prev
	      (goto-char (1- prev))
	    (wisi-backward-cache)))
      (wisi-backward-cache))
  ))

(defun wisi-goto-containing (cache &optional error)
  "Move point to containing token for CACHE, return cache at that point."
  (cond
   ((markerp (wisi-cache-containing cache))
    (goto-char (1- (wisi-cache-containing cache)))
    (wisi-get-cache (point)))
   (t
    (when error
      (error "already at outermost containing token")))
   ))

(defun wisi-goto-containing-paren (cache)
  "Move point to just after the open-paren containing CACHE.
Return cache for paren, or nil if no containing paren."
  (while (and cache
	      (not (eq (wisi-cache-class cache) 'open-paren)))
    (setq cache (wisi-goto-containing cache)))
  (when cache
    (forward-char 1))
  cache)

(defun wisi-goto-start (cache)
  "Move point to containing ancestor of CACHE that has class block-start or statement-start.
Return start cache."
  (when
    ;; cache nil at bob
    (while (and cache
		(not (memq (wisi-cache-class cache) '(block-start statement-start))))
      (setq cache (wisi-goto-containing cache)))
    )
  cache)

(defun wisi-goto-end-1 (cache)
  (goto-char (1- (wisi-cache-end cache))))

(defun wisi-goto-end ()
  "Move point to token at end of statement point is in or before."
  (interactive)
  (wisi-validate-cache (point-max))
  (let ((cache (or (wisi-get-cache (point))
		   (wisi-forward-cache))))
    (when (wisi-cache-end cache)
      ;; nil when cache is statement-end
      (wisi-goto-end-1 cache))
    ))

(defun wisi-next-statement-cache (cache)
  "Move point to CACHE-next, return cache; error if nil."
  (when (not (markerp (wisi-cache-next cache)))
    (error "no next statement cache"))
  (goto-char (1- (wisi-cache-next cache)))
  (wisi-get-cache (point)))

(defun wisi-prev-statement-cache (cache)
  "Move point to CACHE-next, return cache; error if nil."
  (when (not (markerp (wisi-cache-prev cache)))
    (error "no prev statement cache"))
  (goto-char (1- (wisi-cache-prev cache)))
  (wisi-get-cache (point)))

;;;; indentation

(defun wisi-comment-indent ()
  "For `comment-indent-function'. Indent single line comment to
the comment on the previous line."
  ;; This should only be called by comment-indent-new-line or
  ;; fill-comment-paragraph, so there will be a preceding comment line
  ;; that we can trust.
  (save-excursion
    (forward-comment -1)
    (if (looking-at comment-start)
	(current-column)
      (error "wisi-comment-indent called after non-comment"))))

(defun wisi-indent-current (offset)
  "Return indentation OFFSET relative to indentation of current line."
  (+ (current-indentation) offset)
  )

(defun wisi-indent-paren (offset)
  "Return indentation OFFSET relative to preceding open paren."
  (save-excursion
    (goto-char (nth 1 (syntax-ppss)))
    (+ (current-column) offset)))

(defun wisi-indent-start (offset cache)
  "Return indentation of OFFSET relative to containing ancestor
of CACHE with class statement-start or block-start."
  (wisi-goto-start cache)
  (+ (current-indentation) offset))

(defun wisi-indent-statement ()
  "Indent region given by `wisi-goto-start' on cache at or before point, then wisi-cache-end."
  ;; force reparse, in case parser got confused
  (let ((wisi-parse-try t))
    (wisi-validate-cache (point)))

  (save-excursion
    (let ((cache (or (wisi-get-cache (point))
		     (wisi-backward-cache))))
      (when cache
	;; can be nil if in header comment
	(let ((start (progn (wisi-goto-start cache) (point)))
	      (end (progn
		     (when (wisi-cache-end cache)
		       ;; nil when cache is statement-end
		       (goto-char (1- (wisi-cache-end cache))))
		     (point))))
	  (indent-region start end)
	  ))
      )))

(defvar-local wisi-indent-calculate-functions nil
  "Functions to calculate indentation. Each called with point
  before a token at the beginning of a line (at current
  indentation); return indentation column for that token, or
  nil. May move point. Calling stops when first function returns
  non-nil.")

(defvar-local wisi-post-parse-fail-hook
  "Function to reindent portion of buffer.
Called from `wisi-indent-line' when a parse succeeds after
failing; assumes user was editing code that is now syntactically
correct. Must leave point at indentation of current line.")

(defvar-local wisi-indent-failed nil
  "Non-nil when wisi-indent-line fails due to parse failing; cleared when indent succeeds.")

(defun wisi-indent-line ()
  "Indent current line using the wisi indentation engine."
  (interactive)

  (let* ((savep (point))
	 (indent
	  (or (save-excursion
		(wisi-validate-cache (point))
		(back-to-indentation)
		(when (>= (point) savep) (setq savep nil))
		(if wisi-parse-failed
		    (progn
		      ;; parse failed. Assume user is editing; indent to previous line, fix it after parse succeeds
		      (setq wisi-indent-failed t)
		      (forward-line -1);; safe at bob
		      (back-to-indentation)
		      (current-column))

		  ;; else parse succeeded
		  (when wisi-indent-failed
		    (setq wisi-indent-failed nil)
		    (run-hooks 'wisi-post-parse-fail-hook))
		  (with-demoted-errors
		    (or (run-hook-with-args-until-success 'wisi-indent-calculate-functions) 0))
		  )))))
    (if savep
	;; point was inside line text; leave it there
	(save-excursion (indent-line-to indent))
      ;; point was before line text; move to start of text
      (indent-line-to indent))
    ))

;;;; debug
(defun wisi-parse-buffer ()
  (interactive)
  (syntax-propertize (point-max))
  (wisi-invalidate-cache)
  (wisi-validate-cache (point-max)))

(defun wisi-show-cache ()
  "Show cache at point."
  (interactive)
  (message "%s" (wisi-get-cache (point))))

(defun wisi-show-token ()
  "Move forward across one keyword, show token_id."
  (interactive)
  (let ((token (wisi-forward-token)))
    (message "%s" (car token))))

(defun wisi-show-containing-or-previous-cache ()
  (interactive)
  (let ((cache (wisi-get-cache (point))))
    (if cache
	(message "containing %s" (wisi-goto-containing cache t))
      (message "previous %s" (wisi-backward-cache)))
    ))

;;;;; setup

(defun wisi-setup (indent-calculate post-parse-fail class-list keyword-table token-table parse-table)
  "Set up a buffer for parsing files with wisi."
  (setq wisi-class-list class-list)
  (setq wisi-string-double-term (car (symbol-value (intern-soft "string-double" token-table))))
  (setq wisi-string-single-term (car (symbol-value (intern-soft "string-single" token-table))))
  (setq wisi-symbol-term (car (symbol-value (intern-soft "symbol" token-table))))

  (setq wisi-punctuation-table (symbol-value (intern-soft "punctuation" token-table)))
  (setq wisi-punctuation-table-max-length 0)
  (let (fail)
    (dolist (item wisi-punctuation-table)
      (when item ;; default matcher can be nil

	;; check that all chars used in punctuation tokens have punctuation syntax
	(mapc (lambda (char)
		(when (not (= ?. (char-syntax char)))
		  (setq fail t)
		  (message "in %s, %c does not have punctuation syntax"
			   (car item) char)))
	      (cdr item))

	(when (< wisi-punctuation-table-max-length (length (cdr item)))
	  (setq wisi-punctuation-table-max-length (length (cdr item)))))
      )
    (when fail
      (error "aborting due to punctuation errors")))

  (setq wisi-keyword-table keyword-table)
  (setq wisi-parse-table parse-table)

  (setq wisi-indent-calculate-functions indent-calculate)
  (set (make-local-variable 'indent-line-function) 'wisi-indent-line)

  (setq wisi-post-parse-fail-hook post-parse-fail)
  (setq wisi-indent-failed nil)

  (add-hook 'before-change-functions 'wisi-before-change nil t)
  (add-hook 'after-change-functions 'wisi-after-change nil t)

  ;; WORKAROUND: sometimes the first time font-lock is run,
  ;; syntax-propertize is not run properly, so we run it here
  (syntax-propertize (point-max))

  (wisi-invalidate-cache)
  )

(provide 'wisi)
;;; wisi.el ends here
