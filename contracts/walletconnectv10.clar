;; --------------------------------------------------
;; STACKS COMPATIBLE MARKETPLACE (v2)
;; --------------------------------------------------

;; 1. Definir variables de datos
(define-data-var contract-owner principal tx-sender)
(define-data-var service-count uint u0)

;; 2. Definir mapas (Estructura optimizada para Stacks)
(define-map services 
    uint 
    { name: (string-ascii 50), price: uint, active: bool }
)

(define-map purchases 
    { user: principal, service-id: uint } 
    bool
)

;; 3. Funciones Administrativas (Owner Only)
(define-public (add-service (name (string-ascii 50)) (price uint))
    (let ((new-id (+ (var-get service-count) u1)))
        ;; Solo el owner puede añadir servicios
        (asserts! (is-eq tx-sender (var-get contract-owner)) (err u401))
        
        (map-set services new-id { name: name, price: price, active: true })
        (var-set service-count new-id)
        (ok new-id)
    )
)

;; 4. Funciones Públicas (Open for AppKit)
(define-public (buy-service (id uint))
    (let (
        ;; Desempaquetamos el servicio o devolvemos error 404
        (service (unwrap! (map-get? services id) (err u404)))
        (price (get price service))
        (current-owner (var-get contract-owner))
    )
        ;; Validar que esté activo
        (asserts! (get active service) (err u405))
        
        ;; Transferencia de STX (El núcleo de la transacción)
        (try! (stx-transfer? price tx-sender current-owner))
        
        ;; Registrar la compra en el mapa
        (map-set purchases { user: tx-sender, service-id: id } true)
        (ok true)
    )
)

;; 5. Funciones de Lectura (Read-only)
(define-read-only (get-service-info (id uint))
    (ok (map-get? services id))
)

(define-read-only (check-purchase (user principal) (id uint))
    (ok (default-to false (map-get? purchases { user: user, service-id: id })))
)
