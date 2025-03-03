;; Constants 
(define-constant contract-owner tx-sender)
(define-constant err-not-authorized (err u100))
(define-constant err-invalid-community (err u101))
(define-constant err-already-exists (err u102))
(define-constant err-member-not-found (err u103))
(define-constant err-member-limit-reached (err u104))
(define-constant err-invalid-role (err u105))

;; Role constants
(define-constant role-member u1)
(define-constant role-moderator u2)
(define-constant role-admin u3)

;; Data variables
(define-map communities 
  { community-id: uint }
  {
    name: (string-ascii 50),
    owner: principal,
    member-limit: uint,
    member-count: uint,
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
    (asserts! (is-eq tx-sender contract-owner) err-not-authorized)
    (map-set communities
      { community-id: community-id }
      {
        name: name,
        owner: tx-sender,
        member-limit: member-limit,
        member-count: u0,
        treasury-balance: u0
      }
    )
    (var-set next-community-id community-id)
    (print { type: "community_created", community-id: community-id, name: name })
    (ok community-id)
  )
)

;; Add member to community
(define-public (add-member (community-id uint) (member principal))
  (let (
    (community (unwrap! (get-community community-id) err-invalid-community))
    (current-count (get member-count community))
    (member-limit (get member-limit community))
  )
    (asserts! (is-community-admin tx-sender community-id) err-not-authorized)
    (asserts! (< current-count member-limit) err-member-limit-reached)
    (asserts! (is-none (map-get? community-members { community-id: community-id, member: member })) err-already-exists)
    
    (map-set community-members
      { community-id: community-id, member: member }
      {
        role: role-member,
        reputation: u0,
        joined-at: block-height
      }
    )
    
    (map-set communities 
      { community-id: community-id }
      (merge community { member-count: (+ current-count u1) })
    )
    
    (print { type: "member_added", community-id: community-id, member: member })
    (ok true)
  )
)

;; Remove member from community
(define-public (remove-member (community-id uint) (member principal))
  (let (
    (community (unwrap! (get-community community-id) err-invalid-community))
    (current-count (get member-count community))
  )
    (asserts! (is-community-admin tx-sender community-id) err-not-authorized)
    (asserts! (is-some (map-get? community-members { community-id: community-id, member: member })) err-member-not-found)
    
    (map-delete community-members { community-id: community-id, member: member })
    (map-set communities 
      { community-id: community-id }
      (merge community { member-count: (- current-count u1) })
    )
    
    (print { type: "member_removed", community-id: community-id, member: member })
    (ok true)
  )
)

;; Update member role
(define-public (update-member-role (community-id uint) (member principal) (new-role uint))
  (let ((community (unwrap! (get-community community-id) err-invalid-community)))
    (asserts! (is-community-admin tx-sender community-id) err-not-authorized)
    (asserts! (and (>= new-role role-member) (<= new-role role-admin)) err-invalid-role)
    
    (match (map-get? community-members { community-id: community-id, member: member })
      member-data (begin
        (map-set community-members
          { community-id: community-id, member: member }
          (merge member-data { role: new-role })
        )
        (print { type: "role_updated", community-id: community-id, member: member, new-role: new-role })
        (ok true)
      )
      err-member-not-found
    )
  )
)

;; Read-only functions
(define-read-only (get-community (community-id uint))
  (ok (map-get? communities { community-id: community-id }))
)

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
