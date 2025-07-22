;; -----------------------
;; Constants
;; -----------------------

(define-constant ERR_UNAUTHORIZED (err u1))
(define-constant ERR_ALREADY_CLAIMED (err u2))
(define-constant ERR_INVALID_EXPIRY (err u3))
(define-constant ERR_NOT_FOUND (err u4))
(define-constant ERR_INVALID_AMOUNT (err u5))
(define-constant ERR_INSUFFICIENT_FUNDS (err u6))
(define-constant ERR_GIFT_EXPIRED (err u7))
(define-constant ERR_LIST_FULL (err u8))
(define-constant ERR_SELF_TRANSFER (err u9))

(define-constant MAX_GIFTS u100)

;; -----------------------
;; Data Structures
;; -----------------------

(define-map gifts
  { hash-code: (buff 32) }
  {
    sender: principal,
    amount: uint,
    expiry-block: uint,
    claimed: bool
  }
)

(define-map sender-gift-keys
  { sender: principal }
  { gift-keys: (list 100 (buff 32)) }
)

(define-data-var current-target (buff 32) 0x)

;; -----------------------
;; Helper Functions
;; -----------------------

(define-private (get-sender-gift-list (sender principal))
  (map-get? sender-gift-keys { sender: sender })
)

(define-private (not-target-predicate (item (buff 32)))
  (not (is-eq item (var-get current-target)))
)

(define-private (remove-hash (hashes (list 100 (buff 32))) (target (buff 32)))
  (begin
    (var-set current-target target)
    (filter not-target-predicate hashes)
  )
)

(define-private (gift-exists? (hash-code (buff 32)))
  (is-some (map-get? gifts { hash-code: hash-code }))
)

;; -----------------------
;; Core Functions
;; -----------------------

(define-public (create-gift (hash-code (buff 32)) (amount uint) (expiry-block uint))
  (begin
    (asserts! (> amount u0) ERR_INVALID_AMOUNT)
    (asserts! (> expiry-block stacks-block-height) ERR_INVALID_EXPIRY)
    (asserts! (not (gift-exists? hash-code)) ERR_ALREADY_CLAIMED)

    (let ((sender-gifts (get gift-keys (default-to { gift-keys: (list) } (get-sender-gift-list tx-sender)))))
      (asserts! (< (len sender-gifts) MAX_GIFTS) ERR_LIST_FULL)

      (try! (stx-transfer? amount tx-sender (as-contract tx-sender)))

      (map-set gifts
        { hash-code: hash-code }
        {
          sender: tx-sender,
          amount: amount,
          expiry-block: expiry-block,
          claimed: false
        }
      )

      (map-set sender-gift-keys
  { sender: tx-sender }
  { gift-keys: (unwrap! (as-max-len? (append sender-gifts hash-code) u100) ERR_LIST_FULL) }
)

)


      (ok true)
    )
  )


(define-public (extend-expiry (hash-code (buff 32)) (new-expiry-block uint))
  (match (map-get? gifts { hash-code: hash-code })
    gift
    (begin
      (asserts! (is-eq tx-sender (get sender gift)) ERR_UNAUTHORIZED)
      (asserts! (not (get claimed gift)) ERR_ALREADY_CLAIMED)
      (asserts! (> new-expiry-block (get expiry-block gift)) ERR_INVALID_EXPIRY)

      (map-set gifts { hash-code: hash-code } {
        sender: (get sender gift),
        amount: (get amount gift),
        expiry-block: new-expiry-block,
        claimed: false
      })

      (ok true)
    )
    ERR_NOT_FOUND
  )
)

(define-public (update-amount (hash-code (buff 32)) (additional-amount uint))
  (match (map-get? gifts { hash-code: hash-code })
    gift
    (begin
      (asserts! (is-eq tx-sender (get sender gift)) ERR_UNAUTHORIZED)
      (asserts! (not (get claimed gift)) ERR_ALREADY_CLAIMED)
      (asserts! (> additional-amount u0) ERR_INVALID_AMOUNT)

      (try! (stx-transfer? additional-amount tx-sender (as-contract tx-sender)))

      (map-set gifts { hash-code: hash-code } {
        sender: (get sender gift),
        amount: (+ (get amount gift) additional-amount),
        expiry-block: (get expiry-block gift),
        claimed: false
      })

      (ok true)
    )
    ERR_NOT_FOUND
  )
)

(define-public (claim-gift (hash-code (buff 32)))
  (match (map-get? gifts { hash-code: hash-code })
    gift
    (begin
      (asserts! (not (get claimed gift)) ERR_ALREADY_CLAIMED)
      (asserts! (<= stacks-block-height (get expiry-block gift)) ERR_GIFT_EXPIRED)

      (try! (stx-transfer? (get amount gift) (as-contract tx-sender) tx-sender))

      (map-set gifts { hash-code: hash-code } {
        sender: (get sender gift),
        amount: (get amount gift),
        expiry-block: (get expiry-block gift),
        claimed: true
      })

      (ok true)
    )
    ERR_NOT_FOUND
  )
)

(define-public (cancel-gift (hash-code (buff 32)))
  (match (map-get? gifts { hash-code: hash-code })
    gift
    (begin
      (asserts! (is-eq tx-sender (get sender gift)) ERR_UNAUTHORIZED)
      (asserts! (not (get claimed gift)) ERR_ALREADY_CLAIMED)

      (try! (stx-transfer? (get amount gift) (as-contract tx-sender) tx-sender))

      (map-delete gifts { hash-code: hash-code })

(let ((sender-gifts (get gift-keys (default-to { gift-keys: (list) } (get-sender-gift-list tx-sender)))))
  (map-set sender-gift-keys
    { sender: tx-sender }
    { gift-keys: (unwrap! (as-max-len? (remove-hash sender-gifts hash-code) u100) ERR_LIST_FULL) }
  )
)

      (ok true)
    )
    ERR_NOT_FOUND
  )
)

(define-public (transfer-gift (hash-code (buff 32)) (new-sender principal))
  (match (map-get? gifts { hash-code: hash-code })
    gift
    (begin
      (asserts! (is-eq tx-sender (get sender gift)) ERR_UNAUTHORIZED)
      (asserts! (not (get claimed gift)) ERR_ALREADY_CLAIMED)
      (asserts! (not (is-eq tx-sender new-sender)) ERR_SELF_TRANSFER)

      ;; Remove from old sender list
      (let (
            (old-gifts (get gift-keys (default-to { gift-keys: (list) } (get-sender-gift-list tx-sender))))
            (new-gifts (get gift-keys (default-to { gift-keys: (list) } (get-sender-gift-list tx-sender))))
          )
        (asserts! (< (len new-gifts) MAX_GIFTS) ERR_LIST_FULL)

        (map-set gifts
          { hash-code: hash-code }
          {
            sender: new-sender,
            amount: (get amount gift),
            expiry-block: (get expiry-block gift),
            claimed: false
          }
        )

        (map-set sender-gift-keys
          { sender: tx-sender }
          { gift-keys: (unwrap! (as-max-len? (remove-hash old-gifts hash-code) u100) ERR_LIST_FULL) }
        )

        (ok true)
      )
    )
    ERR_NOT_FOUND
  )
)

;; -----------------------
;; Read-Only Functions
;; -----------------------



(define-read-only (is-claimable (hash-code (buff 32)))
  (match (map-get? gifts { hash-code: hash-code })
    gift
    (ok (and (not (get claimed gift)) (<= stacks-block-height (get expiry-block gift))))
    (ok false)
  )
)

(define-read-only (get-gift-details (hash-code (buff 32)))
  (match (map-get? gifts { hash-code: hash-code })
    gift (ok gift)
    ERR_NOT_FOUND
  )
)

(define-private (is-active-gift (hash (buff 32)))
  (is-eq (unwrap-panic (is-claimable hash)) true)
)


