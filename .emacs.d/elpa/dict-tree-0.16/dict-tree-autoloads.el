;;; dict-tree-autoloads.el --- automatically extracted autoloads  -*- lexical-binding: t -*-
;;
;;; Code:

(add-to-list 'load-path (directory-file-name
                         (or (file-name-directory #$) (car load-path))))


;;;### (autoloads nil "dict-tree" "dict-tree.el" (0 0 0 0))
;;; Generated autoloads from dict-tree.el

(autoload 'make-dictree "dict-tree" "\
Create an empty dictionary and return it.

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
contained by the sequences used as keys (e.g. if the keys will
be strings, the function will be passed two characters). It
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
the data (which is not very useful, since an unranked
`dictree-complete' query already does this much more
efficiently).

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
than the :short value (since short strings are likely to be the
slower ones for those cases).

The `time-and-length' setting only caches results if both
conditions are satisfied simultaneously, whereas the
`time-or-length' setting caches results if either condition is
satisfied. For these settings, CACHE-THRESHOLD must be a plist
with properties :time, :long and :short, specifying the
corresponding cache thresholds.

CACHE-THRESHOLD defaults to nil. The values nil and t are
special. If CACHE-THRESHOLD is set to nil, no caching is done. If
it is t, everything is cached for that type of query (similar
behaviour can be obtained by setting the a `time' CACHE-THRESHOLD
of 0, but it is better to use t).

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
used when dumping the contents of the dictionary (see
`dictree-dump-to-buffer' and `dictree-dump-to-file').
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
structure. See `trie-create' for details.

\(fn &optional NAME FILENAME AUTOSAVE UNLISTED COMPARISON-FUNCTION INSERT-FUNCTION RANK-FUNCTION CACHE-POLICY CACHE-THRESHOLD CACHE-UPDATE-POLICY KEY-SAVEFUN KEY-LOADFUN DATA-SAVEFUN DATA-LOADFUN PLIST-SAVEFUN PLIST-LOADFUN TRIE-TYPE)" nil nil)

(defalias 'dictree-create 'make-dictree)

(autoload 'make-dictree-custom "dict-tree" "\
Create an empty dictionary and return it.

The NAME through PLIST-LOADFUN arguments are as for
`dictree-create' (which see).

The remaining arguments control the type of trie to use as the
underlying data structure. See `trie-create' for details.

\(fn &optional NAME FILENAME AUTOSAVE UNLISTED &key COMPARISON-FUNCTION INSERT-FUNCTION RANK-FUNCTION CACHE-POLICY CACHE-THRESHOLD CACHE-UPDATE-POLICY KEY-SAVEFUN KEY-LOADFUN DATA-SAVEFUN DATA-LOADFUN PLIST-SAVEFUN PLIST-LOADFUN CREATEFUN INSERTFUN DELETEFUN LOOKUPFUN MAPFUN EMPTYFUN STACK-CREATEFUN STACK-POPFUN STACK-EMPTYFUN TRANSFORM-FOR-PRINT TRANSFORM-FROM-READ)" nil nil)

(defalias 'dictree-create-custom 'make-dictree-custom)

(autoload 'make-dictree-meta-dict "dict-tree" "\
Create a meta-dictionary based on the list of dictionaries
in DICTIONARY-LIST.

COMBINE-FUNCTION is used to combine data from different
dictionaries. It is passed two pieces of data, each an
association of the same key, but in different dictionaries. It
should return a combined datum.

The other arguments are as for `dictree-create'. Note that
caching is only possible if NAME is supplied, otherwise the
CACHE-THRESHOLD argument is ignored and caching is disabled.

\(fn DICTIONARY-LIST &optional NAME FILENAME AUTOSAVE UNLISTED COMBINE-FUNCTION CACHE-POLICY CACHE-THRESHOLD CACHE-UPDATE-POLICY)" nil nil)

(autoload 'dictree-p "dict-tree" "\
Return t if OBJ is a dictionary tree, nil otherwise.

\(fn OBJ)" nil nil)

(autoload 'dictree-load "dict-tree" "\
Load a dictionary object from file FILE.
Returns the dictionary if successful, nil otherwise.

Interactively, FILE is read from the mini-buffer.

\(fn FILE)" t nil)

(autoload 'read-dict "dict-tree" "\
Read the name of a dictionary with completion, and return it.

Prompt with PROMPT. By default, return DEFAULT. If DICTLIST is
supplied, only complete on dictionaries in that list.

If ALLOW-UNLOADED is non-nil, also complete on the names of
unloaded dictionaries (actually, on any Elisp file in the current
`load-path' restricted to subdirectories of your home directory
whose file name starts with \"dict-\"). If an unloaded dictionary
is read, the name of the Elisp file will be returned, without
extension, suitable for passing to `load-library'.

\(fn PROMPT &optional DEFAULT DICTLIST ALLOW-UNLOADED ALLOW-UNMATCHED)" nil nil)

(register-definition-prefixes "dict-tree" '("dictree-"))

;;;***

;;;### (autoloads nil nil ("dict-tree-pkg.el") (0 0 0 0))

;;;***

;; Local Variables:
;; version-control: never
;; no-byte-compile: t
;; no-update-autoloads: t
;; coding: utf-8
;; End:
;;; dict-tree-autoloads.el ends here
