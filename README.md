# 🎪 Event Cancellation Insurance

> 🛡️ Smart contract-based insurance for event organizers on the Stacks blockchain

## 📋 Overview

Event Cancellation Insurance is a decentralized insurance protocol built with Clarity smart contracts. Event organizers can purchase insurance policies to protect against financial losses from event cancellations. Claims are processed transparently on-chain with automated payouts.

## ✨ Features

- 🎫 **Policy Creation** - Organizers create insurance policies for their events
- 💰 **Premium Payments** - Pay premiums in STX tokens to activate coverage
- 📄 **Claim Filing** - Submit claims for cancelled events with detailed reasons
- ⚡ **Automated Payouts** - Smart contract handles claim processing and payments
- 🔒 **Secure Escrow** - Funds held safely in smart contract until needed
- 📊 **Transparent Process** - All transactions and claims visible on blockchain

## 🚀 Quick Start

### Prerequisites

- [Clarinet](https://github.com/hirosystems/clarinet) installed
- [Stacks CLI](https://github.com/hirosystems/stacks.js) for deployment
- STX tokens for testing and deployment

### Installation

1. Clone this repository:
```bash
git clone https://github.com/your-username/event-cancellation-insurance
cd event-cancellation-insurance
```

2. Initialize Clarinet project:
```bash
clarinet new event-insurance
cd event-insurance
```

3. Copy the contract file to your contracts directory:
```bash
cp event-insurance.clar contracts/
```

### Testing

Run the contract tests:
```bash
clarinet test
```

Check contract syntax:
```bash
clarinet check
```

## 📖 Usage Guide

### 🎯 For Event Organizers

#### 1. Create Insurance Policy

```clarity
(contract-call? .event-insurance create-policy 
  "Summer Music Festival 2024"  ;; event name
  u1000000                      ;; event date (block height)
  u50000                        ;; premium amount (50 STX)
  u500000)                      ;; coverage amount (500 STX)
```

#### 2. Pay Additional Premium (Optional)

```clarity
(contract-call? .event-insurance pay-additional-premium 
  u1                           ;; policy ID
  u25000)                      ;; additional amount (25 STX)
```

#### 3. File Insurance Claim

```clarity
(contract-call? .event-insurance file-claim 
  u1                           ;; policy ID
  u300000                      ;; claim amount (300 STX)
  "Venue unavailable due to emergency")  ;; reason
```

#### 4. Cancel Policy (After Event Date)

```clarity
(contract-call? .event-insurance cancel-policy u1)
```

### 🛡️ For Contract Administrators

#### Approve Claims

```clarity
(contract-call? .event-insurance approve-claim u1)  ;; claim ID
```

#### Reject Claims

```clarity
(contract-call? .event-insurance reject-claim u1)   ;; claim ID
```

#### Update Platform Fee

```clarity
(contract-call? .event-insurance update-platform-fee u750)  ;; 7.5% fee
```

## 📊 Contract Functions

### Public Functions

| Function | Description | Parameters |
|----------|-------------|-----------|
| `create-policy` | Create new insurance policy | event-name, event-date, premium-amount, coverage-amount |
| `pay-additional-premium` | Add funds to existing policy | policy-id, amount |
| `file-claim` | Submit insurance claim | policy-id, claim-amount, reason |
| `approve-claim` | Approve pending claim (admin only) | claim-id |
| `reject-claim` | Reject pending claim (admin only) | claim-id |
| `cancel-policy` | Cancel policy after event date | policy-id |
| `update-platform-fee` | Update platform fee (admin only) | new-fee |
| `emergency-withdraw` | Emergency fund withdrawal (admin only) | policy-id |

### Read-Only Functions

| Function | Description | Returns |
|----------|-------------|----------|
| `get-policy` | Get policy details | Policy data or none |
| `get-claim` | Get claim details | Claim data or none |
| `get-policy-balance` | Get policy fund balance | Balance in STX |
| `get-platform-fee` | Get current platform fee | Fee percentage (basis points) |
| `get-policy-counter` | Get total policies created | Counter value |
| `get-claim-counter` | Get total claims filed | Counter value |
| `get-contract-balance` | Get total contract balance | Balance in STX |

## 💼 Business Logic

### Policy Lifecycle

1. **Creation** - Organizer pays premium and sets coverage amount
2. **Active** - Policy is active until event date
3. **Claim Filing** - Claims can be filed for cancelled events
4. **Processing** - Admin reviews and approves/rejects claims
5. **Payout** - Approved claims trigger automatic STX transfers
6. **Closure** - Policy closes when funds are exhausted or cancelled

### Fee Structure

- Platform fee: 5% (500 basis points) by default
- Maximum fee: 10% (1000 basis points)
- Fee deducted from approved claim payouts

### Security Features

- ✅ Owner-only administrative functions
- ✅ Policy ownership verification
- ✅ Claim amount validation
- ✅ Event date validation
- ✅ Insufficient funds protection
- ✅ Double-claim prevention

## 🔧 Development

### Local Testing

1. Start Clarinet console:
```bash
clarinet console
```

2. Deploy contract:
```clarity
(contract-call? .event-insurance get-policy-counter)
```

3. Test policy creation:
```clarity
(contract-call? .event-insurance create-policy "Test Event" u100 u1000 u10000)
```

### Deployment

Deploy to testnet:
```bash
clarinet deployments generate --testnet
clarinet deployments apply -p testnet
```

Deploy to mainnet:
```bash
clarinet deployments generate --mainnet
clarinet deployments apply -p mainnet
```

## 📈 Roadmap

- 🔮 Oracle integration for automatic event cancellation detection
- 🤖 Multi-signature claim approval system  
- 📱 Frontend web application for easy policy management
- 🏪 Marketplace for policy trading and transfers
- 📊 Analytics dashboard for policy and claim statistics



## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🆘 Support

- 📧 Email: support@event-insurance.com
- 💬 Discord: [Join our community](https://discord.gg/event-insurance)
- 📖 Documentation: [docs.event-insurance.com](https://docs.event-insurance.com)
- 🐛 Issues: [GitHub Issues](https://github.com/your-username/event-cancellation-insurance/issues)

---

Made with ❤️ for the Stacks ecosystem
