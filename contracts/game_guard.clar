;; Constants 
(define-constant contract-owner tx-sender)
(define-constant err-not-authorized (err u100))
(define-constant err-invalid-community (err u101))
(define-constant err-already-exists (err u102))
(define-constant err-member-not-found (err u103))

;; Data variables
(define-map communities 
  { community-id: uint }
  {
    name: (string-ascii 50),
    owner: principal,
    member-limit: uint,
    treasury-balance: uint
  }
)

(define-map community-members
  { community-id: uint, member: principal }
  {
    role: uint,
    reputation: uint,
    joined-at: uint
  }
)

;; Create new community
(define-public (create-community (name (string-ascii 50)) (member-limit uint))
  (let ((community-id (+ (var-get next-community-id) u1)))
    (if (is-eq tx-sender contract-owner)
      (begin
        (map-set communities
          { community-id: community-id }
          {
            name: name,
            owner: tx-sender,
            member-limit: member-limit,
            treasury-balance: u0
          }
        )
        (var-set next-community-id community-id)
        (ok community-id)
      )
      err-not-authorized
    )
  )
)

;; Add member to community
(define-public (add-member (community-id uint) (member principal))
  (let ((community (unwrap! (get-community community-id) err-invalid-community)))
    (if (is-community-admin tx-sender community-id)
      (begin 
        (map-set community-members
          { community-id: community-id, member: member }
          {
            role: u1,
            reputation: u0,
            joined-at: block-height
          }
        )
        (ok true)
      )
      err-not-authorized
    )
  )
)

;; Update member role
(define-public (update-member-role (community-id uint) (member principal) (new-role uint))
  (let ((community (unwrap! (get-community community-id) err-invalid-community)))
    (if (is-community-admin tx-sender community-id)
      (match (map-get? community-members { community-id: community-id, member: member })
        member-data (begin
          (map-set community-members
            { community-id: community-id, member: member }
            (merge member-data { role: new-role })
          )
          (ok true)
        )
        err-member-not-found
      )
      err-not-authorized
    )
  )
)

;; Get community details
(define-read-only (get-community (community-id uint))
  (ok (map-get? communities { community-id: community-id }))
)

;; Get member details
(define-read-only (get-member (community-id uint) (member principal))
  (ok (map-get? community-members { community-id: community-id, member: member }))
)

;; Helper function to check if user is community admin
(define-private (is-community-admin (user principal) (community-id uint))
  (match (map-get? communities { community-id: community-id })
    community (is-eq user (get owner community))
    false
  )
)

;; Initialize community ID counter
(define-data-var next-community-id uint u0)
