;; Attribution Analyst Verification Contract
;; Validates and manages digital attribution analysts

(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u100))
(define-constant ERR_ANALYST_NOT_FOUND (err u101))
(define-constant ERR_ANALYST_ALREADY_EXISTS (err u102))
(define-constant ERR_INVALID_CERTIFICATION (err u103))

;; Data structures
(define-map analysts
  { analyst-id: uint }
  {
    wallet: principal,
    name: (string-ascii 50),
    certification-level: uint,
    verified: bool,
    verification-date: uint,
    total-attributions: uint,
    accuracy-score: uint
  }
)

(define-map analyst-certifications
  { analyst-id: uint, certification-type: (string-ascii 30) }
  {
    issued-date: uint,
    expiry-date: uint,
    issuer: principal,
    valid: bool
  }
)

(define-data-var next-analyst-id uint u1)
(define-data-var total-analysts uint u0)

;; Public functions
(define-public (register-analyst (name (string-ascii 50)) (certification-level uint))
  (let ((analyst-id (var-get next-analyst-id)))
    (asserts! (is-none (map-get? analysts { analyst-id: analyst-id })) ERR_ANALYST_ALREADY_EXISTS)
    (map-set analysts
      { analyst-id: analyst-id }
      {
        wallet: tx-sender,
        name: name,
        certification-level: certification-level,
        verified: false,
        verification-date: u0,
        total-attributions: u0,
        accuracy-score: u0
      }
    )
    (var-set next-analyst-id (+ analyst-id u1))
    (var-set total-analysts (+ (var-get total-analysts) u1))
    (ok analyst-id)
  )
)

(define-public (verify-analyst (analyst-id uint))
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (match (map-get? analysts { analyst-id: analyst-id })
      analyst-data
      (begin
        (map-set analysts
          { analyst-id: analyst-id }
          (merge analyst-data { verified: true, verification-date: block-height })
        )
        (ok true)
      )
      ERR_ANALYST_NOT_FOUND
    )
  )
)

(define-public (add-certification (analyst-id uint) (certification-type (string-ascii 30)) (expiry-date uint))
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (asserts! (is-some (map-get? analysts { analyst-id: analyst-id })) ERR_ANALYST_NOT_FOUND)
    (map-set analyst-certifications
      { analyst-id: analyst-id, certification-type: certification-type }
      {
        issued-date: block-height,
        expiry-date: expiry-date,
        issuer: tx-sender,
        valid: true
      }
    )
    (ok true)
  )
)

(define-public (update-accuracy-score (analyst-id uint) (new-score uint))
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (match (map-get? analysts { analyst-id: analyst-id })
      analyst-data
      (begin
        (map-set analysts
          { analyst-id: analyst-id }
          (merge analyst-data { accuracy-score: new-score })
        )
        (ok true)
      )
      ERR_ANALYST_NOT_FOUND
    )
  )
)

;; Read-only functions
(define-read-only (get-analyst (analyst-id uint))
  (map-get? analysts { analyst-id: analyst-id })
)

(define-read-only (get-certification (analyst-id uint) (certification-type (string-ascii 30)))
  (map-get? analyst-certifications { analyst-id: analyst-id, certification-type: certification-type })
)

(define-read-only (is-analyst-verified (analyst-id uint))
  (match (map-get? analysts { analyst-id: analyst-id })
    analyst-data (get verified analyst-data)
    false
  )
)

(define-read-only (get-total-analysts)
  (var-get total-analysts)
)
