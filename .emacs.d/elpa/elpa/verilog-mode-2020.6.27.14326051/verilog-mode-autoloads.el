;;; verilog-mode-autoloads.el --- automatically extracted autoloads
;;
;;; Code:

(add-to-list 'load-path (directory-file-name
                         (or (file-name-directory #$) (car load-path))))


;;;### (autoloads nil "verilog-mode" "verilog-mode.el" (0 0 0 0))
;;; Generated autoloads from verilog-mode.el

(autoload 'verilog-mode "verilog-mode" "\
Major mode for editing Verilog code.
\\<verilog-mode-map>
See \\[describe-function] verilog-auto (\\[verilog-auto]) for details on how
AUTOs can improve coding efficiency.

Use \\[verilog-faq] for a pointer to frequently asked questions.

NEWLINE, TAB indents for Verilog code.
Delete converts tabs to spaces as it moves back.

Supports highlighting.

Turning on Verilog mode calls the value of the variable `verilog-mode-hook'
with no args, if that value is non-nil.

Variables controlling indentation/edit style:

 variable `verilog-indent-level'      (default 3)
   Indentation of Verilog statements with respect to containing block.
 `verilog-indent-level-module'        (default 3)
   Absolute indentation of Module level Verilog statements.
   Set to 0 to get initial and always statements lined up
   on the left side of your screen.
 `verilog-indent-level-declaration'   (default 3)
   Indentation of declarations with respect to containing block.
   Set to 0 to get them list right under containing block.
 `verilog-indent-level-behavioral'    (default 3)
   Indentation of first begin in a task or function block
   Set to 0 to get such code to lined up underneath the task or
   function keyword.
 `verilog-indent-level-directive'     (default 1)
   Indentation of \\=`ifdef/\\=`endif blocks.
 `verilog-cexp-indent'              (default 1)
   Indentation of Verilog statements broken across lines i.e.:
      if (a)
        begin
 `verilog-case-indent'              (default 2)
   Indentation for case statements.
 `verilog-auto-newline'             (default nil)
   Non-nil means automatically newline after semicolons and the punctuation
   mark after an end.
 `verilog-auto-indent-on-newline'   (default t)
   Non-nil means automatically indent line after newline.
 `verilog-tab-always-indent'        (default t)
   Non-nil means TAB in Verilog mode should always reindent the current line,
   regardless of where in the line point is when the TAB command is used.
 `verilog-indent-begin-after-if'    (default t)
   Non-nil means to indent begin statements following a preceding
   if, else, while, for and repeat statements, if any.  Otherwise,
   the begin is lined up with the preceding token.  If t, you get:
      if (a)
         begin // amount of indent based on `verilog-cexp-indent'
   otherwise you get:
      if (a)
      begin
 `verilog-auto-endcomments'         (default t)
   Non-nil means a comment /* ... */ is set after the ends which ends
   cases, tasks, functions and modules.
   The type and name of the object will be set between the braces.
 `verilog-minimum-comment-distance' (default 10)
   Minimum distance (in lines) between begin and end required before a comment
   will be inserted.  Setting this variable to zero results in every
   end acquiring a comment; the default avoids too many redundant
   comments in tight quarters.
 `verilog-auto-lineup'              (default `declarations')
   List of contexts where auto lineup of code should be done.

Variables controlling other actions:

 `verilog-linter'                   (default `none')
   Unix program to call to run the lint checker.  This is the default
   command for \\[compile-command] and \\[verilog-auto-save-compile].

See \\[customize] for the complete list of variables.

AUTO expansion functions are, in part:

    \\[verilog-auto]  Expand AUTO statements.
    \\[verilog-delete-auto]  Remove the AUTOs.
    \\[verilog-inject-auto]  Insert AUTOs for the first time.

Some other functions are:

    \\[completion-at-point]    Complete word with appropriate possibilities.
    \\[verilog-mark-defun]  Mark function.
    \\[verilog-beg-of-defun]  Move to beginning of current function.
    \\[verilog-end-of-defun]  Move to end of current function.
    \\[verilog-label-be]  Label matching begin ... end, fork ... join, etc statements.

    \\[verilog-comment-region]  Put marked area in a comment.
    \\[verilog-uncomment-region]  Uncomment an area commented with \\[verilog-comment-region].
    \\[verilog-insert-block]  Insert begin ... end.
    \\[verilog-star-comment]    Insert /* ... */.

    \\[verilog-sk-always]  Insert an always @(AS) begin .. end block.
    \\[verilog-sk-begin]  Insert a begin .. end block.
    \\[verilog-sk-case]  Insert a case block, prompting for details.
    \\[verilog-sk-for]  Insert a for (...) begin .. end block, prompting for details.
    \\[verilog-sk-generate]  Insert a generate .. endgenerate block.
    \\[verilog-sk-header]  Insert a header block at the top of file.
    \\[verilog-sk-initial]  Insert an initial begin .. end block.
    \\[verilog-sk-fork]  Insert a fork begin .. end .. join block.
    \\[verilog-sk-module]  Insert a module .. (/*AUTOARG*/);.. endmodule block.
    \\[verilog-sk-ovm-class]  Insert an OVM Class block.
    \\[verilog-sk-uvm-object]  Insert an UVM Object block.
    \\[verilog-sk-uvm-component]  Insert an UVM Component block.
    \\[verilog-sk-primitive]  Insert a primitive .. (.. );.. endprimitive block.
    \\[verilog-sk-repeat]  Insert a repeat (..) begin .. end block.
    \\[verilog-sk-specify]  Insert a specify .. endspecify block.
    \\[verilog-sk-task]  Insert a task .. begin .. end endtask block.
    \\[verilog-sk-while]  Insert a while (...) begin .. end block, prompting for details.
    \\[verilog-sk-casex]  Insert a casex (...) item: begin.. end endcase block, prompting for details.
    \\[verilog-sk-casez]  Insert a casez (...) item: begin.. end endcase block, prompting for details.
    \\[verilog-sk-if]  Insert an if (..) begin .. end block.
    \\[verilog-sk-else-if]  Insert an else if (..) begin .. end block.
    \\[verilog-sk-comment]  Insert a comment block.
    \\[verilog-sk-assign]  Insert an assign .. = ..; statement.
    \\[verilog-sk-function]  Insert a function .. begin .. end endfunction block.
    \\[verilog-sk-input]  Insert an input declaration, prompting for details.
    \\[verilog-sk-output]  Insert an output declaration, prompting for details.
    \\[verilog-sk-state-machine]  Insert a state machine definition, prompting for details.
    \\[verilog-sk-inout]  Insert an inout declaration, prompting for details.
    \\[verilog-sk-wire]  Insert a wire declaration, prompting for details.
    \\[verilog-sk-reg]  Insert a register declaration, prompting for details.
    \\[verilog-sk-define-signal]  Define signal under point as a register at the top of the module.

All key bindings can be seen in a Verilog-buffer with \\[describe-bindings].
Key bindings specific to `verilog-mode-map' are:

\\{verilog-mode-map}

\(fn)" t nil)

(register-definition-prefixes "verilog-mode" '("electric-verilog-" "verilog-" "vl-"))

;;;***

;; Local Variables:
;; version-control: never
;; no-byte-compile: t
;; no-update-autoloads: t
;; coding: utf-8
;; End:
;;; verilog-mode-autoloads.el ends here
