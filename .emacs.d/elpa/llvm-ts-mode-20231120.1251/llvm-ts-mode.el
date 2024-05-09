;;; llvm-ts-mode.el --- LLVM major mode using tree-sitter -*- lexical-binding: t; -*-

;; Author: Noah Peart <noah.v.peart@gmail.com>
;; URL: https://github.com/nverno/llvm-ts-mode
;; Version: 0.0.1
;; Package-Requires: ((emacs "29.1"))
;; Created: 15 November 2023
;; Keywords: languages tree-sitter llvm

;; This file is not part of GNU Emacs.
;;
;; This program is free software; you can redistribute it and/or
;; modify it under the terms of the GNU General Public License as
;; published by the Free Software Foundation; either version 3, or
;; (at your option) any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
;; General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this program; see the file COPYING.  If not, write to
;; the Free Software Foundation, Inc., 51 Franklin Street, Fifth
;; Floor, Boston, MA 02110-1301, USA.

;;; Commentary:
;;
;; Major mode for LLVM using tree-sitter.
;;
;; Features:
;; - font-locking
;; - indentation
;; - structural navigation with tree-sitter objects
;; - imenu
;;
;;; Installation:
;;
;; Install the tree-sitter parser from
;; https://github.com/benwilliamgraham/tree-sitter-llvm.
;;
;;   (add-to-list 'treesit-language-source-alist
;;                '(llvm "https://github.com/benwilliamgraham/tree-sitter-llvm"))
;;   (treesit-install-language-grammar 'llvm)
;;
;;; Code:

(eval-when-compile (require 'cl-lib))
(require 'treesit)

(defcustom llvm-ts-mode-indent-level 2
  "Number of spaces for each indententation step."
  :group 'llvm
  :type 'integer
  :safe 'integerp)

(defcustom llvm-ts-mode-label-indent-level 0
  "Number of spaces to indent label."
  :group 'llvm
  :type 'integer
  :safe 'integerp)

(defcustom llvm-ts-mode-instruction-url
  "https://llvm.org/docs/LangRef.html#%s-instruction"
  "Url format string to lookup llvm instructions."
  :group 'llvm
  :type 'string
  :safe 'stringp)

(defface llvm-ts-mode-metadata-ref-face
  '((t (:inherit font-lock-preprocessor-face)))
  "Face to fontify metadata ref definitions in `llvm-ts-mode'."
  :group 'llvm)

(defface llvm-ts-mode-metadata-ref-use-face
  '((t (:inherit llvm-ts-mode-metadata-ref-face :italic t)))
  "Face to fontify metadata ref uses in `llvm-ts-mode'."
  :group 'llvm)

;;; Syntax

(defvar llvm-ts-mode--syntax-table
  (let ((table (make-syntax-table)))
    (modify-syntax-entry ?_ "_" table)
    (modify-syntax-entry ?+ "." table)
    (modify-syntax-entry ?- "." table)
    (modify-syntax-entry ?= "." table)
    (modify-syntax-entry ?% "'" table)
    (modify-syntax-entry ?@ "'" table)
    (modify-syntax-entry ?. "_" table)
    (modify-syntax-entry ?< "." table)
    (modify-syntax-entry ?> "." table)
    (modify-syntax-entry ?& "." table)
    (modify-syntax-entry ?| "." table)
    (modify-syntax-entry ?\240 "." table)
    (modify-syntax-entry ?\; "< " table)
    (modify-syntax-entry ?* "." table)
    (modify-syntax-entry ?: "." table)
    (modify-syntax-entry ?\n "> " table)
    (modify-syntax-entry ?$ "_" table)
    table)
  "Syntax table for `llvm-ts-mode'.")

;;; Indentation

(defvar llvm-ts-mode--indent-rules
  `((llvm
     ((parent-is "module") parent 0)
     ((node-is ")") parent-bol 0)
     ((node-is "}") parent-bol 0)
     ((node-is "]") parent-bol 0)
     ((node-is "label") column-0 llvm-ts-mode-label-indent-level)
     ((node-is "function_body") parent-bol 0)
     ((parent-is "struct_value") parent-bol llvm-ts-mode-indent-level)
     ((parent-is "struct_body") parent-bol llvm-ts-mode-indent-level)
     ((parent-is "function_body") parent-bol llvm-ts-mode-indent-level)
     ((parent-is "argument_list") parent-bol llvm-ts-mode-indent-level)
     (no-node parent-bol 0)
     (catch-all parent-bol llvm-ts-mode-indent-level)))
  "Tree-sitter indentation rules for `llvm-ts-mode'.")

;;; Font-Lock

(defvar llvm-ts-mode--feature-list
  '(( comment definition)
    ( keyword string)
    ( metadata type builtin variable function constant assignment)
    ( number operator bracket delimiter))
  "`treesit-font-lock-feature-list' for `llvm-ts-mode'.")

(defvar llvm-ts-mode--keywords
  '("addrspace" "alias" "align" "alignstack" "any" "asm" "atomic" "attributes"
    "bitcast" "blockaddress" "caller" "catch" "cleanup" "comdat" "constant"
    "datalayout" "declare" "define" "distinct" "exact" "exactmatch"
    "externally_initialized" "filter" "from" "global" "ifunc" "inbounds"
    "inrange" "inteldialect" "largest" "metadata" "module" "nodeduplicate" "nsw"
    "nuw" "partition" "personality" "ret" "samesize" "section" "sideeffect"
    "source_filename" "swifterror" "syncscope" "tail" "target" "to" "triple"
    "type" "unordered" "unwind" "unwind" "uselistorder" "uselistorder_bb"
    "volatile" "vscale" "within")
  "LLVM keywords for tree-sitter font-locking.")

(defvar llvm-ts-mode--font-lock-settings
  (treesit-font-lock-rules
   :language 'llvm
   :feature 'comment
   '((comment) @font-lock-comment-face)

   :language 'llvm
   :feature 'string
   '([(cstring) (string)] @font-lock-string-face)

   :language 'llvm
   :feature 'keyword
   `([,@llvm-ts-mode--keywords
      (atomic_ordering) (atomic_bin_op_keyword)
      (icmp_cond) (fcmp_cond) (fast_math) (calling_conv)]
     @font-lock-keyword-face)

   :language 'llvm
   :feature 'builtin
   `(["undef" "poison" "none" "zeroinitializer"] @font-lock-builtin-face)
   
   :language 'llvm
   :feature 'definition
   '((function_header
      name: _ @font-lock-function-name-face
      arguments: (argument_list
                  (argument (value) @font-lock-variable-name-face) :*))
     
     (global_type (local_var) @font-lock-variable-name-face)
     (global_global (global_var) @font-lock-variable-name-face)

     (global_metadata (metadata_ref) @llvm-ts-mode-metadata-ref-face)
     (summary_entry (summary_ref) @llvm-ts-mode-metadata-ref-face)
     (comdat (comdat_ref) @font-lock-variable-name-face)
     
     (instruction (local_var) @font-lock-variable-name-face)

     (attribute_name) @font-lock-type-face
     (attr_ref) @font-lock-preprocessor-face
     
     (label) @font-lock-preprocessor-face)

   :language 'llvm
   :feature 'type
   '((type _ @font-lock-type-face "*" @font-lock-operator-face :*)

     ["no_cfi" "thread_local" "localdynamic" "initialexec" "localexec"
      (dso_local) (linkage_aux) (visibility) (unnamed_addr) (dll_storage_class)]
     @font-lock-type-face)
   
   :language 'llvm
   :feature 'metadata
   '([;; !ref '(' (specialized_md_value): ... ')'
      ((specialized_md_value) @font-lock-property-name-face
       :anchor
       (specialized_md_value ":") @font-lock-delimiter-face)
       
      ;; !ref '(' key: <VAL> ')'
      ((specialized_md_value "<" _ ">") @font-lock-string-face)
      ((specialized_md_value (type_keyword) @font-lock-type-face))]
       
     [(metadata_name) (metadata_ref) "!"] @llvm-ts-mode-metadata-ref-use-face

     ;; Summaries
     ;; (summary_entry '(' (summary_value): ... ')'
     [((summary_value) @font-lock-property-name-face
       :anchor
       (summary_value ":") @font-lock-delimiter-face)]

     (summary_ref) @llvm-ts-mode-metadata-ref-use-face)
     
   :language 'llvm
   :feature 'constant
   '(["true" "false" "null"] @font-lock-constant-face)

   :language 'llvm
   :feature 'function
   '((_ callee: _ @font-lock-function-call-face)
     (ifunc (global_var) @font-lock-function-call-face))

   :language 'llvm
   :feature 'assignment
   '((instruction (local_var) @font-lock-variable-name-face))
   
   :language 'llvm
   :feature 'variable
   '([(local_var) (global_var) (comdat_ref)] @font-lock-variable-use-face)
   
   :language 'llvm
   :feature 'number
   '([(float) (number)] @font-lock-number-face)

   :language 'llvm
   :feature 'operator
   '(["=" "|" "x" "..." "*" "!"] @font-lock-operator-face
     (_ inst_name: _ @font-lock-operator-face))

   :language 'llvm
   :feature 'delimiter
   '(["," ":"] @font-lock-delimiter-face)

   :language 'llvm
   :feature 'bracket
   '(["(" ")" "{" "}" "[" "]" "<" ">" "<{" "}>"] @font-lock-bracket-face)

   :language 'llvm
   :feature 'error
   '((ERROR) @font-lock-warning-face))
  "Tree-sitter font-lock settings for LLVM.")

;;; Navigation

(defun llvm-ts-mode--defun-name (node)
  "Find name of NODE."
  (treesit-node-text
   (pcase (treesit-node-type node)
     ((or "global_type"
          "global_global"
          "global_metadata"
          "summary_entry")
      (treesit-node-child node 0))
     ("unnamed_attr_grp"
      (treesit-node-child node 0 t))
     ("function_header"
      (treesit-node-child-by-field-name node "name"))
     (_ node))))

(defvar llvm-ts-mode--sentence-nodes
  (rx (or "define"
          "declare"
          "target_definition"
          "instruction"
          "unnamed_attr_grp"
          "use_list_order"
          "module_asm"
          "summary_entry"
          "source_file_name"
          "comdat"
          "ifunc"
          "alias"
          (seq "global_" (or "global" "metadata" "type"))))
  "See `treesit-sentence-type-regexp' for more information.")

(defvar llvm-ts-mode--sexp-nodes nil
  "See `treesit-sexp-type-regexp' for more information.")

(defvar llvm-ts-mode--text-nodes
  (rx (or "string" "comment" "cstring"))
  "See `treesit-text-type-regexp' for more information.")

;;; Imenu

(defun llvm-ts-mode--valid-imenu-p (node)
  "Return non-nil if NODE is a valid imenu entry."
  (pcase (treesit-node-type node)
    ("label" (treesit-node-match-p (treesit-node-parent node) "function_body"))
    (_ t)))

;;; Help

(defun llvm-ts-mode-lookup-instruction (instr)
  "Lookup help for INSTR, defaulting to thing at point, in online manual.
With prefix, query for INSTR."
  (interactive
   (list (or (and (not current-prefix-arg) (thing-at-point 'symbol))
             (read-from-minibuffer "Lookup instruction: "))))
  (browse-url (format llvm-ts-mode-instruction-url instr)))

;;; Keymap

(defvar-keymap llvm-ts-mode-map
  :doc "Keymap used in `llvm-ts-mode'."
  "C-c C-d" #'llvm-ts-mode-lookup-instruction)

;;;###autoload
(define-derived-mode llvm-ts-mode prog-mode "LLVM"
  "Major mode for editing LLVM source code.

\\<llvm-ts-mode-map>"
  :group 'llvm
  :syntax-table llvm-ts-mode--syntax-table
  (when (treesit-ready-p 'llvm)
    (treesit-parser-create 'llvm)

    ;; Comments
    (setq-local comment-start "; ")
    (setq-local comment-end "")
    (setq-local comment-add 1)
    (setq-local comment-start-skip ";+[ \t]*")
    (setq-local parse-sexp-ignore-comments t)

    ;; Indentation
    (setq-local treesit-simple-indent-rules llvm-ts-mode--indent-rules)

    ;; Font-Locking
    (setq-local treesit-font-lock-settings llvm-ts-mode--font-lock-settings)
    (setq-local treesit-font-lock-feature-list llvm-ts-mode--feature-list)

    ;; Navigation
    (setq-local treesit-defun-tactic 'top-level)
    (setq-local treesit-defun-name-function #'llvm-ts-mode--defun-name)
    (setq-local treesit-defun-type-regexp
                (rx (or "define"
                        "declare"
                        "global_type"
                        "global_global"
                        "global_metadata"
                        "summary_entry")))

    (setq-local treesit-thing-settings
                `((llvm
                   (sexp ,llvm-ts-mode--sexp-nodes)
                   (sentence ,llvm-ts-mode--sentence-nodes)
                   (text ,llvm-ts-mode--text-nodes))))

    ;; Imenu
    (setq-local treesit-simple-imenu-settings
                `(("Function" "\\`function_header\\'")
                  ("Global" "\\`global_global\\'")
                  ("Metadata" "\\`global_metadata\\'")
                  ("Summary" "\\`summary_entry\\'")
                  ("Attribute" "\\`unnamed_attr_grp\\'")
                  ;; ("Alias" "\\`alias\\'")
                  ("Type" "\\`global_type\\'")))
    ;; ("Label" "\\`label\\'" llvm-ts-mode--valid-imenu-p)

    (treesit-major-mode-setup)))

(when (treesit-ready-p 'llvm)
  (add-to-list 'auto-mode-alist '("\\.ll\\'" . llvm-ts-mode)))

(provide 'llvm-ts-mode)
;; Local Variables:
;; coding: utf-8
;; indent-tabs-mode: nil
;; End:
;;; llvm-ts-mode.el ends here
