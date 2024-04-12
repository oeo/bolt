### prerequisites
- nodejs
- coffeescript
- mongodb
- redis

### installation

1. clone the repository
1. install dependencies
1. update the `config.coffee` file as necessary

### primitives
- `models/contract.coffee`: defines smart contracts.
- `models/blockchain.coffee`: contains main blockchain logic.
- `models/transaction.coffee`: defines transactions.
- `models/block.coffee`: defines blocks.

### libraries
- `lib/helpers.coffee`: provides utility functions.
- `lib/wallet.coffee`: manages wallet operations.

### scripts
- `scripts/generate-wallets.coffee`: utility script for generating wallets.

### configuration
- `VERSION`: blockchain version
- `STAGING`: staging environment flag
- `minFee`: minimum transaction fee
- `maxBlockSize`: maximum block size
- `rewardDefault`: default block reward
- `difficultyDefault`: default mining difficulty

for more details, refer to `config.coffee`.

