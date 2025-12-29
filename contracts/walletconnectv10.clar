;; --------------------------------------------------
;; Decentralized Service Market (AppKit Ready)
;; --------------------------------------------------

;; Variables de estado
(define-data-var contract-owner principal tx-sender)
(define-data-var service-count uint u0)

;; Mapas
(define-map services uint { name: (string-ascii 50), price: uint, active: bool })
(define-map purchases { user: principal, service-id: uint } bool)

;; --- Funciones para el Administrador ---

;; Añadir un nuevo servicio al mercado
(define-public (add-service (name (string-ascii 50)) (price uint))
    (let ((new-id (+ (var-get service-count) u1)))
        (asserts! (is-eq tx-sender (var-get contract-owner)) (err u401))
        (map-set services new-id { name: name, price: price, active: true })
        (var-set service-count new-id)
        (ok new-id)
    )
)

;; --- Funciones Públicas (Abiertas al uso) ---

;; Comprar un servicio
(define-public (buy-service (id uint))
    (let (
        (service (unwrap! (map-get? services id) (err u404)))
        (price (get price service))
    )
        ;; 1. El servicio debe estar activo
        (asserts! (get active service) (err u405))
        ;; 2. Pago directo al owner
        (try! (stx-transfer? price tx-sender (var-get contract-owner)))
        ;; 3. Registrar la compra
        (map-set purchases { user: tx-sender, service-id: id } true)
        (ok true)
    )
)

;; --- Funciones de Lectura para el Frontend (AppKit) ---

;; Ver detalles de un servicio
(define-read-only (get-service-details (id uint))
    (map-get? services id)
)

;; Saber si un usuario ya compró el servicio
(define-read-only (has-purchased (user principal) (id uint))
    (default-to false (map-get? purchases { user: user, service-id: id }))
)

;; Ver el total de servicios disponibles
(define-read-only (get-market-size)
    (var-get service-count)
)
