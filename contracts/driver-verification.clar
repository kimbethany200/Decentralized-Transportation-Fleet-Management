;; Driver Verification Contract
;; Validates qualified operators

(define-data-var last-driver-id uint u0)

;; License status: 1=active, 2=suspended, 3=expired
(define-map drivers
  { id: uint }
  {
    address: principal,
    full-name: (string-utf8 128),
    license-number: (string-utf8 32),
    license-expiry: uint,
    license-status: uint,
    verification-date: uint,
    vehicle-types: (list 10 (string-utf8 32))
  }
)

;; Map to track driver-vehicle assignments
(define-map driver-vehicle-assignments
  { driver-id: uint, vehicle-id: uint }
  { assigned-at: uint }
)

;; Public function to register a new driver
(define-public (register-driver
                (full-name (string-utf8 128))
                (license-number (string-utf8 32))
                (license-expiry uint)
                (vehicle-types (list 10 (string-utf8 32))))
  (let ((new-id (+ (var-get last-driver-id) u1)))
    (begin
      (var-set last-driver-id new-id)
      (map-set drivers
        { id: new-id }
        {
          address: tx-sender,
          full-name: full-name,
          license-number: license-number,
          license-expiry: license-expiry,
          license-status: u1,
          verification-date: block-height,
          vehicle-types: vehicle-types
        })
      (ok new-id))))

;; Update driver license status
(define-public (update-license-status (driver-id uint) (new-status uint))
  (let ((driver (map-get? drivers { id: driver-id })))
    (match driver
      driver-data
        (begin
          (map-set drivers
            { id: driver-id }
            (merge driver-data { license-status: new-status }))
          (ok true))
      (err u404)))) ;; Driver not found

;; Assign driver to vehicle
(define-public (assign-vehicle (driver-id uint) (vehicle-id uint))
  (begin
    (map-set driver-vehicle-assignments
      { driver-id: driver-id, vehicle-id: vehicle-id }
      { assigned-at: block-height })
    (ok true)))

;; Unassign driver from vehicle
(define-public (unassign-vehicle (driver-id uint) (vehicle-id uint))
  (begin
    (map-delete driver-vehicle-assignments { driver-id: driver-id, vehicle-id: vehicle-id })
    (ok true)))

;; Read-only function to get driver details
(define-read-only (get-driver (driver-id uint))
  (map-get? drivers { id: driver-id }))

;; Check if a driver is assigned to a vehicle
(define-read-only (is-driver-assigned (driver-id uint) (vehicle-id uint))
  (is-some (map-get? driver-vehicle-assignments { driver-id: driver-id, vehicle-id: vehicle-id })))

;; Read-only function to get total number of drivers
(define-read-only (get-total-drivers)
  (var-get last-driver-id))
