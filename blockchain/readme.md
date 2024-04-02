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

- `VERSION`: blockchain version
- `STAGING`: staging environment flag
- `minFee`: minimum transaction fee
- `maxBlockSize`: maximum block size
- `rewardDefault`: default block reward
- `difficultyDefault`: default mining difficulty

for more details, refer to `config.coffee`.

