;; ClarinetChamber - Elite Chamber Music Collective Platform
;; A blockchain-based platform for clarinet chamber music formation, ensemble rehearsal tracking,
;; intimate performance management, and collaborative artistic excellence

;; Contract constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-already-exists (err u102))
(define-constant err-unauthorized (err u103))
(define-constant err-invalid-input (err u104))
(define-constant err-insufficient-balance (err u105))
(define-constant err-ensemble-full (err u106))

;; Token constants
(define-constant token-name "ClarinetChamber Cantabile Token")
(define-constant token-symbol "CCT")
(define-constant token-decimals u6)
(define-constant token-max-supply u88000000000) ;; 88k tokens with 6 decimals

;; Reward amounts (in micro-tokens)
(define-constant reward-rehearsal u4200000) ;; 4.2 CCT
(define-constant reward-performance u9800000) ;; 9.8 CCT
(define-constant reward-formation u12500000) ;; 12.5 CCT
(define-constant reward-collaboration u28000000) ;; 28.0 CCT

;; Additional constants
(define-constant min-ensemble-size u2)
(define-constant max-ensemble-size u8)
(define-constant rehearsal-vote-threshold u3)

;; Data variables
(define-data-var total-supply uint u0)
(define-data-var next-ensemble-id uint u1)
(define-data-var next-rehearsal-id uint u1)
(define-data-var next-performance-id uint u1)
(define-data-var platform-fee uint u100000) ;; 0.1 CCT

;; Token balances
(define-map token-balances principal uint)

;; Chamber musician profiles
(define-map chamber-profiles
  principal
  {
    chamber-name: (string-ascii 21),
    ensemble-role: (string-ascii 15), ;; "principal", "co-principal", "assistant", "substitute", "guest"
    specialization: (string-ascii 12), ;; "soprano", "alto", "bass", "contrabass", "multi"
    rehearsals-attended: uint,
    performances-given: uint,
    ensembles-formed: uint,
    total-chamber: uint,
    ensemble-rating: uint, ;; 1-5
    chamber-reputation: uint, ;; reputation points
    registration-date: uint
  }
)

;; Chamber ensembles
(define-map chamber-ensembles
  uint
  {
    ensemble-title: (string-ascii 14),
    formation-style: (string-ascii 12), ;; "classical", "contemporary", "experimental", "traditional"
    instrumentation: (string-ascii 10), ;; "duo", "trio", "quartet", "quintet", "sextet", "septet", "octet"
    performance-level: (string-ascii 11), ;; "amateur", "semi-pro", "professional", "virtuoso"
    duration: uint, ;; minutes
    rehearsal-tempo: uint, ;; BPM
    max-members: uint,
    current-members: uint,
    founder: principal,
    rehearsal-count: uint,
    chamber-score: uint, ;; average chamber performance
    ensemble-treasury: uint, ;; shared token pool
    active-status: bool
  }
)

;; Ensemble memberships
(define-map ensemble-memberships
  { ensemble-id: uint, member: principal }
  {
    join-date: uint,
    member-role: (string-ascii 15),
    contribution-score: uint,
    active-member: bool
  }
)

;; Chamber rehearsals
(define-map chamber-rehearsals
  uint
  {
    ensemble-id: uint,
    rehearsal-leader: principal,
    repertoire-focus: (string-ascii 12),
    rehearsal-duration: uint, ;; minutes
    ensemble-tempo: uint, ;; BPM
    balance-quality: uint, ;; 1-5
    intonation-precision: uint, ;; 1-5
    rhythmic-ensemble: uint, ;; 1-5
    musical-communication: uint, ;; 1-5
    rehearsal-notes: (string-ascii 16),
    rehearsal-date: uint,
    participants: (list 8 principal),
    collaborative: bool,
    approved-votes: uint
  }
)

;; Chamber performances
(define-map chamber-performances
  uint
  {
    ensemble-id: uint,
    performance-title: (string-ascii 12),
    venue-type: (string-ascii 8), ;; "salon", "hall", "outdoor", "private", "studio"
    audience-size: uint,
    performance-date: uint,
    performers: (list 8 principal),
    performance-revenue: uint,
    artistic-success: bool
  }
)

;; Performance reviews
(define-map performance-reviews
  { performance-id: uint, reviewer: principal }
  {
    rating: uint, ;; 1-10
    review-content: (string-ascii 16),
    ensemble-chemistry: (string-ascii 9), ;; "poor", "adequate", "good", "excellent", "masterful"
    technical-execution: (string-ascii 9),
    musical-interpretation: (string-ascii 9),
    review-date: uint,
    helpful-votes: uint
  }
)

;; Collaborative achievements
(define-map collaborative-achievements
  { musician: principal, achievement: (string-ascii 16) }
  {
    achievement-date: uint,
    ensemble-context: uint,
    rehearsal-total: uint,
    collaboration-score: uint
  }
)

;; Ensemble invitations
(define-map ensemble-invitations
  { ensemble-id: uint, invitee: principal }
  {
    inviter: principal,
    invitation-date: uint,
    proposed-role: (string-ascii 15),
    invitation-message: (string-ascii 20),
    status: (string-ascii 8) ;; "pending", "accepted", "declined", "expired"
  }
)

;; Helper function to get or create profile
(define-private (get-or-create-profile (musician principal))
  (match (map-get? chamber-profiles musician)
    profile profile
    {
      chamber-name: "",
      ensemble-role: "substitute",
      specialization: "soprano",
      rehearsals-attended: u0,
      performances-given: u0,
      ensembles-formed: u0,
      total-chamber: u0,
      ensemble-rating: u1,
      chamber-reputation: u0,
      registration-date: stacks-block-height
    }
  )
)

;; Helper function to check ensemble membership
(define-private (is-ensemble-member (ensemble-id uint) (member principal))
  (match (map-get? ensemble-memberships {ensemble-id: ensemble-id, member: member})
    membership (get active-member membership)
    false
  )
)

;; Token functions
(define-read-only (get-name)
  (ok token-name)
)

(define-read-only (get-symbol)
  (ok token-symbol)
)

(define-read-only (get-decimals)
  (ok token-decimals)
)

(define-read-only (get-balance (user principal))
  (ok (default-to u0 (map-get? token-balances user)))
)

(define-read-only (get-total-supply)
  (ok (var-get total-supply))
)

(define-private (mint-tokens (recipient principal) (amount uint))
  (let (
    (current-balance (default-to u0 (map-get? token-balances recipient)))
    (new-balance (+ current-balance amount))
    (new-total-supply (+ (var-get total-supply) amount))
  )
    (asserts! (<= new-total-supply token-max-supply) err-invalid-input)
    (map-set token-balances recipient new-balance)
    (var-set total-supply new-total-supply)
    (ok amount)
  )
)

(define-private (transfer-tokens (sender principal) (recipient principal) (amount uint))
  (let (
    (sender-balance (default-to u0 (map-get? token-balances sender)))
    (recipient-balance (default-to u0 (map-get? token-balances recipient)))
  )
    (asserts! (>= sender-balance amount) err-insufficient-balance)
    (map-set token-balances sender (- sender-balance amount))
    (map-set token-balances recipient (+ recipient-balance amount))
    (ok amount)
  )
)

;; Create chamber ensemble
(define-public (create-ensemble (ensemble-title (string-ascii 14)) (formation-style (string-ascii 12)) (instrumentation (string-ascii 10)) (performance-level (string-ascii 11)) (duration uint) (rehearsal-tempo uint) (max-members uint))
  (let (
    (ensemble-id (var-get next-ensemble-id))
    (profile (get-or-create-profile tx-sender))
  )
    (asserts! (> (len ensemble-title) u0) err-invalid-input)
    (asserts! (> duration u0) err-invalid-input)
    (asserts! (and (>= rehearsal-tempo u50) (<= rehearsal-tempo u180)) err-invalid-input)
    (asserts! (and (>= max-members min-ensemble-size) (<= max-members max-ensemble-size)) err-invalid-input)
    
    (map-set chamber-ensembles ensemble-id {
      ensemble-title: ensemble-title,
      formation-style: formation-style,
      instrumentation: instrumentation,
      performance-level: performance-level,
      duration: duration,
      rehearsal-tempo: rehearsal-tempo,
      max-members: max-members,
      current-members: u1,
      founder: tx-sender,
      rehearsal-count: u0,
      chamber-score: u0,
      ensemble-treasury: u0,
      active-status: true
    })
    
    ;; Add founder as first member
    (map-set ensemble-memberships {ensemble-id: ensemble-id, member: tx-sender} {
      join-date: stacks-block-height,
      member-role: "principal",
      contribution-score: u0,
      active-member: true
    })
    
    ;; Update profile
    (map-set chamber-profiles tx-sender
      (merge profile {
        ensembles-formed: (+ (get ensembles-formed profile) u1),
        chamber-reputation: (+ (get chamber-reputation profile) u5)
      })
    )
    
    ;; Award formation tokens
    (try! (mint-tokens tx-sender reward-formation))
    
    (var-set next-ensemble-id (+ ensemble-id u1))
    (print {action: "ensemble-created", ensemble-id: ensemble-id, founder: tx-sender})
    (ok ensemble-id)
  )
)

;; Send ensemble invitation
(define-public (invite-member (ensemble-id uint) (invitee principal) (proposed-role (string-ascii 15)) (invitation-message (string-ascii 20)))
  (let (
    (ensemble (unwrap! (map-get? chamber-ensembles ensemble-id) err-not-found))
  )
    (asserts! (is-ensemble-member ensemble-id tx-sender) err-unauthorized)
    (asserts! (< (get current-members ensemble) (get max-members ensemble)) err-ensemble-full)
    (asserts! (not (is-ensemble-member ensemble-id invitee)) err-already-exists)
    (asserts! (is-none (map-get? ensemble-invitations {ensemble-id: ensemble-id, invitee: invitee})) err-already-exists)
    
    (map-set ensemble-invitations {ensemble-id: ensemble-id, invitee: invitee} {
      inviter: tx-sender,
      invitation-date: stacks-block-height,
      proposed-role: proposed-role,
      invitation-message: invitation-message,
      status: "pending"
    })
    
    (print {action: "invitation-sent", ensemble-id: ensemble-id, invitee: invitee})
    (ok true)
  )
)

;; Accept ensemble invitation
(define-public (accept-invitation (ensemble-id uint))
  (let (
    (invitation (unwrap! (map-get? ensemble-invitations {ensemble-id: ensemble-id, invitee: tx-sender}) err-not-found))
    (ensemble (unwrap! (map-get? chamber-ensembles ensemble-id) err-not-found))
    (profile (get-or-create-profile tx-sender))
  )
    (asserts! (is-eq (get status invitation) "pending") err-unauthorized)
    (asserts! (< (get current-members ensemble) (get max-members ensemble)) err-ensemble-full)
    
    ;; Update invitation status
    (map-set ensemble-invitations {ensemble-id: ensemble-id, invitee: tx-sender}
      (merge invitation {status: "accepted"})
    )
    
    ;; Add member to ensemble
    (map-set ensemble-memberships {ensemble-id: ensemble-id, member: tx-sender} {
      join-date: stacks-block-height,
      member-role: (get proposed-role invitation),
      contribution-score: u0,
      active-member: true
    })
    
    ;; Update ensemble member count
    (map-set chamber-ensembles ensemble-id
      (merge ensemble {current-members: (+ (get current-members ensemble) u1)})
    )
    
    ;; Update profile reputation
    (map-set chamber-profiles tx-sender
      (merge profile {chamber-reputation: (+ (get chamber-reputation profile) u2)})
    )
    
    (print {action: "invitation-accepted", ensemble-id: ensemble-id, new-member: tx-sender})
    (ok true)
  )
)

;; Log chamber rehearsal
(define-public (log-rehearsal (ensemble-id uint) (repertoire-focus (string-ascii 12)) (rehearsal-duration uint) (ensemble-tempo uint) (balance-quality uint) (intonation-precision uint) (rhythmic-ensemble uint) (musical-communication uint) (rehearsal-notes (string-ascii 16)) (participants (list 8 principal)) (collaborative bool))
  (let (
    (rehearsal-id (var-get next-rehearsal-id))
    (ensemble (unwrap! (map-get? chamber-ensembles ensemble-id) err-not-found))
    (profile (get-or-create-profile tx-sender))
  )
    (asserts! (is-ensemble-member ensemble-id tx-sender) err-unauthorized)
    (asserts! (> rehearsal-duration u0) err-invalid-input)
    (asserts! (and (>= ensemble-tempo u40) (<= ensemble-tempo u200)) err-invalid-input)
    (asserts! (and (>= balance-quality u1) (<= balance-quality u5)) err-invalid-input)
    (asserts! (and (>= intonation-precision u1) (<= intonation-precision u5)) err-invalid-input)
    (asserts! (and (>= rhythmic-ensemble u1) (<= rhythmic-ensemble u5)) err-invalid-input)
    (asserts! (and (>= musical-communication u1) (<= musical-communication u5)) err-invalid-input)
    (asserts! (> (len participants) u1) err-invalid-input)
    
    (map-set chamber-rehearsals rehearsal-id {
      ensemble-id: ensemble-id,
      rehearsal-leader: tx-sender,
      repertoire-focus: repertoire-focus,
      rehearsal-duration: rehearsal-duration,
      ensemble-tempo: ensemble-tempo,
      balance-quality: balance-quality,
      intonation-precision: intonation-precision,
      rhythmic-ensemble: rhythmic-ensemble,
      musical-communication: musical-communication,
      rehearsal-notes: rehearsal-notes,
      rehearsal-date: stacks-block-height,
      participants: participants,
      collaborative: collaborative,
      approved-votes: u0
    })
    
    ;; Update ensemble stats if collaborative
    (if collaborative
      (let (
        (new-rehearsal-count (+ (get rehearsal-count ensemble) u1))
        (current-chamber (* (get chamber-score ensemble) (get rehearsal-count ensemble)))
        (chamber-value (/ (+ balance-quality intonation-precision rhythmic-ensemble musical-communication) u4))
        (new-chamber-score (/ (+ current-chamber chamber-value) new-rehearsal-count))
      )
        (map-set chamber-ensembles ensemble-id
          (merge ensemble {
            rehearsal-count: new-rehearsal-count,
            chamber-score: new-chamber-score
          })
        )
        true
      )
      true
    )
    
    ;; Update profile
    (if collaborative
      (begin
        (map-set chamber-profiles tx-sender
          (merge profile {
            rehearsals-attended: (+ (get rehearsals-attended profile) u1),
            total-chamber: (+ (get total-chamber profile) (/ rehearsal-duration u60)),
            ensemble-rating: (+ (get ensemble-rating profile) (/ balance-quality u25)),
            chamber-reputation: (+ (get chamber-reputation profile) u3)
          })
        )
        (try! (mint-tokens tx-sender reward-rehearsal))
        true
      )
      (begin
        (try! (mint-tokens tx-sender (/ reward-rehearsal u9)))
        true
      )
    )
    
    (var-set next-rehearsal-id (+ rehearsal-id u1))
    (print {action: "rehearsal-logged", rehearsal-id: rehearsal-id, ensemble-id: ensemble-id})
    (ok rehearsal-id)
  )
)

;; Vote to approve rehearsal
(define-public (vote-rehearsal-approval (rehearsal-id uint))
  (let (
    (rehearsal (unwrap! (map-get? chamber-rehearsals rehearsal-id) err-not-found))
  )
    (asserts! (is-ensemble-member (get ensemble-id rehearsal) tx-sender) err-unauthorized)
    (asserts! (not (is-eq tx-sender (get rehearsal-leader rehearsal))) err-unauthorized)
    
    (map-set chamber-rehearsals rehearsal-id
      (merge rehearsal {approved-votes: (+ (get approved-votes rehearsal) u1)})
    )
    
    ;; Award bonus if rehearsal reaches approval threshold
    (if (>= (+ (get approved-votes rehearsal) u1) rehearsal-vote-threshold)
      (begin
        (try! (mint-tokens (get rehearsal-leader rehearsal) (/ reward-rehearsal u2)))
        true
      )
      true
    )
    
    (print {action: "rehearsal-approved", rehearsal-id: rehearsal-id, voter: tx-sender})
    (ok true)
  )
)

;; Schedule chamber performance
(define-public (schedule-performance (ensemble-id uint) (performance-title (string-ascii 12)) (venue-type (string-ascii 8)) (audience-size uint) (performers (list 8 principal)))
  (let (
    (performance-id (var-get next-performance-id))
    (ensemble (unwrap! (map-get? chamber-ensembles ensemble-id) err-not-found))
    (profile (get-or-create-profile tx-sender))
  )
    (asserts! (is-ensemble-member ensemble-id tx-sender) err-unauthorized)
    (asserts! (> (len performance-title) u0) err-invalid-input)
    (asserts! (> audience-size u0) err-invalid-input)
    (asserts! (> (len performers) u1) err-invalid-input)
    
    (map-set chamber-performances performance-id {
      ensemble-id: ensemble-id,
      performance-title: performance-title,
      venue-type: venue-type,
      audience-size: audience-size,
      performance-date: stacks-block-height,
      performers: performers,
      performance-revenue: u0,
      artistic-success: false
    })
    
    ;; Update profile
    (map-set chamber-profiles tx-sender
      (merge profile {
        performances-given: (+ (get performances-given profile) u1),
        chamber-reputation: (+ (get chamber-reputation profile) u4)
      })
    )
    
    ;; Award performance tokens
    (try! (mint-tokens tx-sender reward-performance))
    
    (var-set next-performance-id (+ performance-id u1))
    (print {action: "performance-scheduled", performance-id: performance-id, ensemble-id: ensemble-id})
    (ok performance-id)
  )
)

;; Write performance review
(define-public (write-review (performance-id uint) (rating uint) (review-content (string-ascii 16)) (ensemble-chemistry (string-ascii 9)) (technical-execution (string-ascii 9)) (musical-interpretation (string-ascii 9)))
  (let (
    (performance (unwrap! (map-get? chamber-performances performance-id) err-not-found))
  )
    (asserts! (and (>= rating u1) (<= rating u10)) err-invalid-input)
    (asserts! (> (len review-content) u0) err-invalid-input)
    (asserts! (is-none (map-get? performance-reviews {performance-id: performance-id, reviewer: tx-sender})) err-already-exists)
    
    (map-set performance-reviews {performance-id: performance-id, reviewer: tx-sender} {
      rating: rating,
      review-content: review-content,
      ensemble-chemistry: ensemble-chemistry,
      technical-execution: technical-execution,
      musical-interpretation: musical-interpretation,
      review-date: stacks-block-height,
      helpful-votes: u0
    })
    
    (print {action: "review-written", performance-id: performance-id, reviewer: tx-sender})
    (ok true)
  )
)

;; Vote helpful on review
(define-public (vote-helpful (performance-id uint) (reviewer principal))
  (let (
    (review (unwrap! (map-get? performance-reviews {performance-id: performance-id, reviewer: reviewer}) err-not-found))
  )
    (asserts! (not (is-eq tx-sender reviewer)) err-unauthorized)
    
    (map-set performance-reviews {performance-id: performance-id, reviewer: reviewer}
      (merge review {helpful-votes: (+ (get helpful-votes review) u1)})
    )
    
    (print {action: "review-helpful", performance-id: performance-id, reviewer: reviewer})
    (ok true)
  )
)

;; Update specialization
(define-public (update-specialization (new-specialization (string-ascii 12)))
  (let (
    (profile (get-or-create-profile tx-sender))
  )
    (asserts! (> (len new-specialization) u0) err-invalid-input)
    
    (map-set chamber-profiles tx-sender (merge profile {specialization: new-specialization}))
    
    (print {action: "specialization-updated", musician: tx-sender, specialization: new-specialization})
    (ok true)
  )
)

;; Claim collaborative achievement
(define-public (claim-achievement (achievement (string-ascii 16)))
  (let (
    (profile (get-or-create-profile tx-sender))
  )
    (asserts! (is-none (map-get? collaborative-achievements {musician: tx-sender, achievement: achievement})) err-already-exists)
    
    ;; Check achievement requirements
    (let (
      (achievement-earned
        (if (is-eq achievement "chamber-virtuoso") (>= (get rehearsals-attended profile) u50)
        (if (is-eq achievement "ensemble-master") (>= (get ensembles-formed profile) u5)
        (if (is-eq achievement "collaboration-expert") (>= (get chamber-reputation profile) u100)
        false))))
    )
      (asserts! achievement-earned err-unauthorized)
      
      ;; Record achievement
      (map-set collaborative-achievements {musician: tx-sender, achievement: achievement} {
        achievement-date: stacks-block-height,
        ensemble-context: (get ensembles-formed profile),
        rehearsal-total: (get rehearsals-attended profile),
        collaboration-score: (get chamber-reputation profile)
      })
      
      ;; Award collaboration tokens
      (try! (mint-tokens tx-sender reward-collaboration))
      
      (print {action: "achievement-claimed", musician: tx-sender, achievement: achievement})
      (ok true)
    )
  )
)

;; Update chamber name
(define-public (update-chamber-name (new-chamber-name (string-ascii 21)))
  (let (
    (profile (get-or-create-profile tx-sender))
  )
    (asserts! (> (len new-chamber-name) u0) err-invalid-input)
    (map-set chamber-profiles tx-sender (merge profile {chamber-name: new-chamber-name}))
    (print {action: "chamber-name-updated", musician: tx-sender})
    (ok true)
  )
)

;; Read-only functions
(define-read-only (get-chamber-profile (musician principal))
  (map-get? chamber-profiles musician)
)

(define-read-only (get-chamber-ensemble (ensemble-id uint))
  (map-get? chamber-ensembles ensemble-id)
)

(define-read-only (get-ensemble-membership (ensemble-id uint) (member principal))
  (map-get? ensemble-memberships {ensemble-id: ensemble-id, member: member})
)

(define-read-only (get-chamber-rehearsal (rehearsal-id uint))
  (map-get? chamber-rehearsals rehearsal-id)
)

(define-read-only (get-chamber-performance (performance-id uint))
  (map-get? chamber-performances performance-id)
)

(define-read-only (get-performance-review (performance-id uint) (reviewer principal))
  (map-get? performance-reviews {performance-id: performance-id, reviewer: reviewer})
)

(define-read-only (get-achievement (musician principal) (achievement (string-ascii 16)))
  (map-get? collaborative-achievements {musician: musician, achievement: achievement})
)

(define-read-only (get-ensemble-invitation (ensemble-id uint) (invitee principal))
  (map-get? ensemble-invitations {ensemble-id: ensemble-id, invitee: invitee})
)