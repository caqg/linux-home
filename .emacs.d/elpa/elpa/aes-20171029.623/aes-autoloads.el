;;; aes-autoloads.el --- automatically extracted autoloads
;;
;;; Code:

(add-to-list 'load-path (directory-file-name
                         (or (file-name-directory #$) (car load-path))))


;;;### (autoloads nil "aes" "aes.el" (0 0 0 0))
;;; Generated autoloads from aes.el

(autoload 'aes-Cipher "aes" "\
Perform a complete aes encryption of the unibyte string PLAIN.
Return a new string containing the encrypted string PLAIN.
Use KEYS as the expanded key as defined in `aes-SubShiftMixKeys'.
NB is the number of 32-bit words in PLAIN.  NR is the number of rounds.
The length of KEYS is (1 + NR) * NB.

\(fn PLAIN KEYS NB &optional NR)" nil nil)

(autoload 'aes-InvCipher "aes" "\
Perform a complete aes decryption of the unibyte string CIPHER.
Return a new string containing the decrypted string CIPHER.
Use KEYS as the expanded key as defined in `aes-InvSubShiftMixKeys'.
NB is the number of 32-bit words in CIPHER.  NR is the number of rounds.
The length of KEYS is (1 + NR) * NB.

\(fn CIPHER KEYS NB &optional NR)" nil nil)

(if (fboundp 'register-definition-prefixes) (register-definition-prefixes "aes" '("aes-")))

;;;***

;; Local Variables:
;; version-control: never
;; no-byte-compile: t
;; no-update-autoloads: t
;; coding: utf-8
;; End:
;;; aes-autoloads.el ends here
