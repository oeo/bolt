## introduction

bolt is a censorship-resistant, distributed proof-of-work blockchain designed for data posting. the blockchain is built using coffeescript and leverages the scrypt algorithm for cpu efficiency. miners are rewarded in bolt, the native currency of the chain.

## features

- **censorship resistance**: bolt allows for immutable data posting, making it resistant to censorship.
- **scrypt algorithm**: designed to be cpu-efficient, making it accessible for a wide range of hardware.
- **native currency**: bolt has its native currency for rewarding miners.
- **data posting**: the blockchain is designed to store and handle data posts securely.

## getting started

### prerequisites

- node.js
- coffeescript
- mongodb
- redis

### installation

1. clone the repository
2. install dependencies
3. update the `config.coffee` file as necessary
4. run the miner

### files & directories

#### main files
- `miner.coffee`: contains the mining logic and environment setup.
- `config.coffee`: holds global configurations for the blockchain.

#### models
- `models/contract.coffee`: defines smart contracts.
- `models/blockchain.coffee`: contains main blockchain logic.
- `models/transaction.coffee`: defines transactions.
- `models/block.coffee`: defines blocks.

#### libraries
- `lib/helpers.coffee`: provides utility functions.
- `lib/wallet.coffee`: manages wallet operations.

#### scripts
- `scripts/generate-wallets.coffee`: utility script for generating wallets.

## configuration

- `version`: blockchain version
- `staging`: staging environment flag
- `minfee`: minimum transaction fee
- `maxblocksize`: maximum block size
- `rewarddefault`: default block reward
- `difficultydefault`: default mining difficulty

for more details, refer to `config.coffee`.

