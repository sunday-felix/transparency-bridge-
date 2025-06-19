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