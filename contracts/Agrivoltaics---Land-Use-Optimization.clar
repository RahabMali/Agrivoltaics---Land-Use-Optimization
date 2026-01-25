(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-unauthorized (err u102))
(define-constant err-invalid-amount (err u103))
(define-constant err-lease-active (err u104))
(define-constant err-lease-expired (err u105))
(define-constant err-insufficient-balance (err u106))
(define-constant err-auction-not-found (err u107))
(define-constant err-auction-ended (err u108))
(define-constant err-bid-too-low (err u109))
(define-constant err-auction-active (err u110))

(define-data-var land-id-nonce uint u0)
(define-data-var lease-id-nonce uint u0)
(define-data-var yield-token-supply uint u0)
(define-data-var auction-id-nonce uint u0)

(define-map lands
  { land-id: uint }
  {
    owner: principal,
    location: (string-ascii 100),
    size-hectares: uint,
    solar-capacity-kw: uint,
    crop-type: (string-ascii 50),
    is-active: bool
  }
)

(define-map leases
  { lease-id: uint }
  {
    land-id: uint,
    lessee: principal,
    lessor: principal,
    start-block: uint,
    end-block: uint,
    solar-revenue-share: uint,
    crop-revenue-share: uint,
    monthly-rent: uint,
    is-active: bool
  }
)

(define-map yield-tokens
  { token-id: uint }
  {
    land-id: uint,
    token-type: (string-ascii 20),
    amount: uint,
    price-per-unit: uint,
    owner: principal,
    is-available: bool
  }
)

(define-map land-revenues
  { land-id: uint }
  {
    total-solar-revenue: uint,
    total-crop-revenue: uint,
    pending-distribution: uint,
    last-updated: uint
  }
)

(define-map user-balances
  { user: principal }
  { balance: uint }
)

(define-map land-auctions
  { auction-id: uint }
  {
    land-id: uint,
    seller: principal,
    starting-price: uint,
    current-bid: uint,
    highest-bidder: (optional principal),
    end-block: uint,
    is-active: bool
  }
)

(define-public (register-land (location (string-ascii 100)) (size-hectares uint) (solar-capacity-kw uint) (crop-type (string-ascii 50)))
  (let ((new-land-id (+ (var-get land-id-nonce) u1)))
    (asserts! (> size-hectares u0) err-invalid-amount)
    (asserts! (> solar-capacity-kw u0) err-invalid-amount)
    (map-set lands { land-id: new-land-id }
      {
        owner: tx-sender,
        location: location,
        size-hectares: size-hectares,
        solar-capacity-kw: solar-capacity-kw,
        crop-type: crop-type,
        is-active: true
      }
    )
    (map-set land-revenues { land-id: new-land-id }
      {
        total-solar-revenue: u0,
        total-crop-revenue: u0,
        pending-distribution: u0,
        last-updated: stacks-block-height
      }
    )
    (var-set land-id-nonce new-land-id)
    (ok new-land-id)
  )
)

(define-public (create-lease (land-id uint) (lessee principal) (duration-blocks uint) (solar-share uint) (crop-share uint) (monthly-rent uint))
  (let 
    (
      (land (unwrap! (map-get? lands { land-id: land-id }) err-not-found))
      (new-lease-id (+ (var-get lease-id-nonce) u1))
      (end-block (+ stacks-block-height duration-blocks))
    )
    (asserts! (is-eq tx-sender (get owner land)) err-unauthorized)
    (asserts! (get is-active land) err-not-found)
    (asserts! (and (<= solar-share u100) (<= crop-share u100)) err-invalid-amount)
    (asserts! (> duration-blocks u0) err-invalid-amount)
    
    (map-set leases { lease-id: new-lease-id }
      {
        land-id: land-id,
        lessee: lessee,
        lessor: tx-sender,
        start-block: stacks-block-height,
        end-block: end-block,
        solar-revenue-share: solar-share,
        crop-revenue-share: crop-share,
        monthly-rent: monthly-rent,
        is-active: true
      }
    )
    (var-set lease-id-nonce new-lease-id)
    (ok new-lease-id)
  )
)

(define-public (mint-yield-token (land-id uint) (token-type (string-ascii 20)) (amount uint) (price-per-unit uint))
  (let 
    (
      (land (unwrap! (map-get? lands { land-id: land-id }) err-not-found))
      (new-token-id (+ (var-get yield-token-supply) u1))
    )
    (asserts! (is-eq tx-sender (get owner land)) err-unauthorized)
    (asserts! (> amount u0) err-invalid-amount)
    (asserts! (> price-per-unit u0) err-invalid-amount)
    
    (map-set yield-tokens { token-id: new-token-id }
      {
        land-id: land-id,
        token-type: token-type,
        amount: amount,
        price-per-unit: price-per-unit,
        owner: tx-sender,
        is-available: true
      }
    )
    (var-set yield-token-supply new-token-id)
    (ok new-token-id)
  )
)

(define-public (buy-yield-token (token-id uint))
  (let 
    (
      (token (unwrap! (map-get? yield-tokens { token-id: token-id }) err-not-found))
      (total-cost (* (get amount token) (get price-per-unit token)))
      (buyer-balance (default-to u0 (get balance (map-get? user-balances { user: tx-sender }))))
    )
    (asserts! (get is-available token) err-not-found)
    (asserts! (>= buyer-balance total-cost) err-insufficient-balance)
    
    (map-set user-balances { user: tx-sender } { balance: (- buyer-balance total-cost) })
    (map-set user-balances { user: (get owner token) } 
      { balance: (+ (default-to u0 (get balance (map-get? user-balances { user: (get owner token) }))) total-cost) }
    )
    (map-set yield-tokens { token-id: token-id }
      (merge token { owner: tx-sender, is-available: false })
    )
    (ok true)
  )
)

(define-public (add-revenue (land-id uint) (solar-revenue uint) (crop-revenue uint))
  (let 
    (
      (land (unwrap! (map-get? lands { land-id: land-id }) err-not-found))
      (current-revenue (default-to 
        { total-solar-revenue: u0, total-crop-revenue: u0, pending-distribution: u0, last-updated: u0 }
        (map-get? land-revenues { land-id: land-id })
      ))
    )
    (asserts! (is-eq tx-sender (get owner land)) err-unauthorized)
    
    (map-set land-revenues { land-id: land-id }
      {
        total-solar-revenue: (+ (get total-solar-revenue current-revenue) solar-revenue),
        total-crop-revenue: (+ (get total-crop-revenue current-revenue) crop-revenue),
        pending-distribution: (+ (get pending-distribution current-revenue) solar-revenue crop-revenue),
        last-updated: stacks-block-height
      }
    )
    (ok true)
  )
)

(define-public (distribute-revenue (lease-id uint))
  (let 
    (
      (lease (unwrap! (map-get? leases { lease-id: lease-id }) err-not-found))
      (land-id (get land-id lease))
      (revenue (unwrap! (map-get? land-revenues { land-id: land-id }) err-not-found))
      (total-pending (get pending-distribution revenue))
      (lessee-share (/ (* total-pending (+ (get solar-revenue-share lease) (get crop-revenue-share lease))) u200))
      (lessor-share (- total-pending lessee-share))
    )
    (asserts! (get is-active lease) err-lease-expired)
    (asserts! (<= stacks-block-height (get end-block lease)) err-lease-expired)
    (asserts! (> total-pending u0) err-invalid-amount)
    
    (map-set user-balances { user: (get lessee lease) }
      { balance: (+ (default-to u0 (get balance (map-get? user-balances { user: (get lessee lease) }))) lessee-share) }
    )
    (map-set user-balances { user: (get lessor lease) }
      { balance: (+ (default-to u0 (get balance (map-get? user-balances { user: (get lessor lease) }))) lessor-share) }
    )
    (map-set land-revenues { land-id: land-id }
      (merge revenue { pending-distribution: u0 })
    )
    (ok { lessee-share: lessee-share, lessor-share: lessor-share })
  )
)

(define-public (terminate-lease (lease-id uint))
  (let ((lease (unwrap! (map-get? leases { lease-id: lease-id }) err-not-found)))
    (asserts! (or (is-eq tx-sender (get lessor lease)) (is-eq tx-sender (get lessee lease))) err-unauthorized)
    (map-set leases { lease-id: lease-id } (merge lease { is-active: false }))
    (ok true)
  )
)

(define-public (renew-lease (lease-id uint) (extension-blocks uint))
  (let ((lease (unwrap! (map-get? leases { lease-id: lease-id }) err-not-found)))
    (asserts! (is-eq tx-sender (get lessee lease)) err-unauthorized)
    (asserts! (get is-active lease) err-lease-expired)
    (asserts! (<= stacks-block-height (get end-block lease)) err-lease-expired)
    (asserts! (> extension-blocks u0) err-invalid-amount)
    (map-set leases { lease-id: lease-id } (merge lease { end-block: (+ (get end-block lease) extension-blocks) }))
    (ok true)
  )
)

(define-public (withdraw-balance (amount uint))
  (let ((user-balance (default-to u0 (get balance (map-get? user-balances { user: tx-sender })))))
    (asserts! (>= user-balance amount) err-insufficient-balance)
    (asserts! (> amount u0) err-invalid-amount)
    (map-set user-balances { user: tx-sender } { balance: (- user-balance amount) })
    (ok amount)
  )
)

(define-public (deposit-balance (amount uint))
  (let ((current-balance (default-to u0 (get balance (map-get? user-balances { user: tx-sender })))))
    (asserts! (> amount u0) err-invalid-amount)
    (map-set user-balances { user: tx-sender } { balance: (+ current-balance amount) })
    (ok (+ current-balance amount))
  )
)

(define-public (transfer-land-ownership (land-id uint) (new-owner principal))
  (let ((land (unwrap! (map-get? lands { land-id: land-id }) err-not-found)))
    (asserts! (is-eq tx-sender (get owner land)) err-unauthorized)
    (map-set lands { land-id: land-id } (merge land { owner: new-owner }))
    (ok true)
  )
)

(define-public (update-land-details (land-id uint) (new-location (string-ascii 100)) (new-size-hectares uint) (new-solar-capacity-kw uint) (new-crop-type (string-ascii 50)))
  (let ((land (unwrap! (map-get? lands { land-id: land-id }) err-not-found)))
    (asserts! (is-eq tx-sender (get owner land)) err-unauthorized)
    (asserts! (> new-size-hectares u0) err-invalid-amount)
    (asserts! (> new-solar-capacity-kw u0) err-invalid-amount)
    (map-set lands { land-id: land-id }
      (merge land
        {
          location: new-location,
          size-hectares: new-size-hectares,
          solar-capacity-kw: new-solar-capacity-kw,
          crop-type: new-crop-type
        }
      )
    )
    (ok true)
  )
)

(define-public (start-land-auction (land-id uint) (starting-price uint) (duration-blocks uint))
  (let
    (
      (land (unwrap! (map-get? lands { land-id: land-id }) err-not-found))
      (new-auction-id (+ (var-get auction-id-nonce) u1))
      (end-block (+ stacks-block-height duration-blocks))
    )
    (asserts! (is-eq tx-sender (get owner land)) err-unauthorized)
    (asserts! (> starting-price u0) err-invalid-amount)
    (asserts! (> duration-blocks u0) err-invalid-amount)
    (map-set land-auctions { auction-id: new-auction-id }
      {
        land-id: land-id,
        seller: tx-sender,
        starting-price: starting-price,
        current-bid: u0,
        highest-bidder: none,
        end-block: end-block,
        is-active: true
      }
    )
    (var-set auction-id-nonce new-auction-id)
    (ok new-auction-id)
  )
)

(define-public (place-bid (auction-id uint) (bid-amount uint))
  (let
    (
      (auction (unwrap! (map-get? land-auctions { auction-id: auction-id }) err-auction-not-found))
      (current-bid (get current-bid auction))
      (starting-price (get starting-price auction))
      (bidder-balance (default-to u0 (get balance (map-get? user-balances { user: tx-sender }))))
    )
    (asserts! (get is-active auction) err-auction-ended)
    (asserts! (<= stacks-block-height (get end-block auction)) err-auction-ended)
    (asserts! (>= bid-amount starting-price) err-bid-too-low)
    (asserts! (> bid-amount current-bid) err-bid-too-low)
    (asserts! (>= bidder-balance bid-amount) err-insufficient-balance)
    (map-set user-balances { user: tx-sender } { balance: (- bidder-balance bid-amount) })
    (if (> current-bid u0)
      (map-set user-balances { user: (unwrap! (get highest-bidder auction) err-not-found) }
        { balance: (+ (default-to u0 (get balance (map-get? user-balances { user: (unwrap! (get highest-bidder auction) err-not-found) }))) current-bid) }
      )
      true
    )
    (map-set land-auctions { auction-id: auction-id }
      (merge auction { current-bid: bid-amount, highest-bidder: (some tx-sender) })
    )
    (ok true)
  )
)

(define-public (end-auction (auction-id uint))
  (let
    (
      (auction (unwrap! (map-get? land-auctions { auction-id: auction-id }) err-auction-not-found))
      (land-id (get land-id auction))
      (land (unwrap! (map-get? lands { land-id: land-id }) err-not-found))
      (highest-bidder (get highest-bidder auction))
    )
    (asserts! (get is-active auction) err-auction-ended)
    (asserts! (> stacks-block-height (get end-block auction)) err-auction-active)
    (map-set land-auctions { auction-id: auction-id } (merge auction { is-active: false }))
    (if (is-some highest-bidder)
      (begin
        (map-set lands { land-id: land-id } (merge land { owner: (unwrap! highest-bidder err-not-found) }))
        (map-set user-balances { user: (get seller auction) }
          { balance: (+ (default-to u0 (get balance (map-get? user-balances { user: (get seller auction) }))) (get current-bid auction)) }
        )
        (ok true)
      )
      (ok false)
    )
  )
)

(define-read-only (get-land-info (land-id uint))
  (map-get? lands { land-id: land-id })
)

(define-read-only (get-lease-info (lease-id uint))
  (map-get? leases { lease-id: lease-id })
)

(define-read-only (get-yield-token-info (token-id uint))
  (map-get? yield-tokens { token-id: token-id })
)

(define-read-only (get-land-revenue (land-id uint))
  (map-get? land-revenues { land-id: land-id })
)

(define-read-only (get-user-balance (user principal))
  (default-to u0 (get balance (map-get? user-balances { user: user })))
)

(define-read-only (get-contract-stats)
  {
    total-lands: (var-get land-id-nonce),
    total-leases: (var-get lease-id-nonce),
    total-yield-tokens: (var-get yield-token-supply),
    total-auctions: (var-get auction-id-nonce)
  }
)

(define-read-only (get-auction-info (auction-id uint))
  (map-get? land-auctions { auction-id: auction-id })
)
