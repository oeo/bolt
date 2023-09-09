## Introduction

Bolt is a censorship-resistant, distributed Proof-of-Work blockchain designed for data posting. The blockchain is built using CoffeeScript and leverages the Scrypt algorithm for CPU efficiency. Miners are rewarded in Bolt, the native currency of the chain.

## Features

- **Censorship resistance**: Bolt allows for immutable data posting, making it resistant to censorship.
- **Scrypt algorithm**: Designed to be CPU-efficient, making it accessible for a wide range of hardware.
- **Native currency**: Bolt has its native currency for rewarding miners.
- **Data posting**: The blockchain is designed to store and handle data posts securely.

## Getting Started

### Prerequisites

- Node.js
- CoffeeScript
- MongoDB
- Redis

### Installation

1. Clone the repository
2. Install dependencies
3. Update the `config.coffee` file as necessary
4. Run the miner

### Files & directories

#### Main files
- `miner.coffee`: Contains the mining logic and environment setup.
- `config.coffee`: Holds global configurations for the blockchain.

#### Models
- `models/contract.coffee`: Defines smart contracts.
- `models/blockchain.coffee`: Contains main blockchain logic.
- `models/transaction.coffee`: Defines transactions.
- `models/block.coffee`: Defines blocks.

#### Libraries
- `lib/helpers.coffee`: Provides utility functions.
- `lib/wallet.coffee`: Manages wallet operations.

#### Scripts
- `scripts/generate-wallets.coffee`: Utility script for generating wallets.

## Configuration

- `VERSION`: Blockchain version
- `STAGING`: Staging environment flag
- `minFee`: Minimum transaction fee
- `maxBlockSize`: Maximum block size
- `rewardDefault`: Default block reward
- `difficultyDefault`: Default mining difficulty

For more details, refer to `config.coffee`.

