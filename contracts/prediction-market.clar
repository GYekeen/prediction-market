;; WARNING: For educational/demo use only. Not audited for production.


;; Constants
(define-constant ERR-NOT-ADMIN (err u100))
(define-constant ERR-EVENT-EXISTS (err u101))
(define-constant ERR-EVENT-NOT-FOUND (err u110))
(define-constant ERR-ALREADY-RESOLVED (err u111))
(define-constant ERR-NO-BALANCE (err u112))
(define-constant ERR-UNRESOLVED (err u131))
(define-constant ERR-NO-BET (err u132))
(define-constant ERR-ZERO-BET (err u133))
(define-constant ERR-NOT-AUTHORIZED (err u140))

(define-constant admin 'SP2J6ZY48GV1EZ5V2V5RB9MP66SW86PYKKNRV9EJ7)
(define-constant platform-fee-bps u500) ;; 5% fee

;; Event structure tracks stakes and resolution
(define-map events 
  { event-id: uint }
  { creator: principal
  , yes-staked: uint
  , no-staked: uint
  , resolved: bool
  , outcome: bool } ;; true = Yes, false = No
)

;; Track each user's bets per event
(define-map bets
  { event-id: uint, bettor: principal }
  { yes: uint, no: uint }
)

;; Helper functions
(define-private (to-uint-value (n uint))
  (if (> n u0) n u0))

(define-private (safe-id (id uint))
  (to-uint-value id))

;; ----------------------
;; Admin: Create an event
(define-public (create-event (id uint))
  (let ((safe-event-id (safe-id id)))
    (begin
      (asserts! (is-eq tx-sender admin) ERR-NOT-ADMIN)
      (asserts! (is-none (map-get? events {event-id: safe-event-id})) ERR-EVENT-EXISTS)
      (ok (map-set events {event-id: safe-event-id}
        { creator: tx-sender, yes-staked: u0, no-staked: u0, resolved: false, outcome: false })))))

;; ----------------------
;; Bet function: place stx to yes or no
(define-public (place-bet (id uint) (on-yes bool))
  (let ((safe-event-id (safe-id id))
        (evt (unwrap! (map-get? events {event-id: safe-event-id}) ERR-EVENT-NOT-FOUND)))
    (begin
      (asserts! (not (get resolved evt)) ERR-ALREADY-RESOLVED)
      (let ((amt (stx-get-balance tx-sender)))
        (asserts! (> amt u0) ERR-NO-BALANCE)
        (try! (stx-transfer? amt tx-sender (as-contract tx-sender)))
        ;; update totals
        (let ((new-yes (+ (get yes-staked evt) (if on-yes amt u0)))
              (new-no  (+ (get no-staked evt) (if (not on-yes) amt u0))))
          (ok (begin 
            (map-set events {event-id: safe-event-id}
              { creator: (get creator evt)
              , yes-staked: new-yes
              , no-staked: new-no
              , resolved: false
              , outcome: false })
            ;; update bet record
            (map-set bets {event-id: safe-event-id, bettor: tx-sender}
              { yes: (+ (default-to u0 (get yes (map-get? bets {event-id: safe-event-id, bettor: tx-sender}))) 
                       (if on-yes amt u0))
              , no:  (+ (default-to u0 (get no (map-get? bets {event-id: safe-event-id, bettor: tx-sender})))
                       (if (not on-yes) amt u0)) }))))))))

;; ----------------------
;; Admin: Resolve with oracle input
(define-public (resolve-event (id uint) (outcome-bool bool))
  (let ((safe-event-id (safe-id id))
        (evt (unwrap! (map-get? events {event-id: safe-event-id}) ERR-EVENT-NOT-FOUND)))
    (begin
      (asserts! (is-eq tx-sender admin) ERR-NOT-ADMIN)
      (asserts! (not (get resolved evt)) ERR-ALREADY-RESOLVED)
      (ok (map-set events {event-id: safe-event-id}
        { creator: (get creator evt)
        , yes-staked: (get yes-staked evt)
        , no-staked: (get no-staked evt)
        , resolved: true
        , outcome: outcome-bool })))))

;; ----------------------
;; Claim winnings: users claim share minus fee
(define-public (claim (id uint))
  (let ((safe-event-id (safe-id id))
        (evt (unwrap! (map-get? events {event-id: safe-event-id}) ERR-EVENT-NOT-FOUND)))
    (begin
      (asserts! (get resolved evt) ERR-UNRESOLVED)
      (let ((bet (unwrap! (map-get? bets {event-id: safe-event-id, bettor: tx-sender}) ERR-NO-BET))
            (win-yes? (get outcome evt)))
        (let ((user-bet (if win-yes? (get yes bet) (get no bet)))
              (total-pool (+ (get yes-staked evt) (get no-staked evt))))
          (asserts! (> user-bet u0) ERR-ZERO-BET)
          (let ((winning-pool (if win-yes? (get yes-staked evt) (get no-staked evt)))
                (fee (/ (* total-pool platform-fee-bps) u10000))
                (to-winner (/ (* (- total-pool fee) user-bet) winning-pool)))
            (try! (stx-transfer? to-winner (as-contract tx-sender) tx-sender))
            (map-set bets {event-id: safe-event-id, bettor: tx-sender} { yes: u0, no: u0 })
            (ok to-winner)))))))

;; ----------------------
;; Admin: withdraw fees
(define-public (withdraw-fees)
  (begin
    (asserts! (is-eq tx-sender admin) ERR-NOT-AUTHORIZED)
    (let ((bal (stx-get-balance (as-contract tx-sender))))
      ;; For simplicity, withdraw all available STX
      (try! (stx-transfer? bal (as-contract tx-sender) tx-sender))
      (ok bal))))
