;; Vehicle Registration Contract
;; Records details of transportation assets

(define-data-var last-vehicle-id uint u0)

;; Vehicle status: 1=active, 2=maintenance, 3=retired
(define-map vehicles
  { id: uint }
  {
    owner: principal,
    vehicle-type: (string-utf8 64),
    registration-number: (string-utf8 32),
    manufacture-year: uint,
    model: (string-utf8 64),
    status: uint,
    registration-date: uint
  }
)

;; Public function to register a new vehicle
(define-public (register-vehicle
                (vehicle-type (string-utf8 64))
                (registration-number (string-utf8 32))
                (manufacture-year uint)
                (model (string-utf8 64)))
  (let ((new-id (+ (var-get last-vehicle-id) u1)))
    (begin
      (var-set last-vehicle-id new-id)
      (map-set vehicles
        { id: new-id }
        {
          owner: tx-sender,
          vehicle-type: vehicle-type,
          registration-number: registration-number,
          manufacture-year: manufacture-year,
          model: model,
          status: u1,
          registration-date: block-height
        })
      (ok new-id))))

;; Update vehicle status (active, maintenance, retired)
(define-public (update-vehicle-status (vehicle-id uint) (new-status uint))
  (let ((vehicle (map-get? vehicles { id: vehicle-id })))
    (match vehicle
      vehicle-data
        (if (is-eq tx-sender (get owner vehicle-data))
          (begin
            (map-set vehicles
              { id: vehicle-id }
              (merge vehicle-data { status: new-status }))
            (ok true))
          (err u403)) ;; Unauthorized
      (err u404)))) ;; Vehicle not found

;; Transfer vehicle ownership
(define-public (transfer-vehicle (vehicle-id uint) (new-owner principal))
  (let ((vehicle (map-get? vehicles { id: vehicle-id })))
    (match vehicle
      vehicle-data
        (if (is-eq tx-sender (get owner vehicle-data))
          (begin
            (map-set vehicles
              { id: vehicle-id }
              (merge vehicle-data { owner: new-owner }))
            (ok true))
          (err u403)) ;; Unauthorized
      (err u404)))) ;; Vehicle not found

;; Read-only function to get vehicle details
(define-read-only (get-vehicle (vehicle-id uint))
  (map-get? vehicles { id: vehicle-id }))

;; Read-only function to get total number of vehicles
(define-read-only (get-total-vehicles)
  (var-get last-vehicle-id))
