;;; nrepl-client.el --- Client for Clojure nREPL -*- lexical-binding: t -*-

;; Copyright © 2012-2013 Tim King, Phil Hagelberg, Bozhidar Batsov
;; Copyright © 2013-2022 Bozhidar Batsov, Artur Malabarba and CIDER contributors
;;
;; Author: Tim King <kingtim@gmail.com>
;;         Phil Hagelberg <technomancy@gmail.com>
;;         Bozhidar Batsov <bozhidar@batsov.dev>
;;         Artur Malabarba <bruce.connor.am@gmail.com>
;;         Hugo Duncan <hugo@hugoduncan.org>
;;         Steve Purcell <steve@sanityinc.com>
;;         Reid McKenzie <me@arrdem.com>
;;
;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.
;;
;; This file is not part of GNU Emacs.
;;
;;; Commentary:
;;
;; Provides an Emacs Lisp client to connect to Clojure nREPL servers.
;;
;; A connection is an abstract idea of the communication between Emacs (client)
;; and nREPL server.  On the Emacs side connections are represented by two
;; running processes.  The two processes are the server process and client
;; process (the connection to the server).  Each of these is represented by its
;; own process buffer, filter and sentinel.
;;
;; The nREPL communication process can be broadly represented as follows:
;;
;;    1) The server process is started as an Emacs subprocess (usually by
;;       `cider-jack-in', which in turn fires up an nREPL server).  Note that
;;       if a connection was established using `cider-connect' there won't be
;;       a server process.
;;
;;    2) The server's process filter (`nrepl-server-filter') detects the
;;       connection port from the first plain text response from the server and
;;       starts a communication process (socket connection) as another Emacs
;;       subprocess.  This is the nREPL client process (`nrepl-client-filter').
;;       All requests and responses handling happens through this client
;;       connection.
;;
;;    3) Requests are sent by `nrepl-send-request' and
;;       `nrepl-send-sync-request'.  A request is simply a list containing a
;;       requested operation name and the parameters required by the
;;       operation.  Each request has an associated callback that is called once
;;       the response for the request has arrived.  Besides the above functions
;;       there are specialized request senders for each type of common
;;       operations.  Examples are `nrepl-request:eval', `nrepl-request:clone',
;;       `nrepl-sync-request:describe'.
;;
;;    4) Responses from the server are decoded in `nrepl-client-filter' and are
;;       physically represented by alists whose structure depends on the type of
;;       the response.  After having been decoded, the data from the response is
;;       passed over to the callback that was registered by the original
;;       request.
;;
;; Please see the comments in dedicated sections of this file for more detailed
;; description.

;;; Code:
(require 'seq)
(require 'subr-x)
(require 'cl-lib)
(require 'nrepl-dict)
(require 'queue)
(require 'sesman)
(require 'tramp)


;;; Custom

(defgroup nrepl nil
  "Interaction with the Clojure nREPL Server."
  :prefix "nrepl-"
  :group 'applications)

;; (defcustom nrepl-buffer-name-separator " "
;;   "Used in constructing the REPL buffer name.
;; The `nrepl-buffer-name-separator' separates cider-repl from the project name."
;;   :type '(string)
;;   :group 'nrepl)
(make-obsolete-variable 'nrepl-buffer-name-separator 'cider-session-name-template "0.18")

;; (defcustom nrepl-buffer-name-show-port nil
;;   "Show the connection port in the nrepl REPL buffer name, if set to t."
;;   :type 'boolean
;;   :group 'nrepl)
(make-obsolete-variable 'nrepl-buffer-name-show-port 'cider-session-name-template "0.18")

(defcustom nrepl-connected-hook nil
  "List of functions to call when connecting to the nREPL server."
  :type 'hook)

(defcustom nrepl-disconnected-hook nil
  "List of functions to call when disconnected from the nREPL server."
  :type 'hook)

(defcustom nrepl-force-ssh-for-remote-hosts nil
  "If non-nil, do not attempt a direct connection for remote hosts."
  :type 'boolean)

(defcustom nrepl-use-ssh-fallback-for-remote-hosts nil
  "If non-nil, Use ssh as a fallback to connect to remote hosts.
It will attempt to connect via ssh to remote hosts when unable to connect
directly."
  :type 'boolean)

(defcustom nrepl-sync-request-timeout 10
  "The number of seconds to wait for a sync response.
Setting this to nil disables the timeout functionality."
  :type 'integer)

(defcustom nrepl-hide-special-buffers nil
  "Control the display of some special buffers in buffer switching commands.
When true some special buffers like the server buffer will be hidden."
  :type 'boolean)


;;; Buffer Local Declarations

;; These variables are used to track the state of nREPL connections
(defvar-local nrepl-connection-buffer nil)
(defvar-local nrepl-server-buffer nil)
(defvar-local nrepl-messages-buffer nil)
(defvar-local nrepl-endpoint nil)
(defvar-local nrepl-project-dir nil)
(defvar-local nrepl-is-server nil)
(defvar-local nrepl-server-command nil)
(defvar-local nrepl-tunnel-buffer nil)

(defvar-local nrepl-session nil
  "Current nREPL session id.")

(defvar-local nrepl-tooling-session nil
  "Current nREPL tooling session id.
To be used for tooling calls (i.e. completion, eldoc, etc)")

(defvar-local nrepl-request-counter 0
  "Continuation serial number counter.")

(defvar-local nrepl-pending-requests nil)

(defvar-local nrepl-completed-requests nil)

(defvar-local nrepl-last-sync-response nil
  "Result of the last sync request.")

(defvar-local nrepl-last-sync-request-timestamp nil
  "The time when the last sync request was initiated.")

(defvar-local nrepl-ops nil
  "Available nREPL server ops (from describe).")

(defvar-local nrepl-versions nil
  "Version information received from the describe op.")

(defvar-local nrepl-aux nil
  "Auxiliary information received from the describe op.")


;;; nREPL Buffer Names

(defconst nrepl-message-buffer-name-template "*nrepl-messages %s(%r:%S)*")
(defconst nrepl-error-buffer-name "*nrepl-error*")
(defconst nrepl-repl-buffer-name-template "*cider-repl %s(%r:%S)*")
(defconst nrepl-server-buffer-name-template "*nrepl-server %s*")
(defconst nrepl-tunnel-buffer-name-template "*nrepl-tunnel %s*")

(declare-function cider-format-connection-params "cider-connection")
(defun nrepl-make-buffer-name (template params &optional dup-ok)
  "Generate a buffer name using TEMPLATE and PARAMS.
TEMPLATE and PARAMS are as in `cider-format-connection-params'.  If
optional DUP-OK is non-nil, the returned buffer is not \"uniquified\" by a
call to `generate-new-buffer-name'."
  (let ((name (cider-format-connection-params template params)))
    (if dup-ok
        name
      (generate-new-buffer-name name))))

(defun nrepl--make-hidden-name (buffer-name)
  "Apply a prefix to BUFFER-NAME that will hide the buffer."
  (concat (if nrepl-hide-special-buffers " " "") buffer-name))

(defun nrepl-repl-buffer-name (params &optional dup-ok)
  "Return the name of the repl buffer.
PARAMS and DUP-OK are as in `nrepl-make-buffer-name'."
  (nrepl-make-buffer-name nrepl-repl-buffer-name-template params dup-ok))

(defun nrepl-server-buffer-name (params)
  "Return the name of the server buffer.
PARAMS is as in `nrepl-make-buffer-name'."
  (nrepl-make-buffer-name (nrepl--make-hidden-name nrepl-server-buffer-name-template)
                          params))

(defun nrepl-tunnel-buffer-name (params)
  "Return the name of the tunnel buffer.
PARAMS is as in `nrepl-make-buffer-name'."
  (nrepl-make-buffer-name (nrepl--make-hidden-name nrepl-tunnel-buffer-name-template)
                          params))

(defun nrepl-messages-buffer-name (params)
  "Return the name for the message buffer given connection PARAMS."
  (nrepl-make-buffer-name nrepl-message-buffer-name-template params))


;;; Utilities
(defun nrepl-op-supported-p (op connection)
  "Return t iff the given operation OP is supported by the nREPL CONNECTION."
  (when (buffer-live-p connection)
    (with-current-buffer connection
      (and nrepl-ops (nrepl-dict-get nrepl-ops op)))))

(defun nrepl-aux-info (key connection)
  "Return KEY's aux info, as returned via the :describe op for CONNECTION."
  (with-current-buffer connection
    (and nrepl-aux (nrepl-dict-get nrepl-aux key))))

(defun nrepl-local-host-p (host)
  "Return t if HOST is local."
  (string-match-p tramp-local-host-regexp host))

(defun nrepl-extract-port (dir)
  "Read port from applicable repl-port file in directory DIR."
  (or (nrepl--port-from-file (expand-file-name "repl-port" dir))
      (nrepl--port-from-file (expand-file-name ".nrepl-port" dir))
      (nrepl--port-from-file (expand-file-name "target/repl-port" dir))
      (nrepl--port-from-file (expand-file-name ".shadow-cljs/nrepl.port" dir))))

(defun nrepl-extract-ports (dir)
  "Read ports from applicable repl-port files in directory DIR."
  (delq nil
        (list (nrepl--port-from-file (expand-file-name "repl-port" dir))
              (nrepl--port-from-file (expand-file-name ".nrepl-port" dir))
              (nrepl--port-from-file (expand-file-name "target/repl-port" dir))
              (nrepl--port-from-file (expand-file-name ".shadow-cljs/nrepl.port" dir)))))

(make-obsolete 'nrepl-extract-port 'nrepl-extract-ports "1.5.0")

(defun nrepl--port-from-file (file)
  "Attempts to read port from a file named by FILE."
  (when (file-exists-p file)
    (with-temp-buffer
      (insert-file-contents file)
      (buffer-string))))


;;; Bencode

(cl-defstruct (nrepl-response-queue
               (:include queue)
               (:constructor nil)
               (:constructor nrepl-response-queue (&optional stub)))
  stub)

(put 'nrepl-response-queue 'function-documentation
     "Create queue object used by nREPL to store decoded server responses.
The STUB slot stores a stack of nested, incompletely parsed objects.")

(defun nrepl--bdecode-list (&optional stack)
  "Decode a bencode list or dict starting at point.
STACK is as in `nrepl--bdecode-1'."
  ;; skip leading l or d
  (forward-char 1)
  (let* ((istack (nrepl--bdecode-1 stack))
         (pos0 (point))
         (info (car istack)))
    (while (null info)
      (setq istack (nrepl--bdecode-1 (cdr istack))
            pos0 (point)
            info (car istack)))
    (cond ((eq info :e)
           (cons nil (cdr istack)))
          ((eq info :stub)
           (goto-char pos0)
           istack)
          (t istack))))

(defun nrepl--bdecode-1 (&optional stack)
  "Decode one elementary bencode object starting at point.
Bencoded object is either list, dict, integer or string.  See
http://en.wikipedia.org/wiki/Bencode#Encoding_algorithm for the encoding
rules.

STACK is a list of so far decoded components of the current message.  Car
of STACK is the innermost incompletely decoded object.  The algorithm pops
this list when inner object was completely decoded or grows it by one when
new list or dict was encountered.

The returned value is of the form (INFO . STACK) where INFO is
:stub, nil, :end or :eob and STACK is either an incomplete parsing state as
above (INFO is :stub, nil or :eob) or a list of one component representing
the completely decoded message (INFO is :end).  INFO is nil when an
elementary non-root object was successfully decoded.  INFO is :end when this
object is a root list or dict."
  (cond
   ;; list
   ((eq (char-after) ?l)
    (nrepl--bdecode-list (cons () stack)))
   ;; dict
   ((eq (char-after) ?d)
    (nrepl--bdecode-list (cons '(dict) stack)))
   ;; end of a list or a dict
   ((eq (char-after) ?e)
    (forward-char 1)
    (cons (if (cdr stack) :e :end)
          (nrepl--push (nrepl--nreverse (car stack))
                       (cdr stack))))
   ;; string
   ((looking-at "\\([0-9]+\\):")
    (let ((pos0 (point))
          (beg (goto-char (match-end 0)))
          (end (byte-to-position (+ (position-bytes (point))
                                    (string-to-number (match-string 1))))))
      (if (null end)
          (progn (goto-char pos0)
                 (cons :stub stack))
        (goto-char end)
        ;; normalise any platform-specific newlines
        (let* ((original (buffer-substring-no-properties beg end))
               (result (replace-regexp-in-string "\r\n\\|\n\r\\|\r" "\n" original)))
          (cons nil (nrepl--push result stack))))))
   ;; integer
   ((looking-at "i\\(-?[0-9]+\\)e")
    (goto-char (match-end 0))
    (cons nil (nrepl--push (string-to-number (match-string 1))
                           stack)))
   ;; should happen in tests only as eobp is checked in nrepl-bdecode.
   ((eobp)
    (cons :eob stack))
   ;; truncation in the middle of an integer or in 123: string prefix
   ((looking-at-p "[0-9i]")
    (cons :stub stack))
   ;; else, throw a quiet error
   (t
    (message "Invalid bencode message detected. See the %s buffer for details."
             nrepl-error-buffer-name)
    (nrepl-log-error
     (format "Decoder error at position %d (`%s'):"
             (point) (buffer-substring (point) (min (+ (point) 10) (point-max)))))
    (nrepl-log-error (buffer-string))
    (ding)
    ;; Ensure loop break and clean queues' states in nrepl-bdecode:
    (goto-char (point-max))
    (cons :end nil))))

(defun nrepl--bdecode-message (&optional stack)
  "Decode one full message starting at point.
STACK is as in `nrepl--bdecode-1'.  Return a cons (INFO . STACK)."
  (let* ((istack (nrepl--bdecode-1 stack))
         (info (car istack))
         (stack (cdr istack)))
    (while (or (null info)
               (eq info :e))
      (setq istack (nrepl--bdecode-1 stack)
            info (car istack)
            stack (cdr istack)))
    istack))

(defun nrepl--ensure-fundamental-mode ()
  "Enable `fundamental-mode' if it is not enabled already."
  (when (not (eq 'fundamental-mode major-mode))
    (fundamental-mode)))

(defun nrepl-bdecode (string-q &optional response-q)
  "Decode STRING-Q and place the results into RESPONSE-Q.
STRING-Q is either a queue of strings or a string.  RESPONSE-Q is a queue of
server requests (nREPL dicts).  STRING-Q and RESPONSE-Q are modified by side
effects.

Return a cons (STRING-Q . RESPONSE-Q) where STRING-Q is the original queue
containing the remainder of the input strings which could not be
decoded.  RESPONSE-Q is the original queue with successfully decoded messages
enqueued and with slot STUB containing a nested stack of an incompletely
decoded message or nil if the strings were completely decoded."
  (with-current-buffer (get-buffer-create " *nrepl-decoding*")
    ;; Don't needlessly call `fundamental-mode', to prevent needlessly firing
    ;; hooks. This fixes an issue with evil-mode where the cursor loses its
    ;; correct color.
    (nrepl--ensure-fundamental-mode)
    (erase-buffer)
    (if (queue-p string-q)
        (while (queue-head string-q)
          (insert (queue-dequeue string-q)))
      (insert string-q)
      (setq string-q (queue-create)))
    (goto-char 1)
    (unless response-q
      (setq response-q (nrepl-response-queue)))
    (let ((istack (nrepl--bdecode-message
                   (nrepl-response-queue-stub response-q))))
      (while (and (eq (car istack) :end)
                  (not (eobp)))
        (queue-enqueue response-q (cadr istack))
        (setq istack (nrepl--bdecode-message)))
      (unless (eobp)
        (queue-enqueue string-q (buffer-substring (point) (point-max))))
      (if (not (eq (car istack) :end))
          (setf (nrepl-response-queue-stub response-q) (cdr istack))
        (queue-enqueue response-q (cadr istack))
        (setf (nrepl-response-queue-stub response-q) nil))
      (erase-buffer)
      (cons string-q response-q))))

(defun nrepl-bencode (object)
  "Encode OBJECT with bencode.
Integers, lists and nrepl-dicts are treated according to bencode
specification.  Everything else is encoded as string."
  (cond
   ((integerp object) (format "i%de" object))
   ((nrepl-dict-p object) (format "d%se" (mapconcat #'nrepl-bencode (cdr object) "")))
   ((listp object) (format "l%se" (mapconcat #'nrepl-bencode object "")))
   (t (format "%s:%s" (string-bytes object) object))))


;;; Client: Process Filter

(defvar nrepl-response-handler-functions nil
  "List of functions to call on each nREPL message.
Each of these functions should be a function with one argument, which will
be called by `nrepl-client-filter' on every response received.  The current
buffer will be connection (REPL) buffer of the process.  These functions
should take a single argument, a dict representing the message.  See
`nrepl--dispatch-response' for an example.

These functions are called before the message's own callbacks, so that they
can affect the behavior of the callbacks.  Errors signaled by these
functions are demoted to messages, so that they don't prevent the
callbacks from running.")

(defun nrepl-client-filter (proc string)
  "Decode message(s) from PROC contained in STRING and dispatch them."
  (let ((string-q (process-get proc :string-q)))
    (queue-enqueue string-q string)
    ;; Start decoding only if the last letter is 'e'
    (when (eq ?e (aref string (1- (length string))))
      (let ((response-q (process-get proc :response-q)))
        (nrepl-bdecode string-q response-q)
        (while (queue-head response-q)
          (with-current-buffer (process-buffer proc)
            (let ((response (queue-dequeue response-q)))
              (with-demoted-errors "Error in one of the `nrepl-response-handler-functions': %s"
                (run-hook-with-args 'nrepl-response-handler-functions response))
              (nrepl--dispatch-response response))))))))

(defun nrepl--dispatch-response (response)
  "Dispatch the RESPONSE to associated callback.
First we check the callbacks of pending requests.  If no callback was found,
we check the completed requests, since responses could be received even for
older requests with \"done\" status."
  (nrepl-dbind-response response (id)
    (nrepl-log-message response 'response)
    (let ((callback (or (gethash id nrepl-pending-requests)
                        (gethash id nrepl-completed-requests))))
      (if callback
          (funcall callback response)
        (error "[nREPL] No response handler with id %s found" id)))))

(defun nrepl-client-sentinel (process message)
  "Handle sentinel events from PROCESS.
Notify MESSAGE and if the process is closed run `nrepl-disconnected-hook'
and kill the process buffer."
  (if (string-match "deleted\\b" message)
      (message "[nREPL] Connection closed")
    (message "[nREPL] Connection closed unexpectedly (%s)"
             (substring message 0 -1)))
  (when (equal (process-status process) 'closed)
    (when-let* ((client-buffer (process-buffer process)))
      (sesman-remove-object 'CIDER nil client-buffer
                            (not (process-get process :keep-server))
                            'no-error)
      (nrepl--clear-client-sessions client-buffer)
      (with-current-buffer client-buffer
        (goto-char (point-max))
        (insert-before-markers
         (propertize
          (format "\n*** Closed on %s ***\n" (current-time-string))
          'face 'cider-repl-stderr-face))
        (run-hooks 'nrepl-disconnected-hook)
        (let ((server-buffer nrepl-server-buffer))
          (when (and (buffer-live-p server-buffer)
                     (not (process-get process :keep-server)))
            (setq nrepl-server-buffer nil)
            (nrepl--maybe-kill-server-buffer server-buffer)))))))


;;; Network

(defun nrepl--unix-connect (socket-file &optional no-error)
  "If SOCKET-FILE is given, try to `make-network-process'.
If NO-ERROR is non-nil, show messages instead of throwing an error."
  (if (not socket-file)
      (unless no-error
        (error "[nREPL] Socket file not provided"))
    (message "[nREPL] Establishing unix socket connection to %s ..." socket-file)
    (condition-case nil
        (prog1 (list :proc (make-network-process :name "nrepl-connection" :buffer nil
                                                 :family 'local :service socket-file)
                     :host "local-unix-domain-socket"
                     :port socket-file
                     :socket-file socket-file)
          (message "[nREPL] Unix socket connection to %s established" socket-file))
      (error (let ((msg (format "[nREPL] Unix socket connection to %s failed" socket-file)))
               (if no-error
                   (message msg)
                 (error msg))
               nil)))))

(defun nrepl-connect (host port)
  "Connect to the nREPL server identified by HOST and PORT.
For local hosts use a direct connection.  For remote hosts, if
`nrepl-force-ssh-for-remote-hosts' is nil, attempt a direct connection
first.  If `nrepl-force-ssh-for-remote-hosts' is non-nil or the direct
connection failed (and `nrepl-use-ssh-fallback-for-remote-hosts' is
non-nil), try to start a SSH tunneled connection.  Return a plist of the
form (:proc PROC :host \"HOST\" :port PORT) that might contain additional
key-values depending on the connection type."
  (let ((localp (if host
                    (nrepl-local-host-p host)
                  (not (file-remote-p default-directory)))))
    (if localp
        (nrepl--direct-connect (or host "localhost") port)
      ;; we're dealing with a remote host
      (if (and host (not nrepl-force-ssh-for-remote-hosts))
          (or (nrepl--direct-connect host port 'no-error)
              ;; direct connection failed
              ;; fallback to ssh tunneling if enabled
              (and nrepl-use-ssh-fallback-for-remote-hosts
                   (message "[nREPL] Falling back to SSH tunneled connection ...")
                   (nrepl--ssh-tunnel-connect host port))
              ;; fallback is either not enabled or it failed as well
              (if (and (null nrepl-use-ssh-fallback-for-remote-hosts)
                       (not localp))
                  (error "[nREPL] Direct connection to %s:%s failed; try setting `nrepl-use-ssh-fallback-for-remote-hosts' to t"
                         host port)
                (error "[nREPL] Cannot connect to %s:%s" host port)))
        ;; `nrepl-force-ssh-for-remote-hosts' is non-nil
        (nrepl--ssh-tunnel-connect host port)))))

(defun nrepl--direct-connect (host port &optional no-error)
  "If HOST and PORT are given, try to `open-network-stream'.
If NO-ERROR is non-nil, show messages instead of throwing an error."
  (if (not (and host port))
      (unless no-error
        (unless host
          (error "[nREPL] Host not provided"))
        (unless port
          (error "[nREPL] Port not provided")))
    (message "[nREPL] Establishing direct connection to %s:%s ..." host port)
    (condition-case nil
        (prog1 (list :proc (open-network-stream "nrepl-connection" nil host port)
                     :host host :port port)
          (message "[nREPL] Direct connection to %s:%s established" host port))
      (error (let ((msg (format "[nREPL] Direct connection to %s:%s failed" host port)))
               (if no-error
                   (message msg)
                 (error msg))
               nil)))))

(defun nrepl--ssh-tunnel-connect (host port)
  "Connect to a remote machine identified by HOST and PORT through SSH tunnel."
  (message "[nREPL] Establishing SSH tunneled connection to %s:%s ..." host port)
  (let* ((current-buf (buffer-file-name))
         (tramp-file-regexp "/ssh:\\(.+@\\)?\\(.+?\\)\\(:\\|#\\).+")
         (remote-dir (cond
                      ;; If current buffer is a TRAMP buffer and its host is
                      ;; the same as HOST, reuse its connection parameters for
                      ;; SSH tunnel.
                      ((and (string-match tramp-file-regexp current-buf)
                            (string= host (match-string 2 current-buf))) current-buf)
                      ;; Otherwise, if HOST was provided, use it for connection.
                      (host (format "/ssh:%s:" host))
                      ;; Use default directory as fallback.
                      (t default-directory)))
         (ssh (or (executable-find "ssh")
                  (error "[nREPL] Cannot locate 'ssh' executable")))
         (cmd (nrepl--ssh-tunnel-command ssh remote-dir port))
         (tunnel-buf (nrepl-tunnel-buffer-name
                      `((:host ,host) (:port ,port))))
         (tunnel (start-process-shell-command "nrepl-tunnel" tunnel-buf cmd)))
    (process-put tunnel :waiting-for-port t)
    (set-process-filter tunnel (nrepl--ssh-tunnel-filter port))
    (while (and (process-live-p tunnel)
                (process-get tunnel :waiting-for-port))
      (accept-process-output nil 0.005))
    (if (not (process-live-p tunnel))
        (error "[nREPL] SSH port forwarding failed.  Check the '%s' buffer" tunnel-buf)
      (message "[nREPL] SSH port forwarding established to localhost:%s" port)
      (let ((endpoint (nrepl--direct-connect "localhost" port)))
        (thread-first
          endpoint
          (plist-put :tunnel tunnel)
          (plist-put :remote-host host))))))

(defun nrepl--ssh-tunnel-command (ssh dir port)
  "Command string to open SSH tunnel to the host associated with DIR's PORT."
  (with-parsed-tramp-file-name dir v
    ;; this abuses the -v option for ssh to get output when the port
    ;; forwarding is set up, which is used to synchronise on, so that
    ;; the port forwarding is up when we try to connect.
    (format-spec
     "%s -v -N -L %p:localhost:%p %u'%h' %n"
     `((?s . ,ssh)
       (?p . ,port)
       (?h . ,v-host)
       (?u . ,(if v-user (format "-l '%s' " v-user) ""))
       (?n . ,(if v-port (format "-p '%s' " v-port) ""))))))

(autoload 'comint-watch-for-password-prompt "comint"  "(autoload).")

(defun nrepl--ssh-tunnel-filter (port)
  "Return a process filter that waits for PORT to appear in process output."
  (let ((port-string (format "LOCALHOST:%s" port)))
    (lambda (proc string)
      (when (string-match-p port-string string)
        (process-put proc :waiting-for-port nil))
      (when (and (process-live-p proc)
                 (buffer-live-p (process-buffer proc)))
        (with-current-buffer (process-buffer proc)
          (let ((moving (= (point) (process-mark proc))))
            (save-excursion
              (goto-char (process-mark proc))
              (insert string)
              (set-marker (process-mark proc) (point))
              (comint-watch-for-password-prompt string))
            (if moving (goto-char (process-mark proc)))))))))


;;; Client: Process Handling

(defun nrepl--kill-process (proc)
  "Attempt to kill PROC tree.
On MS-Windows, using the standard API is highly likely to leave the child
processes still running in the background as orphans.  As a workaround, an
attempt is made to delegate the task to the `taskkill` program, which comes
with windows since at least Windows XP, and fallback to the Emacs API if it
can't be found.

It is expected that the `(process-status PROC)` return value after PROC is
killed is `exit` when `taskkill` is used and `signal` otherwise."
  (cond
   ((and (eq system-type 'windows-nt)
         (process-live-p proc)
         (executable-find "taskkill"))
    ;; try to use `taskkill` if available
    (with-temp-buffer
      (call-process-shell-command (format "taskkill /PID %s /T /F" (process-id proc))
                                  nil (buffer-name) )
      ;; useful for debugging.
      ;;(message ":PROCESS-KILL-OUPUT %s" (buffer-string))
      ))

   ((memq system-type '(cygwin windows-nt))
    ;; fallback, this is considered to work better than `kill-process` on
    ;; MS-Windows.
    (interrupt-process proc))

   (t (kill-process proc))))

(defun nrepl-kill-server-buffer (server-buf)
  "Kill SERVER-BUF and its process."
  (when (buffer-live-p server-buf)
    (let ((proc (get-buffer-process server-buf)))
      (when (process-live-p proc)
        (set-process-query-on-exit-flag proc nil)
        (nrepl--kill-process proc))
      (kill-buffer server-buf))))

(defun nrepl--maybe-kill-server-buffer (server-buf)
  "Kill SERVER-BUF and its process.
Do not kill the server if there is a REPL connected to that server."
  (when (buffer-live-p server-buf)
    (with-current-buffer server-buf
      ;; Don't kill if there is at least one REPL connected to it.
      (when (not (seq-find (lambda (b)
                             (eq (buffer-local-value 'nrepl-server-buffer b)
                                 server-buf))
                           (buffer-list)))
        (nrepl-kill-server-buffer server-buf)))))

(defun nrepl-start-client-process (&optional host port server-proc buffer-builder socket-file)
  "Create new client process identified by either HOST and PORT or SOCKET-FILE.
If SOCKET-FILE is non-nil, it takes precedence.  In remote buffers, HOST
and PORT are taken from the current tramp connection.  SERVER-PROC must be
a running nREPL server process within Emacs.  BUFFER-BUILDER is a function
of one argument (endpoint returned by `nrepl-connect') which returns a
client buffer.  Return the newly created client process."
  (let* ((endpoint (if socket-file
                       (nrepl--unix-connect (expand-file-name socket-file))
                     (nrepl-connect host port)))
         (client-proc (plist-get endpoint :proc))
         (builder (or buffer-builder (error "`buffer-builder' must be provided")))
         (client-buf (funcall builder endpoint)))

    (set-process-buffer client-proc client-buf)

    (set-process-filter client-proc #'nrepl-client-filter)
    (set-process-sentinel client-proc #'nrepl-client-sentinel)
    (set-process-coding-system client-proc 'utf-8-unix 'utf-8-unix)

    (process-put client-proc :string-q (queue-create))
    (process-put client-proc :response-q (nrepl-response-queue))

    (with-current-buffer client-buf
      (when-let* ((server-buf (and server-proc (process-buffer server-proc))))
        (setq nrepl-project-dir (buffer-local-value 'nrepl-project-dir server-buf)
              nrepl-server-buffer server-buf))
      (setq nrepl-endpoint endpoint
            nrepl-tunnel-buffer (when-let* ((tunnel (plist-get endpoint :tunnel)))
                                  (process-buffer tunnel))
            nrepl-pending-requests (make-hash-table :test 'equal)
            nrepl-completed-requests (make-hash-table :test 'equal)))

    (with-current-buffer client-buf
      (nrepl--init-client-sessions client-proc)
      (nrepl--init-capabilities client-buf)
      (run-hooks 'nrepl-connected-hook))

    client-proc))

(defun nrepl--init-client-sessions (client)
  "Initialize CLIENT connection nREPL sessions.
We create two client nREPL sessions per connection - a main session and a
tooling session.  The main session is general purpose and is used for pretty
much every request that needs a session.  The tooling session is used only
for functionality that's implemented in terms of the \"eval\" op, so that
eval requests for functionality like pretty-printing won't clobber the
values of *1, *2, etc."
  (let* ((client-conn (process-buffer client))
         (response-main (nrepl-sync-request:clone client-conn))
         (response-tooling (nrepl-sync-request:clone client-conn t))) ; t for tooling
    (nrepl-dbind-response response-main (new-session err)
      (if new-session
          (with-current-buffer client-conn
            (setq nrepl-session new-session))
        (error "Could not create new session (%s)" err)))
    (nrepl-dbind-response response-tooling (new-session err)
      (if new-session
          (with-current-buffer client-conn
            (setq nrepl-tooling-session new-session))
        (error "Could not create new tooling session (%s)" err)))))

(defun nrepl--init-capabilities (conn-buffer)
  "Store locally in CONN-BUFFER the capabilities of nREPL server."
  (let ((description (nrepl-sync-request:describe conn-buffer)))
    (nrepl-dbind-response description (ops versions aux)
      (with-current-buffer conn-buffer
        (setq nrepl-ops ops)
        (setq nrepl-versions versions)
        (setq nrepl-aux aux)))))

(defun nrepl--clear-client-sessions (conn-buffer)
  "Clear information about nREPL sessions in CONN-BUFFER.
CONN-BUFFER refers to a (presumably) dead connection,
which we can eventually reuse."
  (with-current-buffer conn-buffer
    (setq nrepl-session nil)
    (setq nrepl-tooling-session nil)))


;;; Client: Response Handling
;; After being decoded, responses (aka, messages from the server) are dispatched
;; to handlers. Handlers are constructed with `nrepl-make-response-handler'.

(defvar nrepl-err-handler nil
  "Evaluation error handler.")

(defun nrepl--mark-id-completed (id)
  "Move ID from `nrepl-pending-requests' to `nrepl-completed-requests'.
It is safe to call this function multiple times on the same ID."
  ;; FIXME: This should go away eventually when we get rid of
  ;; pending-request hash table
  (when-let* ((handler (gethash id nrepl-pending-requests)))
    (puthash id handler nrepl-completed-requests)
    (remhash id nrepl-pending-requests)))

(declare-function cider-repl--emit-interactive-output "cider-repl")
(defun nrepl-notify (msg type)
  "Handle \"notification\" server request.
MSG is a string to be displayed.  TYPE is the type of the message.  All
notifications are currently displayed with `message' function and emitted
to the REPL."
  (let* ((face (pcase type
                 ((or "message" `nil) 'font-lock-builtin-face)
                 ("warning" 'warning)
                 ("error"   'error)))
         (msg (if face
                  (propertize msg 'face face)
                (format "%s: %s" (upcase type) msg))))
    (cider-repl--emit-interactive-output msg (or face 'font-lock-builtin-face))
    (message msg)))

(defvar cider-buffer-ns)
(defvar cider-print-quota)
(defvar cider-special-mode-truncate-lines)
(declare-function cider-need-input "cider-client")
(declare-function cider-set-buffer-ns "cider-mode")

(defun nrepl-make-response-handler (buffer value-handler stdout-handler
                                           stderr-handler done-handler
                                           &optional eval-error-handler
                                           content-type-handler
                                           truncated-handler)
  "Make a response handler for connection BUFFER.
A handler is a function that takes one argument - response received from
the server process.  The response is an alist that contains at least 'id'
and 'session' keys.  Other standard response keys are 'value', 'out', 'err',
and 'status'.

The presence of a particular key determines the type of the response.  For
example, if 'value' key is present, the response is of type 'value', if
'out' key is present the response is 'stdout' etc.

Depending on the type, the handler dispatches the appropriate value to one
of the supplied handlers: VALUE-HANDLER, STDOUT-HANDLER, STDERR-HANDLER,
DONE-HANDLER, EVAL-ERROR-HANDLER, CONTENT-TYPE-HANDLER, and
TRUNCATED-HANDLER.

Handlers are functions of the buffer and the value they handle, except for
the optional CONTENT-TYPE-HANDLER which should be a function of the buffer,
content, the content-type to be handled as a list `(type attrs)'.

If the optional EVAL-ERROR-HANDLER is nil, the default `nrepl-err-handler'
is used.  If any of the other supplied handlers are nil nothing happens for
the corresponding type of response."
  (lambda (response)
    (nrepl-dbind-response response (content-type content-transfer-encoding body
                                                 value ns out err status id)
      (when (buffer-live-p buffer)
        (with-current-buffer buffer
          (when (and ns (not (derived-mode-p 'clojure-mode)))
            (cider-set-buffer-ns ns))))
      (cond ((and content-type content-type-handler)
             (funcall content-type-handler buffer
                      (if (string= content-transfer-encoding "base64")
                          (base64-decode-string body)
                        body)
                      content-type))
            (value
             (when value-handler
               (funcall value-handler buffer value)))
            (out
             (when stdout-handler
               (funcall stdout-handler buffer out)))
            (err
             (when stderr-handler
               (funcall stderr-handler buffer err)))
            (status
             (when (and truncated-handler (member "nrepl.middleware.print/truncated" status))
               (let ((warning (format "\n... output truncated to %sB ..."
                                      (file-size-human-readable cider-print-quota))))
                 (funcall truncated-handler buffer warning)))
             (when (member "notification" status)
               (nrepl-dbind-response response (msg type)
                 (nrepl-notify msg type)))
             (when (member "interrupted" status)
               (message "Evaluation interrupted."))
             (when (member "eval-error" status)
               (funcall (or eval-error-handler nrepl-err-handler)))
             (when (member "namespace-not-found" status)
               (message "Namespace `%s' not found." ns))
             (when (member "need-input" status)
               (cider-need-input buffer))
             (when (member "done" status)
               (nrepl--mark-id-completed id)
               (when done-handler
                 (funcall done-handler buffer))))))))


;;; Client: Request Core API

;; Requests are messages from an nREPL client (like CIDER) to an nREPL server.
;; Requests can be asynchronous (sent with `nrepl-send-request') or
;; synchronous (send with `nrepl-send-sync-request'). The request is a pair list
;; of operation name and operation parameters. The core operations are described
;; at https://github.com/nrepl/nrepl/blob/master/doc/ops.md. CIDER adds
;; many more operations through nREPL middleware. See
;; https://github.com/clojure-emacs/cider-nrepl#supplied-nrepl-middleware for
;; the up-to-date list.

(defun nrepl-next-request-id (connection)
  "Return the next request id for CONNECTION."
  (with-current-buffer connection
    (number-to-string (cl-incf nrepl-request-counter))))

(defun nrepl-send-request (request callback connection &optional tooling)
  "Send REQUEST and register response handler CALLBACK using CONNECTION.
REQUEST is a pair list of the form (\"op\" \"operation\" \"par1-name\"
\"par1\" ... ). See the code of `nrepl-request:clone',
`nrepl-request:stdin', etc. This expects that the REQUEST does not have a
session already in it. This code will add it as appropriate to prevent
connection/session drift.
Return the ID of the sent message.
Optional argument TOOLING Set to t if desiring the tooling session rather than
the standard session."
  (with-current-buffer connection
    (when-let* ((session (if tooling nrepl-tooling-session nrepl-session)))
      (setq request (append request `("session" ,session))))
    (let* ((id (nrepl-next-request-id connection))
           (request (cons 'dict (lax-plist-put request "id" id)))
           (message (nrepl-bencode request)))
      (nrepl-log-message request 'request)
      (puthash id callback nrepl-pending-requests)
      (process-send-string nil message)
      id)))

(defvar nrepl-ongoing-sync-request nil
  "Dynamically bound to t while a sync request is ongoing.")

(declare-function cider-repl-emit-interactive-stderr "cider-repl")
(declare-function cider--render-stacktrace-causes "cider-eval")

(defun nrepl-send-sync-request (request connection &optional abort-on-input tooling)
  "Send REQUEST to the nREPL server synchronously using CONNECTION.
Hold till final \"done\" message has arrived and join all response messages
of the same \"op\" that came along.
If ABORT-ON-INPUT is non-nil, the function will return nil at the first
sign of user input, so as not to hang the interface.
If TOOLING, use the tooling session rather than the standard session."
  (let* ((time0 (current-time))
         (response (cons 'dict nil))
         (nrepl-ongoing-sync-request t)
         status)
    (nrepl-send-request request
                        (lambda (resp) (nrepl--merge response resp))
                        connection
                        tooling)
    (while (and (not (member "done" status))
                (not (and abort-on-input
                          (input-pending-p))))
      (setq status (nrepl-dict-get response "status"))
      ;; If we get a need-input message then the repl probably isn't going
      ;; anywhere, and we'll just timeout. So we forward it to the user.
      (if (member "need-input" status)
          (progn (cider-need-input (current-buffer))
                 ;; If the used took a few seconds to respond, we might
                 ;; unnecessarily timeout, so let's reset the timer.
                 (setq time0 (current-time)))
        ;; break out in case we don't receive a response for a while
        (when (and nrepl-sync-request-timeout
                   (time-less-p
                    nrepl-sync-request-timeout
                    (time-subtract nil time0)))
          (error "Sync nREPL request timed out %s after %s secs" request nrepl-sync-request-timeout)))
      ;; Clean up the response, otherwise we might repeatedly ask for input.
      (nrepl-dict-put response "status" (remove "need-input" status))
      (accept-process-output nil 0.01))
    ;; If we couldn't finish, return nil.
    (when (member "done" status)
      (nrepl-dbind-response response (ex err eval-error pp-stacktrace id)
        (when (and ex err)
          (cond (eval-error (funcall nrepl-err-handler))
                (pp-stacktrace (cider--render-stacktrace-causes
                                pp-stacktrace (remove "done" status))))) ;; send the error type
        (when id
          (with-current-buffer connection
            (nrepl--mark-id-completed id)))
        response))))

(defun nrepl-request:stdin (input callback connection)
  "Send a :stdin request with INPUT using CONNECTION.
Register CALLBACK as the response handler."
  (nrepl-send-request `("op" "stdin"
                        "stdin" ,input)
                      callback
                      connection))

(defun nrepl-request:interrupt (pending-request-id callback connection)
  "Send an :interrupt request for PENDING-REQUEST-ID.
The request is dispatched using CONNECTION.
Register CALLBACK as the response handler."
  (nrepl-send-request `("op" "interrupt"
                        "interrupt-id" ,pending-request-id)
                      callback
                      connection))

(define-minor-mode cider-enlighten-mode nil
  :lighter (cider-mode " light")
  :global t)

(defun nrepl--eval-request (input &optional ns line column)
  "Prepare :eval request message for INPUT.
NS provides context for the request.
If LINE and COLUMN are non-nil and current buffer is a file buffer, \"line\",
\"column\" and \"file\" are added to the message."
  (nconc (and ns `("ns" ,ns))
         `("op" "eval"
           "code" ,(substring-no-properties input))
         (when cider-enlighten-mode
           '("enlighten" "true"))
         (let ((file (or (buffer-file-name) (buffer-name))))
           (when (and line column file)
             `("file" ,file
               "line" ,line
               "column" ,column)))))

(defun nrepl-request:eval (input callback connection &optional ns line column additional-params tooling)
  "Send the request INPUT and register the CALLBACK as the response handler.
The request is dispatched via CONNECTION.  If NS is non-nil,
include it in the request.  LINE and COLUMN, if non-nil, define the position
of INPUT in its buffer.  A CONNECTION uniquely determines two connections
available: the standard interaction one and the tooling session.  If the
tooling is desired, set TOOLING to true.
ADDITIONAL-PARAMS is a plist to be appended to the request message."
  (nrepl-send-request (append (nrepl--eval-request input ns line column) additional-params)
                      callback
                      connection
                      tooling))

(defun nrepl-sync-request:clone (connection &optional tooling)
  "Sent a :clone request to create a new client session.
The request is dispatched via CONNECTION.
Optional argument TOOLING Tooling is set to t if wanting the tooling session
from CONNECTION."
  (nrepl-send-sync-request '("op" "clone")
                           connection
                           nil tooling))

(defun nrepl-sync-request:close (connection)
  "Sent a :close request to close CONNECTION's SESSION."
  (nrepl-send-sync-request '("op" "close") connection)
  (nrepl-send-sync-request '("op" "close") connection nil t)) ;; close tooling session

(defun nrepl-sync-request:describe (connection)
  "Perform :describe request for CONNECTION and SESSION."
  (nrepl-send-sync-request '("op" "describe")
                           connection))

(defun nrepl-sync-request:ls-sessions (connection)
  "Perform :ls-sessions request for CONNECTION."
  (nrepl-send-sync-request '("op" "ls-sessions") connection))

(defun nrepl-sync-request:ls-middleware (connection)
  "Perform :ls-middleware request for CONNECTION."
  (nrepl-send-sync-request '("op" "ls-middleware") connection))

(defun nrepl-sync-request:eval (input connection &optional ns tooling)
  "Send the INPUT to the nREPL server synchronously.
The request is dispatched via CONNECTION.
If NS is non-nil, include it in the request
If TOOLING is non-nil the evaluation is done using the tooling nREPL
session."
  (nrepl-send-sync-request
   (nrepl--eval-request input ns)
   connection
   nil
   tooling))

(defun nrepl-sessions (connection)
  "Get a list of active sessions on the nREPL server using CONNECTION."
  (nrepl-dict-get (nrepl-sync-request:ls-sessions connection) "sessions"))

(defun nrepl-middleware (connection)
  "Get a list of middleware on the nREPL server using CONNECTION."
  (nrepl-dict-get (nrepl-sync-request:ls-middleware connection) "middleware"))


;;; Server

;; The server side process is started by `nrepl-start-server-process' and has a
;; very simple filter that pipes its output directly into its process buffer
;; (*nrepl-server*). The main purpose of this process is to start the actual
;; nrepl communication client (`nrepl-client-filter') when the message "nREPL
;; server started on port ..." is detected.

;; internal variables used for state transfer between nrepl-start-server-process
;; and nrepl-server-filter.
(defvar-local nrepl-on-port-callback nil)

(defun nrepl-server-p (buffer-or-process)
  "Return t if BUFFER-OR-PROCESS is an nREPL server."
  (let ((buffer (if (processp buffer-or-process)
                    (process-buffer buffer-or-process)
                  buffer-or-process)))
    (buffer-local-value 'nrepl-is-server buffer)))

(defun nrepl-start-server-process (directory cmd on-port-callback)
  "Start nREPL server process in DIRECTORY using shell command CMD.
Return a newly created process.  Set `nrepl-server-filter' as the process
filter, which starts REPL process with its own buffer once the server has
started.  ON-PORT-CALLBACK is a function of one argument (server buffer)
which is called by the process filter once the port of the connection has
been determined."
  (let* ((default-directory (or directory default-directory))
         (serv-buf (get-buffer-create
                    (nrepl-server-buffer-name
                     `(:project-dir ,default-directory)))))
    (with-current-buffer serv-buf
      (setq nrepl-is-server t
            nrepl-project-dir default-directory
            nrepl-server-command cmd
            nrepl-on-port-callback on-port-callback))
    (let ((serv-proc (start-file-process-shell-command
                      "nrepl-server" serv-buf cmd)))
      (set-process-filter serv-proc #'nrepl-server-filter)
      (set-process-sentinel serv-proc #'nrepl-server-sentinel)
      (set-process-coding-system serv-proc 'utf-8-unix 'utf-8-unix)
      (message "[nREPL] Starting server via %s"
               (propertize cmd 'face 'font-lock-keyword-face))
      serv-proc)))

(defconst nrepl-listening-unix-address-regexp
  (rx
   (and "nREPL server listening on" (+ " ")
        "nrepl+unix:" (group-n 1 (+ not-newline)))))

(defconst nrepl-listening-inet-address-regexp
  (rx (or
       ;; standard
       (and "nREPL server started on port " (group-n 1 (+ (any "0-9"))))
       ;; babashka
       (and "Started nREPL server at "
            (group-n 2 (+? any)) ":" (group-n 1 (+ (any "0-9"))))))
  "A regexp to search an nREPL's stdout for the address it is listening on.

If it matches, the address components can be extracted using the following
match groups:
1  for the port, and
2  for the host (babashka only).")

(defun cider--process-plist-put (proc prop val)
  "Change value in PROC's plist of PROP to VAL.
Value is changed using `plist-put`, of which see."
  (thread-first
    proc
    (process-plist)
    (plist-put prop val)
    (thread-last (set-process-plist proc))))

(defun nrepl-server-filter (process output)
  "Process nREPL server output from PROCESS contained in OUTPUT.

The PROCESS plist is updated as (non-exhaustive list):

:cider--nrepl-server-ready set to t when the server is successfully brought
up."
  ;; In Windows this can be false:
  (let ((server-buffer (process-buffer process)))
    (when (buffer-live-p server-buffer)
      (with-current-buffer server-buffer
        ;; auto-scroll on new output
        (let ((moving (= (point) (process-mark process))))
          (save-excursion
            (goto-char (process-mark process))
            (insert output)
            (ansi-color-apply-on-region (process-mark process) (point))
            (set-marker (process-mark process) (point)))
          (when moving
            (goto-char (process-mark process))
            (when-let* ((win (get-buffer-window)))
              (set-window-point win (point)))))
        ;; detect the port the server is listening on from its output
        (when (null nrepl-endpoint)
          (let ((end (cond
                      ((string-match nrepl-listening-unix-address-regexp output)
                       (let ((path (match-string 1 output)))
                         (message "[nREPL] server started on nrepl+unix:%s" path)
                         (list :host "local-unix-domain-socket"
                               :port path
                               :socket-file path)))
                      ((string-match nrepl-listening-inet-address-regexp output)
                       (let ((host (or (match-string 2 output)
                                       (file-remote-p default-directory 'host)
                                       "localhost"))
                             (port (string-to-number (match-string 1 output))))
                         (message "[nREPL] server started on %s" port)
                         (list :host host :port port))))))
            (when end
              (setq nrepl-endpoint end)
              (cider--process-plist-put process :cider--nrepl-server-ready t)
              (when nrepl-on-port-callback
                (funcall nrepl-on-port-callback (process-buffer process))))))))))

(defmacro emacs-bug-46284/when-27.1-windows-nt (&rest body)
  "Only evaluate BODY when Emacs bug #46284 has been detected."
  (when (and (eq system-type 'windows-nt)
             (string= emacs-version "27.1"))
    (cons 'progn body)))


(declare-function cider--close-connection "cider-connection")
(defun nrepl-server-sentinel (process event)
  "Handle nREPL server PROCESS EVENT.
On a fatal EVENT, attempt to close any open client connections, and signal
an `error' if the nREPL PROCESS exited because it couldn't start up."
  ;; only interested on fatal signals.
  (when (not (process-live-p process))
    (emacs-bug-46284/when-27.1-windows-nt
     ;; There is a bug in emacs 27.1 (since fixed) that sets all EVENT
     ;; descriptions for signals to "unknown signal". We correct this by
     ;; resetting it back to its canonical value.
     (when (eq (process-status process) 'signal)
       (cl-case (process-exit-status process)
         ;; SIGHUP==1 emacs nt/inc/ms-w32.h
         (1 (setq event "Hangup"))
         ;; SIGINT==2 x86_64-w64-mingw32/include/signal.h
         (2 (setq event "Interrupt"))
         ;; SIGKILL==9 emacs nt/inc/ms-w32.h
         (9 (setq event "Killed")))))
    (let* ((server-buffer (process-buffer process))
           (clients (seq-filter (lambda (b)
                                  (eq (buffer-local-value 'nrepl-server-buffer b)
                                      server-buffer))
                                (buffer-list))))
      ;; close any known open client connections
      (mapc #'cider--close-connection clients)

      (if (process-get process :cider--nrepl-server-ready)
          (progn
            (when server-buffer (kill-buffer server-buffer))
            (message "nREPL server exited."))
        (let ((problem (when (and server-buffer (buffer-live-p server-buffer))
                         (with-current-buffer server-buffer
                           (buffer-substring (point-min) (point-max))))))
          (error "Could not start nREPL server: %s (%S)" problem (string-trim event)))))))


;;; Messages

(defcustom nrepl-log-messages nil
  "If non-nil, log protocol messages to an nREPL messages buffer.
This is extremely useful for debug purposes, as it allows you to inspect
the communication between Emacs and an nREPL server.  Enabling the logging
might have a negative impact on performance, so it's not recommended to
keep it enabled unless you need to debug something."
  :type 'boolean
  :safe #'booleanp)

(defconst nrepl-message-buffer-max-size 1000000
  "Maximum size for the nREPL message buffer.
Defaults to 1000000 characters, which should be an insignificant
memory burden, while providing reasonable history.")

(defconst nrepl-message-buffer-reduce-denominator 4
  "Divisor by which to reduce message buffer size.
When the maximum size for the nREPL message buffer is exceeded, the size of
the buffer is reduced by one over this value.  Defaults to 4, so that 1/4
of the buffer is removed, which should ensure the buffer's maximum is
reasonably utilized, while limiting the number of buffer shrinking
operations.")

(defvar nrepl-messages-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd "n")   #'next-line)
    (define-key map (kbd "p")   #'previous-line)
    (define-key map (kbd "TAB") #'forward-button)
    (define-key map (kbd "RET") #'nrepl-log-expand-button)
    (define-key map (kbd "e")   #'nrepl-log-expand-button)
    (define-key map (kbd "E")   #'nrepl-log-expand-all-buttons)
    (define-key map (kbd "<backtab>") #'backward-button)
    map))

(define-derived-mode nrepl-messages-mode special-mode "nREPL Messages"
  "Major mode for displaying nREPL messages.

\\{nrepl-messages-mode-map}"
  (when cider-special-mode-truncate-lines
    (setq-local truncate-lines t))
  (setq-local sesman-system 'CIDER)
  (setq-local electric-indent-chars nil)
  (setq-local comment-start ";")
  (setq-local comment-end "")
  (setq-local paragraph-start "(-->\\|(<--")
  (setq-local paragraph-separate "(<--"))

(defun nrepl-decorate-msg (msg type)
  "Decorate nREPL MSG according to its TYPE."
  (pcase type
    (`request (cons '--> (cdr msg)))
    (`response (cons '<-- (cdr msg)))))

(defun nrepl-log-message (msg type)
  "Log the nREPL MSG.
TYPE is either request or response.  The message is logged to a buffer
described by `nrepl-message-buffer-name-template'."
  (when nrepl-log-messages
    ;; append a time-stamp to the message before logging it
    ;; the time-stamps are quite useful for debugging
    (setq msg (cons (car msg)
                    (lax-plist-put (cdr msg) "time-stamp"
                                   (format-time-string "%Y-%m-%0d %H:%M:%S.%N"))))
    (with-current-buffer (nrepl-messages-buffer (current-buffer))
      (setq buffer-read-only nil)
      (when (> (buffer-size) nrepl-message-buffer-max-size)
        (goto-char (/ (buffer-size) nrepl-message-buffer-reduce-denominator))
        (re-search-forward "^(" nil t)
        (delete-region (point-min) (- (point) 1)))
      (goto-char (point-max))
      (nrepl-log-pp-object (nrepl-decorate-msg msg type)
                           (nrepl-log--message-color (lax-plist-get (cdr msg) "id"))
                           t)
      (when-let* ((win (get-buffer-window)))
        (set-window-point win (point-max)))
      (setq buffer-read-only t))))

(defun nrepl-toggle-message-logging ()
  "Toggle the value of `nrepl-log-messages' between nil and t.

This in effect enables or disables the logging of nREPL messages."
  (interactive)
  (setq nrepl-log-messages (not nrepl-log-messages))
  (if nrepl-log-messages
      (message "nREPL message logging enabled")
    (message "nREPL message logging disabled")))

(defcustom nrepl-message-colors
  '("red" "brown" "coral" "orange" "green" "deep sky blue" "blue" "dark violet")
  "Colors used in the messages buffer."
  :type '(repeat color))

(defun nrepl-log-expand-button (&optional button)
  "Expand the objects hidden in BUTTON's :nrepl-object property.
BUTTON defaults the button at point."
  (interactive)
  (if-let* ((button (or button (button-at (point)))))
      (let* ((start (overlay-start button))
             (end   (overlay-end   button))
             (obj   (overlay-get button :nrepl-object))
             (inhibit-read-only t))
        (save-excursion
          (goto-char start)
          (delete-overlay button)
          (delete-region start end)
          (nrepl-log-pp-object obj)
          (delete-char -1)))
    (error "No button at point")))

(defun nrepl-log-expand-all-buttons ()
  "Expand all buttons in nREPL log buffer."
  (interactive)
  (if (not (eq major-mode 'nrepl-messages-mode))
      (user-error "Not in a `nrepl-messages-mode'")
    (save-excursion
      (let* ((pos (point-min))
             (button (next-button pos)))
        (while button
          (setq pos (overlay-start button))
          (nrepl-log-expand-button button)
          (setq button (next-button pos)))))))

(defun nrepl-log--expand-button-mouse (event)
  "Expand the text hidden under overlay button.
EVENT gives the button position on window."
  (interactive "e")
  (pcase (elt event 1)
    (`(,window ,_ ,_ ,_ ,_ ,point . ,_)
     (with-selected-window window
       (nrepl-log-expand-button (button-at point))))))

(defun nrepl-log-insert-button (label object)
  "Insert button with LABEL and :nrepl-object property as OBJECT."
  (insert-button label
                 :nrepl-object object
                 'action #'nrepl-log-expand-button
                 'face 'link
                 'help-echo "RET: Expand object."
                 ;; Workaround for bug#1568 (don't use local-map here; it
                 ;; overwrites major mode map.)
                 'keymap `(keymap (mouse-1 . nrepl-log--expand-button-mouse)))
  (insert "\n"))

(defun nrepl-log--message-color (id)
  "Return the color to use when pretty-printing the nREPL message with ID.
If ID is nil, return nil."
  (when id
    (thread-first
      (string-to-number id)
      (mod (length nrepl-message-colors))
      (nth nrepl-message-colors))))

(defun nrepl-log--pp-listlike (object &optional foreground button)
  "Pretty print nREPL list like OBJECT.
FOREGROUND and BUTTON are as in `nrepl-log-pp-object'."
  (cl-flet ((color (str)
                   (propertize str 'face
                               (append '(:weight ultra-bold)
                                       (when foreground `(:foreground ,foreground))))))
    (let ((head (format "(%s" (car object))))
      (insert (color head))
      (if (null (cdr object))
          (insert ")\n")
        (let* ((indent (+ 2 (- (current-column) (length head))))
               (sorted-pairs (sort (seq-partition (cl-copy-list (cdr object)) 2)
                                   (lambda (a b)
                                     (string< (car a) (car b)))))
               (name-lengths (seq-map (lambda (pair) (length (car pair))) sorted-pairs))
               (longest-name (seq-max name-lengths))
               ;; Special entries are displayed first
               (specialq (lambda (pair) (member (car pair) '("id" "op" "session" "time-stamp"))))
               (special-pairs (seq-filter specialq sorted-pairs))
               (not-special-pairs (seq-remove specialq sorted-pairs))
               (all-pairs (seq-concatenate 'list special-pairs not-special-pairs))
               (sorted-object (apply #'seq-concatenate 'list all-pairs)))
          (insert "\n")
          (cl-loop for l on sorted-object by #'cddr
                   do (let ((indent-str (make-string indent ?\s))
                            (name-str (propertize (car l) 'face
                                                  ;; Only highlight top-level keys.
                                                  (unless (eq (car object) 'dict)
                                                    'font-lock-keyword-face)))
                            (spaces-str (make-string (- longest-name (length (car l))) ?\s)))
                        (insert (format "%s%s%s " indent-str name-str spaces-str))
                        (nrepl-log-pp-object (cadr l) nil button)))
          (when (eq (car object) 'dict)
            (delete-char -1))
          (insert (color ")\n")))))))

(defun nrepl-log-pp-object (object &optional foreground button)
  "Pretty print nREPL OBJECT, delimited using FOREGROUND.
If BUTTON is non-nil, try making a button from OBJECT instead of inserting
it into the buffer."
  (let ((min-dict-fold-size   1)
        (min-list-fold-size   10)
        (min-string-fold-size 60))
    (if-let* ((head (car-safe object)))
        ;; list-like objects
        (cond
         ;; top level dicts (always expanded)
         ((memq head '(<-- -->))
          (nrepl-log--pp-listlike object foreground button))
         ;; inner dicts
         ((eq head 'dict)
          (if (and button (> (length object) min-dict-fold-size))
              (nrepl-log-insert-button "(dict ...)" object)
            (nrepl-log--pp-listlike object foreground button)))
         ;; lists
         (t
          (if (and button (> (length object) min-list-fold-size))
              (nrepl-log-insert-button (format "(%s ...)" (prin1-to-string head)) object)
            (pp object (current-buffer)))))
      ;; non-list objects
      (if (stringp object)
          (if (and button (> (length object) min-string-fold-size))
              (nrepl-log-insert-button (format "\"%s...\"" (substring object 0 min-string-fold-size)) object)
            (insert (prin1-to-string object) "\n"))
        (pp object (current-buffer))
        (insert "\n")))))

(declare-function cider--gather-connect-params "cider-connection")
(defun nrepl-messages-buffer (conn)
  "Return or create the buffer for CONN.
The default buffer name is *nrepl-messages connection*."
  (with-current-buffer conn
    (or (and (buffer-live-p nrepl-messages-buffer)
             nrepl-messages-buffer)
        (setq nrepl-messages-buffer
              (let ((buffer (get-buffer-create
                             (nrepl-messages-buffer-name
                              (cider--gather-connect-params)))))
                (with-current-buffer buffer
                  (buffer-disable-undo)
                  (nrepl-messages-mode)
                  buffer))))))

(defun nrepl-error-buffer ()
  "Return or create the buffer.
The default buffer name is *nrepl-error*."
  (or (get-buffer nrepl-error-buffer-name)
      (let ((buffer (get-buffer-create nrepl-error-buffer-name)))
        (with-current-buffer buffer
          (buffer-disable-undo)
          (nrepl--ensure-fundamental-mode)
          buffer))))

(defun nrepl-log-error (msg)
  "Log the given MSG to the buffer given by `nrepl-error-buffer'."
  (with-current-buffer (nrepl-error-buffer)
    (setq buffer-read-only nil)
    (goto-char (point-max))
    (insert msg)
    (when-let* ((win (get-buffer-window)))
      (set-window-point win (point-max)))
    (setq buffer-read-only t)))

(make-obsolete 'nrepl-default-client-buffer-builder nil "0.18")

(provide 'nrepl-client)

;;; nrepl-client.el ends here
