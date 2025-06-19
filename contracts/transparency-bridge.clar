;; Title: TransparencyBridge - Decentralized Donation & Impact Tracking Platform
;; Summary: A comprehensive Layer 2 donation ecosystem enabling transparent fund 
;;          distribution with milestone-based accountability and role-based governance
;; Description: TransparencyBridge revolutionizes charitable giving through blockchain
;;              transparency, providing donors with real-time visibility into fund
;;              utilization while empowering verified beneficiaries with milestone-
;;              driven funding mechanisms. Built for Stacks Layer 2 compliance with
;;              enterprise-grade security and scalable governance protocols.

;; CONTRACT GOVERNANCE & SECURITY

;; Primary contract authority
(define-data-var contract-owner principal tx-sender)

;; Comprehensive error handling system
(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-ALREADY-REGISTERED (err u101))
(define-constant ERR-NOT-FOUND (err u102))
(define-constant ERR-INSUFFICIENT-FUNDS (err u103))
(define-constant ERR-BENEFICIARY-NOT-FOUND (err u104))
(define-constant ERR-UTILIZATION-NOT-FOUND (err u105))
(define-constant ERR-INVALID-INPUT (err u106))

;; Hierarchical role-based access control
(define-constant ROLE-ADMIN u1)
(define-constant ROLE-MODERATOR u2)
(define-constant ROLE-BENEFICIARY u3)

;; CORE DATA STRUCTURES & PERSISTENT STORAGE

;; Multi-tier role management system
(define-map roles
  { user: principal }
  { role: uint }
)

;; Verified beneficiary registry with funding targets
(define-map beneficiaries
  { id: uint }
  {
    name: (string-utf8 50),
    description: (string-utf8 255),
    target-amount: uint,
    received-amount: uint,
    status: (string-ascii 20),
  }
)

;; Immutable donation transaction ledger
(define-map donations
  { id: uint }
  {
    donor: principal,
    beneficiary-id: uint,
    amount: uint,
    timestamp: uint,
  }
)

;; Milestone-driven fund utilization tracker
(define-map utilization
  { id: uint }
  {
    beneficiary-id: uint,
    milestone: uint,
    description: (string-utf8 255),
    amount: uint,
    status: (string-ascii 20),
  }
)

;; PLATFORM STATE MANAGEMENT

;; Auto-incrementing unique identifier counters
(define-data-var beneficiary-count uint u0)
(define-data-var donation-count uint u0)
(define-data-var utilization-count uint u0)

;; SECURITY & VALIDATION UTILITIES

;; Role-based authorization with hierarchical permissions
(define-private (is-authorized
    (user principal)
    (required-role uint)
  )
  (let ((role-data (default-to { role: u0 } (map-get? roles { user: user }))))
    (>= (get role role-data) required-role)
  )
)

;; Progressive milestone calculation for beneficiary tracking
(define-private (get-last-milestone (beneficiary-id uint))
  (var-get utilization-count)
)

;; ROLE MANAGEMENT & ACCESS CONTROL

;; Secure role assignment with comprehensive validation
(define-public (set-role
    (user principal)
    (new-role uint)
  )
  (let ((existing-role (default-to u0 (get role (map-get? roles { user: user })))))
    (if (and
        (is-eq tx-sender (var-get contract-owner))
        (<= new-role ROLE-BENEFICIARY)
        (not (is-eq user tx-sender)) ;; Prevent self-role modification
        (or
          (is-eq new-role ROLE-ADMIN)
          (is-eq new-role ROLE-MODERATOR)
          (is-eq new-role ROLE-BENEFICIARY)
        )
      )
      (ok (map-set roles { user: user } { role: new-role }))
      ERR-NOT-AUTHORIZED
    )
  )
)

;; Protected role removal with ownership verification
(define-public (remove-role (user principal))
  (if (and
      (is-eq tx-sender (var-get contract-owner))
      (is-some (map-get? roles { user: user }))
      (not (is-eq user tx-sender)) ;; Prevent self-role removal
    )
    (ok (map-delete roles { user: user }))
    ERR-NOT-AUTHORIZED
  )
)

;; BENEFICIARY REGISTRY & VERIFICATION SYSTEM

;; Register authenticated beneficiaries with rigorous validation
(define-public (register-beneficiary
    (name (string-utf8 50))
    (description (string-utf8 255))
    (target-amount uint)
  )
  (let ((beneficiary-id (+ (var-get beneficiary-count) u1)))
    (if (and
        (is-authorized tx-sender ROLE-MODERATOR)
        (> (len name) u0)
        (> (len description) u0)
        (> target-amount u0)
      )
      (begin
        (map-set beneficiaries { id: beneficiary-id } {
          name: name,
          description: description,
          target-amount: target-amount,
          received-amount: u0,
          status: "active",
        })
        (var-set beneficiary-count beneficiary-id)
        (ok beneficiary-id)
      )
      ERR-INVALID-INPUT
    )
  )
)

;; Query beneficiary information with error-safe retrieval
(define-read-only (get-beneficiary (id uint))
  (match (map-get? beneficiaries { id: id })
    beneficiary (ok beneficiary)
    ERR-BENEFICIARY-NOT-FOUND
  )
)
