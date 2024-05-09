;;; dict-tree.el --- Dictionary data structure  -*- lexical-binding: t; -*-

;; Copyright (C) 2004-2023  Free Software Foundation, Inc

;; Author: Toby Cubitt <toby-predictive@dr-qubit.org>
;; Version: 0.17
;; Keywords: extensions, matching, data structures
;;           trie, tree, dictionary, completion, regexp
;; Package-Requires: ((trie "0.6") (tNFA "0.1.1") (heap "0.3") (emacs "24.1"))
;; URL: http://www.dr-qubit.org/emacs.php

;; This file is part of Emacs.
;;
;; GNU Emacs is free software: you can redistribute it and/or modify it under
;; the terms of the GNU General Public License as published by the Free
;; Software Foundation, either version 3 of the License, or (at your option)
;; any later version.
;;
;; GNU Emacs is distributed in the hope that it will be useful, but WITHOUT
;; ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
;; FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
;; more details.
;;
;; You should have received a copy of the GNU General Public License along
;; with GNU Emacs.  If not, see <http://www.gnu.org/licenses/>.


;;; Commentary:
;;
;; A dict-tree (created using `dictree-create') is used to store strings,
;; along with arbitrary data associated with each string. (Note that the
;; "strings" can be any sequence data type, not just Elisp strings.) As well
;; as basic data insertion (`dictree-insert'), manipulation
;; (`dictree-insert'), and retrieval (`dictree-lookup', `dictree-member-p'), a
;; dict-tree can perform sophisticated queries on strings, including:
;;
;; - retrieve all completions of a prefix
;;   (`dictree-complete')
;;
;; - retrieve all strings that match a regular expression
;;   (`dictree-regexp-search')
;;
;; - retrieve all fuzzy matches to a string, i.e. matches within a specified
;;   Lewenstein distance (a.k.a. edit distance)
;;   (`dictree-fuzzy-match')
;;
;; - retrieve all fuzzy completions of a prefix, i.e. completions of prefixes
;;   within a specified Lewenstein distance
;;   (`dictree-fuzzy-complete')
;;
;; The results of all of these queries can be ranked in alphabetical order, or
;; according to any other desired ranking. The results can also be limited to
;; a given number of matches.
;;
;; These sophisticated string queries are fast even for very large dict-trees,
;; and dict-tree's also cache query results (and automatically keep these
;; caches synchronised) to speed up queries even further.
;;
;; Other functions allow you to:
;;
;; - create dict-tree stack objects, which allow efficient access to the
;;   strings in the dictionary or in query results as though they were sorted
;;   on a stack (useful for designing efficient algorithms on top of
;;   dict-trees)
;;   (`dictree-stack', `dictree-complete-stack', `dictree-regexp-stack',
;;    `dictree-fuzzy-match-stack', `dictree-fuzzy-complete-stack')
;;
;; - generate dict-tree iterator objects which allow you to retrieve
;;   successive elements by calling `iter-next'
;;   (`dictree-iter', `dictree-complete-iter', `dictree-regexp-iter',
;;    `dictree-fuzzy-match-iter', `dictree-fuzzy-complete-iter')
;;
;; - map over all strings in alphabetical order
;;   (`dictree-mapc', `dictree-mapcar' and `dictree-mapf')
;;
;; Dict-trees can be combined together into a "meta dict-tree", which combines
;; the data from identical keys in its constituent dict-trees, in whatever way
;; you specify (`dictree-create-meta-dict'). Any number of dict-trees can be
;; combined in this way. Meta-dicts behave *exactly* like dict-trees: all of
;; the above functions work on meta-dicts as well as dict-trees, and
;; meta-dicts can themselves be used in new meta-dicts.
;;
;; The package also provides persistent storage of dict-trees to file.
;; (`dictree-save', `dictree-write', `dictee-load')
;;
;; This package uses the trie package trie.el, the tagged NFA package tNFA.el,
;; and the heap package heap.el.


;;; Code:

(require 'cl-lib)
(require 'gv)

(require 'trie)
(require 'tNFA)


;;; ================================================================
;;;            Replacements for CL and Elisp functions

;; copied from cl-extra.el
(defun dictree--subseq (seq start &optional end)
  "Return the subsequence of SEQ from START to END.
If END is omitted, it defaults to the length of the sequence.
If START or END is negative, it counts from the end."
  (if (stringp seq) (substring seq start end)
    (let (len)
      (and end (< end 0) (setq end (+ end (setq len (length seq)))))
      (when (< start 0)
	(setq start (+ start (or len (setq len (length seq))))))
      (cond ((listp seq)
	     (if (> start 0) (setq seq (nthcdr start seq)))
	     (if end
		 (let ((res nil))
		   (while (>= (setq end (1- end)) start)
		     (push (pop seq) res))
		   (nreverse res))
	       (copy-sequence seq)))
	    (t
	     (or end (setq end (or len (length seq))))
	     (let ((res (make-vector (max (- end start) 0) nil))
		   (i 0))
	       (while (< start end)
		 (aset res i (aref seq start))
		 (setq i (1+ i) start (1+ start)))
	       res))))))



;; `goto-line' without messing around with mark and messages
(defun dictree--goto-line (line)
  "Goto line LINE, counting from line 1 at beginning of buffer."
  (goto-char 1)
  (if (eq selective-display t)
      (re-search-forward "[\n\C-m]" nil 'no-error (1- line))
    (forward-line (1- line))))


;;; ====================================================================
;;;  Internal functions and variables for use in the dictionary package

(defvar dictree-loaded-list nil
  "Stores list of loaded dictionaries.")


;; ----------------------------------------------------------------
;;                   Dictionary data cell structures

;; Note: It would be more elegant to use a defstruct for the data cells,
;;       but the problem is that the resulting setf in
;;       `dictree--wrap-insfun' won't get expanded into the cell-data
;;       accessor function at compile-time because it's burried inside a
;;       backquote construct. Not only is it inelegant to have to expand
;;       macros at run-time whenever `dictree--wrap-insfun' is called,
;;       but it also requires the 'cl-macs package to be loaded at
;;       run-time rather than just at compile-time. We could use
;;       `lexical-let' instead, but it doesn't seem worth it here.

;; wrap data in a cons cell
(defalias 'dictree--cell-create #'cons)  ; INTERNAL USE ONLY

;; get data component from data cons cell
(eval-and-compile ;; So the compiler finds the setter.
  (defalias 'dictree--cell-data #'car)  ; INTERNAL USE ONLY

;; get property list component from data cons cell
  (defalias 'dictree--cell-plist #'cdr))  ; INTERNAL USE ONLY

;; ----------------------------------------------------------------
;;                 Dictionary cache entry structures

;; Note: We *could* use a defstruct for the cache entries, but for
;;       something this simple it doesn't seem worth it, especially
;;       given that we're using the defalias approach anyway for the
;;       data cells (above).

;; Construct and return a completion cache entry
(defalias 'dictree--cache-create #'cons)  ; INTERNAL USE ONLY

;; Return the completions list for cache entry CACHE
(eval-and-compile ;; So the compiler finds the setter.
  (defalias 'dictree--cache-results #'car)  ; INTERNAL USE ONLY

  ;; Return the max number of completions returned for cache entry CACHE
  (defalias 'dictree--cache-maxnum #'cdr))  ; INTERNAL USE ONLY

;; ----------------------------------------------------------------
;;                     Wrapping functions

;; return wrapped insfun to deal with data wrapping
(defun dictree--wrap-insfun (insfun)  ; INTERNAL USE ONLY
  (lambda (new old)
    (setf (dictree--cell-data old)
	  (funcall insfun
		   (dictree--cell-data new)
		   (dictree--cell-data old)))
    old))

;; return wrapped rankfun to deal with data wrapping
(defun dictree--wrap-rankfun (rankfun)  ; INTERNAL USE ONLY
  (lambda (a b)
    (funcall rankfun
	     (cons (car a) (dictree--cell-data (cdr a)))
	     (cons (car b) (dictree--cell-data (cdr b))))))

;; return wrapped rankfun to ignore regexp grouping data
(defun dictree--wrap-regexp-rankfun (rankfun)
  (lambda (a b)
    ;; if car of argument contains a key+group list rather than a straight
    ;; key, remove group list
    ;; FIXME: the test for straight key, below, will fail if the key is a
    ;;        list, and the first element of the key is itself a list
    ;;        (there might be no easy way to fully fix this...)
    (funcall rankfun
             (if (or (atom (car a))
	             (and (listp (car a)) (not (sequencep (caar a)))))
	         (cons (car a) (dictree--cell-data (cdr a)))
	       (cons (caar a) (dictree--cell-data (cdr a))))
	     (if (or (atom (car b))
	             (and (listp (car b)) (not (sequencep (caar b)))))
	         (cons (car b) (dictree--cell-data (cdr b)))
	       (cons (caar b) (dictree--cell-data (cdr b)))))))

;; return wrapped sortfun to ignore regexp grouping data
(defun dictree--wrap-regexp-sortfun (cmpfun &optional reverse)
  (let ((sortfun (trie-construct-sortfun cmpfun reverse)))
    (lambda (a b)
      ;; if car of argument contains a key+group list rather than a
      ;; straight key, remove group list
      ;; FIXME: the test for straight key, below, will fail if the key
      ;;        is a list, and the first element of the key is itself a
      ;;        list (there might be no easy way to fully fix this...)
      (funcall sortfun
               (if (or (atom (car a))
	               (and (listp (car a)) (not (sequencep (caar a)))))
	           (car a)
	         (caar a))
	       (if (or (atom (car b))
	               (and (listp (car b)) (not (sequencep (caar b)))))
	           (car b)
	         (caar b))))))

;; return wrapped rankfun to deal with data wrapping and ignore fuzzy query
;; distance data. Note: works for both fuzzy-matching and fuzzy-completion.
(defun dictree--wrap-fuzzy-rankfun (rankfun)  ; INTERNAL USE ONLY
  (lambda (a b)
    (funcall rankfun
	     (cons (car a) (dictree--cell-data (cdr a)))
	     (cons (car b) (dictree--cell-data (cdr b))))))

(defun dictree--construct-fuzzy-trie-rankfun (rankfun &optional dict)
  (cond
   ((eq rankfun 'distance) t)
   ((and (or (eq (car-safe rankfun) t)
	     (eq (car-safe rankfun) 'distance))
	 (or (eq (cdr-safe rankfun) t)
	     (eq (cdr-safe rankfun) 'ranked)))
    (cons t (dictree--wrap-rankfun (dictree-rank-function dict))))
   ((or (eq (car-safe rankfun) t)
	(eq (car-safe rankfun) 'distance))
    (cons t (dictree--wrap-fuzzy-rankfun (cdr rankfun))))
   ((or (eq rankfun t)
	(eq rankfun 'ranked))
    (dictree--wrap-fuzzy-rankfun (dictree-rank-function dict)))
   (rankfun (dictree--wrap-fuzzy-rankfun rankfun))))

(defun dictree--construct-fuzzy-match-rankfun (rankfun dict)
  (trie--construct-fuzzy-match-rankfun
   (dictree--construct-fuzzy-trie-rankfun rankfun dict)
   (dictree--trie dict)))

(defun dictree--construct-fuzzy-complete-rankfun (rankfun dict)
  (trie--construct-fuzzy-complete-rankfun
   (dictree--construct-fuzzy-trie-rankfun rankfun dict)
   (dictree--trie dict)))


;; return wrapped sortfun to ignore fuzzy query distance data
(defun dictree--wrap-fuzzy-sortfun (cmpfun &optional reverse)
  (let ((sortfun (trie-construct-sortfun cmpfun reverse)))
    (lambda (a b) (funcall sortfun (car a) (car b)))))

;; return wrapped combfun to deal with data wrapping
(defun dictree--wrap-combfun (combfun)  ; INTERNAL USE ONLY
  (lambda (cell1 cell2)
    (dictree--cell-create
     (funcall combfun
	      (dictree--cell-data cell1)
	      (dictree--cell-data cell2))
     (append (dictree--cell-plist cell1)
	     (dictree--cell-plist cell2)))))

;; return wrapped filter function to deal with data wrapping
(defun dictree--wrap-filter (filter)  ; INTERNAL USE ONLY
  (lambda (key data) (funcall filter key (dictree--cell-data data))))

;; return wrapped result function to deal with data wrapping
(defun dictree--wrap-resultfun (resultfun)  ; INTERNAL USE ONLY
  (lambda (res)
    (funcall resultfun (car res) (dictree--cell-data (cdr res)))))

;; construct lexicographic sort function from DICT's comparison function.
;; ACCESSOR is used to obtain the sort key, defaulting to `car'.
(defun dictree--construct-sortfun (comparison-function &optional accessor)  ; INTERNAL USE ONLY
  (unless accessor (setq accessor #'car))
  (let ((sortfun (trie-construct-sortfun comparison-function)))
    (lambda (a b)
      (funcall sortfun (funcall accessor a) (funcall accessor b)))))


;; ----------------------------------------------------------------
;;                 The dictionary data structures

(cl-defstruct
  (dictree-
   :named
   (:constructor nil)
   (:constructor dictree--create
		 (&optional
		  name
		  filename
		  autosave
		  _unlisted
		  (comparison-function #'<)
		  (insert-function (lambda (a _b) a))
		  (rank-function (lambda (a b) (> (cdr a) (cdr b))))
		  (cache-policy 'time)
		  cache-threshold
		  (cache-update-policy 'synchronize)
		  key-savefun key-loadfun
		  data-savefun data-loadfun
		  plist-savefun plist-loadfun
		  (trie-type 'avl)
		  &aux
		  (modified nil)
		  (trie (trie-create comparison-function trie-type))
		  (lookup-cache nil)
		  (complete-cache nil)
		  (regexp-cache nil)
		  (fuzzy-match-cache nil)
		  (fuzzy-complete-cache nil)
		  (meta-dict-list nil)
		  ))
   (:constructor dictree--create-custom
		 (&optional
		  name
		  filename
		  autosave
		  _unlisted
		  (comparison-function #'<)
		  (insert-function (lambda (a _b) a))
		  (rank-function (lambda (a b) (> (cdr a) (cdr b))))
		  (cache-policy 'time)
		  cache-threshold
		  (cache-update-policy 'synchronize)
		  key-savefun key-loadfun
		  data-savefun data-loadfun
		  plist-savefun plist-loadfun
		  &key
		  createfun insertfun deletefun
		  lookupfun mapfun emptyfun
		  stack-createfun stack-popfun stack-emptyfun
		  transform-for-print transform-from-read
		  &aux
		  (modified nil)
		  (trie (make-trie-custom
			 comparison-function
			 :createfun createfun
			 :insertfun insertfun
			 :deletefun deletefun
			 :lookupfun lookupfun
			 :mapfun mapfun
			 :emptyfun emptyfun
			 :stack-createfun stack-createfun
			 :stack-popfun stack-popfun
			 :stack-emptyfun stack-emptyfun
			 :transform-for-print transform-for-print
			 :transform-from-read transform-from-read))
		  (lookup-cache nil)
		  (complete-cache nil)
		  (regexp-cache nil)
		  (fuzzy-match-cache nil)
		  (fuzzy-complete-cache nil)
		  (meta-dict-list nil)
		  ))
   (:copier dictree--copy))
  name filename autosave modified
  comparison-function insert-function rank-function
  cache-policy cache-threshold cache-update-policy
  lookup-cache complete-cache regexp-cache
  fuzzy-match-cache fuzzy-complete-cache
  key-savefun key-loadfun
  data-savefun data-loadfun
  plist-savefun plist-loadfun
  trie meta-dict-list)


(cl-defstruct
  (dictree--meta-dict
   :named
   (:constructor nil)
   (:constructor dictree--meta-dict-create
		 (dictionary-list
		  &optional
		  name
		  filename
		  autosave
		  _unlisted
		  (combine-function #'+)
		  (cache-policy 'time)
		  cache-threshold
		  (cache-update-policy 'synchronize)
		  &aux
		  (dictlist
		   (mapcar
		    (lambda (dic)
		      (cond
		       ((dictree-p dic) dic)
		       ((symbolp dic) (symbol-value dic))
		       (t (error "Invalid object in DICTIONARY-LIST"))))
		    dictionary-list))
		  (lookup-cache nil)
		  (complete-cache nil)
		  (regexp-cache nil)
		  (fuzzy-match-cache nil)
		  (fuzzy-complete-cache nil)
		  ))
   (:copier dictree--meta-dict-copy))
  name filename autosave modified combine-function
  cache-policy cache-threshold cache-update-policy
  lookup-cache complete-cache regexp-cache
  fuzzy-match-cache fuzzy-complete-cache
  dictlist meta-dict-list)




;; ----------------------------------------------------------------
;;           Miscelaneous internal functions and macros

(defun dictree--trielist (dict)
  ;; Return a list of all the tries on which DICT is based. If DICT is a
  ;; meta-dict, this recursively descends the hierarchy, gathering all
  ;; the tries from the base dictionaries.
  (dictree--do-trielist dict))

(defun dictree--do-trielist (dict)
  (if (dictree-meta-dict-p dict)
      (apply #'nconc (mapcar #'dictree--do-trielist
			     (dictree--meta-dict-dictlist dict)))
    (list (dictree--trie dict))))


(defun dictree--merge (list1 list2 cmpfun &optional maxnum)
  ;; Destructively merge together sorted lists LIST1 and LIST2, sorting
  ;; elements according to CMPFUN. For non-null MAXNUM, only the first
  ;; MAXNUM are kept.
  (or (listp list1) (setq list1 (append list1 nil)))
  (or (listp list2) (setq list2 (append list2 nil)))
  (let (res (i 0))

    ;; build up result list backwards
    (while (and list1 list2 (or (null maxnum) (< (cl-incf i) maxnum)))
      ;; move smaller element to result list
      (if (funcall cmpfun (car list2) (car list1))
	  (push (pop list2) res)
	(push (pop list1) res)))

    ;; return result if we already have MAXNUM entries
    (if (and maxnum (= i maxnum))
	(nreverse res)
      ;; otherwise, return result plus enough leftover entries to make
      ;; up MAXNUM (only one of list1 or list2 will be non-nil)
      (let (tmp)
	(or (null maxnum)
	    (and (setq tmp (nthcdr (- maxnum i 1) list1))
		 (setcdr tmp nil))
	    (and (setq tmp (nthcdr (- maxnum i 1) list2))
		 (setcdr tmp nil)))
	(nconc (nreverse res) list1 list2)))
    ))


;; (defun dictree--merge-sort (list sortfun &optional combfun)
;;   ;; Destructively sort LIST according to SORTFUN, combining
;;   ;; identical elements using COMBFUN if supplied.
;;   (dictree--do-merge-sort list (/ (length list) 2) sortfun combfun))


;; (defun dictree--do-merge-sort (list1 len sortfun combfun)
;;   ;; Merge sort LIST according to SORTFUN, combining identical
;;   ;; elements using COMBFUN.
;;   (let* ((p (nthcdr (1- len) list1))
;; 	 (list2 (cdr p)))
;;     (setcdr p nil)
;;     (dictree--merge
;;      (dictree--do-merge-sort list1 (/ len 2) sortfun combfun)
;;      (dictree--do-merge-sort list2 (/ len 2) sortfun combfun)
;;      sortfun)))




;;; ================================================================
;;;    The (mostly) public functions which operate on dictionaries

;;;###autoload
(defun make-dictree
  (&optional
   name filename autosave unlisted
   comparison-function insert-function rank-function
   cache-policy cache-threshold cache-update-policy
   key-savefun key-loadfun
   data-savefun data-loadfun
   plist-savefun plist-loadfun
   trie-type)
  "Create an empty dictionary and return it.

If NAME is supplied, the dictionary is stored in the variable
NAME, and saved to a file named \"NAME.el(c)\".

FILENAME sets the default file name to use when saving the
dictionary. If the AUTOSAVE flag is non-nil, then the dictionary
will automatically be saved to this file when it is unloaded or
when exiting Emacs. If FIlENAME is a directory, then it will be
saved to a file called \"NAME.el(c)\" under that directory.

If UNLISTED is non-nil, the dictionary will not be recorded in
the list of loaded dictionaries. Note that this disables
autosaving.

COMPARISON-FUNCTION sets the function used to compare elements of
the keys. It should take two arguments, A and B, both of the type
contained by the sequences used as keys \(e.g. if the keys will
be strings, the function will be passed two characters\). It
should return t if the first is strictly \"less than\" the
second. Defaults to `<'.

INSERT-FUNCTION sets the function used to insert data into the
dictionary. It should take two arguments: the new data, and the
data already in the dictionary, and should return the data to
insert. Defaults to replacing any existing data with the new
data.

RANK-FUNCTION sets the function used to rank the results of
`dictree-complete'. It should take two arguments, each a cons
whose car is a dictree key (a sequence) and whose cdr is the data
associated with that key. It should return non-nil if the first
argument is \"better\" than the second, nil otherwise. It
defaults to \"lexicographic\" comparison of the keys, ignoring
the data \(which is not very useful, since an unranked
`dictree-complete' query already does this much more
efficiently\).

CACHE-POLICY should be a symbol (`time', `length',
`time-and-length' or `time-or-length'), which determines which
query operations are cached. The `time' setting caches queries
that take longer (in seconds) than the CACHE-THRESHOLD value.

The `length' setting caches query operations based on the length
of the string involved the query. For this setting, CACHE-POLICY
should be a plist with properties :long and :short. Lookups,
fuzzy matches, and regexp queries that do not end in \".*\" will
be cached if the string is longer than the :long value (since
long strings are likely to be the slower ones in these
cases). Completions, fuzzy completions, and regexp queries that
end in \".*\" will be cached if the string or regexp is shorter
than the :short value \(since short strings are likely to be the
slower ones for those cases\).

The `time-and-length' setting only caches results if both
conditions are satisfied simultaneously, whereas the
`time-or-length' setting caches results if either condition is
satisfied. For these settings, CACHE-THRESHOLD must be a plist
with properties :time, :long and :short, specifying the
corresponding cache thresholds.

CACHE-THRESHOLD defaults to nil. The values nil and t are
special. If CACHE-THRESHOLD is set to nil, no caching is done. If
it is t, everything is cached for that type of query \(similar
behaviour can be obtained by setting the a `time' CACHE-THRESHOLD
of 0, but it is better to use t\).

CACHE-UPDATE-POLICY should be a symbol (`synchronize' or
`delete'), which determines how the caches are updated when data
is inserted or deleted. The former updates tainted cache entries,
which makes queries faster but insertion and deletion slower,
whereas the latter deletes any tainted cache entries, which makes
queries slower but insertion and deletion faster.

KEY-SAVEFUN, DATA-SAVEFUN and PLIST-SAVEFUN are functions used to
convert keys, data and property lists into lisp objects that have
a valid read syntax, for writing to file. DATA-SAVEFUN and
PLIST-SAVEFUN are used when saving the dictionary (see
`dictree-save' and `dictree-write'), and all three functions are
used when dumping the contents of the dictionary \(see
`dictree-dump-to-buffer' and `dictree-dump-to-file'\).
KEY-SAVEFUN, DATA-SAVEFUN and PLIST-SAVEFUN should each accept
one argument: a key, data or property list from DICT,
respectively. They should return a lisp object which has a valid
read syntax. When defining these functions, be careful not to
accidentally modify the lisp object in the dictionary; usually,
you will need to make a copy before converting it.

KEY-LOADFUN, DATA-LOADFUN and PLIST-LOADFUN are used to convert
keys, data and property lists back again when loading a
dictionary (only DATA-LOADFUN and PLIST-LOADFUN, see
`dictree-save' and `dictree-write') or populating it from a
file (all three, see `dictree-populate-from-file'). They should
accept one argument: a lisp object of the type produced by the
corresponding SAVEFUN, and return a lisp object to use in the
loaded dictionary.

TRIE-TYPE sets the type of trie to use as the underlying data
structure. See `trie-create' for details."

  ;; derive NAME from FILENAME or vice versa
  (when (and (not name) filename
	     (not (string= (setq name (file-name-nondirectory filename))
			   "")))
    (setq name (intern (file-name-sans-extension name))))
  (when (and name filename
	     (string= (file-name-directory filename) filename))
    (setq filename (concat filename (symbol-name name))))
  ;; sadly, passing null values overrides the defaults in the defstruct
  ;; dictree--create, so we have to explicitly set the defaults again here
  (unless comparison-function (setq comparison-function #'<))
  (unless insert-function (setq insert-function (lambda (a _b) a)))
  (unless rank-function (setq rank-function (lambda (a b) (> (cdr a) (cdr b)))))
  (unless cache-policy (setq cache-policy 'time))
  (unless cache-update-policy (setq cache-update-policy 'synchronize))
  (unless trie-type (setq trie-type 'avl))

  (let ((dict
	 (dictree--create
	  (when name (symbol-name name)) filename autosave unlisted
	  comparison-function insert-function rank-function
	  cache-policy cache-threshold cache-update-policy
	  key-savefun key-loadfun
	  data-savefun data-loadfun
	  plist-savefun plist-loadfun
	  trie-type)))
    ;; store dictionary in variable NAME
    (when name (set name dict))
    ;; add it to loaded dictionary list, unless it's unlisted
    (unless (or (null name) unlisted)
      (push dict dictree-loaded-list))
    dict))


;;;###autoload
(defalias 'dictree-create #'make-dictree)


;;;###autoload
(cl-defun make-dictree-custom
    (&optional
     name filename autosave unlisted
     &key
     comparison-function insert-function rank-function
     cache-policy cache-threshold cache-update-policy
     key-savefun key-loadfun
     data-savefun data-loadfun
     plist-savefun plist-loadfun
     createfun insertfun deletefun lookupfun mapfun emptyfun
     stack-createfun stack-popfun stack-emptyfun
     transform-for-print transform-from-read)
  "Create an empty dictionary and return it.

The NAME through PLIST-LOADFUN arguments are as for
`dictree-create' (which see).

The remaining arguments control the type of trie to use as the
underlying data structure. See `trie-create' for details."

  ;; derive NAME from FILENAME or vice versa
  (when (and (not name) filename
	     (not (string= (setq name (file-name-nondirectory filename))
			   "")))
    (setq name (intern (file-name-sans-extension name))))
  (when (and name filename
	     (string= (file-name-directory filename) filename))
    (setq filename (concat filename (symbol-name name))))
  ;; sadly, passing null values overrides the defaults in the defstruct
  ;; dictree--create, so we have to explicitly set the defaults again here
  (or comparison-function (setq comparison-function #'<))
  (or insert-function (setq insert-function (lambda (a _b) a)))
  (or rank-function (setq rank-function (lambda (a b) (< (cdr a) (cdr b)))))
  (or cache-policy (setq cache-policy 'time))
  (or cache-update-policy (setq cache-update-policy 'synchronize))

  (let ((dict
	 (dictree--create-custom
	  (when name (symbol-name name)) filename autosave unlisted
	  comparison-function insert-function rank-function
	  cache-policy cache-threshold cache-update-policy
	  key-savefun key-loadfun
	  data-savefun data-loadfun
	  plist-savefun plist-loadfun
	  :createfun createfun
	  :insertfun insertfun
	  :deletefun deletefun
	  :lookupfun lookupfun
	  :mapfun mapfun
	  :emptyfun emptyfun
	  :stack-createfun stack-createfun
	  :stack-popfun stack-popfun
	  :stack-emptyfun stack-emptyfun
	  :transform-for-print transform-for-print
	  :transform-from-read transform-from-read)))
    ;; store dictionary in variable NAME
    (when name (set name dict))
    ;; add it to loaded dictionary list, unless it's unlisted
    (unless (or (null name) unlisted)
      (push dict dictree-loaded-list))
    dict))


;;;###autoload
(defalias 'dictree-create-custom #'make-dictree-custom)


;;;###autoload
(defun make-dictree-meta-dict
  (dictionary-list
   &optional
   name filename autosave unlisted
   combine-function
   cache-policy cache-threshold cache-update-policy)
  "Create a meta-dictionary based on the list of dictionaries
in DICTIONARY-LIST.

COMBINE-FUNCTION is used to combine data from different
dictionaries. It is passed two pieces of data, each an
association of the same key, but in different dictionaries. It
should return a combined datum.

The other arguments are as for `dictree-create'. Note that
caching is only possible if NAME is supplied, otherwise the
CACHE-THRESHOLD argument is ignored and caching is disabled."

  ;; derive NAME from FILENAME or vice versa
  (when (and (not name) filename
	     (not (string= (setq name (file-name-nondirectory filename))
			   "")))
    (setq name (intern (file-name-sans-extension name))))
  (when (and name filename
	     (string= (file-name-directory filename) filename))
    (setq filename (concat filename (symbol-name name))))
  ;; sadly, passing null values overrides the defaults in the defstruct
  ;; `dictree--create-meta-dict', so we have to explicitly set the defaults
  ;; again here
  (unless combine-function (setq combine-function #'+))
  (unless cache-policy (setq cache-policy 'time))
  (unless cache-update-policy (setq cache-update-policy 'synchronize))

  (let ((dict
	 (dictree--meta-dict-create
	  dictionary-list combine-function
	  (when name (symbol-name name)) filename autosave unlisted
	  cache-policy (when name cache-threshold) cache-update-policy
	 )))
    ;; store dictionary in variable NAME
    (when name (set name dict))
    ;; add it to loaded dictionary list, unless it's unlisted
    (unless (or (null name) unlisted)
      (push dict dictree-loaded-list))
    ;; update meta-dict-list cells of constituent dictionaries
    (unless (or (null name) (not cache-threshold))
      (mapc
       (lambda (dic)
	 (if (symbolp dic) (setq dic (symbol-value dic)))
	 (setf (dictree--meta-dict-list dic)
	       (cons dict (dictree--meta-dict-list dic))))
       dictionary-list))
    dict))

(defalias 'dictree-create-meta-dict #'make-dictree-meta-dict)


;;;###autoload
(defun dictree-p (obj)
  "Return t if OBJ is a dictionary tree, nil otherwise."
  (or (dictree--p obj) (dictree--meta-dict-p obj)))


(defalias 'dictree-meta-dict-p #'dictree--meta-dict-p
  "Return t if argument is a meta-dictionary, nil otherwise.")

(defun dictree-empty-p (dict)
  "Return t if the dictionary DICT is empty, nil otherwise."
  (if (dictree--meta-dict-p dict)
      (catch 'nonempty
	(mapc (lambda (dic)
		(if (not (dictree-empty-p dic)) (throw 'nonempty t)))
	      (dictree--meta-dict-dictlist dict)))
    (trie-empty (dictree--trie dict))))

(defsubst dictree-autosave (dict)
  "Return dictionary's autosave flag."
  (declare (gv-setter
            (lambda (val)
              `(setf (if (dictree--meta-dict-p ,dict)
                         (dictree--meta-dict-autosave ,dict)
                       (dictree--autosave ,dict))
                     ,val))))
  (if (dictree--meta-dict-p dict)
      (dictree--meta-dict-autosave dict)
    (dictree--autosave dict)))

(defsubst dictree-modified (dict)
  "Return dictionary's modified flag."
  (declare (gv-setter
            (lambda (val)
              `(setf (if (dictree--meta-dict-p ,dict)
                         (dictree--meta-dict-modified ,dict)
                       (dictree--modified ,dict))
                     ,val))))
  (if (dictree--meta-dict-p dict)
      (dictree--meta-dict-modified dict)
    (dictree--modified dict)))

(defsubst dictree-name (dict)
  "Return dictionary DICT's name."
  (declare (gv-setter
            (lambda (name)
              `(setf (if (dictree--meta-dict-p ,dict)
                         (dictree--meta-dict-name ,dict)
                       (dictree--name ,dict))
                     ,name))))
  (if (dictree--meta-dict-p dict)
      (dictree--meta-dict-name dict)
    (dictree--name dict)))

(defsubst dictree-filename (dict)
  "Return dictionary DICT's associated file name."
  (declare (gv-setter
            (lambda (filename)
              `(setf (if (dictree--meta-dict-p ,dict)
                         (dictree--meta-dict-filename ,dict)
                       (dictree--filename ,dict))
                     ,filename))))
  (if (dictree--meta-dict-p dict)
      (dictree--meta-dict-filename dict)
    (dictree--filename dict)))

(defun dictree-comparison-function (dict)
  "Return dictionary DICT's comparison function."
  (if (dictree--meta-dict-p dict)
      (dictree-comparison-function
       (car (dictree--meta-dict-dictlist dict)))
    (dictree--comparison-function dict)))

(defalias 'dictree-insert-function #'dictree--insert-function
  "Return the insertion function for dictionary DICT.")

(defun dictree-rank-function (dict)
  "Return the rank function for dictionary DICT"
  (if (dictree--meta-dict-p dict)
      (dictree-rank-function (car (dictree--meta-dict-dictlist dict)))
    (dictree--rank-function dict)))

(defalias 'dictree-meta-dict-combine-function
  #'dictree--meta-dict-combine-function
  "Return the combine function for meta-dictionary DICT.")

(defalias 'dictree-meta-dict-dictlist
  #'dictree--meta-dict-dictlist
  "Return the list of constituent dictionaries
for meta-dictionary DICT.")

(defsubst dictree-cache-policy (dict)
  "Return the cache policy for dictionary DICT."
  (if (dictree--meta-dict-p dict)
      (dictree--meta-dict-cache-policy dict)
    (dictree--cache-policy dict)))

(defsubst dictree-cache-update-policy (dict)
  "Return the cache update policy for dictionary DICT."
  (if (dictree--meta-dict-p dict)
      (dictree--meta-dict-cache-update-policy dict)
    (dictree--cache-update-policy dict)))

(defsubst dictree-cache-threshold (dict)
  "Return the cache threshold for dictionary DICT."
  (declare (gv-setter
            (lambda (param)
              `(setf (if (dictree--meta-dict-p ,dict)
	                 (dictree--meta-dict-cache-threshold ,dict)
	               (dictree--cache-threshold ,dict))
	             ,param))))
  (if (dictree--meta-dict-p dict)
      (dictree--meta-dict-cache-threshold dict)
    (dictree--cache-threshold dict)))

(defun dictree-lookup-cache (dict)
  ;; Return the lookup cache for dictionary DICT.
  (declare (gv-setter
            (lambda (param)
              `(setf (if (dictree--meta-dict-p ,dict)
	                 (dictree--meta-dict-lookup-cache ,dict)
	               (dictree--lookup-cache ,dict))
	             ,param))))
  (if (dictree--meta-dict-p dict)
      (dictree--meta-dict-lookup-cache dict)
    (dictree--lookup-cache dict)))

(defun dictree-create-lookup-cache (dict)
  ;; Create DICT's lookup cache if it doesn't already exist.
  (unless (dictree-lookup-cache dict)
    (setf (dictree-lookup-cache dict)
	  (make-hash-table :test 'equal))))


(defun dictree-complete-cache (dict)
  ;; Return the completion cache for dictionary DICT.
  (declare (gv-setter
            (lambda (param)
              `(setf (if (dictree--meta-dict-p ,dict)
	                 (dictree--meta-dict-complete-cache ,dict)
	               (dictree--complete-cache ,dict))
	             ,param))))
  (if (dictree--meta-dict-p dict)
      (dictree--meta-dict-complete-cache dict)
    (dictree--complete-cache dict)))

(defun dictree-create-complete-cache (dict)
  ;; Create DICT's completion cache if it doesn't already exist.
  (unless (dictree-complete-cache dict)
    (setf (dictree-complete-cache dict)
	  (make-hash-table :test 'equal))))


(defun dictree-regexp-cache (dict)
  ;; Return the regexp cache for dictionary DICT.
  (declare (gv-setter
            (lambda (param)
              `(setf (if (dictree--meta-dict-p ,dict)
	                 (dictree--meta-dict-regexp-cache ,dict)
	               (dictree--regexp-cache ,dict))
	             ,param))))
  (if (dictree--meta-dict-p dict)
      (dictree--meta-dict-regexp-cache dict)
    (dictree--regexp-cache dict)))

(defun dictree-create-regexp-cache (dict)
  ;; Create DICT's regexp cache if it doesn't already exist.
  (unless (dictree-regexp-cache dict)
    (setf (dictree-regexp-cache dict)
	  (make-hash-table :test 'equal))))


(defun dictree-fuzzy-match-cache (dict)
  ;; Return the fuzzy match cache for dictionary DICT.
  (declare (gv-setter
            (lambda (param)
             `(setf (if (dictree--meta-dict-p ,dict)
	                (dictree--meta-dict-fuzzy-match-cache ,dict)
	              (dictree--fuzzy-match-cache ,dict))
	            ,param))))
  (if (dictree--meta-dict-p dict)
      (dictree--meta-dict-fuzzy-match-cache dict)
    (dictree--fuzzy-match-cache dict)))

(defun dictree-create-fuzzy-match-cache (dict)
  ;; Create DICT's fuzzy match cache if it doesn't already exist.
  (unless (dictree-fuzzy-match-cache dict)
    (setf (dictree-fuzzy-match-cache dict)
	  (make-hash-table :test 'equal))))


(defun dictree-fuzzy-complete-cache (dict)
  ;; Return the regexp cache for dictionary DICT.
  (declare (gv-setter
            (lambda (param)
              `(setf (if (dictree--meta-dict-p ,dict)
	                 (dictree--meta-dict-fuzzy-complete-cache ,dict)
	               (dictree--fuzzy-complete-cache ,dict))
	             ,param))))
  (if (dictree--meta-dict-p dict)
      (dictree--meta-dict-fuzzy-complete-cache dict)
    (dictree--fuzzy-complete-cache dict)))

(defun dictree-create-fuzzy-complete-cache (dict)
  ;; Create DICT's fuzzy completion cache if it doesn't already exist.
  (unless (dictree-fuzzy-complete-cache dict)
    (setf (dictree-fuzzy-complete-cache dict)
	  (make-hash-table :test 'equal))))





;; ----------------------------------------------------------------
;;                  Inserting and deleting data

(defun dictree-insert (dict key &optional data insert-function)
  "Insert KEY and DATA into dictionary DICT.
If KEY does not already exist, this creates it. How the data is
inserted depends on the dictionary's insertion function \(see
`dictree-create'\).

The optional INSERT-FUNCTION overrides the dictionary's own
insertion function. If KEY already exists in DICT,
INSERT-FUNCTION is called with two arguments: the data DATA, and
the data associated with KEY in the dictionary. Its return value
becomes the new association for KEY."

  ;; if dictionary is a meta-dictionary, insert key into all the
  ;; dictionaries it's based on
  (if (dictree--meta-dict-p dict)
      (mapc (lambda (dic)
	      (dictree-insert dic key data insert-function))
	    (dictree--meta-dict-dictlist dict))

    ;; otherwise...
    (let ((insfun (or (and insert-function
			   (dictree--wrap-insfun insert-function))
		      (dictree--wrap-insfun (dictree--insert-function dict))))
	  olddata newdata)
      ;; set the dictionary's modified flag
      (setf (dictree-modified dict) t)
      ;; insert key in dictionary's trie
      (setq newdata
	    (trie-insert
	     (dictree--trie dict) key (dictree--cell-create data nil)
	     (lambda (nd od)
	       (setq olddata od)
	       (funcall insfun nd od))))
      ;; update dictionary's caches
      (dictree--update-cache dict key olddata newdata)
      ;; update cache's of any meta-dictionaries based on dict
      (mapc (lambda (dic) (dictree--update-cache dic key olddata newdata))
	    (dictree--meta-dict-list dict))

      ;; return the new data
      (dictree--cell-data newdata))))



(defun dictree-delete (dict key &optional test)
  "Delete KEY from DICT.
Returns non-nil if KEY was deleted, nil if KEY was not in DICT.

If TEST is supplied, it should be a function that accepts three
arguments: the key being deleted, its associated data, and its
associated property list. The key will then only be deleted if
TEST returns non-nil."

  (let ((dictree--delete-test test)
	olddata deleted del)
    (cond
     ;; if DICT is a meta-dictionary, delete KEY from all dictionaries
     ;; it's based on
     ((dictree--meta-dict-p dict)
      (dolist (dic (dictree--meta-dict-dictlist dict))
	(when (setq del (dictree-delete dic key))
	  (setq deleted (cons del deleted))))
      (setf (dictree-modified dict) (and deleted t))
      (setq deleted (nreverse deleted)))

     ;; otherwise...
     (t
      (setq deleted
	    (trie-delete (dictree--trie dict) key
			 (lambda (k cell)
			   (setq olddata (dictree--cell-data cell))
			   (if dictree--delete-test
			       (funcall dictree--delete-test
					k (dictree--cell-data cell)
					(dictree--cell-plist cell))
			     t))))
      ;; if key was deleted, have to update the caches
      (when deleted
	(dictree--update-cache dict key olddata nil t)
	(setf (dictree-modified dict) t)
	;; update cache's of any meta-dictionaries based on DICT
	(mapc (lambda (dic)
		(dictree--update-cache dic key olddata nil t))
	      (dictree--meta-dict-list dict)))))

    ;; return deleted key/data pair
    (when deleted
      (cons (car deleted) (dictree--cell-data (cdr deleted))))))




;; ----------------------------------------------------------------
;;                     Cache updating

(defun dictree--prefix-p (prefix str)
  "Return t if PREFIX is a prefix of STR, nil otherwise.

PREFIX and STR can be any sequence type (string, vector, or
list), but they must both be the same type. PREFIX can also be a
list of sequences, in which case it returns t if any element of
PREFIX is a prefix of STR."
  ;; wrap prefix in a list if necessary
  ;; FIXME: the test for a list of prefixes, below, will fail if the
  ;;        PREFIX sequence is a list, and the elements of PREFIX are
  ;;        themselves lists (there might be no easy way to fully fix
  ;;        this...)
  (when (or (atom prefix)
	    (and (listp prefix) (not (sequencep (car prefix)))))
    (setq prefix (list prefix)))
  (let (len)
    (catch 'is-prefix
      (dolist (pfx prefix)
	(setq len (length pfx))
	(when (and (<= len (length str))
		   (equal pfx (dictree--subseq str 0 len)))
	  (throw 'is-prefix t))))))

(defun dictree--filter-prefix (prefix pfxfilter)
  "Return non-nil if all prefixes of PREFIX pass PFXFILTER.
Otherwise, return nil."
  (catch 'failed
    (dotimes (i (length prefix))
      (unless (funcall pfxfilter (cl-subseq prefix 0 i))
	(throw 'failed nil)))
    t))


(defun dictree--above-cache-threshold-p
  (time length policy threshold &optional cache-long-keys)
  ;; Return t if query taking TIME seconds for a key of length LENGTH
  ;; should be cached according to the cache POLICY and
  ;; THRESHOLD. Otherwise, return nil. Optional argument CACHE-LONG-KEYS
  ;; means that keys of length longer than THRESHOLD are to be
  ;; cached. Default is keys of length shorter than THRESHOLD.
  (and threshold
       (or (eq threshold t)
	   (and (eq policy 'time) (>= time threshold))
	   (and (eq policy 'length)
		(if cache-long-keys
		    (>= length (plist-get threshold :long))
		  (<= length (plist-get threshold :short))))
	   (and (eq policy 'time-and-length)
		(>= time (plist-get threshold :time))
		(if cache-long-keys
		    (>= length (plist-get threshold :long))
		  (<= length (plist-get threshold :short))))
	   (and (eq policy 'time-or-length)
		(or (>= time (plist-get threshold :time))
		    (if cache-long-keys
			(>= length (plist-get threshold :long))
		      (<= length (plist-get threshold :short))))))))



(defun dictree--update-cache (dict key olddata newdata &optional deleted)
  ;; Synchronise dictionary DICT's caches, given that the data associated with
  ;; KEY has been updated from OLDDATA to NEWDATA, or KEY has been deleted if
  ;; DELETED is non-nil (NEWDATA is ignored in that case)."
  (when (dictree-cache-threshold dict)

    ;; synchronise lookup cache if dict is a meta-dictionary, since it doesn't
    ;; happen automatically for a meta-dict
    (when (dictree--meta-dict-p dict)
      (cond
       ;; updating dirty cache entries
       ((eq (dictree-cache-update-policy dict) 'synchronize)
	(when (and (dictree--lookup-cache dict)
		   (gethash key (dictree--lookup-cache dict)))
	  (if deleted
	      (remhash key (dictree--lookup-cache dict))
	    (puthash key newdata (dictree--lookup-cache dict)))))
       ;; deleting dirty cache entries
       (t (remhash key (dictree--lookup-cache dict)))))

    ;; synchronize query caches if something's actually changed
    (when (or deleted (not (equal olddata newdata)))
      (dolist (cachefuns
	       `((dictree-complete-cache
		  dictree--synchronize-completion-cache
		  dictree--prefix-p)
		 (dictree-regexp-cache
		  dictree--synchronize-regexp-cache
		  ,(lambda (regexp key)
		     (tNFA-regexp-match
		      regexp key :test (trie--construct-equality-function
					(dictree--comparison-function dict)))))
		 (dictree-fuzzy-match-cache
		  dictree--synchronize-fuzzy-match-cache
		  ,(lambda (string dist key)
		     (if (consp dist)
			 (<= (trie-lewenstein-distance (substring string (car dist)) key)
			     (cdr dist))
		       (<= (trie-lewenstein-distance string key) dist))))
		 (dictree-fuzzy-complete-cache
		  dictree--synchronize-fuzzy-complete-cache
		  ,(lambda (prefix dist key)
		     (if (consp dist)
			 (<= (trie-lewenstein-distance (substring prefix (car dist)) key)
			     (cdr dist))
		       (<= (trie-lewenstein-distance prefix key) dist))))
		 ))
	(when (funcall (nth 0 cachefuns) dict)
	  (maphash
	   (lambda (cache-key cache-entry)
	     (pcase-let ((`(,args ,rank-function ,reverse ,filter ,pfxfilter)
		          cache-key))
	       (when (apply (nth 2 cachefuns) (append args (list key)))
		 (cond
		  ;; updating dirty cache entries
		  ((eq (dictree-cache-update-policy dict) 'synchronize)
		   (funcall (nth 1 cachefuns)
			    dict key olddata newdata deleted cache-entry args
			    :reverse reverse :rank-function rank-function
			    :filter filter :pfxfilter pfxfilter))
		  ;; deleting dirty cache entries
		  (t (remhash (list args rank-function reverse filter pfxfilter)
			      (funcall (nth 0 cachefuns) dict)))))))
	   (funcall (nth 0 cachefuns) dict)))
	))))



(cl-defun dictree--synchronize-completion-cache
    (dict key olddata newdata deleted cache-entry args
	  &key reverse rank-function filter pfxfilter)
  ;; Synchronize DICT's completion CACHE-ENTRY for a query with arguments
  ;; ARGS, RANK-FUNCTION, REVERSE, FILTER and PFXFILTER, where KEY's data was
  ;; either updated from OLDDATA to NEWDATA or DELETED,

  (let* ((completions (dictree--cache-results cache-entry))
	 (maxnum (dictree--cache-maxnum cache-entry))
	 (cmpl (assoc key completions))
	 (rankfun (cond ((eq rank-function t)
			 (dictree--wrap-rankfun
			  (dictree--rank-function dict)))
			(rank-function
			 (dictree--wrap-rankfun rank-function)))))
    ;; for meta-dict, get old data from cache instead of OLDDATA
    (when (dictree--meta-dict-p dict) (setq olddata (cdr cmpl)))
    ;; skip cache update if key/data pair doesn't pass FILTER
    (when (and (or (null filter)
		   (funcall filter key olddata)
		   (funcall filter key newdata))
	       (or (null pfxfilter)
		   (dictree--filter-prefix (cl-subseq key (length (car args)))
					   pfxfilter)))
      ;; if key was...
      (cond

       ;; deleted and in cached result: remove cache entry and re-run the
       ;; same completion to update the cache
       ((and deleted cmpl)
	(remhash (list args rank-function reverse filter pfxfilter)
		 (dictree-complete-cache dict))
	(dictree-complete dict (car args)
			  :maxnum maxnum :reverse reverse
			  :rank-function rank-function
			  :filter filter :pfxfilter pfxfilter))

       ;; modified and not in cached result: merge it into the completion
       ;; list, retaining only the first maxnum
       ((and (not deleted) (not cmpl))
	(when (or (null filter) (funcall filter key newdata))
	  (setf (dictree--cache-results cache-entry)
		(dictree--merge
		 (list (cons key newdata)) completions
		 (or rankfun (dictree--construct-sortfun dict))
		 maxnum))))

       ;; modified and in the cached result
       ((and (not deleted) cmpl)
	;; update the associated data if dict is a meta-dictionary (this
	;; happens automatically for a normal dict)
	(when (dictree--meta-dict-p dict) (setcdr cmpl newdata))
	;; if updated entry gets filtered, or gets sorted at end of list,
	;; re-run the same query to update the cache
	(when (or (and filter (not (funcall filter key newdata)))
		  (and rankfun
		       (setf (dictree--cache-results cache-entry)
			     (sort completions rankfun))
		       (equal key (car (last (dictree--cache-results
					      cache-entry))))))
	  (remhash (list args rank-function reverse filter pfxfilter)
		   (dictree-complete-cache dict))
	  (dictree-complete dict (car args)
			    :maxnum maxnum :reverse reverse
			    :rank-function rank-function
			    :filter filter :pfxfilter pfxfilter)))

       ;; deleted and not in cached result: requires no action
       ))))


(cl-defun dictree--synchronize-regexp-cache
    (dict key olddata newdata deleted cache-entry args
	  &key reverse rank-function filter pfxfilter)
  ;; Synchronize DICT's regexp CACHE-ENTRY for a query with arguments ARGS
  ;; RANK-FUNCTION, REVERSE, FILTER and PFXFILTER, where KEY's data was either
  ;; updated from OLDDATA to NEWDATA or DELETED,

  (let* ((completions (dictree--cache-results cache-entry))
	 (maxnum (dictree--cache-maxnum cache-entry))
	 group-data
	 (cmpl (catch 'found
		 (dolist (c completions)
		   (if (and (listp (car c))
			    (or (stringp (caar c))
				(vectorp (caar c))
				(listp (caar c))))
		       (when (equal key (caar c)) (throw 'found c))
		     (when (equal key (car c)) (throw 'found c))))))
	 (rankfun (cond ((eq rank-function t)
			 (dictree--wrap-regexp-rankfun
			  (dictree-rank-function dict)))
			(rank-function
			 (dictree--wrap-regexp-rankfun rank-function)))))
    ;; for meta-dict, get old data from cache instead of OLDDATA
    (when (dictree--meta-dict-p dict) (setq olddata (cdr cmpl)))
    ;; skip cache update if key/data pair doesn't pass FILTER
    (when (and (or (null filter)
		   (funcall filter key olddata)
		   (funcall filter key newdata))
	       (or (null pfxfilter)
		   (dictree--filter-prefix key pfxfilter)))
      ;; if key was...
      (cond

       ;; deleted and in cached result: remove cache entry and re-run the
       ;; same completion to update the cache
       ((and deleted cmpl)
	(remhash (list args rank-function reverse filter pfxfilter)
		 (dictree-regexp-cache dict))
	(dictree-regexp-search dict (car args)
			       :maxnum maxnum :reverse reverse
			       :rank-function rank-function
			       :filter filter :pfxfilter pfxfilter))

       ;; modified and not in cached result: merge it into the completion
       ;; list, retaining only the first maxnum
       ((and (not deleted) (not cmpl))
	(when (or (null filter) (funcall filter key newdata))
	  (save-match-data
	    (set-match-data nil)
	    (tNFA-regexp-match (car args) key
			       :test (trie--construct-equality-function
				      (dictree--comparison-function dict)))
	    (when (setq group-data (nthcdr 2 (match-data)))
	      (setq key (cons key group-data))))
	  (setf (dictree--cache-results cache-entry)
		(dictree--merge
		 (list (cons key newdata)) completions
		 (or rankfun (dictree--construct-sortfun dict #'caar))
		 maxnum))))

       ;; modified and in the cached result
       ((and (not deleted) cmpl)
	;; update the associated data if dict is a meta-dictionary (this
	;; happens automatically for a normal dict)
	(when (dictree--meta-dict-p dict) (setcdr cmpl newdata))
	;; if updated entry gets filtered, or gets sorted at end of list,
	;; re-run the same query to update the cache
	(when (or (and filter (not (funcall filter key newdata)))
		  (and rankfun
		       (setf (dictree--cache-results cache-entry)
			     (sort completions rankfun))
		       (equal key (car (last (dictree--cache-results
					      cache-entry))))))
	  (remhash (list args rank-function reverse filter pfxfilter)
		   (dictree-regexp-cache dict))
	  (dictree-regexp-search dict (car args)
				 :maxnum maxnum :reverse reverse
				 :rank-function rank-function
				 :filter filter :pfxfilter pfxfilter)))

       ;; deleted and not in cached result: requires no action
       ))))


(cl-defun dictree--synchronize-fuzzy-match-cache
    (dict key olddata newdata deleted cache-entry args
	  &key reverse rank-function filter pfxfilter)
  ;; Synchronize DICT's fuzzy match CACHE-ENTRY for a query with arguments
  ;; ARGS, RANK-FUNCTION, REVERSE, FILTER and PFXFILTER, where KEY's data was
  ;; either updated from OLDDATA to NEWDATA or DELETED,

  (let* ((completions (dictree--cache-results cache-entry))
	 (maxnum (dictree--cache-maxnum cache-entry))
	 (cmpl (catch 'found
		 (dolist (c completions)
		   (when (equal key (caar c)) (throw 'found c)))))
	 (distance (trie-lewenstein-distance (car args) key))
	 (rankfun (dictree--construct-fuzzy-match-rankfun
		   rank-function dict)))
    ;; for meta-dict, get old data from cache instead of OLDDATA
    (when (dictree--meta-dict-p dict) (setq olddata (cdr cmpl)))
    ;; skip cache update if key/data pair doesn't pass FILTER
    (when (and (or (null filter)
		   (funcall filter key olddata)
		   (funcall filter key newdata))
	       (or (null pfxfilter)
		   (dictree--filter-prefix key pfxfilter)))
      ;; if key was...
      (cond

       ;; deleted and in cached result: remove cache entry and re-run the
       ;; same completion to update the cache
       ((and deleted cmpl)
	(remhash (list args rank-function reverse filter pfxfilter)
		 (dictree-fuzzy-match-cache dict))
	(dictree-fuzzy-match dict (car args) (nth 1 args)
			     :maxnum maxnum :reverse reverse
			     :rank-function rank-function
			     :filter filter :pfxfilter pfxfilter))

       ;; modified and not in cached result: merge it into the completion
       ;; list, retaining only the first maxnum
       ((and (not deleted) (not cmpl))
	(when (or (null filter) (funcall filter key newdata))
	  (setf (dictree--cache-results cache-entry)
		(dictree--merge
		 (list (cons (cons key distance) newdata)) completions
		 (or rankfun (dictree--construct-sortfun dict #'caar))
		 maxnum))))

       ;; modified and in the cached result
       ((and (not deleted) cmpl)
	;; update the associated data if dict is a meta-dictionary (this
	;; happens automatically for a normal dict)
	(when (dictree--meta-dict-p dict) (setcdr cmpl newdata))
	;; if updated entry gets filtered, or gets sorted at end of list,
	;; re-run the same query to update the cache
	(when (or (and filter (not (funcall filter key newdata)))
		  (and rankfun
		       (setf (dictree--cache-results cache-entry)
			     (sort completions rankfun))
		       (equal key (car (last (dictree--cache-results
					      cache-entry))))))
	  (remhash (list args rank-function reverse filter pfxfilter)
		   (dictree-fuzzy-match-cache dict))
	  (dictree-fuzzy-match dict (car args) (nth 1 args)
			       :maxnum maxnum :reverse reverse
			       :rank-function rank-function
			       :filter filter :pfxfilter pfxfilter)))

       ;; deleted and not in cached result: requires no action
       ))))


(cl-defun dictree--synchronize-fuzzy-complete-cache
    (dict key olddata newdata deleted cache-entry args
	  &key rank-function reverse filter pfxfilter)
  ;; Synchronize DICT's fuzzy completion CACHE-ENTRY for a query with
  ;; arguments ARG, AUXARGS, RANK-FUNCTION, REVERSE and FILTER, where KEY's
  ;; data was either updated from OLDDATA to NEWDATA or DELETED,

  (let* ((completions (dictree--cache-results cache-entry))
	 (maxnum (dictree--cache-maxnum cache-entry))
	 (cmpl (catch 'found
		 (dolist (c completions)
		   (when (equal key (caar c)) (throw 'found c)))))
	 (distance (trie-lewenstein-prefix-distance (car args) key))
	 (pfxlen (cdr distance))
	 (distance (car distance))
	 (rankfun (dictree--construct-fuzzy-complete-rankfun
		   rank-function dict)))
    ;; for meta-dict, get old data from cache instead of OLDDATA
    (when (dictree--meta-dict-p dict) (setq olddata (cdr cmpl)))
    ;; skip cache update if key/data pair doesn't pass FILTER
    (when (and (or (null filter)
		   (funcall filter key olddata)
		   (funcall filter key newdata))
	       (or (null pfxfilter)
		   (dictree--filter-prefix key pfxfilter)))
      ;; if key was...
      (cond

       ;; deleted and in cached result: remove cache entry and re-run the
       ;; same completion to update the cache
       ((and deleted cmpl)
	(remhash (list args rank-function reverse filter pfxfilter)
		 (dictree-fuzzy-complete-cache dict))
	(dictree-fuzzy-complete dict (car args) (nth 1 args)
				:maxnum maxnum :reverse reverse
				:rank-function rank-function
				:filter filter :pfxfilter pfxfilter))

       ;; modified and not in cached result: merge it into the completion
       ;; list, retaining only the first maxnum
       ((and (not deleted) (not cmpl))
	(when (or (null filter) (funcall filter key newdata))
	  (setf (dictree--cache-results cache-entry)
		(dictree--merge
		 (list (cons (list key distance pfxlen) newdata))
		 completions
		 (or rankfun (dictree--construct-sortfun dict #'caar))
		 maxnum))))

       ;; modified and in the cached result
       ((and (not deleted) cmpl)
	;; update the associated data if dict is a meta-dictionary (this
	;; happens automatically for a normal dict)
	(when (dictree--meta-dict-p dict) (setcdr cmpl newdata))
	;; if updated entry gets filtered, or gets sorted at end of list,
	;; re-run the same query to update the cache
	(when (or (and filter (not (funcall filter key newdata)))
		  (and rankfun
		       (setf (dictree--cache-results cache-entry)
			     (sort completions rankfun))
		       (equal key (car (last (dictree--cache-results
					      cache-entry))))))
	  (remhash (list args rank-function reverse filter pfxfilter)
		   (dictree-fuzzy-complete-cache dict))
	  (dictree-fuzzy-complete dict (car args) (nth 1 args)
				  :maxnum maxnum :reverse reverse
				  :rank-function rank-function
				  :filter filter :pfxfilter pfxfilter)))

       ;; deleted and not in cached result: requires no action
       ))))


(defun dictree-clear-caches (dict)
  "Clear all DICT's query caches."
  (interactive (list (read-dict "Dictionary: ")))
  (when (and (called-interactively-p 'any) (symbolp dict))
    (setq dict (symbol-value dict)))
  (dolist (cachefun '(dictree-lookup-cache
		      dictree-complete-cache
		      dictree-regexp-cache
		      dictree-fuzzy-match-cache
		      dictree-fuzzy-complete-cache))
    (when (funcall cachefun dict)
      (clrhash (funcall cachefun dict))))
  (when (called-interactively-p 'interactive)
    (message "Cleared caches for dictionary %s" (dictree-name dict))))




;; ----------------------------------------------------------------
;;                        Retrieving data

(defun dictree-member (dict key &optional nilflag)
  "Return the data associated with KEY in dictionary DICT,
or nil if KEY is not in the dictionary.

Optional argument NILFLAG specifies a value to return instead of
nil if KEY does not exist in TREE. This allows a non-existent KEY
to be distinguished from an element with a null association. (See
also `dictree-member-p' for testing existence alone.)"
  (let* ((data (dictree--lookup dict key nilflag)))
    (if (eq data nilflag)
	nilflag
      (dictree--cell-data data))))

(defalias 'dictree-lookup #'dictree-member)

(defun dictree-member-p (dict key)
  "Return t if KEY exists in DICT, nil otherwise."
  (let ((flag '(nil)))
    (not (eq flag (dictree-member dict key flag)))))


(defun dictree--lookup (dict key nilflag)
  ;; Return association of KEY in DICT, or NILFLAG if KEY does not
  ;; exist. Does not do any data/meta-data unwrapping

  (let* (data time (flag '(nil)))
    ;; KEY is in cache: done
    (unless (and (dictree-lookup-cache dict)
		 (setq data (gethash key (dictree--lookup-cache dict))))

      ;; meta-dict: look in all its constituent dictionaries
      (if (dictree--meta-dict-p dict)
	  (let (newdata)
	    ;; time lookup for caching
	    (setq time (float-time))
	    (dolist (dic (dictree--meta-dict-dictlist dict))
	      (setq newdata (dictree--lookup dic key flag))
	      (unless (eq newdata flag)
		(if (eq data flag) (setq data newdata)
		  ;; combine results from multiple dictionaries
		  (setq data
			(funcall (dictree--wrap-combfun
				  (dictree--meta-dict-combine-function dict))
				 data newdata)))))
	    (setq time (- (float-time) time)))

	;; normal dict: look in it's trie, timing lookup for caching
	(setq time (float-time))
	(setq data (trie-member (dictree--trie dict) key flag))
	(setq time (- (float-time) time)))

      ;; found something and we're above the cache-threshold: cache result
      (when (and (not (eq data flag))
		 (dictree--above-cache-threshold-p
		  time (length key) (dictree-cache-policy dict)
		  (dictree-cache-threshold dict) 'long-keys))
	(setf (dictree-modified dict) t)
	;; create lookup cache if it doesn't already exist
	(dictree-create-lookup-cache dict)
	(puthash key data (dictree-lookup-cache dict))))

    ;; return data
    (if (eq data flag) nilflag data)))




;; ----------------------------------------------------------------
;;                 Getting and setting meta-data

(defun dictree-put-property (dict key property value)
  "Set PROPERTY for KEY in dictionary DICT.
PROPERTY should be a symbol. Returns VALUE if successful, nil if
KEY was not found in DICT.

Note that if DICT is a meta-dictionary, then this will set KEY's
PROPERTY to VALUE in *all* its constituent dictionaries.

Unlike the data associated with a key (cf. `dictree-insert'),
properties are not included in the results of queries on the
dictionary \(`dictree-lookup', `dictree-complete', etc.\), nor do
they affect the outcome of any of the queries. They merely serve
to tag a key with some additional information, and can only be
retrieved using `dictree-get-property'."

  ;; sort out arguments
  (and (symbolp dict) (setq dict (symbol-value dict)))
  (cond
   ;; meta-dict: set PROPERTY for KEY in all constituent dictionaries
   ((dictree--meta-dict-p dict)
    (warn "Setting %s property for key %s in all constituent\
 dictionaries of meta-dictionary %s" property key (dictree-name dict))
    (setf (dictree-modified dict) t)
    (let (dictree--put-property-ret)
      (mapc (lambda (dic k p v)
	      (setq dictree--put-property-ret
		    (or dictree--put-property-ret
			(dictree-put-property dic k p v))))
	    (dictree--meta-dict-dictlist dict))
      ;; return VALUE if KEY was found in at least one constituent dict
      dictree--put-property-ret))

   (t  ;; normal dict: set PROPERTY for KEY in DICT
    (let ((cell (trie-member (dictree--trie dict) key)))
      (when cell
	(setf (dictree-modified dict) t)
	(setf (dictree--cell-plist cell)
	      (plist-put (dictree--cell-plist cell) property value))
	value)))  ; return VALUE
   ))



(defun dictree-delete-property (dict key property)
  "Delete PROPERTY from KEY in dictionary DICT.
Returns the new property list for KEY, with PROPERTY deleted.

Setting PROPERTY to nil using `dictree-put-property' is not quite
the same thing as deleting it, since null property values can
still be detected by supplying the optional argument to
`dictree-get-propery' (which see).

Note that if DICT is a meta-dictionary, then this will delete
KEY's PROPERTY in *all* its constituent dictionaries."

  ;; sort out arguments
  (and (symbolp dict) (setq dict (symbol-value dict)))
  (cond
   ;; meta-dict: delete PROPERTY from KEY in all constituent dictionaries
   ((dictree--meta-dict-p dict)
    (warn "Deleting %s property from key %s in all constituent\
 dictionaries of meta-dicttionary %s" property key (dictree-name dict))
    (setf (dictree-modified dict) t)
    (mapcar (lambda (dic k p) (dictree-delete-property dic k p))
	    (dictree--meta-dict-dictlist dict)))

   (t  ;; normal dict: delete PROPERTY from KEY in DICT
    (let* ((cell (trie-member (dictree--trie dict) key))
	   plist tail)
      (when (and cell
		 (setq tail
		       (plist-member
			(setq plist (dictree--cell-plist cell))
			property)))
	(setf (dictree-modified dict) t)
	;; delete property and value from plist
	(setcdr tail (cddr tail))
	(setq plist (delq property plist))
	(setf (dictree--cell-plist cell) plist))))
   ))



(defun dictree-get-property (dict key property &optional nilflag)
  "Get the value of PROPERTY for KEY in dictionary DICT,
or return nil if KEY is not in the dictionary.

Optional argument NILFLAG specifies a value to return instead of
nil if KEY does not exist in TREE. This allows a non-existent KEY
to be distinguished from a key for which PROPERTY is not
set. (See also `dictree-member-p' for testing existence alone.)"
  (let ((cell (dictree--lookup dict key nilflag)))
    (unless (eq cell nilflag)
      (plist-get (dictree--cell-plist cell) property))))




;; ----------------------------------------------------------------
;;                        Mapping functions

(defun dictree-mapc (function dict &optional type reverse)
  "Apply FUNCTION to all entries in dictionary DICT,
for side-effects only.

FUNCTION will be passed two arguments: a key of type
TYPE (`string', `vector', or `list', defaulting to `vector') from the
dictionary, and the data associated with that key. The dictionary
entries will be traversed in \"lexicographic\" order, i.e. the
order defined by the dictionary's comparison function (cf.
`dictree-create').

If TYPE is string, it must be possible to apply the function
`string' to the elements of sequences stored in DICT.

FUNCTION is applied in ascending order, or descending order if
REVERSE is non-nil."

  ;; "rename" FUNCTION to something hopefully unique to lessen the
  ;; likelihood of dynamic scoping bugs caused by a supplied function
  ;; binding a variable with the same name as one of the arguments
  (let ((--dictree-mapc--function function))
    (dictree--mapc
     (lambda (key data _plist)
       (funcall --dictree-mapc--function key data))
     dict type reverse)))



(defun dictree--mapc (function dict &optional type reverse)
  ;; Like `dictree-mapc', but FUNCTION is passed three arguments: the
  ;; key, the data, and the property list, instead of just key and data.

  ;; try to avoid dynamic binding bugs
  (let ((--dictree--mapc--function function))
    (if (dictree--meta-dict-p dict)
	;; for a meta-dict, use a dictree-stack
	(let ((stack (dictree-stack dict))
	      entry)
	  (while (setq entry (dictree--stack-pop stack))
	    (funcall --dictree--mapc--function
		     (car entry)
		     (dictree--cell-data (cdr entry))
		     (dictree--cell-plist (cdr entry)))))
      ;; for a normal dictionary, map the function over its trie
      (trie-mapc
       (lambda (key cell)
	 (funcall --dictree--mapc--function
		  key
		  (dictree--cell-data cell)
		  (dictree--cell-plist cell)))
       (dictree--trie dict)
       type reverse)
      )))



(defun dictree-mapf (function combinator dict &optional type reverse)
  "Apply FUNCTION to all entries in dictionary DICT,
and combine the results using COMBINATOR.

FUNCTION should take two arguments: a key sequence from the
dictionary and its associated data.

Optional argument TYPE (one of the symbols `vector', `lisp' or
`string'; defaults to `vector') sets the type of sequence passed to
FUNCTION. If TYPE is `string', it must be possible to apply the
function `string' to the individual elements of key sequences
stored in DICT.

The FUNCTION will be applied and the results combined in
asscending \"lexicographic\" order (i.e. the order defined by the
dictionary's comparison function; cf. `dictree-create'), or
descending order if REVERSE is non-nil."

  ;; try to avoid dynamic scoping bugs
  (let ((--dictree-mapf--function function)
	(--dictree-mapf--combinator combinator))

    ;; for a normal dictionary, map the function over its trie
    (if (not (dictree--meta-dict-p dict))
	(trie-mapf
	 `(lambda (key data)
	    (,--dictree-mapf--function key (dictree--cell-data data)))
	 --dictree-mapf--combinator (dictree--trie dict) type reverse)

      ;; for a meta-dict, use a dictree-stack
      (let ((--dictree-mapf--stack (dictree-stack dict))
	    --dictree-mapf--entry
	    --dictree-mapf--accumulate)
	(while (setq --dictree-mapf--entry
		     (dictree-stack-pop --dictree-mapf--stack))
	  (setq --dictree-mapf--accumulate
		(funcall --dictree-mapf--combinator
			 (funcall --dictree-mapf--function
				  (car --dictree-mapf--entry)
				  (cdr --dictree-mapf--entry))
			 --dictree-mapf--accumulate)))
	--dictree-mapf--accumulate))))



(defun dictree-mapcar (function dict &optional type reverse)
  "Apply FUNCTION to all entries in dictionary DICT,
and make a list of the results.

FUNCTION should take two arguments: a key sequence from the
dictionary and its associated data.

Optional argument TYPE (one of the symbols `vector', `list' or
`string'; defaults to `vector') sets the type of sequence passed
to FUNCTION. If TYPE is string, it must be possible to apply the
function `string' to the individual elements of key sequences
stored in DICT.

The FUNCTION will be applied and the results combined in
asscending \"lexicographic\" order \(i.e. the order defined by
the dictionary's comparison function; cf. `dictree-create'\), or
descending order if REVERSE is non-nil.

Note that if you don't care about the order in which FUNCTION is
applied, just that the resulting list is in the correct order,
then

  (dictree-mapf function #\\='cons dict type (not reverse))

is more efficient."
  (nreverse (dictree-mapf function #'cons dict type reverse)))



(defun dictree-size (dict)
  "Return the number of entries in dictionary DICT.
Interactively, DICT is read from the mini-buffer."
  (interactive (list (read-dict "Dictionary: ")))
  (when (and (called-interactively-p 'any) (symbolp dict))
    (setq dict (symbol-value dict)))
  (let ((count 0))
    (dictree-mapc (lambda (&rest _dummy) (cl-incf count)) dict)
    (when (called-interactively-p 'interactive)
      (message "Dictionary %s contains %d entries"
	       (dictree--name dict) count))
    count))




;; ----------------------------------------------------------------
;;                        Using dictrees as stacks

;; A dictree--meta-stack is the meta-dict version of a dictree-stack (the
;; ordinary version is just a single trie-stack). It consists of a heap of
;; trie-stacks for its constituent tries, where the heap order is the usual
;; lexicographic order over the keys at the top of the trie-stacks.

(cl-defstruct
  (dictree--meta-stack
   (:constructor nil)
   (:constructor dictree--meta-stack-create
		 (dict &optional (type 'vector) reverse
		  &aux
		  (combfun (dictree--wrap-combfun
			    (dictree--meta-dict-combine-function dict)))
		  (sortfun (trie-construct-sortfun
			    (dictree-comparison-function dict)))
		  (heap (heap-create
			 (dictree--construct-meta-stack-heapfun sortfun)
			 (length (dictree--trielist dict))))
		  (pushed '())
		  (_dummy (mapc
			   (lambda (dic)
			     (heap-add
			      heap (trie-stack dic type reverse)))
			   (dictree--trielist dict)))))
   (:constructor dictree--complete-meta-stack-create
		 (dict prefix &optional reverse
		  &aux
		  (combfun (dictree--wrap-combfun
			    (dictree--meta-dict-combine-function dict)))
		  (sortfun (trie-construct-sortfun
			    (dictree-comparison-function dict)))
		  (heap (heap-create
			 (dictree--construct-meta-stack-heapfun
			  sortfun reverse)
			 (length (dictree--trielist dict))))
		  (pushed '())
		  (_dummy (mapc
			   (lambda (trie)
			     (let ((stack (trie-complete-stack
					   trie prefix reverse)))
			       (unless (trie-stack-empty-p stack)
				 (heap-add heap stack))))
			   (dictree--trielist dict)))))
      (:constructor dictree--regexp-meta-stack-create
		 (dict regexp &optional reverse
		  &aux
		  (combfun (dictree--wrap-combfun
			    (dictree--meta-dict-combine-function dict)))
		  (sortfun (dictree--wrap-regexp-sortfun
			    (dictree-comparison-function dict) 'reverse))
		  (heap (heap-create
			 (dictree--construct-meta-stack-heapfun
			  sortfun reverse)
			 (length (dictree--trielist dict))))
		  (pushed '())
		  (_dummy (mapc
			   (lambda (trie)
			     (let ((stack (trie-regexp-stack
					   trie regexp reverse)))
			       (unless (trie-stack-empty-p stack)
				 (heap-add heap stack))))
			   (dictree--trielist dict)))))
      (:constructor dictree--fuzzy-match-meta-stack-create
		 (dict string distance &optional reverse
		  &aux
		  (combfun (dictree--wrap-combfun
			    (dictree--meta-dict-combine-function dict)))
		  (sortfun (dictree--wrap-fuzzy-sortfun
			    (dictree-comparison-function dict)))
		  (heap (heap-create
			 (dictree--construct-meta-stack-heapfun
			  sortfun reverse)
			 (length (dictree--trielist dict))))
		  (pushed '())
		  (_dummy (mapc
			   (lambda (trie)
			     (let ((stack (trie-fuzzy-match-stack
					   trie string distance reverse)))
			       (unless (trie-stack-empty-p stack)
				 (heap-add heap stack))))
			   (dictree--trielist dict)))))
      (:constructor dictree--fuzzy-complete-meta-stack-create
		 (dict prefix distance &optional reverse
		  &aux
		  (combfun (dictree--wrap-combfun
			    (dictree--meta-dict-combine-function dict)))
		  (sortfun (dictree--wrap-fuzzy-sortfun
			    (dictree-comparison-function dict)))
		  (heap (heap-create
			 (dictree--construct-meta-stack-heapfun
			  sortfun reverse)
			 (length (dictree--trielist dict))))
		  (pushed '())
		  (_dummy (mapc
			   (lambda (trie)
			     (let ((stack (trie-fuzzy-complete-stack
					   trie prefix distance reverse)))
			       (unless (trie-stack-empty-p stack)
				 (heap-add heap stack))))
			   (dictree--trielist dict)))))
   (:copier nil))
  combfun sortfun heap pushed)



;; Wrap SORTFUN, which sorts keys, so it can act on dictree--meta-stack
;; elements.
(defun dictree--construct-meta-stack-heapfun (sortfun &optional reverse)
  (if reverse
      (lambda (b a) (funcall sortfun (car (dictree-stack-first a))
			     (car (dictree-stack-first b))))
    (lambda (a b) (funcall sortfun (car (dictree-stack-first a))
			   (car (dictree-stack-first b))))))

(cl-defun dictree-stack (dict &key type reverse pfxfilter)
  "Create an object that allows DICT to be accessed as a stack.

The stack is sorted in \"lexicographic\" order, i.e. the order
defined by the DICT's comparison function, or in reverse order if
REVERSE is non-nil. Calling `dictree-stack-pop' pops the top
element (a key and its associated data) from the stack.

Optional argument TYPE (one of the symbols `vector', `list' or
`string') sets the type of sequence used for the keys.

Note that any modification to DICT *immediately* invalidates all
dictree-stacks created before the modification (in particular,
calling `dictree-stack-pop' will give unpredictable results).

Operations on dictree-stacks are significantly more efficient
than constructing a real stack from the dictionary and using
standard stack functions. As such, they can be useful in
implementing efficient algorithms on dictionaries. However, in
cases where mapping functions `dictree-mapc', `dictree-mapcar' or
`dictree-mapf' would be sufficient, it is better to use one of
those instead."
  (if (dictree--meta-dict-p dict)
      (dictree--meta-stack-create
       dict :type type :reverse reverse :pfxfilter pfxfilter)
    (trie-stack (dictree--trie dict)
		:type type :reverse reverse :pfxfilter pfxfilter)))


(cl-defun dictree-complete-stack (dict prefix &key reverse pfxfilter)
  "Return an object that allows completions of PREFIX to be accessed
as if they were a stack.

The stack is sorted in \"lexicographic\" order, i.e. the order
defined by DICT's comparison function, or in reverse order if
REVERSE is non-nil. Calling `dictree-stack-pop' pops the top
element (a key and its associated data) from the stack.

PREFIX must be a sequence (vector, list or string) that forms the
initial part of a DICT key. (If PREFIX is a string, it must be
possible to apply `string' to individual elements of DICT keys.)
The returned keys will be sequences of the same type as
PREFIX. If PREFIX is a list of sequences, completions of all
sequences in the list are included in the stack. All sequences in
the list must be of the same type.

Note that any modification to DICT *immediately* invalidates all
dictree-stacks created before the modification (in particular,
calling `dictree-stack-pop' will give unpredictable results).

Operations on dictree-stacks are significantly more efficient
than constructing a real stack from completions of PREFIX in DICT
and using standard stack functions. As such, they can be useful
in implementing efficient algorithms on dict-trees. However, in
cases where `dictree-complete' is sufficient, it is better to use
that instead."
  (if (dictree--meta-dict-p dict)
      (dictree--complete-meta-stack-create
       dict prefix :reverse reverse :pfxfilter pfxfilter)
    (trie-complete-stack (dictree--trie dict) prefix
			 :reverse reverse :pfxfilter pfxfilter)))


(cl-defun dictree-regexp-stack (dict regexp &key reverse pfxfilter)
  "Return an object that allows REGEXP matches to be accessed
as if they were a stack.

The stack is sorted in \"lexicographic\" order, i.e. the order
defined by DICT's comparison function, or in reverse order if
REVERSE is non-nil. Calling `dictree-stack-pop' pops the top
element (a key and its associated data) from the stack.

REGEXP is a regular expression, but it need not necessarily be a
string. It must be a sequence (vector, list of string) whose
elements are either elements of the same type as elements of the
keys in DICT (which behave as literals in the regexp), or any of
the usual regexp special characters and backslash constructs. If
REGEXP is a string, it must be possible to apply `string' to
individual elements of the keys stored in DICT. The matches
returned in the alist will be sequences of the same type as KEY.

Back-references and non-greedy postfix operators are *not*
supported, and the matches are always anchored, so `$' and `^'
lose their special meanings.

If the regexp contains any non-shy grouping constructs, subgroup
match data is included in the results. In this case, the car of
each match is no longer just a key. Instead, it is a list whose
first element is the matching key, and whose remaining elements
are cons cells whose cars and cdrs give the start and end indices
of the elements that matched the corresponding groups, in order.

Note that any modification to DICT *immediately* invalidates all
dictree-stacks created before the modification (in particular,
calling `dictree-stack-pop' will give unpredictable results).

Operations on dictree-stacks are significantly more efficient
than constructing a real stack from completions of PREFIX in DICT
and using standard stack functions. As such, they can be useful
in implementing efficient algorithms on dict-trees. However, in
cases where `dictree-regexp-search' is sufficient, it is better
to use that instead."
  (if (dictree--meta-dict-p dict)
      (dictree--regexp-meta-stack-create
       dict regexp :reverse reverse :pfxfilter pfxfilter)
    (trie-regexp-stack (dictree--trie dict) regexp
		       :reverse reverse :pfxfilter pfxfilter)))


(cl-defun dictree-fuzzy-match-stack (dict string distance
					&key reverse pfxfilter)
  "Return an object that allows fuzzy matches to be accessed
as if they were a stack.

The stack is sorted in \"lexicographic\" order, i.e. the order
defined by DICT's comparison function, or in reverse order if
REVERSE is non-nil. Calling `dictree-stack-pop' pops the top
element (a key and its associated data) from the stack.

STRING must be a sequence (vector, list or string), and DISTANCE
must be an integer. (If STRING is a string, it must be possible
to apply `string' to individual elements of DICT keys.) The
matches returned in the alist will be sequences of the same type
as STRING that are within Lewenstein distance DISTANCE of
STRING. If STRING is a list of sequences, keys withing DISTANCE
of any sequences in the list are included in the stack. All
sequences in the list must be of the same type.

Note that any modification to DICT *immediately* invalidates all
dictree-stacks created before the modification (in particular,
calling `dictree-stack-pop' will give unpredictable results).

Operations on dictree-stacks are significantly more efficient
than constructing a real stack from fuzzy matches within DISTANCE
of STRING in DICT and using standard stack functions. As such,
they can be useful in implementing efficient algorithms on
dict-trees. However, in cases where `dictree-fuzzy-match' is
sufficient, it is better to use that instead."
  (if (dictree--meta-dict-p dict)
      (dictree--fuzzy-match-meta-stack-create
       dict string distance :reverse reverse :pfxfilter pfxfilter)
    (trie-fuzzy-match-stack (dictree--trie dict) string distance
			    :reverse reverse :pfxfilter pfxfilter)))


(cl-defun dictree-fuzzy-complete-stack (dict prefix distance
					   &key reverse pfxfilter)
  "Return an object that allows fuzzy completions to be accessed
as if they were a stack.

The stack is sorted in \"lexicographic\" order, i.e. the order
defined by DICT's comparison function, or in reverse order if
REVERSE is non-nil. Calling `dictree-stack-pop' pops the top
element (a key and its associated data) from the stack.

PREFIX must be a sequence (vector, list or string), and DISTANCE
must be an integer. (If PREFIX is a string, it must be possible
to apply `string' to individual elements of DICT keys.) The
completions returned in the alist will be sequences of the same
type as STRING that are completions of prefixes within Lewenstein
distance DISTANCE of PREFIX. If PREFIX is a list of sequences,
completions within DISTANCE of any prefix in the list are
included in the stack. All sequences in the list must be of the
same type.

Note that any modification to DICT *immediately* invalidates all
dictree-stacks created before the modification (in particular,
calling `dictree-stack-pop' will give unpredictable results).

Operations on dictree-stacks are significantly more efficient
than constructing a real stack from fuzzy matches within DISTANCE
of STRING in DICT and using standard stack functions. As such,
they can be useful in implementing efficient algorithms on
dict-trees. However, in cases where `dictree-fuzzy-complete' is
sufficient, it is better to use that instead."
  (if (dictree--meta-dict-p dict)
      (dictree--fuzzy-complete-meta-stack-create
       dict prefix distance :reverse reverse :pfxfilter pfxfilter)
    (trie-fuzzy-complete-stack (dictree--trie dict) prefix distance
			       :reverse reverse :pfxfilter pfxfilter)))


(defun dictree-stack-pop (dictree-stack)
  "Pop the first element from the DICTREE-STACK.
Returns nil if the stack is empty."
  (cond
   ;; if elements have been pushed onto a dict stack, pop those first
   ;; FIXME: shouldn't be using internal trie functions!
   ((and (trie-stack-p dictree-stack)
	 (trie--stack-pushed dictree-stack))
    (trie-stack-pop dictree-stack))
   ;; if elements have been pushed onto a meta-dict stack, pop those
   ;; first
   ((and (dictree--meta-stack-p dictree-stack)
	 (dictree--meta-stack-pushed dictree-stack))
    (pop (dictree--meta-stack-pushed dictree-stack)))
   ;; otherwise, pop first element from dictree-stack
   (t (let ((popped (dictree--stack-pop dictree-stack)))
	(when popped
	  (cons (car popped) (dictree--cell-data (cdr popped))))))
   ))


(defun dictree-stack-push (element dictree-stack)
  "Push ELEMENT onto DICTREE-STACK."
  (if (trie-stack-p dictree-stack)
      ;; normal dict
      (trie-stack-push element dictree-stack)
    ;; meta-dict
    (push element (dictree--meta-stack-pushed dictree-stack))))


(defun dictree-stack-first (dictree-stack)
  "Return the first element from DICTREE-STACK, without removing it.
Returns nil if the stack is empty."
  ;; if elements have been pushed onto the stack, return first of those
  (if (and (dictree--meta-stack-p dictree-stack)
	   (dictree--meta-stack-pushed dictree-stack))
      (car (dictree--meta-stack-pushed dictree-stack))
    ;; otherwise, return first element from dictree-stack
    (let ((first (dictree--stack-first dictree-stack)))
      (cons (car first) (dictree--cell-data (cdr first))))))


(defun dictree-stack-empty-p (dictree-stack)
  "Return t if DICTREE-STACK is empty, nil otherwise."
  (if (trie-stack-p dictree-stack)
      ;; normal dict
      (trie-stack-empty-p dictree-stack)
    ;; meta-dict
    (and (heap-empty (dictree--meta-stack-heap dictree-stack))
	 (null (dictree--meta-stack-pushed dictree-stack)))))


(defun dictree--stack-first (dictree-stack)
  ;; Return the raw first element from DICTREE-STACK, without removing it.
  ;; Returns nil if the stack is empty.
  (if (trie-stack-p dictree-stack)
      ;; normal dict
      (trie-stack-first dictree-stack)
    ;; meta-dict
    (if (dictree--meta-stack-pushed dictree-stack)
	;; pushed element
	(car (dictree--meta-stack-pushed dictree-stack))
      ;; dictree-stack element
      (dictree--stack-first
       (heap-root (dictree--meta-stack-heap dictree-stack))))))


(defun dictree--stack-pop (dictree-stack)
  ;; Pop the raw first element from DICTREE-STACK. Returns nil if the
  ;; stack is empty.

  ;; dictree-stack for normal dictionaries is a trie-stack
  (if (trie-stack-p dictree-stack)
      (trie-stack-pop dictree-stack)

    ;; meta-dictionary dictree-stack...more work!
    ;; if elements have been pushed onto meta-dict stack, pop those
    ;; first
    (if (dictree--meta-stack-pushed dictree-stack)
	(pop (dictree--meta-stack-pushed dictree-stack))
      ;; otherwise...
      (let ((heap (dictree--meta-stack-heap dictree-stack))
	    (sortfun (dictree--meta-stack-sortfun dictree-stack))
	    stack curr next)
	(unless (heap-empty heap)
	  ;; remove the first dictree-stack from the heap, pop it's
	  ;; first element, and add it back to the heap (note that it
	  ;; will almost certainly not end up at the root again)
	  (setq stack (heap-delete-root heap))
	  (setq curr (dictree--stack-pop stack))
	  (unless (dictree-stack-empty-p stack) (heap-add heap stack))
	  ;; peek at the first element of the stack now at the root of
	  ;; the heap
	  (unless (heap-empty heap)
	    (setq next (dictree--stack-first (heap-root heap)))
	    ;; repeat this as long as we keep finding elements with the
	    ;; same key, combining them together as we go
	    (when (dictree--meta-stack-combfun dictree-stack)
	      (while (and (null (funcall sortfun
					 (car curr) (car next)))
			  (null (funcall sortfun
					 (car next) (car curr))))
		(setq stack (heap-delete-root heap))
		(setq next (dictree--stack-pop stack))
		(setq curr (cons (car curr)
				 (funcall
				  (dictree--meta-stack-combfun dictree-stack)
				  (cdr curr) (cdr next))))
		(heap-add heap stack)
		(setq next (dictree--stack-first (heap-root heap))))))
	  ;; return the combined dictionary element
	  curr)))))




;; ----------------------------------------------------------------
;;                    dictree iterator generators

;; dictree-stacks *are* iterators (with additional push and
;; inspect-first-element operations). If we're running on a modern Emacs that
;; includes the `generator' library, we can trivially define dictree iterator
;; generators in terms of dictree-stacks.

(heap--when-generators
 (cl-iter-defun dictree-iter (dict &key type reverse pfxfilter)
   "Return a dictree iterator object.

Calling `iter-next' on this object will retrieve the next
element (a cons cell containing a key and its associated data)
from DICT in \"lexicographic\" order, i.e. the order defined by
the DICT's comparison function, or in reverse order if REVERSE is
non-nil.

Optional argument TYPE (one of the symbols `vector', `list' or
`string') sets the type of sequence used for the keys.

Note that any modification to DICT *immediately* invalidates all
iterators created from DICT before the modification (in
particular, calling `iter-next' will give unpredictable
results). If DICT is a meta-dict, this includes any modifications
to its constituent dicts."
   (let ((stack (dictree-stack dict :type type :reverse reverse
			       :pfxfilter pfxfilter)))
     (while (not (dictree-stack-empty-p stack))
       (iter-yield (dictree-stack-pop stack))))))


(heap--when-generators
 (cl-iter-defun dictree-complete-iter (dict prefix
					    &key reverse pfxfilter)
   "Return an iterator object for completions of PREFIX in DICT.

Calling `iter-next' on this object will retrieve the next
completion of PREFIX (a cons cell containing a key and its
associated data) from DICT in \"lexicographic\" order, i.e. the
order defined by DICT's comparison function, or in reverse order
if REVERSE is non-nil.

PREFIX must be a sequence (vector, list or string) that forms the
initial part of a DICT key. (If PREFIX is a string, it must be
possible to apply `string' to individual elements of DICT keys.)
The returned keys will be sequences of the same type as
PREFIX. If PREFIX is a list of sequences, completions of all
sequences in the list are included in the stack. All sequences in
the list must be of the same type.

Note that any modification to DICT *immediately* invalidates all
iterators created from DICT before the modification (in
particular, calling `iter-next' will give unpredictable
results). If DICT is a meta-dict, this includes any modifications
to its constituent dicts."
   (let ((stack (dictree-complete-stack dict prefix reverse)))
     (while (not (dictree-stack-empty-p stack))
       (iter-yield (dictree-stack-pop stack))))))


(heap--when-generators
 (cl-iter-defun dictree-regexp-iter (dict regexp
					  &key reverse pfxfilter)
   "Return an iterator object for REGEXP matches in DICT.

Calling `iter-next' on this object will retrieve the next match
\(a cons cell containing a key and its associated data\) in
\"lexicographic\" order, i.e. the order defined by DICT's
comparison function, or in reverse order if REVERSE is non-nil.

REGEXP is a regular expression, but it need not necessarily be a
string. It must be a sequence (vector, list of string) whose
elements are either elements of the same type as elements of the
keys in DICT (which behave as literals in the regexp), or any of
the usual regexp special characters and backslash constructs. If
REGEXP is a string, it must be possible to apply `string' to
individual elements of the keys stored in DICT. The matches
returned in the alist will be sequences of the same type as KEY.

Back-references and non-greedy postfix operators are *not*
supported, and the matches are always anchored, so `$' and `^'
lose their special meanings.

If the regexp contains any non-shy grouping constructs, subgroup
match data is included in the results. In this case, the car of
each match is no longer just a key. Instead, it is a list whose
first element is the matching key, and whose remaining elements
are cons cells whose cars and cdrs give the start and end indices
of the elements that matched the corresponding groups, in order.

Note that any modification to DICT *immediately* invalidates all
iterators created from DICT before the modification (in
particular, calling `iter-next' will give unpredictable
results). If DICT is a meta-dict, this includes any modifications
to its constituent dicts."
   (let ((stack (dictree-regexp-stack dict regexp
				      :reverse reverse
				      :pfxfilter pfxfilter)))
     (while (not (dictree-stack-empty-p stack))
       (iter-yield (dictree-stack-pop stack))))))

(heap--when-generators
 (cl-iter-defun dictree-fuzzy-match-iter (dict string distance
					       &key reverse pfxfilter)
   "Return an iterator object for fuzzy matches to STRING in DICT.

Calling `iter-next' on this object will retrieve the next match
\(a cons cell containing a key and its associated data\) in
\"lexicographic\" order, i.e. the order defined by DICT's
comparison function, or in reverse order if REVERSE is non-nil.

STRING must be a sequence (vector, list or string), and DISTANCE
must be an integer. (If STRING is a string, it must be possible
to apply `string' to individual elements of DICT keys.) The
returned keys will be sequences of the same type as STRING that
are within Lewenstein distance DISTANCE of STRING. If STRING is a
list of sequences, keys withing DISTANCE of any sequences in the
list are included in the stack. All sequences in the list must be
of the same type.

Note that any modification to DICT *immediately* invalidates all
iterators created from DICT before the modification (in
particular, calling `iter-next' will give unpredictable
results). If DICT is a meta-dict, this includes any modifications
to its constituent dicts."
   (let ((stack (dictree-fuzzy-match-stack dict string distance
					   :reverse reverse
					   :pfxfilter pfxfilter)))
     (while (not (dictree-stack-empty-p stack))
       (iter-yield (dictree-stack-pop stack))))))


(heap--when-generators
 (cl-iter-defun dictree-fuzzy-complete-iter (dict prefix distance
						  &key reverse pfxfilter)
   "Return an iterator object for fuzzy completions of PREFIX in DICT.

Calling `iter-next' on this object will retrieve the next fuzzy
completion in \"lexicographic\" order, i.e. the order defined by
DICT's comparison function, or in reverse order if REVERSE is
non-nil. Each returned element has the form:

    ((KEY . DIST) . DATA)

PREFIX must be a sequence (vector, list or string), and DISTANCE
must be an integer. (If PREFIX is a string, it must be possible
to apply `string' to individual elements of DICT keys.) The
returned keys will be sequences of the same type as STRING that
are completions of prefixes within Lewenstein distance DISTANCE
of PREFIX. If PREFIX is a list of sequences, completions within
DISTANCE of any prefix in the list are included in the stack. All
sequences in the list must be of the same type.

Note that any modification to DICT *immediately* invalidates all
iterators created from DICT before the modification (in
particular, calling `iter-next' will give unpredictable
results). If DICT is a meta-dict, this includes any modifications
to its constituent dicts."
   (let ((stack (dictree-fuzzy-complete-stack dict prefix distance
					      :reverse reverse
					      :pfxfilter pfxfilter)))
     (while (not (dictree-stack-empty-p stack))
       (iter-yield (dictree-stack-pop stack))))))




;; ----------------------------------------------------------------
;;             Functions for building advanced queries

(cl-defun dictree--query
    (dict triefun stackfun cachefun cachecreatefun cache-long no-cache args
	  &key maxnum reverse rank-function rankfun stack-rankfun
	  filter pfxfilter resultfun)
  ;; Return results of querying DICT with argument ARG (and AUXARGS list, if
  ;; any) using TRIEFUN or STACKFUN. If DICT's cache-threshold is non-nil,
  ;; look first for cached result in cache returned by calling CACHEFUN on
  ;; DICT, and cache result if query fulfils caching conditions. Non-nil
  ;; CACHE-LONG indicates long ARGs should be cached, rather than short
  ;; ARGs. If RANK-FUNCTION is non-nil, return results ordered
  ;; accordingly. RANKFUN should be the appropriately wrapped version of
  ;; RANK-FUNCTION. If MAXNUM is an integer, only the first MAXNUM results
  ;; will be returned. If REVERSE is non-nil, results are in reverse order. A
  ;; non-nil NO-CACHE prevents caching of results, irrespective of DICT's
  ;; cache settings. If FILTER is supplied, only results that pass FILTER are
  ;; included. A non-nil RESULTFUN is applied to results before adding them to
  ;; final results list. Otherwise, an alist of key-data associations is
  ;; returned.

  ;; map over all dictionaries in list
  (when (dictree-p dict) (setq dict (list dict)))
  (let (cache results res cache-entry)
    (dolist (dic dict)

      ;; if there's a cache entry with enough results, use it
      (if (and cachefun
	       (or (symbolp rank-function)
	       	   ;; can be '(t . rankfun) for `dictree-fuzzy-complete'
	       	   (and (consp rank-function)
	       		(symbolp (car rank-function))
	       		(symbolp (cdr rank-function))))
	       (symbolp filter)
	       (symbolp pfxfilter)
	       (setq cache (funcall cachefun dic))
	       (setq cache-entry
		     (gethash (list args rank-function reverse filter pfxfilter)
			      cache))
	       (or (null (dictree--cache-maxnum cache-entry))
		   (and maxnum
			(<= maxnum (dictree--cache-maxnum cache-entry))))
	       (setq res (dictree--cache-results cache-entry)))
	  ;; drop any excess results
	  (when (and maxnum
		     (or (null (dictree--cache-maxnum cache-entry))
			 (> (dictree--cache-maxnum cache-entry) maxnum)))
	    (setq res (cl-subseq res 0 maxnum)))

	;; if there was nothing useful in the cache, do query and time it
	(let ((time (float-time)))
	  (setq res
		(dictree--do-query
		 dic triefun stackfun args rankfun maxnum reverse
		 (when filter (dictree--wrap-filter filter)) pfxfilter
		 stack-rankfun))
	  (setq time (- (float-time) time))
	  ;; if we're above the dictionary's cache threshold, cache the result
	  (when (and cachefun (not no-cache)
		     ;; (or (symbolp rank-function)
		     ;; 	 ;; can be '(t . rankfun) for `dictree-fuzzy-complete'
		     ;; 	 (and (consp rank-function)
		     ;; 	      (symbolp (car rank-function))
		     ;; 	      (symbolp (cdr rank-function))))
		     ;; (symbolp filter)
		     ;; (symbolp pfxfilter)
		     (dictree--above-cache-threshold-p
		      time (length (car args)) (dictree-cache-policy dic)
		      (dictree-cache-threshold dic) cache-long))
	    (setf (dictree-modified dic) t)
	    ;; create query cache if it doesn't already exist
	    (funcall cachecreatefun dic)
	    (puthash (list args rank-function reverse filter pfxfilter)
		     (dictree--cache-create res maxnum)
		     (funcall cachefun dic)))))

      ;; merge new result into results list
      (setq results
	    (dictree--merge
	     results res
	     (or rankfun (dictree--construct-sortfun (car dict)))
	     maxnum)))


    ;; return results list, applying RESULTFUN if specified, otherwise just
    ;; stripping meta-data
    (mapcar (if resultfun
		(dictree--wrap-resultfun resultfun)
	      (lambda (el) (cons (car el) (dictree--cell-data (cdr el)))))
	    results)))



(defun dictree--do-query
    (dict triefun stackfun args
	  &optional rankfun maxnum reverse filter pfxfilter stack-rankfun)
  ;; Return first MAXNUM results of querying DICT with argument ARG (and
  ;; AUXARGS list, if any) using TRIEFUN or STACKFUN that satisfy FILTER,
  ;; ordered according to RANKFUN (defaulting to "lexicographic" order).

  (if (dictree--p dict)
      ;; for a normal dict, call corresponding trie function on dict's
      ;; trie. Note: could use a dictree-stack here too - would it be more
      ;; efficient?
      (apply triefun
	     (append (list (dictree--trie dict)) args
		     (list :maxnum maxnum :reverse reverse
			   :rankfun rankfun
			   :filter filter :pfxfilter pfxfilter)))

    ;; for a meta-dict, use a dictree-stack
    (unless stack-rankfun (setq stack-rankfun rankfun))
    (let ((stack (apply stackfun
			(append (list dict) args
				(list :reverse reverse
				      :pfxfilter pfxfilter))))
	  (heap (when stack-rankfun
		  (heap-create   ; heap order is inverse of rank order
		   (if reverse stack-rankfun
		     (lambda (a b) (not (funcall stack-rankfun a b))))
		   (1+ maxnum))))
	  (i 0) res results)
      ;; pop MAXNUM results from the stack
      (while (and (or (null maxnum) (< i maxnum))
		  (setq res (dictree--stack-pop stack)))
	;; check result passes FILTER
	(when (or (null filter) (funcall filter res))
	  (if stack-rankfun
	      (heap-add heap res)   ; for ranked query, add to heap
	    (push res results))     ; for lexicographic query, add to list
	  (cl-incf i)))
      (if (null stack-rankfun)
	  ;; for lexicographic query, reverse and return result list (we
	  ;; built it backwards)
	  (nreverse results)
	;; for ranked query, pass rest of results through heap
	(while (setq res (dictree--stack-pop stack))
	  (when (or (null filter) (funcall filter res))
	    (heap-add heap res)
	    (heap-delete-root heap)))
	;; extract results from heap
	(while (setq res (heap-delete-root heap))
	  (push res results))
	results))  ; return result list
    ))




;; ----------------------------------------------------------------
;;                        Completing

(cl-defun dictree-complete
    (dict prefix
	  &key maxnum reverse rank-function filter pfxfilter
	  resultfun no-cache)
  "Return an alist containing all completions of PREFIX in DICT
along with their associated data, sorted according to
RANK-FUNCTION (defaulting to \"lexicographic\" order, i.e. the
order defined by the dictionary's comparison function,
cf. `dictree-create'). Return nil if no completions are found.

PREFIX can also be a list of sequences, in which case completions
of all elements in the list are returned, merged together in a
single sorted alist.

DICT can also be a list of dictionaries, in which case
completions are sought in all dictionaries in the list. (Note
that if the same key appears in multiple dictionaries, the alist
may contain the same key multiple times, each copy associated
with the data from a different dictionary. If you want to combine
identical keys, use a meta-dictionary; see
`dictree-create-meta-dict'.)

If optional argument RANK-FUNCTION is t, the completions are
sorted according to the dictionary's rank-function (see
`dictree-create'). Any non-nil value that *is* a function
overrides this. In that case, RANK-FUNCTION should accept two
arguments, both cons cells. The car of each contains a completion
from DICT (of the same type as PREFIX), the cdr contains its
associated data. The RANK-FUNCTION should return non-nil if first
argument is ranked strictly higher than the second, nil
otherwise.

The optional integer argument MAXNUM limits the results to the
first MAXNUM completions. The default is to return all matches.

If the optional argument NO-CACHE is non-nil, it prevents caching
of the result. Ignored for dictionaries that do not have
completion caching enabled.

The FILTER argument sets a filter function for the
completions. For each potential completion, it is passed two
arguments: the completion, and its associated data. If the filter
function returns nil, the completion is not included in the
results, and doesn't count towards MAXNUM.

The PFXFILTER argument sets a prefix filter function. If
supplied, it is called with one argument: a sequence of the same
type as PREFIX. If it returns nil, all completions with that
sequence as a prefix will be ignored. When PFXFILTER suffices, it
is more efficient than using FILTER for the same purpose.

RESULTFUN defines a function used to process results before
adding them to the final result list. If specified, it should
accept two arguments: a key and its associated data. Its return
value is what gets added to the final result list, instead of the
default key-data cons cell."
  ;; run completion query
  (dictree--query
   dict #'trie-complete #'dictree-complete-stack
   #'dictree-complete-cache #'dictree-create-complete-cache
   nil no-cache  ; cache short PREFIXes
   (list prefix)
   :rank-function rank-function
   :maxnum maxnum
   :reverse reverse
   :rankfun (when rank-function
	      (dictree--wrap-rankfun
	       (if (eq rank-function t)
		   (dictree--rank-function (if (listp dict) (car dict) dict))
		 rank-function)))
   :filter filter
   :pfxfilter pfxfilter
   :resultfun resultfun))


(defun dictree-collection-function (dict string predicate all)
  "Function for use in `try-completion', `all-completions',
and `completing-read'. To complete from dictionary DICT, use the
following as the COLLECTION argument of any of those functions:

  (lambda (string predicate all)
    (dictree-collection-function dict string predicate all))

Note that PREDICATE will be called with two arguments: the
completion, and its associated data."
  (let ((completions
	 (dictree-complete dict string
			   :filter predicate
			   :resultfun (lambda (key _data) key))))
    (if all completions (try-completion "" completions))))




;; ----------------------------------------------------------------
;;                      Regexp search

(cl-defun dictree-regexp-search
    (dict regexp &key maxnum reverse rank-function
	  filter pfxfilter resultfun no-cache)
  "Return an alist containing all matches for REGEXP in DICT
along with their associated data, in the order defined by
RANKFUN, defauling to \"lexicographic\" order. If REVERSE is
non-nil, the completions are sorted in the reverse order. Returns
nil if no completions are found.

DICT can also be a list of dictionaries, in which case matches
are sought in all dictionaries in the list. (Note that if the
same key appears in multiple dictionaries, the alist may contain
the same key multiple times, each copy associated with the data
from a different dictionary. If you want to combine identical
keys, use a meta-dictionary; see `dictree-create-meta-dict'.)

REGEXP is a regular expression, but it need not necessarily be a
string. It must be a sequence (vector, list of string) whose
elements are either of the same type as elements of DICT
keys (these behave as literals in the regexp), or any of the
usual regexp special characters and backslash constructs. If
REGEXP is a string, it must be possible to apply `string' to
individual elements of the keys stored in DICT. The matches
returned in the alist will be sequences of the same type as
REGEXP.

Only a subset of the full Emacs regular expression syntax is
supported. There is no support for regexp constructs that are
only meaningful for strings (character ranges and character
classes inside character alternatives, and syntax-related
backslash constructs). Back-references and non-greedy postfix
operators are not supported, so `?' after a postfix operator
loses its special meaning. Also, matches are always anchored, so
`$' and `^' lose their special meanings (use `.*' at the
beginning and end of the regexp to get an unanchored match).

If the regexp contains any non-shy grouping constructs, subgroup
match data is included in the results. In this case, the car of
each match is no longer just a key. Instead, each element of the
results list has the form

    ((KEY (START1 . END1) (START2 . END2) ...) . DATA)

where the (START . END) cons cells give the start and end indices
of the elements that matched the corresponding groups, in order.


The optional integer argument MAXNUM limits the results to the
first MAXNUM matches. The default is to return all matches.

If the optional argument NO-CACHE is non-nil, it prevents caching
of the result. Ignored for dictionaries that do not have wildcard
caching enabled.


If optional argument RANK-FUNCTION is t, the matches are sorted
according to the dictionary's rank-function (see
`dictree-create').

Any other non-nil value of RANK-FUNCTION should be a function
which accepts two arguments. If the regexp does not contain any
non-shy grouping constructs, both arguments are (KEY . DATA) cons
cells, where the car is a sequence of the same type as REGEXP. If
the regexp does contain non-shy grouping constructs, both
arguments are of the form

    ((KEY (START1 . END1) (START2 . END2) ...) . DATA)

RANKFUN should return non-nil if first argument is ranked
strictly higher than the second, nil otherwise.


The FILTER argument sets a filter function for the matches. If
supplied, it is called for each possible match with two
arguments: a key and its associated data. If the regexp contains
non-shy grouping constructs, the first argument is of the form

    (KEY (START1 . END1) (START2 . END2) ...)

If the FILTER function returns nil, the match is not included in
the results, and does not count towards MAXNUM.

The PFXFILTER argument sets a prefix filter function. If
supplied, it is called with one argument: a sequence of the same
type as PREFIX. If it returns nil, all matches with that sequence
as a prefix will be ignored. When PFXFILTER suffices, it is more
efficient than using FILTER for the same purpose.


RESULTFUN defines a function used to process results before
adding them to the final result list. If specified, it should
accept two arguments, of the same form as those for FILTER (see
above). Its return value is what gets added to the final result
list, instead of the default key-data cons cell."

  ;; run regexp query
  (dictree--query
   dict #'trie-regexp-search #'dictree-regexp-stack
   #'dictree-regexp-cache #'dictree-create-regexp-cache
   (if (and (eq (elt regexp (- (length regexp) 2)) ?.)
	    (eq (elt regexp (- (length regexp) 1)) ?*))
       nil  ; cache short REGEXP if it ends in .*
     t)     ; cache long REGEXPs otherwise
   no-cache
   (list regexp)
   :maxnum maxnum
   :reverse reverse
   :rank-function rank-function
   :rankfun (when rank-function
	      (dictree--wrap-regexp-rankfun
	       (if (eq rank-function t)
		   (dictree-rank-function (if (listp dict) (car dict) dict))
		 rank-function)))
   :filter filter
   :pfxfilter pfxfilter
   :resultfun resultfun))




;; ----------------------------------------------------------------
;;                      Fuzzy queries

(cl-defun dictree-fuzzy-match
    (dict string distance &key maxnum reverse rank-function
	  filter pfxfilter resultfun no-cache)
  "Return matches for STRING in DICT within Lewenstein DISTANCE
\(edit distance\) of STRING along with their associated data, in
the order defined by RANKFUN, defauling to \"lexicographic\"
order. If REVERSE is non-nil, the matches are sorted in the
reverse order. Returns nil if no completions are found.

Returns a list of matches, with elements of the form:

    ((KEY . DIST) . DATA)

where KEY is a matching key from the trie, DATA its associated
data, and DIST is its Lewenstein distance \(edit distance\) from
STRING.

DICT can also be a list of dictionaries, in which case matches
are sought in all dictionaries in the list. (Note that if the
same key appears in multiple dictionaries, the alist may contain
the same key multiple times, each copy associated with the data
from a different dictionary. If you want to combine identical
keys, use a meta-dictionary; see `dictree-create-meta-dict'.)

STRING is a sequence (vector, list or string), whose elements
must be of the same type as elements of the keys stored in
DICT. If STRING is a string, it must be possible to apply
`string' to individual elements of DICT keys. The KEYs returned
in the list will be sequences of the same type as STRING.

DISTANCE must be an integer, and specifies the maximum Lewenstein
distance \(edit distances\) of matches from STRING.


If optional argument RANK-FUNCTION is the symbol `distance', the
matches are sorted according to their Lewenstein distance from
STRING. If it is t, the matches are sorted according to the
dictionary's rank-function (see `dictree-create').

Any other non-nil value of RANK-FUNCTION should be a function
which accepts two arguments, both of the form

  ((KEY . DIST) . DATA)

where KEY is a sequence from the dictionary (of the same type as
STRING), DIST is its Lewenstein distance from STRING, and DATA is
its associated data. The RANK-FUNCTION should return non-nil if
the first argument is ranked strictly higher than the second, nil
otherwise.


The optional integer argument MAXNUM limits the results to the
first MAXNUM matches. The default is to return all matches.

If the optional argument NO-CACHE is non-nil, it disables any
caching of the result.

The FILTER argument sets a filter function for the matches. If
supplied, it is called for each possible match with two
arguments: a (KEY . DIST) cons cell, and DATA. If the filter
function returns nil, the match is not included in the results,
and does not count towards MAXNUM.

The PFXFILTER argument sets a prefix filter function. If
supplied, it is called with one argument: a sequence of the same
type as PREFIX. If it returns nil, all matches with that sequence
as a prefix will be ignored. When PFXFILTER suffices, it is more
efficient than using FILTER for the same purpose.

RESULTFUN defines a function used to process results before
adding them to the final result list. If specified, it should
accept two arguments: a (KEY . DIST) cons cell, and DATA. Its
return value is what gets added to the final result list, instead
of the default key-dist-data list."

  ;; run fuzzy-match query
  (dictree--query
   dict #'trie-fuzzy-match #'dictree-fuzzy-match-stack
   #'dictree-fuzzy-match-cache #'dictree-create-fuzzy-match-cache
   t no-cache  ; cache long STRINGs
   (list string distance)
   :maxnum maxnum
   :reverse reverse
   :rank-function rank-function
   :rankfun (dictree--construct-fuzzy-trie-rankfun
	     rank-function (if (listp dict) (car dict) dict))
   :stack-rankfun (dictree--construct-fuzzy-match-rankfun
		   rank-function  (if (listp dict) (car dict) dict))
   :filter filter
   :pfxfilter pfxfilter
   :resultfun resultfun))


(cl-defun dictree-fuzzy-complete
    (dict prefix distance
	  &key maxnum reverse rank-function
	  filter pfxfilter resultfun no-cache)
  "Return completion of prefixes in DICT within Lewenstein DISTANCE
\(edit distance\) of PREFIX along with their associated data, in
the order defined by RANKFUN, defauling to lexicographic order.
If REVERSE is non-nil, the matches are sorted in the reverse
order. Returns nil if no completions are found.

Returns a list of completions with elements of the form:

    ((KEY DIST PFXLEN) . DATA)

where KEY is a matching completion from the trie, DATA its
associated data, PFXLEN is the length of the prefix part of KEY,
and DIST is its Lewenstein distance \(edit distance\) from
PREFIX.

DICT can also be a list of dictionaries, in which case matches
are sought in all dictionaries in the list. (Note that if the
same key appears in multiple dictionaries, the alist may contain
the same key multiple times, each copy associated with the data
from a different dictionary. If you want to combine identical
keys, use a meta-dictionary; see `dictree-create-meta-dict'.)

PREFIX is a sequence (vector, list or string), whose elements
must be of the same type as elements of the keys stored in
DICT. If PREFIX is a string, it must be possible to apply
`string' to individual elements of DICT keys. The KEYs returned
in the list will be sequences of the same type as PREFIX.


DISTANCE is a positive integer specifying the maximum Lewenstein
distance prefixes from PREFIX. \(Note that DISTANCE=0 will not
give meaningful results; use `trie-complete' instead.\)

DISTANCE can also be a cons cell \(LENGTH . DISTANCE\) containing
two positive integers. In this case, the first LENGTH elements of
PREFIX must be matched exactly, and the remaining elements must
be within the specified Lewenstain DISTANCE.


If optional argument RANK-FUNCTION is the symbol `ranked', the
matches are sorted according to the dictionary's
rank-function (see `dictree-create').

If RANK-FUNCTION is t, the matches are sorted by increasing
Lewenstein distance of their prefix, with same-distance prefixes
ordered lexicographically.

If RANK-FUNCTION is a cons cell of the form

    (t . RANKFUN)

then matches are again ordered by increasing Lewenstein distance
of their prefix, but with same-distance prefixes ordered by
RANKFUN. If RANKFUN is the symbol `ranked', same-distance
prefixes are ordered by the dictionary's rank-function (see
`dictree-create'). Otherwise, RANKFUN should take two arguments,
both of the form

    (KEY . DATA)

where KEY is a key from the trie and DATA is its associated data.
RANKFUN should return non-nil if first argument is ranked
strictly higher than the second, nil otherwise.

Any other non-nil value of RANK-FUNCTION should be a function
that accepts two arguments, both of the form:

    ((KEY DIST PFXLEN) . DATA)

where KEY is a completion (of the same type as PREFIX), DIST is
its Lewenstein distances from PREFIX, and DATA is its associated
data. RANKFUN should return non-nil if first argument is ranked
strictly higher than the second, nil otherwise.


The optional integer argument MAXNUM limits the results to the
first MAXNUM matches. The default is to return all matches.

If the optional argument NO-CACHE is non-nil, it prevents caching
of the result. Ignored for dictionaries that do not have
fuzzy-match caching enabled.


FILTER sets a filter function for the matches. If supplied, it is
called for each possible completion with two arguments: a
\(KEY DIST PFXLEN\) list, and DATA. If FILTER returns nil, that
match is not included in the results, and does not count towards
MAXNUM.

The PFXFILTER argument sets a prefix filter function. If
supplied, it is called with one argument: a sequence of the same
type as PREFIX. If it returns nil, all completions with that
sequence as a prefix will be ignored. When PFXFILTER suffices, it
is more efficient than using FILTER for the same purpose.


RESULTFUN defines a function used to process results before
adding them to the final result list. If specified, it should
accept two arguments: a \(KEY DIST PFXLEN\) list, and DATA. Its
return value is what gets added to the final result list, instead
of the default key-dist-pfxlen-data list."

  ;; run fuzzy-complete query
  (dictree--query
   dict #'trie-fuzzy-complete #'dictree-fuzzy-complete-stack
   #'dictree-fuzzy-complete-cache #'dictree-create-fuzzy-complete-cache
   nil no-cache  ; cache short PREFIXes
   prefix (list distance)
   :maxnum maxnum
   :reverse reverse
   :rank-function rank-function
   :rankfun (dictree--construct-fuzzy-trie-rankfun
	     rank-function (if (listp dict) (car dict) dict))
   :stack-rankfun (dictree--construct-fuzzy-complete-rankfun
		   rank-function (if (listp dict) (car dict) dict))
   :filter filter
   :pfxfilter pfxfilter
   :resultfun resultfun))




;; ----------------------------------------------------------------
;;                    Persistent storage

(defun dictree-save (dict &optional compilation)
  "Save dictionary DICT to its associated directory.
Use `dictree-write' to save to a different directory.

Optional argument COMPILATION determines whether to save the
dictionary in compiled or uncompiled form. The default is to save
both forms. See `dictree-write'.

Interactively, DICT is read from the mini-buffer."
  (interactive (list (read-dict "Dictionary: ")))
  (when (symbolp dict) (setq dict (symbol-value dict)))

  (let ((filename (dictree-filename dict)))
    ;; if dictionary has no associated file, prompt for one
    (unless (and filename (> (length filename) 0))
      (setq filename
	    (read-file-name
	     (format "Save dictionary %s to file\
 (leave blank to NOT save): "
		     (dictree-name dict))
	     nil "")))

    ;; if filename is blank, don't save
    (if (string= filename "")
	(message "Dictionary %s NOT saved" (dictree-name dict))
      ;; otherwise write dictionary to file
      (setf (dictree-filename dict) filename)
      (dictree-write dict filename t compilation))))



(defun dictree-write (dict &optional filename overwrite compilation)
  "Write dictionary DICT to the file FILENAME.
Defaults to the file the dictionary was loaded from, if any.
\(See also `dictree-save'.\)

If FILENAME is just a directory, DICT is written to a file under
that directory with the same name as DICT.

If optional argument OVERWRITE is non-nil, no confirmation will
be asked for before overwriting an existing file.

The default is to create both compiled and uncompiled versions of
the dictionary, with extensions .elc and .el respectively. The
compiled version is always used in preference to the uncomplied
version, as it loads faster. However, only the uncompiled version
is portable between different Emacs versions.

If optional argument COMPILATION is the symbol `compiled', only
the compiled version will be created, whereas if it is the symbol
`uncompiled', only the uncompiled version will be created.

Interactively, DICT and DIRECTORY are read from the mini-buffer,
and OVERWRITE is the prefix argument."
  (interactive (list (read-dict "Dictionary: ")
		     (read-file-name
		      "Write dictionary to file/directory: " nil "")
		     current-prefix-arg))
  (when (symbolp dict) (setq dict (symbol-value dict)))
  ;; default to filename DICT was loaded from, if any
  (cond
   ((and (or (null filename)
	     (and (called-interactively-p 'any) (string= filename "")))
	 (dictree-filename dict))
    (setq filename (dictree-filename dict)))
   ((file-directory-p filename)
    (setq filename (concat filename (dictree-name dict))))
   ((string= (substring filename -3) ".el")
    (setq filename (substring filename 0 -3)))
   ((string= (substring filename -4) ".elc")
    (setq filename (substring filename 0 -4))))

  (if (null filename)
      (progn
	(message "Dictionary %s NOT written" (dictree-name dict))
	nil)  ; return nil to indicate failure

    (let ((dictname (file-name-sans-extension (file-name-nondirectory filename)))
	  buff tmpfile)

      ;; prompt for confirmation if necessary
      (when (or (string= dictname (dictree-name dict))
		(and
		 (y-or-n-p (format "Change dictionary name? "))
		 (or overwrite
		     (and
		      (or (eq compilation 'compiled)
			  (not (file-exists-p (concat filename ".el"))))
		      (or (eq compilation 'uncompiled)
			  (not (file-exists-p (concat filename ".elc")))))
		     (y-or-n-p
		      (format "File %s already exists. Overwrite? "
			      (concat filename ".el(c)"))))))
	(setf (dictree-name dict) dictname)
	(setf (dictree-filename dict) filename)

	(message "Writing dictionary %s to %s..." dictname filename)
	(save-excursion
	  ;; create a temporary file
	  (setq buff
		(find-file-noselect
		 (setq tmpfile (make-temp-file dictname))))
	  (set-buffer buff)
	  ;; byte-compiler seems to b0rk on dos line-endings in some Emacsen
	  (set-buffer-file-coding-system 'utf-8-unix)
	  ;; call the appropriate write function to write the dictionary code
	  (if (dictree--meta-dict-p dict)
	      (dictree--write-meta-dict-code dict)
	    (dictree--write-dict-code dict))
	  (save-buffer)
	  (kill-buffer buff))

	(condition-case nil
	    (progn
	      ;; move the uncompiled version to its final destination
	      (unless (eq compilation 'compiled)
		(copy-file tmpfile (concat filename ".el") t))
	      ;; byte-compile and move the compiled version to its final
	      ;; destination
	      (unless (eq compilation 'uncompiled)
		(if (save-window-excursion
;;		      (let ((byte-compile-disable-print-circle t))
			(byte-compile-file tmpfile));)
		    (rename-file (concat tmpfile ".elc")
				 (concat filename ".elc")
				 'overwrite)
		  (error ""))))
	  (error "Error writing dictionary. Dictionary %s NOT saved"
		 dictname))

	(setf (dictree-modified dict) nil))
      (delete-file tmpfile)
      (message "Writing dictionary %s to %s...done" dictname filename)
      t)  ; return t to indicate dictionary was successfully saved
    ))



(defun dictree-save-modified (&optional dict ask compilation force)
  "Save all modified dictionaries that have their autosave flag set.
Returns t if all dictionaries were successfully saved. Otherwise,
inform the user about the dictionaries which failed to save
properly, ask them whether they wish to continue anyway, and
return t or nil accordingly.

If optional argument DICT is a list of dictionaries or a single
dictionary, only save those.

If optional argument ASK is non-nil, ask for confirmation before
saving.

Optional argument COMPILATION determines whether to save the
dictionaries in compiled or uncompiled form. The default is to
save both forms. See `dictree-write'.

If optional argument FORCE is non-nil, save modified dictionaries
irrespective of their autosave flag.

Interactively, FORCE is the prefix argument, and the user will not be
asked whether they wish to continue after a failed save."
  (interactive "P")

  ;; sort out arguments.
  ;; Note: We use a lazy hack in the `interactive' form, and pass FORCE
  ;;       argument as DICT, which gets sorted out here.
  (when (and (called-interactively-p 'any) dict) (setq dict nil force t))
  (when (symbolp dict) (setq dict (symbol-value dict)))
  (cond
   ((dictree-p dict) (setq dict (list dict)))
   ((null dict) (setq dict dictree-loaded-list)))

  ;; For each dictionary in list / each loaded dictionary, check if
  ;; dictionary has been modified. If so, save it if autosave is set or
  ;; FORCE is non-nil.
  (let (save-failures)
    (dolist (dic dict)
      (when (and (dictree-modified dic)
		 (or force (dictree-autosave dic))
		 (or (not ask)
		     (y-or-n-p (format "Save modified dictionary %s? "
				       (dictree-filename dic)))))
	(condition-case nil
	    (progn
	      (dictree-save dic compilation)
	      (setf (dictree-modified dic) nil))
	  (error (push dic save-failures)))))

    ;; warn if dictionary saving failed
    (when save-failures
	(message (concat
		  "Error: failed to save the following modified "
		  "dictionaries: "
		  (mapconcat #'dictree-name save-failures ", ")))
	nil)  ; return nil to indicate failure
    t))  ; return t to indicate success


;; Add the dictree-save-modified function to the kill-emacs-hook to save
;; modified dictionaries when exiting emacs
(add-hook 'kill-emacs-query-functions #'dictree-save-modified)



;;;###autoload
(defun dictree-load (file)
  "Load a dictionary object from file FILE.
Returns the dictionary if successful, nil otherwise.

Interactively, FILE is read from the mini-buffer."
  (interactive (list (read-dict "Load dictionary from file: " nil nil t)))

  (cond
   ;; if we've be passed an already-loaded dictionary, just return it
   ((dictree-p file) file)
   ((and (symbolp file)
	 (condition-case nil
	     (dictree-p (symbol-value file))
	   (void-variable nil)))
    (symbol-value file))

   (t  ;; otherwise, load the dictionary
    (when (symbolp file) (setq file (symbol-name file)))
    (if (not (load file t))
	;; if loading failed, throw error interactively, return nil
	;; non-interactively
	(if (called-interactively-p 'any)
	    (error "Cannot load dictionary file: %s" file)
	  nil)

      (let* ((dictname (file-name-nondirectory (file-name-sans-extension file)))
	     (dict (symbol-value (intern-soft dictname))))
	(if (not (dictree-p dict))
	    ;; if loading failed, throw error interactively, return nil
	    ;; non-interactively
	    (if (called-interactively-p 'any)
		(error "Error loading dictionary from file: %s" file)
	      nil)
	  ;; return dictionary on sucess
	  (message (format "Loaded dictionary %s" dictname))
	  dict))))))


(defun dictree-unload (dict &optional dont-save)
  "Unload dictionary DICT.
If optional argument DONT-SAVE is non-nil, the dictionary will
NOT be saved even if its autosave flag is set.

Interactively, DICT is read from the mini-buffer, and DONT-SAVE
is the prefix argument."
  (interactive (list (read-dict "Dictionary: ")
		     current-prefix-arg))
  (when  (symbolp dict) (setq dict (symbol-value dict)))

  ;; possible save dictionary first
  (when (and (dictree-modified dict)
	     (null dont-save)
	     (or (eq (dictree-autosave dict) t)
		 (and (eq (dictree-autosave dict) 'ask)
		      (y-or-n-p
		       (format
			"Dictionary %s modified. Save before unloading? "
			(dictree-name dict))))))
    (dictree-save dict))

  ;; remove references to meta-dict from constituent dictionaries'
  ;; meta-dict-list cell
  (when (dictree--meta-dict-p dict)
    (mapc
     (lambda (dic)
       (setf (dictree--meta-dict-list dic)
	     (delq dict (dictree--meta-dict-list dic))))
     (dictree--meta-dict-dictlist dict)))

  ;; remove dictionary from list of loaded dictionaries and unload it
  (setq dictree-loaded-list (delq dict dictree-loaded-list))
  ;; used `unintern' here before, but that's too dangerous!
  (makunbound (intern (dictree-name dict)))
  (message "Dictionary %s unloaded" (dictree-name dict)))


(defun dictree-revert (dict)
  "Revert dictionary DICT to version from it associated file."
  (interactive (list (read-dict "Dictionary to revert: ")))

  (let ((filename (dictree-filename dict)))
    (when (and (dictree-modified dict)
	       (or (not (called-interactively-p 'any))
		   (yes-or-no-p
		    (format "Dictionary %s already loaded and has\
 unsaved changes. Revert from file %s? "
			    (dictree-name dict) filename))))
    (dictree-unload dict 'dont-save)
    (dictree-load filename))))



(defun dictree--write-dict-code (dict)
  ;; Write code for normal dictionary DICT to current buffer
  (let ((dictname (dictree-name dict))
	(tmpdict (dictree--copy dict))
	tmptrie hashcode)

    ;; --- convert trie data ---
    ;; if dictionary uses custom save functions, create a temporary writable
    ;; trie and generate code to convert it back to original form
    (if (or (dictree--data-savefun dict)
	    (dictree--plist-savefun dict))
	(setq tmptrie (dictree--generate-writable-trie dict)
	      hashcode (concat hashcode
			       (dictree--generate-triecode dict)))
      ;; otherwise, can use dictionary's trie directly
      (setq tmptrie (dictree--trie dict)))

    ;; hash tables have no read syntax in older Emacsen
    (unless (featurep 'hashtable-print-readable)
      (setq hashcode
	    (concat hashcode
		    (dictree--generate-dict-hashcode dict tmpdict))))

    ;; generate the structure to save
    (setf (dictree--trie tmpdict) tmptrie
	  (dictree--name tmpdict) dictname
	  (dictree--filename tmpdict) nil
	  (dictree--modified tmpdict) nil
	  (dictree--meta-dict-list tmpdict) nil)

    ;; write lisp code that generates the dictionary object
    (let ((print-circle t) (print-level nil) (print-length nil))
      (insert "(eval-when-compile (require 'cl))\n")
      (insert "(require 'dict-tree)\n")
      (insert "(defvar " dictname " nil \"Dictionary " dictname ".\")\n")
      (unwind-protect
	  (progn
	    ;; transform trie to print form
	    (trie-transform-for-print (dictree--trie tmpdict))
	    (insert "(setq " dictname)
	    (prin1 tmpdict (current-buffer))
	    (insert ")\n"))
	;; if dictionary doesn't use any custom save functions, tmpdict's trie
	;; is identical to original dict, so transform it back to usable form
	(unless (or (dictree--data-savefun dict)
		    (dictree--plist-savefun dict))
	  (trie-transform-from-read (dictree--trie tmpdict))))
      (insert "(trie-transform-from-read (dictree--trie " dictname "))\n"
 	      "(setf (dictree--filename " dictname ")\n"
	      "      (file-name-sans-extension load-file-name))\n")
      (when hashcode (insert hashcode))
      (insert "(unless (memq " dictname " dictree-loaded-list)\n"
	      "  (push " dictname " dictree-loaded-list))\n"))))


(defun dictree--write-meta-dict-code (dict)
  ;; Write code for meta-dictionary DICT to current buffer, giving it
  ;; the name DICTNAME and file FILENAME.
  (let ((dictname (dictree-name dict))
	(tmpdict (dictree--meta-dict-copy dict))
	hashcode)

    ;; hash tables have no read syntax in older Emacsen
    (unless (featurep 'hashtable-print-readable)
      (setq hashcode
	    (dictree--generate-meta-dict-hashcode dict tmpdict)))

    ;; generate the structure to save
    (setf (dictree--meta-dict-name tmpdict) dictname
	  (dictree--meta-dict-filename tmpdict) nil
	  (dictree--meta-dict-modified tmpdict) nil
	  (dictree--meta-dict-meta-dict-list tmpdict) nil
	  (dictree--meta-dict-dictlist tmpdict)
	    (mapcar (lambda (dic) (intern (dictree-name dic)))
		    (dictree--meta-dict-dictlist dict)))

    ;; write lisp code that generates the dictionary object
    (let ((print-circle t) (print-level nil) (print-length nil))
      (insert "(eval-when-compile (require 'cl))\n"
	      "(require 'dict-tree)\n")
      (mapc
       (lambda (dic)
	 (insert "(unless (dictree-load \"" (dictree-filename dic) "\")\n"
		 "        (error \"Failed to load dictionary "
		                  (dictree-name dic)
		                  " required by meta-dict "
		                  dictname "\"))\n"))
       (dictree--meta-dict-dictlist dict))
      (insert "(defvar " dictname " nil \"Dictionary " dictname ".\")\n"
	      "(setq " dictname " '")
      (prin1 tmpdict (current-buffer))
      (insert ")\n"
 	      "(setf (dictree--filename " dictname ")\n"
	      "      (file-name-sans-extension load-file-name))\n"
	      "(setf (dictree--meta-dict-dictlist " dictname ")\n"
	      "      (mapcar #'symbol-value (dictree--meta-dict-dictlist "
	                                     dictname ")))\n")
      (when hashcode (insert hashcode))
      (insert "(unless (memq " dictname " dictree-loaded-list)"
	      " (push " dictname " dictree-loaded-list))\n"))))



(defun dictree--generate-writable-trie (dict)
  ;; generate writable version of DICT's trie using DICT's data and plist save
  ;; functions
  (let ((trie
	 (trie-create-custom
	  (trie-comparison-function (dictree--trie dict))
	  :createfun (trie--createfun (dictree--trie dict))
	  :insertfun (trie--insertfun (dictree--trie dict))
	  :deletefun (trie--deletefun (dictree--trie dict))
	  :lookupfun (trie--lookupfun (dictree--trie dict))
	  :mapfun (trie--mapfun (dictree--trie dict))
	  :emptyfun (trie--emptyfun (dictree--trie dict))
	  :stack-createfun (trie--stack-createfun (dictree--trie dict))
	  :stack-popfun (trie--stack-popfun (dictree--trie dict))
	  :stack-emptyfun (trie--stack-emptyfun (dictree--trie dict)))))
    (trie-mapc
     (lambda (key cell)
       (trie-insert trie key
		    (dictree--cell-create
		     (funcall (or (dictree--data-savefun dict)
				  #'identity)
			      (dictree--cell-data cell))
		     (funcall (or (dictree--plist-savefun dict)
				  #'identity)
			      (dictree--cell-plist cell)))))
     (dictree--trie dict))
    trie))


(defun dictree--generate-triecode (dict)
  ;; generate code to convert writable trie back to original form using DICT's
  ;; data and plist load functions
  (let ((dictname (dictree-name dict)))
    (concat
     " (trie-map\n"
     "  (lambda (key cell)\n"
     "    (dictree--cell-create\n"
     (if (dictree--data-loadfun dict)
	 (concat
	  "(funcall (dictree--data-loadfun " dictname ")\n"
	  "         (dictree--cell-data cell))\n")
       "   (dictree--cell-data cell)\n")
     (if (dictree--plist-loadfun dict)
	 (concat
	  "(funcall (dictree--plist-loadfun " dictname ")\n"
	  "         (dictree--cell-plist cell))))\n")
       "   (dictree--cell-plist cell)))\n")
     "  (dictree--trie " dictname "))\n")))


(defun dictree--generate-dict-hashcode (dict tmpdict)
  ;; convert DICT's hash tables to alists stored in TMPDICT, and return code
  ;; to convert these back
  (let ((dictname (dictree-name dict))
	hashcode lookup-alist complete-alist regexp-alist
	fuzzy-match-alist fuzzy-complete-alist)

    ;; convert lookup cache hash table to alist, if it exists
    (when (dictree--lookup-cache dict)
      (maphash
       (lambda (key val)
	 (push
	  (cons key
		(cons (mapcar #'car (dictree--cache-results val))
		      (dictree--cache-maxnum val)))
	  lookup-alist))
       (dictree--lookup-cache dict))
      ;; generate code to reconstruct the lookup hash table
      (setq hashcode
	    (concat
	     hashcode
	     "(let ((lookup-cache (make-hash-table :test #'equal))\n"
	     "      (trie (dictree--trie " dictname ")))\n"
	     "  (mapc\n"
	     "   (lambda (entry)\n"
	     "     (puthash\n"
	     "      (car entry)\n"
	     "      (dictree--cache-create\n"
	     "       (mapcar\n"
	     "        (lambda (key)\n"
	     "          (cons key (trie-member trie key)))\n"
	     "        (dictree--cache-results (cdr entry)))\n"
	     "       (dictree--cache-maxnum (cdr entry)))\n"
	     "      lookup-cache))\n"
	     "   (dictree--lookup-cache " dictname "))\n"
	     "  (setf (dictree--lookup-cache " dictname ")\n"
	     "        lookup-cache))\n")))

    ;; convert query caches, if they exist
    (dolist (cache-details
	     '((dictree--complete-cache complete-alist)
	       (dictree--regexp-cache regexp-alist)
	       (dictree--fuzzy-match-cache fuzzy-match-alist)
	       (dictree--fuzzy-complete-cache fuzzy-complete-alist)))
      (when (funcall (nth 0 cache-details) dict)
	;; convert hash table to alist
	(set (nth 1 cache-details)
	     (let (alist)
	       (maphash
		(lambda (key val)
		  (push
		   (cons key
			 (cons
			  (mapcar #'car (dictree--cache-results val))
			  (dictree--cache-maxnum val)))
		   alist))
		(funcall (nth 0 cache-details) dict))
	       alist))
	;; generate code to reconstruct hash table from alist
	(setq hashcode
	      (concat
	       hashcode
	       "(let ((cache (make-hash-table :test #'equal))\n"
	       "      (trie (dictree--trie " dictname ")))\n"
	       "  (mapc\n"
	       "   (lambda (entry)\n"
	       "     (puthash\n"
	       "      (car entry)\n"
	       "      (dictree--cache-create\n"
	       "       (mapcar\n"
	       "        (lambda (key)\n"
	       "          (cons key\n"
	       "                (trie-member\n"
	       "                 trie (if (stringp key) key (car key)))))\n"
	       "        (dictree--cache-results (cdr entry)))\n"
	       "       (dictree--cache-maxnum (cdr entry)))\n"
	       "      cache))\n"
	       "   (" (symbol-name (nth 0 cache-details)) " " dictname "))\n"
	       "  (setf (" (symbol-name (nth 0 cache-details)) " " dictname ")\n"
	       "        cache))\n"))))

    ;; replace TMPDICT's caches with alists
    (setf (dictree--lookup-cache tmpdict)         lookup-alist
	  (dictree--complete-cache tmpdict)       complete-alist
	  (dictree--regexp-cache tmpdict)         regexp-alist
	  (dictree--fuzzy-match-cache tmpdict)    fuzzy-match-alist
	  (dictree--fuzzy-complete-cache tmpdict) fuzzy-complete-alist)
    ;; return generated conversion code
    hashcode))


(defun dictree--generate-meta-dict-hashcode (dict tmpdict)
  ;; hash tables have no read syntax in older Emacsen, so we convert
  ;; the dictionary caches to alists for writing
  (let ((dictname (dictree-name dict))
	hashcode lookup-alist complete-alist regexp-alist
	fuzzy-match-alist fuzzy-complete-alist)
    (when (dictree--meta-dict-lookup-cache dict)
      (maphash (lambda (key val)
		 (push (cons key (mapcar #'car val)) lookup-alist))
	       (dictree--meta-dict-lookup-cache dict))
      ;; generate code to reconstruct the lookup hash table
      (setq hashcode
	    (concat
	     hashcode
	     "(let ((cache (make-hash-table :test #'equal)))\n"
	     "  (mapc (lambda (entry)\n"
	     "    (puthash (car entry) (cdr entry) cache))\n"
	     "    (dictree--meta-dict-lookup-cache " dictname "))\n"
	     "  (setf (dictree--meta-dict-lookup-cache " dictname ")\n"
	     "        cache))\n")))

    ;; convert query caches, if they exist
    (dolist (cache-details
	     '((dictree--meta-dict-complete-cache       complete-alist)
	       (dictree--meta-dict-regexp-cache         regexp-alist)
	       (dictree--meta-dict-fuzzy-match-cache    fuzzy-match-alist)
	       (dictree--meta-dict-fuzzy-complete-cache fuzzy-complete-alist)))
      (when (funcall (nth 0 cache-details) dict)
	;; convert hash table to alist
	(set (nth 1 cache-details)
	     (let (alist)
	       (maphash (lambda (key val) (push (cons key val) alist))
			(funcall (nth 0 cache-details) dict))
	       alist))
	;; generate code to reconstruct hash table from alist
	(setq hashcode
	      (concat
	       hashcode
	       "(let ((cache (make-hash-table :test #'equal)))\n"
	       "  (mapc (lambda (entry)\n"
	       "    (puthash (car entry) (cdr entry) cache))\n"
	       "    (" (symbol-name (nth 0 cache-details)) " " dictname "))\n"
	       "  (setf (" (symbol-name (nth 0 cache-details)) " " dictname ")\n"
	       "        cache))\n"))))

    ;; replace TMPDICT's caches with alists
    (setf (dictree--lookup-cache tmpdict)         lookup-alist
	  (dictree--complete-cache tmpdict)       complete-alist
	  (dictree--regexp-cache tmpdict)         regexp-alist
	  (dictree--fuzzy-match-cache tmpdict)    fuzzy-match-alist
	  (dictree--fuzzy-complete-cache tmpdict) fuzzy-complete-alist)
    hashcode))




;; ----------------------------------------------------------------
;;                Dumping and restoring contents

(cl-defun dictree-populate-from-file
    (dict file
	  &key insert-function key-loadfun data-loadfun plist-loadfun
	  balance)
  "Populate dictionary DICT from the key list in file FILE.

Each line of FILE should contain a key, either a string
\(delimited by \"\), a vector, or a list. (Use the escape
sequence \\\" to include a \" in a string.) If a line does not
contain a key, it is silently ignored.

Each line can optionally include data and a property list (in
that order) to be associated with the key. If present, these
should separated from each other and the key by whitespace.

INSERT-FUNCTION, KEY-LOAD-FUNCTION, DATA-LOAD-FUNCTION and
PLIST-LOAD-FUNCTION override the corresponding default functions
for DICT (see `dictree-create').

Interactively, DICT and FILE are read from the mini-buffer.


Technicalities:

The key, data and property list are read as lisp expressions
using `read'. The keys will be read from FILE in order, unless
BALANCE is non-nil, in which case they are read from the median
element outwards (which can help ensure efficient data structures
are created when using a trie that is not self-balancing, see
`dictree-create')."
  (interactive (list (read-dict "Dictionary: ")
		     (read-file-name "File to populate from: "
				     nil "" t)))
  (when (symbolp dict) (setq dict (symbol-value dict)))
  (if (and (called-interactively-p 'any) (string= file ""))
      (message "No file specified; dictionary %s NOT populated"
	       (dictree-name dict))

    (unless (dictree--meta-dict-p dict)
      (unless key-loadfun
	(setq key-loadfun (dictree--key-loadfun dict)))
      (unless data-loadfun
	(setq data-loadfun (dictree--data-loadfun dict)))
      (unless plist-loadfun
	(setq plist-loadfun (dictree--plist-loadfun dict))))

    (save-excursion
      (let ((buff (find-file-noselect file)))
	(set-buffer buff)

	;; insert the keys starting from the median to ensure a
	;; reasonably well-balanced tree
	(let* ((lines (count-lines (point-min) (point-max)))
	       (midpt (+ (/ lines 2) (mod lines 2))))
	  (message "Inserting keys in %s...(1 of %d)" (dictree-name dict) lines)

	  ;; insert the median key and set the dictionary's modified flag
	  (cond
	   (balance
	    (dictree--goto-line midpt)
	    (dictree--populate dict midpt file
			       insert-function key-loadfun data-loadfun plist-loadfun)
	    ;; insert keys successively further away from the median in both directions
	    (dotimes (i (1- midpt))
	      (dictree--goto-line (+ midpt i 1))
	      (dictree--populate dict (+ midpt i 1) file
				 insert-function key-loadfun data-loadfun plist-loadfun)
	      (when (= 49 (mod i 50))
		(message "Inserting keys in %s...(%d of %d)"
			 (dictree-name dict) (+ (* 2 i) 2) lines))
	      (dictree--goto-line (- midpt i 1))
	      (dictree--populate dict (- midpt i 1) file
				 insert-function key-loadfun data-loadfun plist-loadfun))
	    ;; if inserting from mid-point out, and file contains an even
	    ;; number of keys, we still have to add the last one
	    (when (= 0 (mod lines 2))
	      (dictree--goto-line lines)
	      (dictree--populate dict lines file
				 insert-function key-loadfun data-loadfun plist-loadfun)))

	   (t
	    (goto-char (point-min))
	    (dotimes (i lines)
	      (dictree--populate dict (1+ i) file
				 insert-function key-loadfun data-loadfun plist-loadfun)
	      (when (= 49 (mod i 50))
		(message "Inserting keys in %s...(%d of %d)" (dictree-name dict) (1+ i) lines))
	      (forward-line 1)))
	   ))

	(message "Inserting keys in %s...done" (dictree-name dict))
	(kill-buffer buff)))))


(defun dictree--populate (dict &optional line file
			       insert-function key-loadfun data-loadfun plist-loadfun)
  ;; Read entry from current line of current buffer, and insert it in DICT.
  (pcase-let ((`(,key ,data ,plist)
               (dictree--read-line
                line file key-loadfun data-loadfun plist-loadfun)))
    ;; insert entry in DICT
    (dictree-insert dict key data insert-function)
    (setf (dictree--cell-plist (dictree--lookup dict key nil)) plist)))


(defun dictree--read-line
  (&optional line file key-loadfun data-loadfun plist-loadfun)
  ;; Return a list containing the key, data (if any, otherwise nil) and
  ;; property list (ditto) at the current line of the current buffer.
  (save-excursion
    (let (key data plist)
      ;; read key
      (beginning-of-line)
      (when (setq key (condition-case nil
			  (read (current-buffer))
			(error (error "Error reading key from line %d of %s"
				      line file))))
	(when key-loadfun
	  (setq key (condition-case nil
			(funcall key-loadfun key)
		      (error (error "Error calling KEY-LOADFUN on key read from line %d of %s"
				    line file)))))
	;; if there's anything after the key, use it as data
	(unless (eq (line-end-position) (point))
	  (setq data (condition-case nil
			 (read (current-buffer))
		       (error (error "Error reading data from line %d of %s"
				     line file)))))
	(when data-loadfun
	  (setq data
		(condition-case nil
		    (funcall data-loadfun data)
		  (error (error "Error calling DATA-LOADFUN on data read from line %d of %s"
				line file)))))
	;; if there's anything after the data, use it as the property list
	(unless (eq (line-end-position) (point))
	  (setq plist
		(condition-case nil
		    (read (current-buffer))
		  (error (error "Error reading plist from line %d of %s"
				line file)))))
	(when plist-loadfun
	  (setq plist
		(condition-case nil
		    (funcall plist-loadfun plist)
		  (error (error "Error calling PLIST-LOADFUN on plist read from line %d of %s"
				line file)))))

	;; sanity check what we read from file
	(if (symbolp key)
	    (setq key (symbol-name key))
	  (unless (or (vectorp key) (stringp key) (listp key))
	    (error "Invalid key at line %d of %s - must be string, vector, list or symbol"
		   line file)))
	(unless (and (listp plist) (cl-evenp (length plist)))
	  (error "Invalid plist at line %d of %s" line file))

	;; return what we've read
	(list key data plist)))))


(defun dictree-dump-to-buffer (dict &optional buffer type)
  "Dump keys and their associated data
from dictionary DICT to BUFFER, in the same format as that used
by `dictree-populate-from-file'. If BUFFER exists, data will be
appended to the end of it. Otherwise, a new buffer will be
created. If BUFFER is omitted, the current buffer is used.

TYPE determines the type of sequence to use to represent the
keys, and should be one of the symbols `string', `vector' or
`list'. The default is `vector'.

Note that if the data does not have a read syntax, the dumped
data can not be used to recreate the dictionary using
`dictree-populate-from-file'.

Interactively, DICT and BUFFER are read from the mini-buffer."
  (interactive (list (read-dict "Dictionary: ")
		     (read-buffer
		      "Buffer to dump to (defaults to current): "
		      (buffer-name (current-buffer)))
		     'vector))
  (when (symbolp dict) (setq dict (symbol-value dict)))

  ;; select the buffer, creating it if necessary
  (if buffer
      (setq buffer (get-buffer-create buffer))
    (setq buffer (current-buffer)))
  (set-buffer buffer)

  ;; move point to end of buffer and make sure it's at start of new line
  (goto-char (point-max))
  (unless (= (point) (line-beginning-position))
    (insert "\n"))

  ;; dump keys
  (message "Dumping keys from %s to %s..."
	   (dictree-name dict) (buffer-name buffer))
  (let ((count 0) (dictsize (dictree-size dict)))
    (message "Dumping keys from %s to %s...(key 1 of %d)"
	     (dictree-name dict) (buffer-name buffer) dictsize)

    ;; map dump function over dictionary
    (dictree--mapc
     (lambda (key data plist)
       (when (= 99 (mod count 100))
	 (message "Dumping keys from %s to %s...(key %d of %d)"
		  (dictree-name dict) (buffer-name buffer)
		  (1+ count) dictsize))
       (insert (prin1-to-string
		(funcall (or (dictree--key-savefun dict) #'identity)
			 key)))
       (when (setq data
		   (funcall (or (dictree--data-savefun dict) #'identity)
			    data))
	 (insert " " (prin1-to-string data)))
       (when (setq plist
		   (funcall (or (dictree--plist-savefun dict) #'identity)
			    plist))
	 (unless data (insert " nil"))
	 (insert " " (prin1-to-string plist)))
       (insert "\n")
       (setq count (1+ count)))
     dict type)  ; dictree--mapc target

    (message "Dumping keys from %s to %s...done"
	     (dictree-name dict) (buffer-name buffer)))
  (switch-to-buffer buffer))



(defun dictree-dump-to-file (dict filename &optional type overwrite)
  "Dump keys and their associated data
from dictionary DICT to a text file FILENAME, in the same format
as that used by `dictree-populate-from-file'. Prompts to overwrite
FILENAME if it already exists, unless OVERWRITE is non-nil.

TYPE determines the type of sequence to use to represent the
keys, and should be one of the symbols `string', `vector' or
`list'. The default is `vector'.

Note that if the data does not have a read syntax and no , the dumped
data can not be used to recreate the dictionary using
`dictree-populate-from-file'.

Interactively, DICT and FILE are read from the mini-buffer,
OVERWRITE is the prefix argument, and TYPE is always string."
  (interactive (list (read-dict "Dictionary: ")
		     (read-file-name "File to dump to: " nil "")))
  (when (symbolp dict) (setq dict (symbol-value dict)))

  (if (and (called-interactively-p 'any) (string= filename ""))
      (message "Dictionary %s NOT dumped" (dictree-name dict))

    ;; check if file exists, and prompt to overwrite it if necessary
    (if (and (file-exists-p filename)
	     (not overwrite)
	     (not (y-or-n-p
		   (format "File %s already exists. Overwrite? "
			   filename))))
	(message "Key dump cancelled")

      (let (buff)
	;; create temporary buffer, dump keys to it, and save to
	;; FILENAME
	(setq buff (generate-new-buffer filename))
	(save-window-excursion
	  (dictree-dump-to-buffer dict buff type)
	  (write-file filename))
	(kill-buffer buff)))))




;; ----------------------------------------------------------------
;;                     Minibuffer completion

(defvar dictree-history nil
  "History list for commands that read a dictionary name.")

(defvar dictree-loaded-history nil
  "History list for commands that read a loaded dictionary name.")


;;;###autoload
(defun read-dict
  (prompt &optional default dictlist allow-unloaded allow-unmatched)
  "Read the name of a dictionary with completion, and return it.

Prompt with PROMPT. By default, return DEFAULT. If DICTLIST is
supplied, only complete on dictionaries in that list.

If ALLOW-UNLOADED is non-nil, also complete on the names of
unloaded dictionaries (actually, on any Elisp file in the current
`load-path' restricted to subdirectories of your home directory
whose file name starts with \"dict-\"). If an unloaded dictionary
is read, the name of the Elisp file will be returned, without
extension, suitable for passing to `load-library'."

  (let (dictname paths)
    ;; when allowing unloaded dictionaries...
    (when allow-unloaded
      ;; get paths in load-path that are subdirectories of home
      ;; directory
      (dolist (d load-path)
	(when (eq (aref d 0) ?~) (push d paths)))
      ;; gather names of all Elisp libraries in this restricted
      ;; load-path
      (dolist (f (all-completions
		  "" (apply-partially #'locate-file-completion-table
				      paths (get-load-suffixes))))
	(when (and (null (file-name-directory f))
		   (and (> (length f) 5)
			(string= (substring f 0 5) "dict-"))
		   (null (file-name-extension f))
		   (not (member (file-name-sans-extension f) dictname)))
	  (push (file-name-sans-extension f) dictname))))
    ;; gather names of loaded dictionaries
    (mapc (lambda (dict)
	    (unless (or (null (dictree-name dict))
			(member (dictree-name dict) dictname))
	      (push (list (dictree-name dict)) dictname)))
	  (or dictlist dictree-loaded-list))
    ;; do completing-read
    (setq dictname (completing-read
		    prompt
		    (if allow-unmatched
			(completion-table-in-turn
			 dictname #'read-file-name-internal)
		      dictname)
		    nil (not allow-unmatched) nil
		    (if allow-unloaded
			'dictree-history
		      'dictree-loaded-history)
		    (and (dictree-p default) (dictree-name default))))
    ;; return dictionary
    (cond
     ;; if user typed a file name, return that
     ((and allow-unmatched (file-regular-p dictname)) dictname)
     ;; if user selected a loaded dictionary, return dict itself
     ((condition-case nil
	  (dictree-p (symbol-value (intern-soft dictname)))
	(void-variable nil))
      (intern-soft dictname))
     ;; if user selected an unloaded dictionary, return dict name
     ((and allow-unloaded (stringp dictname)) dictname)
     ;; if DEFAULT was specified, return that
     (default default)
     ;; should never get here!
     (t (error "Unknown error reading dictionary")))
    ))




;; ----------------------------------------------------------------
;;            Pretty-print dictionaries during edebug

;; We advise the `edebug-prin1' and `edebug-prin1-to-string' functions
;; (actually, aliases) so that they print "#<dict-tree NAME>" instead of
;; the full print form for dictionaries.
;;
;; This is because, if left to its own devices, edebug hangs for ages
;; whilst printing large dictionaries, and you either have to wait for a
;; *very* long time for it to finish, or kill Emacs entirely. (Even C-g
;; C-g fails!)
;;
;; We do this also for lists of dictionaries, since those occur quite
;; often, but not for other sequence types or deeper nested structures,
;; to keep the implementation as simple as possible.
;;
;; Since the print form of a dictionary is practically incomprehensible
;; anyway, we don't lose much by doing this. If you *really* want to
;; print dictionaries in full whilst edebugging, despite this warning,
;; disable the advice.

(defun dictree--prin1 (dict stream)
  (princ (concat "#<dict-tree \"" (dictree-name dict) "\""
		 (if (dictree--lookup-cache dict)
		     (concat " lookup "
			     (prin1-to-string
			      (hash-table-count
			       (dictree--lookup-cache dict))))
		   "")
		 (if (dictree--complete-cache dict)
		     (concat " complete "
			     (prin1-to-string
			      (hash-table-count
			       (dictree--complete-cache dict))))
		   "")
		 (if (dictree--regexp-cache dict)
		     (concat " regexp "
			     (prin1-to-string
			      (hash-table-count
			       (dictree--regexp-cache dict))))
		   "")
		 (if (dictree--fuzzy-match-cache dict)
		     (concat " fuzzy-match "
			     (prin1-to-string
			      (hash-table-count
			       (dictree--fuzzy-match-cache dict))))
		   "")
		 (if (dictree--fuzzy-complete-cache dict)
		     (concat " fuzzy-complete "
			     (prin1-to-string
			      (hash-table-count
			       (dictree--fuzzy-complete-cache dict))))
		   "")
		 ">")
	 stream))

(trie--if-when-compile (>= emacs-major-version 26)
    (progn
      (cl-defmethod cl-print-object ((object dictree-) stream)
        (dictree--prin1 object stream))
      (cl-defmethod cl-print-object ((object dictree--meta-dict) stream)
        (dictree--prin1 object stream)))

  (progn
    (defun dictree--edebug-pretty-print (object)
      (cond
       ((dictree-p object)
	(concat "#<dict-tree \"" (dictree-name object) "\""
		(if (dictree--lookup-cache object)
		    (concat " lookup "
			    (prin1-to-string
			     (hash-table-count
			      (dictree--lookup-cache object))))
		  "")
		(if (dictree--complete-cache object)
		    (concat " complete "
			    (prin1-to-string
			     (hash-table-count
			      (dictree--complete-cache object))))
		  "")
		(if (dictree--regexp-cache object)
		    (concat " regexp "
			    (prin1-to-string
			     (hash-table-count
			      (dictree--regexp-cache object))))
		  "")
		(if (dictree--fuzzy-match-cache object)
		    (concat " fuzzy-match "
			    (prin1-to-string
			     (hash-table-count
			      (dictree--fuzzy-match-cache object))))
		  "")
		(if (dictree--fuzzy-complete-cache object)
		    (concat " fuzzy-complete "
			    (prin1-to-string
			     (hash-table-count
			      (dictree--fuzzy-complete-cache object))))
		  "")
		">"))
       ((null object) "nil")
       ((let ((dlist object) (test t))
	  (while (or (dictree-p (car-safe dlist))
		     (and dlist (setq test nil)))
	    (setq dlist (cdr dlist)))
	  test)
	(concat "(" (mapconcat (lambda (d)
				 (concat "#<dict-tree \""
				         (dictree-name d) "\">"))
			       object " ")
		")"))
       ;; ((vectorp object)
       ;;  (let ((pretty "[") (len (length object)))
       ;;    (dotimes (i (1- len))
       ;; 	(setq pretty
       ;; 	      (concat pretty
       ;; 		      (if (trie-p (aref object i))
       ;; 			  "#<trie>" (prin1-to-string (aref object i))) " ")))
       ;;    (concat pretty
       ;; 	      (if (trie-p (aref object (1- len)))
       ;; 		  "#<trie>" (prin1-to-string (aref object (1- len))))
       ;; 	      "]")))
       ))

    (advice-add 'edebug-prin1 :around #'dictree--edebug-prin1)
    (defun dictree--edebug-prin1 (orig-fun object &optional printcharfun &rest args)
      (let ((pretty (dictree--edebug-pretty-print object)))
        (if pretty
	    (progn
	      (prin1 pretty printcharfun)
	      pretty)
	  (apply orig-fun object printcharfun args))))

    (when (fboundp 'ad-define-subr-args)
      (ad-define-subr-args 'edebug-prin1-to-string '(object &optional noescape)))

    (advice-add 'edebug-prin1-to-string
                :around #'dictree--edebug-prin1-to-string)
    (defun dictree--edebug-prin1-to-string (orig-fun object &rest args)
      (or (dictree--edebug-pretty-print object)
	  (apply orig-fun object args)))))


(provide 'dict-tree)

;;; dict-tree.el ends here
