# NFT-Based Identity Contract

A Stacks blockchain smart contract that implements decentralized digital identity using NFTs. Each identity is represented as a unique, non-fungible token with associated metadata, reputation scoring, and cross-chain verification capabilities.

## Overview

This contract enables users to:
- Mint unique identity NFTs with decentralized identifiers (DIDs)
- Manage reputation scores
- Verify identity across multiple blockchain networks
- Transfer identity ownership while maintaining data integrity

## Features

### Core Identity Management
- **Unique Identity NFTs**: Each user can own only one identity NFT
- **DID Integration**: Support for decentralized identifiers (up to 256 characters)
- **Metadata Storage**: Optional metadata URI for additional identity information
- **Reputation System**: Numeric reputation scoring (default: 100)

### Cross-Chain Verification
- **Multi-Chain Proofs**: Link identities to addresses on other blockchain networks
- **Proof Methods**: Flexible verification methods for different chains
- **Verification Status**: Admin-controlled verification of cross-chain proofs

### NFT Standard Compliance
- Full SIP-009 NFT standard implementation
- Standard transfer, ownership, and metadata functions
- Compatible with existing NFT marketplaces and wallets

## Contract Structure

### Data Storage
- `identity-metadata`: Core identity information (DID, reputation, verification status)
- `cross-chain-proofs`: Cross-blockchain address verification data
- `token-to-owner` & `owner-to-token`: Bidirectional ownership mapping

### Error Codes
- `ERR-NOT-AUTHORIZED (100)`: Unauthorized access attempt
- `ERR-NOT-FOUND (101)`: Requested resource doesn't exist
- `ERR-ALREADY-EXISTS (102)`: Identity already exists for user
- `ERR-NOT-OWNER (103)`: Not the owner of the specified token

## Public Functions

### Identity Management

#### `mint-identity`
```clarity
(mint-identity (recipient principal) (did (string-ascii 256)) (metadata-uri (optional (string-ascii 256))))
```
Creates a new identity NFT for a recipient. Each principal can only have one identity.

**Parameters:**
- `recipient`: The principal who will own the identity
- `did`: Decentralized identifier string
- `metadata-uri`: Optional URI for additional metadata

**Returns:** Token ID of the newly minted identity

#### `transfer`
```clarity
(transfer (token-id uint) (sender principal) (recipient principal))
```
Transfers an identity NFT between principals. Updates all associated mappings.

### Cross-Chain Verification

#### `add-cross-chain-proof`
```clarity
(add-cross-chain-proof (chain-id uint) (external-address (string-ascii 128)) (proof-method (string-ascii 50)))
```
Links an external blockchain address to the caller's identity.

**Parameters:**
- `chain-id`: Numeric identifier for the blockchain network
- `external-address`: Address on the external chain
- `proof-method`: Method used for verification (e.g., "signature", "transaction")

#### `verify-cross-chain-proof` (Admin Only)
```clarity
(verify-cross-chain-proof (token-id uint) (chain-id uint))
```
Marks a cross-chain proof as verified. Only callable by contract owner.

### Reputation Management

#### `update-reputation` (Admin Only)
```clarity
(update-reputation (token-id uint) (new-reputation uint))
```
Updates the reputation score for an identity. Only callable by contract owner.

## Read-Only Functions

### `get-identity-by-owner`
Returns identity metadata for a given principal.

### `get-identity-metadata`
Returns complete metadata for a token ID.

### `get-cross-chain-proof`
Returns cross-chain proof data for a specific token and chain combination.

### `get-last-token-id`
Returns the most recently minted token ID.

### `get-token-uri`
Returns the metadata URI for a token (SIP-009 standard).

### `get-owner`
Returns the owner of a specific token ID (SIP-009 standard).

## Usage Examples

### Minting an Identity
```clarity
;; Mint identity for Alice with DID and metadata URI
(contract-call? .identity-contract mint-identity 
    'SP1ALICE123...
    "did:stx:alice123"
    (some "https://alice.com/metadata.json"))
```

### Adding Cross-Chain Proof
```clarity
;; Link Ethereum address to identity
(contract-call? .identity-contract add-cross-chain-proof
    u1  ;; Ethereum chain ID
    "0x742d35Cc6639C0532fEb5004C0CC08f7d9C18e3B"
    "signature")
```

### Checking Identity
```clarity
;; Get identity information for a principal
(contract-call? .identity-contract get-identity-by-owner 'SP1ALICE123...)
```

## Security Considerations

1. **Single Identity**: Each principal can only own one identity NFT at a time
2. **Admin Controls**: Reputation updates and proof verification require admin privileges
3. **Transfer Safety**: Standard NFT transfer protections ensure only owners can transfer
4. **Data Integrity**: All metadata updates maintain referential integrity

## Development

### Prerequisites
- Stacks blockchain development environment
- Clarity smart contract knowledge
- NFT trait implementation (`.nft-trait`)

### Deployment
1. Deploy the NFT trait contract
2. Deploy this identity contract
3. Configure contract owner for admin functions

## Integration

This contract can be integrated with:
- DID resolution systems
- Cross-chain identity bridges
- Reputation systems
- NFT marketplaces
- Web3 authentication systems
