(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-unauthorized (err u102))
(define-constant err-invalid-amount (err u103))
(define-constant err-policy-expired (err u104))
(define-constant err-policy-active (err u105))
(define-constant err-claim-exists (err u106))
(define-constant err-insufficient-funds (err u107))
(define-constant err-claim-not-found (err u108))
(define-constant err-claim-processed (err u109))
(define-constant err-event-not-canceled (err u110))

(define-data-var policy-counter uint u0)
(define-data-var claim-counter uint u0)
(define-data-var platform-fee uint u500)

(define-map policies
  uint
  {
    organizer: principal,
    event-name: (string-ascii 100),
    event-date: uint,
    premium-amount: uint,
    coverage-amount: uint,
    created-at: uint,
    status: (string-ascii 20)
  }
)

(define-map claims
  uint
  {
    policy-id: uint,
    claimant: principal,
    claim-amount: uint,
    reason: (string-ascii 200),
    submitted-at: uint,
    status: (string-ascii 20),
    approved-by: (optional principal)
  }
)

(define-map policy-balances uint uint)

(define-public (create-policy (event-name (string-ascii 100)) (event-date uint) (premium-amount uint) (coverage-amount uint))
  (let ((policy-id (+ (var-get policy-counter) u1)))
    (asserts! (> premium-amount u0) err-invalid-amount)
    (asserts! (> coverage-amount u0) err-invalid-amount)
    (asserts! (> event-date block-height) err-policy-expired)
    (try! (stx-transfer? premium-amount tx-sender (as-contract tx-sender)))
    (map-set policies policy-id {
      organizer: tx-sender,
      event-name: event-name,
      event-date: event-date,
      premium-amount: premium-amount,
      coverage-amount: coverage-amount,
      created-at: block-height,
      status: "active"
    })
    (map-set policy-balances policy-id coverage-amount)
    (var-set policy-counter policy-id)
    (ok policy-id)
  )
)

(define-public (pay-additional-premium (policy-id uint) (amount uint))
  (let ((policy (unwrap! (map-get? policies policy-id) err-not-found)))
    (asserts! (is-eq (get organizer policy) tx-sender) err-unauthorized)
    (asserts! (is-eq (get status policy) "active") err-policy-active)
    (asserts! (> amount u0) err-invalid-amount)
    (try! (stx-transfer? amount tx-sender (as-contract tx-sender)))
    (map-set policy-balances policy-id 
      (+ (default-to u0 (map-get? policy-balances policy-id)) amount))
    (ok true)
  )
)

(define-public (file-claim (policy-id uint) (claim-amount uint) (reason (string-ascii 200)))
  (let ((policy (unwrap! (map-get? policies policy-id) err-not-found))
        (claim-id (+ (var-get claim-counter) u1)))
    (asserts! (is-eq (get organizer policy) tx-sender) err-unauthorized)
    (asserts! (is-eq (get status policy) "active") err-policy-active)
    (asserts! (> claim-amount u0) err-invalid-amount)
    (asserts! (<= claim-amount (get coverage-amount policy)) err-invalid-amount)
    (map-set claims claim-id {
      policy-id: policy-id,
      claimant: tx-sender,
      claim-amount: claim-amount,
      reason: reason,
      submitted-at: block-height,
      status: "pending",
      approved-by: none
    })
    (var-set claim-counter claim-id)
    (ok claim-id)
  )
)

(define-public (approve-claim (claim-id uint))
  (let ((claim (unwrap! (map-get? claims claim-id) err-claim-not-found))
        (policy (unwrap! (map-get? policies (get policy-id claim)) err-not-found))
        (policy-balance (default-to u0 (map-get? policy-balances (get policy-id claim))))
        (payout-amount (get claim-amount claim))
        (platform-fee-amount (/ (* payout-amount (var-get platform-fee)) u10000)))
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (asserts! (is-eq (get status claim) "pending") err-claim-processed)
    (asserts! (>= policy-balance payout-amount) err-insufficient-funds)
    (asserts! (> (get event-date policy) block-height) err-event-not-canceled)
    (try! (as-contract (stx-transfer? (- payout-amount platform-fee-amount) tx-sender (get claimant claim))))
    (try! (as-contract (stx-transfer? platform-fee-amount tx-sender contract-owner)))
    (map-set claims claim-id (merge claim {
      status: "approved",
      approved-by: (some tx-sender)
    }))
    (map-set policy-balances (get policy-id claim) (- policy-balance payout-amount))
    (if (is-eq policy-balance payout-amount)
      (map-set policies (get policy-id claim) (merge policy { status: "closed" }))
      true
    )
    (ok true)
  )
)

(define-public (reject-claim (claim-id uint))
  (let ((claim (unwrap! (map-get? claims claim-id) err-claim-not-found)))
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (asserts! (is-eq (get status claim) "pending") err-claim-processed)
    (map-set claims claim-id (merge claim {
      status: "rejected",
      approved-by: (some tx-sender)
    }))
    (ok true)
  )
)

(define-public (cancel-policy (policy-id uint))
  (let ((policy (unwrap! (map-get? policies policy-id) err-not-found))
        (policy-balance (default-to u0 (map-get? policy-balances policy-id))))
    (asserts! (is-eq (get organizer policy) tx-sender) err-unauthorized)
    (asserts! (is-eq (get status policy) "active") err-policy-active)
    (asserts! (< (get event-date policy) block-height) err-policy-expired)
    (if (> policy-balance u0)
      (try! (as-contract (stx-transfer? policy-balance tx-sender (get organizer policy))))
      true
    )
    (map-set policies policy-id (merge policy { status: "cancelled" }))
    (map-delete policy-balances policy-id)
    (ok true)
  )
)

(define-public (update-platform-fee (new-fee uint))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (asserts! (<= new-fee u1000) err-invalid-amount)
    (var-set platform-fee new-fee)
    (ok true)
  )
)

(define-public (emergency-withdraw (policy-id uint))
  (let ((policy (unwrap! (map-get? policies policy-id) err-not-found))
        (policy-balance (default-to u0 (map-get? policy-balances policy-id))))
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (asserts! (> policy-balance u0) err-insufficient-funds)
    (try! (as-contract (stx-transfer? policy-balance tx-sender contract-owner)))
    (map-set policy-balances policy-id u0)
    (map-set policies policy-id (merge policy { status: "emergency-closed" }))
    (ok true)
  )
)

(define-read-only (get-policy (policy-id uint))
  (map-get? policies policy-id)
)

(define-read-only (get-claim (claim-id uint))
  (map-get? claims claim-id)
)

(define-read-only (get-policy-balance (policy-id uint))
  (default-to u0 (map-get? policy-balances policy-id))
)

(define-read-only (get-platform-fee)
  (var-get platform-fee)
)

(define-read-only (get-policy-counter)
  (var-get policy-counter)
)

(define-read-only (get-claim-counter)
  (var-get claim-counter)
)

(define-read-only (get-contract-balance)
  (stx-get-balance (as-contract tx-sender))
)