;;; org-jira-autoloads.el --- automatically extracted autoloads
;;
;;; Code:
(add-to-list 'load-path (directory-file-name (or (file-name-directory #$) (car load-path))))

;;;### (autoloads nil "jiralib" "jiralib.el" (0 0 0 0))
;;; Generated autoloads from jiralib.el

(if (fboundp 'register-definition-prefixes) (register-definition-prefixes "jiralib" '("jiralib-")))

;;;***

;;;### (autoloads nil "org-jira" "org-jira.el" (0 0 0 0))
;;; Generated autoloads from org-jira.el

(autoload 'org-jira-mode "org-jira" "\
Toggle org-jira mode.
With no argument, the mode is toggled on/off.
Non-nil argument turns mode on.
Nil argument turns mode off.

Commands:
\\{org-jira-entry-mode-map}

Entry to this mode calls the value of `org-jira-mode-hook'.

\(fn &optional ARG)" t nil)

(autoload 'org-jira-get-projects "org-jira" "\
Get list of projects.

\(fn)" t nil)

(autoload 'org-jira-get-issues-headonly "org-jira" "\
Get list of ISSUES, head only.

The default behavior is to return issues assigned to you and unresolved.

With a prefix argument, allow you to customize the jql.  See
`org-jira-get-issue-list'.

\(fn ISSUES)" t nil)

(autoload 'org-jira-get-issue "org-jira" "\
Get a JIRA issue, allowing you to enter the issue-id first.

\(fn)" t nil)

(autoload 'org-jira-get-issues "org-jira" "\
Get list of ISSUES into an org buffer.

Default is get unfinished issues assigned to you, but you can
customize jql with a prefix argument.
See`org-jira-get-issue-list'

\(fn ISSUES)" t nil)

(autoload 'org-jira-update-comment "org-jira" "\
Update a comment for the current issue.

\(fn)" t nil)

(autoload 'org-jira-copy-current-issue-key "org-jira" "\
Copy the current issue's key into clipboard.

\(fn)" t nil)

(autoload 'org-jira-update-issue "org-jira" "\
Update an issue.

\(fn)" t nil)

(autoload 'org-jira-todo-to-jira "org-jira" "\
Convert an ordinary todo item to a jira ticket.

\(fn)" t nil)

(autoload 'org-jira-get-subtasks "org-jira" "\
Get subtasks for the current issue.

\(fn)" t nil)

(autoload 'org-jira-create-issue "org-jira" "\
Create an issue in PROJECT, of type TYPE, with given SUMMARY and DESCRIPTION.

\(fn PROJECT TYPE SUMMARY DESCRIPTION)" t nil)

(autoload 'org-jira-create-subtask "org-jira" "\
Create a subtask issue for PROJECT, of TYPE, with SUMMARY and DESCRIPTION.

\(fn PROJECT TYPE SUMMARY DESCRIPTION)" t nil)

(autoload 'org-jira-refresh-issue "org-jira" "\
Refresh issue from jira to org.

\(fn)" t nil)

(autoload 'org-jira-progress-issue "org-jira" "\
Progress issue workflow.

\(fn)" t nil)

(autoload 'org-jira-browse-issue "org-jira" "\
Open the current issue in external browser.

\(fn)" t nil)

(autoload 'org-jira-get-issues-from-filter "org-jira" "\
Get issues from the server-side stored filter named FILTER.

Provide this command in case some users are not able to use
client side jql (maybe because of JIRA server version?).

\(fn FILTER)" t nil)

(autoload 'org-jira-get-issues-from-filter-headonly "org-jira" "\
Get issues *head only* from saved filter named FILTER.
See `org-jira-get-issues-from-filter'.

\(fn FILTER)" t nil)

(if (fboundp 'register-definition-prefixes) (register-definition-prefixes "org-jira" '("org-jira-" "ensure-on-" "jira-users")))

;;;***

;;;### (autoloads nil nil ("org-jira-pkg.el") (0 0 0 0))

;;;***

;; Local Variables:
;; version-control: never
;; no-byte-compile: t
;; no-update-autoloads: t
;; End:
;;; org-jira-autoloads.el ends here
