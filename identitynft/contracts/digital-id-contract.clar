;; NFT-Based Identity Contract
;; Each identity is represented as a unique NFT (SIP-009 Compatible)

;; Error codes
(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-NOT-FOUND (err u101))
(define-constant ERR-ALREADY-EXISTS (err u102))
(define-constant ERR-NOT-OWNER (err u103))

;; NFT implementation
(define-non-fungible-token identity-nft uint)

;; Data vars
(define-data-var last-token-id uint u0)
(define-data-var contract-owner principal tx-sender)

;; Maps
(define-map token-to-owner uint principal)
(define-map owner-to-token principal uint)
(define-map identity-metadata
    uint
    {
        did: (string-ascii 256),
        reputation: uint,
        created-at: uint,
        verified: bool,
        metadata-uri: (optional (string-ascii 256))
    }
)

(define-map cross-chain-proofs
    { token-id: uint, chain-id: uint }
    {
        external-address: (string-ascii 128),
        proof-method: (string-ascii 50),
        verified: bool,
        timestamp: uint
    }
)

;; SIP-009 NFT Standard Functions
(define-read-only (get-last-token-id)
    (ok (var-get last-token-id))
)

(define-read-only (get-token-uri (token-id uint))
    (match (map-get? identity-metadata token-id)
        metadata (ok (get metadata-uri metadata))
        (err ERR-NOT-FOUND)
    )
)

(define-read-only (get-owner (token-id uint))
    (ok (nft-get-owner? identity-nft token-id))
)

(define-public (transfer (token-id uint) (sender principal) (recipient principal))
    (begin
        (asserts! (is-eq tx-sender sender) ERR-NOT-AUTHORIZED)
        (asserts! (is-some (nft-get-owner? identity-nft token-id)) ERR-NOT-FOUND)
        (try! (nft-transfer? identity-nft token-id sender recipient))
        (map-set token-to-owner token-id recipient)
        (map-delete owner-to-token sender)
        (map-set owner-to-token recipient token-id)
        (ok true)
    )
)

;; Identity Functions
(define-public (mint-identity (recipient principal) (did (string-ascii 256)) (metadata-uri (optional (string-ascii 256))))
    (let ((new-token-id (+ (var-get last-token-id) u1)))
        (asserts! (is-none (map-get? owner-to-token recipient)) ERR-ALREADY-EXISTS)
        (try! (nft-mint? identity-nft new-token-id recipient))
        (map-set token-to-owner new-token-id recipient)
        (map-set owner-to-token recipient new-token-id)
        (map-set identity-metadata new-token-id {
            did: did,
            reputation: u100,
            created-at: block-height,
            verified: false,
            metadata-uri: metadata-uri
        })
        (var-set last-token-id new-token-id)
        (ok new-token-id)
    )
)

(define-public (add-cross-chain-proof 
    (chain-id uint) 
    (external-address (string-ascii 128)) 
    (proof-method (string-ascii 50)))
    (let ((token-id (unwrap! (map-get? owner-to-token tx-sender) ERR-NOT-FOUND)))
        (map-set cross-chain-proofs
            { token-id: token-id, chain-id: chain-id }
            {
                external-address: external-address,
                proof-method: proof-method,
                verified: false,
                timestamp: block-height
            }
        )
        (ok true)
    )
)

(define-public (verify-cross-chain-proof (token-id uint) (chain-id uint))
    (begin
        (asserts! (is-eq tx-sender (var-get contract-owner)) ERR-NOT-AUTHORIZED)
        (let ((proof (unwrap! (map-get? cross-chain-proofs { token-id: token-id, chain-id: chain-id }) ERR-NOT-FOUND)))
            (map-set cross-chain-proofs
                { token-id: token-id, chain-id: chain-id }
                (merge proof { verified: true })
            )
            (ok true)
        )
    )
)

(define-public (update-reputation (token-id uint) (new-reputation uint))
    (begin
        (asserts! (is-eq tx-sender (var-get contract-owner)) ERR-NOT-AUTHORIZED)
        (let ((metadata (unwrap! (map-get? identity-metadata token-id) ERR-NOT-FOUND)))
            (map-set identity-metadata token-id
                (merge metadata { reputation: new-reputation })
            )
            (ok true)
        )
    )
)

;; Read functions
(define-read-only (get-identity-by-owner (owner principal))
    (match (map-get? owner-to-token owner)
        token-id (map-get? identity-metadata token-id)
        none
    )
)

(define-read-only (get-identity-metadata (token-id uint))
    (map-get? identity-metadata token-id)
)

(define-read-only (get-cross-chain-proof (token-id uint) (chain-id uint))
    (map-get? cross-chain-proofs { token-id: token-id, chain-id: chain-id })
)