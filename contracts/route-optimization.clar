;; Route Optimization Contract
;; Records efficient delivery paths

(define-data-var last-route-id uint u0)

;; Route status: 1=active, 2=completed, 3=cancelled
(define-map routes
  { id: uint }
  {
    name: (string-utf8 128),
    start-location: (string-utf8 256),
    end-location: (string-utf8 256),
    waypoints: (list 10 (string-utf8 256)),
    estimated-distance: uint,
    estimated-duration: uint,
    created-at: uint,
    status: uint
  }
)

;; Map to track route assignments
(define-map route-assignments
  { route-id: uint }
  {
    vehicle-id: uint,
    driver-id: uint,
    assigned-at: uint
  }
)

;; Map to track route completion metrics
(define-map route-completions
  { route-id: uint }
  {
    actual-duration: uint,
    actual-distance: uint,
    fuel-consumed: uint,
    completed-at: uint,
    notes: (string-utf8 512)
  }
)

;; Public function to create a new route
(define-public (create-route
                (name (string-utf8 128))
                (start-location (string-utf8 256))
                (end-location (string-utf8 256))
                (waypoints (list 10 (string-utf8 256)))
                (estimated-distance uint)
                (estimated-duration uint))
  (let ((new-id (+ (var-get last-route-id) u1)))
    (begin
      (var-set last-route-id new-id)
      (map-set routes
        { id: new-id }
        {
          name: name,
          start-location: start-location,
          end-location: end-location,
          waypoints: waypoints,
          estimated-distance: estimated-distance,
          estimated-duration: estimated-duration,
          created-at: block-height,
          status: u1 ;; active
        })
      (ok new-id))))

;; Assign route to vehicle and driver
(define-public (assign-route (route-id uint) (vehicle-id uint) (driver-id uint))
  (begin
    (map-set route-assignments
      { route-id: route-id }
      {
        vehicle-id: vehicle-id,
        driver-id: driver-id,
        assigned-at: block-height
      })
    (ok true)))

;; Mark route as completed with metrics
(define-public (complete-route
                (route-id uint)
                (actual-duration uint)
                (actual-distance uint)
                (fuel-consumed uint)
                (notes (string-utf8 512)))
  (let ((route (map-get? routes { id: route-id })))
    (match route
      route-data
        (begin
          ;; Update route status
          (map-set routes
            { id: route-id }
            (merge route-data { status: u2 })) ;; completed

          ;; Record completion metrics
          (map-set route-completions
            { route-id: route-id }
            {
              actual-duration: actual-duration,
              actual-distance: actual-distance,
              fuel-consumed: fuel-consumed,
              completed-at: block-height,
              notes: notes
            })
          (ok true))
      (err u404)))) ;; Route not found

;; Cancel route
(define-public (cancel-route (route-id uint))
  (let ((route (map-get? routes { id: route-id })))
    (match route
      route-data
        (begin
          (map-set routes
            { id: route-id }
            (merge route-data { status: u3 })) ;; cancelled
          (ok true))
      (err u404)))) ;; Route not found

;; Read-only function to get route details
(define-read-only (get-route (route-id uint))
  (map-get? routes { id: route-id }))

;; Read-only function to get route assignment
(define-read-only (get-route-assignment (route-id uint))
  (map-get? route-assignments { route-id: route-id }))

;; Read-only function to get route completion metrics
(define-read-only (get-route-completion (route-id uint))
  (map-get? route-completions { route-id: route-id }))

;; Read-only function to get total number of routes
(define-read-only (get-total-routes)
  (var-get last-route-id))
