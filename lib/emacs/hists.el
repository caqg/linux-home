;;; -*- Emacs-Lisp -*-
;;;
;;; This implements a form of cyclic histories, useful for interaction
;;; modes where previous events might be needed.
;;;
;;; Cesar Quiroz @ UofR DofCSc.

(provide 'hists)
(require 'cl)

(defstruct (history (:constructor new-history))
  "Type of interaction histories: ring buffers and such.
A history is a cyclic array of so-called events (any type).
A history is characterized by the maximum number of events it admits
and by the position of the next slot to be used for insertion of a new
event.

Important invariants:
    * 0<=here<capacity at all times, here indicates where to insert a
      new event.
    * 0<=occupancy<capacity   for the first 'capacity' calls
      occupancy=capacity      after at least 'capacity' calls
    * The legal range of ring is 0<=index<occupancy, at all times.

Histories are created by make-history.  Events are thereafter
introduced by history-store.  The latest event is retrieved by
history-retrieve-current.  An arbitrary event is retrieved by
history-retrieve, with a second argument taken modulo the actual
occupancy.  One can also update an event (without modifying the ring
structure), but that is not often desirable."
  here                                  ;cursor to current event
  occupancy                             ;actual level of occupation
  capacity                              ;maximum number of events
  ring                                  ;the storage itself
  )

(defun make-history (cap)
  "Return a history with capacity for CAP events."
  (unless (> cap 0)
    (error "Need positive capacity, got `%s'."
           (prin1-to-string cap)))
  (let ((h (new-history)))
    (setf (history-here h)      0
          (history-occupancy h) 0
          (history-capacity h)  cap
          (history-ring h)      (make-vector cap nil))
    h))

(defun history-store (history event)
  "Set current position of HISTORY to EVENT
Returns current position in HISTORY after insertion.  This should be
the way to add events, see also history-update and history-update-current." 
  (unless (history-p history)
    (error "Expected a history, got `%s'." (prin1-to-string history)))
  (let ((here (history-here history)))
    ;; insert in ring
    (setf (aref (history-ring history) here) event)
    (let ((oldoc (history-occupancy  history))
          (capac (history-capacity   history)))
      (if (< oldoc capac)               ;still filling in
          (incf (history-occupancy history))))
    ;; advance here-cursor
    (setf (history-here history)
          (mod (1+ here) (history-capacity history)))))

(defun history-retrieve (history position)
  "Retrieve event of HISTORY at index POSITION.
POSITION is taken modulo the level of occupancy of HISTORY."
  (unless (history-p history)
    (error "Expected a history, got `%s'." (prin1-to-string history)))
  (unless (/= (history-occupancy history) 0)
    (error "No events in `%s'." (prin1-to-string history)))
  (aref (history-ring history)
        (mod position (history-occupancy history))))

(defun history-retrieve-current (history)
  "Returns the most recent event in HISTORY."
  (history-retrieve history (- (history-here history) 1)))

(defun history-update (history position event)
  "Updates HISTORY at POSITION with EVENT."
  (unless (history-p history)
    (error "Expected a history, got `%s'." (prin1-to-string history)))
  (unless (/= (history-occupancy history) 0)
    (error "No events in `%s'." (prin1-to-string history)))
  (aset (history-ring history)
        (mod position (history-occupancy history))
        event))

(defun history-update-current (history event)
  "Replace current event in HISTORY with EVENT."
  (history-update history (- (history-here history) 1) event))

(defsetf history-retrieve history-update
  "Destructive way to store in HISTORY.")

(defsetf history-retrieve-current history-update-current
  "Destructive way to alter the most recent event of HISTORY.")

;;; end of hists.el
