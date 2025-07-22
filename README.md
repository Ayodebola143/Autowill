# AutoWill Smart Contract

A decentralized protocol for managing time-locked STX gifts on the Stacks blockchain. AutoWill enables secure, expirable gift transfers with ownership tracking and claim management.

## Features

- 🎁 Create time-locked STX gifts
- ⏰ Set and extend expiry blocks
- 💰 Update gift amounts
- 🔄 Transfer gift ownership
- ✅ Claim gifts before expiry
- ❌ Cancel unclaimed gifts
- 📊 Track gift ownership

## Contract Functions

### Core Functions

```clarity
;; Create a new time-locked gift
(create-gift (hash-code (buff 32)) (amount uint) (expiry-block uint))

;; Extend the expiry block of an existing gift
(extend-expiry (hash-code (buff 32)) (new-expiry-block uint))

;; Add more STX to an existing gift
(update-amount (hash-code (buff 32)) (additional-amount uint))

;; Claim a gift before expiry
(claim-gift (hash-code (buff 32)))

;; Cancel an unclaimed gift
(cancel-gift (hash-code (buff 32)))

;; Transfer gift ownership to another principal
(transfer-gift (hash-code (buff 32)) (new-sender principal))
```

### Read-Only Functions

```clarity
;; Check if a gift is claimable
(is-claimable (hash-code (buff 32)))

;; Get gift details
(get-gift-details (hash-code (buff 32)))
```

## Error Codes

| Code | Name | Description |
|------|------|-------------|
| u1 | `ERR_UNAUTHORIZED` | Caller not authorized |
| u2 | `ERR_ALREADY_CLAIMED` | Gift already claimed |
| u3 | `ERR_INVALID_EXPIRY` | Invalid expiry block |
| u4 | `ERR_NOT_FOUND` | Gift not found |
| u5 | `ERR_INVALID_AMOUNT` | Invalid amount |
| u6 | `ERR_INSUFFICIENT_FUNDS` | Insufficient funds |
| u7 | `ERR_GIFT_EXPIRED` | Gift has expired |
| u8 | `ERR_LIST_FULL` | Maximum gifts reached |
| u9 | `ERR_SELF_TRANSFER` | Cannot transfer to self |


### Setup

1. Clone the repository:
```bash
git clone https://github.com/yourusername/autowill.git
cd autowill
```

2. Install dependencies:
```bash
npm install
```

3. Run tests:
```bash
clarinet test
```

### Deployment

1. Configure deployment settings:
```bash
clarinet deployment generate
```

2. Deploy to testnet:
```bash
clarinet deployment apply --testnet
```

## Security Considerations

- All functions include authorization checks
- STX transfers use safe transfer patterns
- Gift claims protected against double-claiming
- Expiry validation against block height
- Maximum gift limit per sender

