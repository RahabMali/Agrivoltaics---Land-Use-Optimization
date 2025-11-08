# 🌱⚡ Agrivoltaics & Land Use Optimization

[![Clarity](https://img.shields.io/badge/Clarity-Smart%20Contract-blue)](https://clarity.tools/)
[![Stacks](https://img.shields.io/badge/Stacks-Blockchain-orange)](https://www.stacks.co/)

A blockchain-based system for managing dual land use combining solar energy and agriculture through smart contracts.

## 🚀 Overview

This smart contract enables efficient land use optimization by managing:
- 📋 Land lease agreements between owners and operators
- 🪙 Tokenized yields from both solar and crop production  
- 💰 Automated revenue distribution based on agreed shares
- 🤝 Transparent and trustless transactions

## ✨ Key Features

### 🏞️ Land Management
- Register agricultural land with solar capacity
- Track location, size, and crop types
- Monitor solar panel capacity in kW

### 📜 Smart Lease Agreements  
- Create customizable lease terms
- Set revenue sharing percentages for solar and crops
- Define lease duration and monthly rent
- Automatic lease expiration handling

### 🎯 Yield Tokenization
- Mint tokens representing solar and crop yields
- Set pricing for tokenized production
- Enable trading of future yields
- Transparent ownership tracking

### 💵 Revenue Distribution
- Automated revenue sharing based on lease terms
- Separate tracking for solar and agricultural income
- Real-time balance management
- Secure withdrawal system

### 🏠 Land Ownership Transfer
- Seamless transfer of land ownership between principals
- Maintains all existing land data and associations
- Enables flexible land trading and inheritance
- Owner-only authorization for security
### 🛡️ Land Auction System
- Decentralized land auctions with transparent bidding
- Time-based auction mechanics with automatic expiration
- Secure bid placement with balance validation
- Automatic ownership transfer upon successful auction completion
- Refund mechanism for outbid participants
- Enables dynamic land value discovery through market competition


### 🔄 Lease Renewal
- Extend active lease durations seamlessly
- Preserve all existing lease terms
- Enable long-term operational planning

## 🛠️ Usage Instructions

### Setting Up

1. Deploy the contract to Stacks testnet/mainnet
2. Register your land using `register-land`
3. Create lease agreements with `create-lease`

### For Land Owners 🏡

```clarity
;; Register your land
(contract-call? .agrivoltaics register-land 
  "Farm Location ABC" 
  u100    ;; 100 hectares
  u500    ;; 500 kW solar capacity
  "wheat" ;; crop type
)

;; Create a lease agreement
(contract-call? .agrivoltaics create-lease
  u1          ;; land-id
  'SP123...   ;; lessee principal
  u52560      ;; ~1 year in blocks
  u40         ;; 40% solar revenue share
  u60         ;; 60% crop revenue share
  u1000       ;; monthly rent
)
```

### For Lessees/Operators 👨‍🌾

```clarity
;; Add revenue from operations
(contract-call? .agrivoltaics add-revenue
  u1     ;; land-id
  u5000  ;; solar revenue
  u3000  ;; crop revenue
)

;; Distribute revenue according to lease terms
(contract-call? .agrivoltaics distribute-revenue u1) ;; lease-id

;; Renew lease before expiration
(contract-call? .agrivoltaics renew-lease
  u1      ;; lease-id
  u26280  ;; ~6 months extension in blocks
)
```

### For Yield Token Trading 📈

```clarity
;; Mint yield tokens
(contract-call? .agrivoltaics mint-yield-token
### For Land Auctions 🏛️

```clarity
;; Start an auction for land
(contract-call? .agrivoltaics start-land-auction
  u1         ;; land-id
  u10000     ;; starting price
  u1440      ;; duration in blocks (~1 day)
)

;; Place a bid on an auction
(contract-call? .agrivoltaics place-bid
  u1         ;; auction-id
  u15000     ;; bid amount
)

;; End auction after expiration
(contract-call? .agrivoltaics end-auction u1) ;; auction-id
```

  u1         ;; land-id
  "solar"    ;; token type
  u100       ;; amount
  u50        ;; price per unit
)

;; Purchase yield tokens
(contract-call? .agrivoltaics buy-yield-token u1) ;; token-id
```

## 🔍 Available Functions

### Public Functions
- `register-land` - Register new agricultural land
- `create-lease` - Create lease agreements
- `mint-yield-token` - Create tokenized yields
- `start-land-auction` - Initiate auction for land ownership
- `place-bid` - Submit competitive bids during active auctions
- `end-auction` - Finalize auction and transfer ownership to winner
- `get-auction-info` - Retrieve detailed auction status and bids

- `buy-yield-token` - Purchase yield tokens
- `add-revenue` - Record income from operations
- `distribute-revenue` - Share revenue per lease terms
- `terminate-lease` - End lease agreements early
- `renew-lease` - Extend lease duration
- `withdraw-balance` - Withdraw earned funds
- `deposit-balance` - Add funds to account
- `transfer-land-ownership` - Transfer land ownership to new principal

### Read-Only Functions  
- `get-land-info` - View land details
- `get-lease-info` - View lease terms
- `get-yield-token-info` - View token details
- `get-land-revenue` - View revenue data
- `get-user-balance` - Check account balance
- `get-contract-stats` - View system statistics

## 🏗️ Technical Details

**Language**: Clarity  
**Blockchain**: Stacks  
**Contract Size**: 180+ lines  
**Error Handling**: Comprehensive error codes  
**Storage**: Optimized map structures  

## 🔐 Security Features

- Owner-only functions for critical operations
- Balance validation before transactions  
- Lease expiration checks
- Unauthorized access prevention
- Input validation for all parameters

## 🤝 Contributing

1. Fork the repository
2. Create feature branch (`git checkout -b feature/amazing-feature`)
3. Commit changes (`git commit -m 'Add amazing feature'`)
4. Push to branch (`git push origin feature/amazing-feature`)
5. Open Pull Request

## 📄 License

This project is open source and available under the [MIT License](LICENSE).

---

Made with ❤️ for sustainable agriculture and renewable energy 🌍
