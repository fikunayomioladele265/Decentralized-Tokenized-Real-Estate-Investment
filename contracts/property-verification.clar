;; Property Verification Contract
;; This contract validates and registers legitimate real estate assets

(define-data-var admin principal tx-sender)

;; Property status: 0 = unverified, 1 = verified, 2 = rejected
(define-map properties
  { property-id: (string-ascii 36) }
  {
    owner: principal,
    location: (string-ascii 100),
    value: uint,
    status: uint,
    verification-date: uint
  }
)

(define-map property-documents
  { property-id: (string-ascii 36) }
  { document-hash: (buff 32) }
)

(define-read-only (get-property (property-id (string-ascii 36)))
  (map-get? properties { property-id: property-id })
)

(define-read-only (get-property-document (property-id (string-ascii 36)))
  (map-get? property-documents { property-id: property-id })
)

(define-public (register-property
    (property-id (string-ascii 36))
    (location (string-ascii 100))
    (value uint)
    (document-hash (buff 32))
  )
  (let ((existing-property (get-property property-id)))
    (asserts! (is-none existing-property) (err u1)) ;; Property ID already exists
    (asserts! (> value u0) (err u2)) ;; Value must be greater than 0

    (map-set properties
      { property-id: property-id }
      {
        owner: tx-sender,
        location: location,
        value: value,
        status: u0, ;; Initially unverified
        verification-date: u0
      }
    )

    (map-set property-documents
      { property-id: property-id }
      { document-hash: document-hash }
    )

    (ok true)
  )
)

(define-public (verify-property (property-id (string-ascii 36)))
  (let ((property (unwrap! (get-property property-id) (err u3)))) ;; Property not found
    (asserts! (is-eq tx-sender (var-get admin)) (err u4)) ;; Not authorized
    (asserts! (is-eq (get status property) u0) (err u5)) ;; Property already verified or rejected

    (map-set properties
      { property-id: property-id }
      (merge property {
        status: u1, ;; Set to verified
        verification-date: block-height
      })
    )

    (ok true)
  )
)

(define-public (reject-property (property-id (string-ascii 36)))
  (let ((property (unwrap! (get-property property-id) (err u3)))) ;; Property not found
    (asserts! (is-eq tx-sender (var-get admin)) (err u4)) ;; Not authorized
    (asserts! (is-eq (get status property) u0) (err u5)) ;; Property already verified or rejected

    (map-set properties
      { property-id: property-id }
      (merge property {
        status: u2, ;; Set to rejected
        verification-date: block-height
      })
    )

    (ok true)
  )
)

(define-public (transfer-admin (new-admin principal))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u4)) ;; Not authorized
    (var-set admin new-admin)
    (ok true)
  )
)
